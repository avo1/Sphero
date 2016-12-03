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
    
    var isFlying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SwiftSpinner.show(delay: 0.5, title: "Shouldn't see this", animated: false)
        SwiftSpinner.hide()
        
        SwiftSpinner.show(delay: 0.7, title: "Searching for drone", animated: true)
    }
    
    func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.deviceLabel.text = btDiscoverySharedInstance.deviceName
                    self.statusLabel.text = "Drone is connected"
                    SwiftSpinner.hide()
                } else {
                    self.statusLabel.text = "Drone is disconnected"
                }
            }
        })
    }
    
    @IBAction func scanPeripheral(_ sender: UIButton) {
        
    }
    
    @IBAction func estop(_ sender: UIButton) {
        print("send command: estop")
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeCommand([0x11, 0x22, 0x06])
            statusLabel.text = "E-stop"
            isFlying = false
            flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
        }
    }

    @IBAction func landingOrTakeoff(_ sender: UIButton) {
        if isFlying {
            print("send command: landing")
            if let bleService = btDiscoverySharedInstance.bleService {
                bleService.writeCommand([0x11, 0x22, 0x07])
                statusLabel.text = "Landing"
                isFlying = false
                flightButton.setImage(UIImage(named: "takeoff"), for: UIControlState.normal)
            }
            
        } else {
            print("send command: take off")
            if let bleService = btDiscoverySharedInstance.bleService {
                bleService.writeCommand([0x11, 0x22, 0x01])
                statusLabel.text = "Take off"
                isFlying = true
                flightButton.setImage(UIImage(named: "landing"), for: UIControlState.normal)
            }
        }
    }
    
}
