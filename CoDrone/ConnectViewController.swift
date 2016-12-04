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
    
    var isFlying = false
    var isConnected = false
    
    var joystickRadius: CGFloat!
    var leftButtonCenter: CGPoint!
    var rightButtonCenter: CGPoint!
    
    // For transmission
    var timerTXDelay: Timer?
    var allowTX = true
    var throttle: Int8 = 0
    var yaw: Int8 = 0
    var pitch: Int8 = 0
    var roll: Int8 = 0
    
    var isDebuging = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        // debug
        if isDebuging {
            sendPosition(throttle, yaw: yaw, pitch: pitch, roll: roll)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    func initialize() {
        // Init the UI
        connectButton.backgroundColor = UIColor.clear
        connectButton.layer.cornerRadius = connectButton.frame.width / 2
        connectButton.layer.borderWidth = 2
        connectButton.clipsToBounds = true
        setConnectButton(isConnected: false)

        view.layoutIfNeeded()
        print("left center = \(leftJoystickImage.center)")
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
        
        self.stopTimerTXDelay()
    }
    
    func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let connected: Bool = userInfo["isConnected"] {
                self.isConnected = connected
                self.setConnectButton(isConnected: connected)
                
                if connected {
                    self.deviceLabel.text = btDiscoverySharedInstance.deviceName
                    self.statusLabel.text = "Drone is connected"
                    
                    SwiftSpinner.sharedInstance.innerColor = UIColor.green.withAlphaComponent(0.5)
                    SwiftSpinner.show("Connected", animated: false).delay(0.7, completion: {
                        // return to default color
                        SwiftSpinner.sharedInstance.innerColor = UIColor.gray
                        SwiftSpinner.hide()
                    })
                    
                } else {
                    self.statusLabel.text = "Drone is disconnected"
                }
            }
        })
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
            pitch = -analogScaleChange(y, fromRange: joystickRadius, toRange: 100)
            roll = analogScaleChange(x, fromRange: joystickRadius, toRange: 100)
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
    
    @IBAction func estop(_ sender: UIButton) {
        if isFlying {
            print("send command: estop")
            
            if let bleService = btDiscoverySharedInstance.bleService {
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
                bleService.writeCommand(DroneCmd.landingCmd)
                statusLabel.text = "Landing"
                isFlying = false
                flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
            }
            
        } else {
            print("send command: take off")
            
            if let bleService = btDiscoverySharedInstance.bleService {
                bleService.writeCommand(DroneCmd.takeOffCmd)
                statusLabel.text = "Take off"
                isFlying = true
                flightButton.setImage(UIImage(named: "landing"), for: UIControlState.normal)
                
                // Start to control
                sendPosition(throttle, yaw: yaw, pitch: pitch, roll: roll)
            }
        }
    }
    
    func sendPosition(_ throttle: Int8, yaw: Int8, pitch: Int8, roll: Int8) {
        if isDebuging {
            print("update \(throttle, yaw, pitch, roll)")
            // Start delay timer
            allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerTXDelayElapsed), userInfo: nil, repeats: false)
            }
        }
        
        if !allowTX || !isFlying {
            return
        }
        
        // Send position to BLE Shield (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeCommand([])
            
            // Start delay timer
            allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerTXDelayElapsed), userInfo: nil, repeats: false)
            }
        }
    }
    
    func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
        
        // Send current slider position
        self.sendPosition(throttle, yaw: yaw, pitch: pitch, roll: roll)
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }
}
