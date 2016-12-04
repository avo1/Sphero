//
//  ConnectViewController.swift
//  CoDrone
//
//  Created by Dave Vo on 11/27/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import UIKit
import Darwin

class ConnectViewController: UIViewController {
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var flightButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var leftJoystickImage: UIImageView!
    @IBOutlet weak var rightJoystickImage: UIImageView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var batteryImage: UIImageView!
    @IBOutlet weak var batteryLabel: UILabel!
    
    
    var isFlying = false
    var isConnected = false
    var isExhaused = false  // battery < critical level
    
    var joystickRadius: CGFloat!
    var leftButtonCenter: CGPoint!
    var rightButtonCenter: CGPoint!
    
    // For transmission
    var timerTXDelay: Timer?
    var timerBatteryCheck: Timer?
    
    var throttle: Int8 = 0
    var yaw: Int8 = 0
    var pitch: Int8 = 0
    var roll: Int8 = 0
    
    var preThrottle: Int8 = 0
    var preYaw: Int8 = 0
    var prePitch: Int8 = 0
    var preRoll: Int8 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(self.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        // Watch battery percentage
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryUpdated(_:)), name: NSNotification.Name(rawValue: BatteryStatusNotification), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BatteryStatusNotification), object: nil)
    }
    
    func initialize() {
        // Init the UI
        connectButton.backgroundColor = UIColor.clear
        connectButton.layer.cornerRadius = connectButton.frame.width / 2
        connectButton.layer.borderWidth = 2
        connectButton.clipsToBounds = true
        setConnectButton(isConnected: false)
        batteryLabel.text = ""
        
        view.layoutIfNeeded()
        //print("left center = \(leftJoystickImage.center)")
        joystickRadius = leftJoystickImage.bounds.width / 2 - 10.0
        leftButtonCenter = leftJoystickImage.center
        rightButtonCenter = rightJoystickImage.center
    }
    
    
    func setConnectButton(isConnected: Bool) {
        if isConnected {
            connectButton.layer.borderColor = UIColor.blue.cgColor
            connectButton.backgroundColor = UIColor(red: 19/255, green: 158/255, blue: 236/255, alpha: 1)
            connectButton.setImage(UIImage(named: "whiteBT"), for: UIControlState.normal)
        } else {
            connectButton.layer.borderColor = UIColor.lightGray.cgColor
            connectButton.backgroundColor = UIColor.white
            connectButton.setImage(UIImage(named: "bluetooth"), for: UIControlState.normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // why it only works when all appear?
        SwiftSpinner.show("Searching for drone...").addTapHandler({
            SwiftSpinner.hide()
            btDiscoverySharedInstance.clearDevices()
        }, subtitle: "Tap to cancel")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timerTXDelay?.invalidate()
        timerBatteryCheck?.invalidate()
    }
    
    func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        if let userInfo = (notification as NSNotification).userInfo as? [String: Bool] {
            
            DispatchQueue.main.async(execute: {
                // Set image based on connection status
                if let connected: Bool = userInfo["isConnected"] {
                    self.isConnected = connected
                    self.setConnectButton(isConnected: connected)
                    
                    if connected {
                        self.deviceLabel.text = btDiscoverySharedInstance.deviceName
                        self.statusLabel.text = "Connected"
                        
                        SwiftSpinner.sharedInstance.innerColor = UIColor.green.withAlphaComponent(0.5)
                        SwiftSpinner.show("Connected", animated: false).delay(0.7, completion: {
                            // return to default color
                            SwiftSpinner.sharedInstance.innerColor = UIColor.gray
                            SwiftSpinner.hide()
                            
                            // start to check the battery
                            if let bleService = btDiscoverySharedInstance.bleService {
                                bleService.writeCommand(DroneCmd.checkBatteryCmd)
                                
                                self.timerBatteryCheck = Timer.scheduledTimer(timeInterval: DroneCmd.batteryCheckFrequency,
                                                                              target: self,
                                                                              selector: #selector(self.checkBattery),
                                                                              userInfo: nil,
                                                                              repeats: true)
                            }
                            
                        })
                        
                    } else {
                        self.statusLabel.text = "Disconnected"
                        self.isFlying = false
                        self.flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
                        self.timerBatteryCheck?.invalidate()
                        self.resetControl()
                    }
                }
            })
        }
    }
    
    func batteryUpdated(_ notification: Notification) {
        // Battery updated. Indicate on GUI.
        if let userInfo = (notification as NSNotification).userInfo as? [String: UInt8] {
            
            DispatchQueue.main.async(execute: {
                // Set image based on connection status
                if let battery: UInt8 = userInfo["battery"] {
                    print("battery = \(battery)")
                    if battery == 100 {
                        self.batteryLabel.text = "100%"
                    } else {
                        self.batteryLabel.text = String(battery) + " %"
                    }
                    
                    if battery > DroneCmd.batteryWarningLevel {
                        self.isExhaused = false
                        self.batteryImage.image = UIImage(named: "greenBattery")
                        self.batteryLabel.textColor = UIColor.init(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)
                    } else {
                        self.isExhaused = false
                        self.batteryImage.image = UIImage(named: "redBattery")
                        self.batteryLabel.textColor = UIColor.init(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
                        
                        if battery < DroneCmd.batteryCriticalLevel {
                            self.isExhaused = true
                            self.statusLabel.text = "Low battery, don't fly"
                        }
                    }
                    
                }
            })
        }
    }
    
    @IBAction func scanPeripheral(_ sender: UIButton) {
        if isConnected {
            // Only allow to Disconnect it not flying
            if isFlying {
                statusLabel.text = "Flying, can't disconnect"
            } else {
                btDiscoverySharedInstance.clearDevices()
            }
            
        } else {
            // Start the Bluetooth discovery process
            btDiscoverySharedInstance.startScanning()
            SwiftSpinner.show("Searching for drone...").addTapHandler({
                SwiftSpinner.hide()
                btDiscoverySharedInstance.clearDevices()
            }, subtitle: "Tap to cancel")
        }
    }
    
    func analogScaleChange(_ value: CGFloat, fromRange: CGFloat, toRange: Int8) -> Int8 {
        return Int8(value * CGFloat(toRange) / fromRange)
    }
    
    @IBAction func onLeftJoyStick(_ sender: UIPanGestureRecognizer) {
        let state = sender.state
        let translation = sender.translation(in: self.view)
        
        if state == .changed {
            // don't go out of the joystick
            var x = translation.x
            var y = translation.y
            let d = x * x + y * y
            if d <= joystickRadius * joystickRadius {
                leftButton.center = CGPoint(x: leftButtonCenter.x + x, y: leftButtonCenter.y + y)
            } else {
                let k = sqrt(d) / joystickRadius
                x = x/k
                y = y/k
                leftButton.center = CGPoint(x: leftButtonCenter.x + x, y: leftButtonCenter.y + y)
            }
            
            // convert -y -> throttle, x -> yaw
            throttle = -analogScaleChange(y, fromRange: joystickRadius, toRange: 100)
            yaw = analogScaleChange(x, fromRange: joystickRadius, toRange: 100)
        }
        
        if state == .ended {
            throttle = 0
            yaw = 0
            leftButton.center = leftButtonCenter
        }
    }
    
    @IBAction func onRightJoyStick(_ sender: UIPanGestureRecognizer) {
        let state = sender.state
        let translation = sender.translation(in: self.view)
        
        if state == .changed {
            // don't go out of the joystick
            var x = translation.x
            var y = translation.y
            let d = x * x + y * y
            if d <= joystickRadius * joystickRadius {
                rightButton.center = CGPoint(x: rightButtonCenter.x + x, y: rightButtonCenter.y + y)
            } else {
                let k = sqrt(d) / joystickRadius
                x = x/k
                y = y/k
                rightButton.center = CGPoint(x: rightButtonCenter.x + x, y: rightButtonCenter.y + y)
            }
            
            // convert -y -> pitch, x -> roll
            // it moves so fast and easily out of control, let make it in scale of 50
            pitch = -analogScaleChange(y, fromRange: joystickRadius, toRange: 50)
            roll = analogScaleChange(x, fromRange: joystickRadius, toRange: 50)
        }
        
        if state == .ended {
            pitch = 0
            roll = 0
            rightButton.center = rightButtonCenter
        }
    }
    
}

// MARK: Transmission

extension ConnectViewController {
    
    func resetControl() {
        timerTXDelay?.invalidate()
        throttle = 0
        yaw = 0
        pitch = 0
        roll = 0
    }
    
    @IBAction func estop(_ sender: UIButton) {
        if isFlying {
            print("send command: estop")
            
            if let bleService = btDiscoverySharedInstance.bleService {
                resetControl()
                bleService.writeCommand(DroneCmd.estopCmd)
                statusLabel.text = "E-stop"
                isFlying = false
                flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
            }
        }
    }
    
    @IBAction func landingOrTakeoff(_ sender: UIButton) {
        if isFlying {
            print("send command: landing")
            
            if let bleService = btDiscoverySharedInstance.bleService {
                resetControl()
                bleService.writeCommand(DroneCmd.landingCmd)
                statusLabel.text = "Landing"
                isFlying = false
                flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
            }
            
        } else {
            if isExhaused {
                print("Can't take off, low battery")
                statusLabel.text = "Low battery, don't fly"
            } else {
                print("send command: take off")
                
                if let bleService = btDiscoverySharedInstance.bleService {
                    bleService.writeCommand(DroneCmd.takeOffCmd)
                    statusLabel.text = "Take off"
                    isFlying = true
                    flightButton.setImage(UIImage(named: "landing"), for: UIControlState.normal)
                    
                    // Start to control
                    timerTXDelay = Timer.scheduledTimer(timeInterval: DroneCmd.sendControlFrequency, target: self, selector: #selector(self.sendPosition), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    func checkBattery() {
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeCommand(DroneCmd.checkBatteryCmd)
        }
    }
    
    func sendPosition() {
        
        if !isFlying {
            return
        }
        
        // if nothing has change then don't send?
        if (preThrottle == throttle) && (preYaw == yaw) &&
            (prePitch == pitch) && (preRoll == roll) {
            return
        }
        
        preThrottle = throttle
        preYaw = yaw
        prePitch = pitch
        preRoll = roll
        
        // Send position to BLE Shield (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService {
            print("control(r,p,y,t) = \(roll, pitch, yaw, throttle)")
            bleService.writeCommand(DroneCmd.flightCommand(r: roll, p: pitch, y: yaw, t: throttle))
        }
    }
    
}
