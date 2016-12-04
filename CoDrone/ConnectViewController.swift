//
//  ConnectViewController.swift
//  CoDrone
//
//  Created by Dave Vo on 11/27/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import UIKit

class ConnectViewController: UIViewController {
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var flightButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    
    var isFlying = false
    var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init the UI
        connectButton.backgroundColor = UIColor.clear
        connectButton.layer.cornerRadius = connectButton.frame.width / 2
        connectButton.layer.borderWidth = 2
        connectButton.clipsToBounds = true
        setConnectButton(isConnected: false)
        
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
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
            }
        }
    }
    
}
