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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
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
                    
                } else {
                    self.statusLabel.text = "Drone is disconnected"
                }
            }
        })
    }
    
    @IBAction func scanPeripheral(_ sender: UIButton) {
        // Start the Bluetooth discovery process
        _ = btDiscoverySharedInstance
    }
    

    @IBAction func takeOff(_ sender: UIButton) {
        print("send command: take off")
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeCommand([0x11, 0x22, 0x01])
            statusLabel.text = "Take off"
        }
        //writeCommand()  //u8: 0x22: Flight Event, then 0x01: Takeoff
    }
    
    @IBAction func landing(_ sender: UIButton) {
        print("send command: landing")
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeCommand([0x11, 0x22, 0x06])
            statusLabel.text = "Landing"
        }
        //writeCommand([0x11, 0x22, 0x06])  //u8: 0x22: Flight Event, then 0x06: Landing
    }
    
}
