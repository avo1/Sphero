//
//  BTService.swift
//  CoDrone
//
//  Refer to the tutorial from
//  https://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//
//  Created by Dave Vo on 12/3/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import Foundation
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery()

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var peripheralBLE: CBPeripheral?
    var deviceName = ""
    
    override init() {
        super.init()
        
        let centralQueue = DispatchQueue(label: "vn.coderschool", attributes: [])
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    func startScanning() {
        print("start scanning")
        if let central = centralManager {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    var bleService: BTService? {
        didSet {
            if let service = self.bleService {
                service.startDiscoveringServices()
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            self.clearDevices()
            
        case .unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            break
            
        case .unknown:
            // Wait for another event
            break
            
        case .poweredOn:
            print("Bluetooth is On and ready.")
            self.startScanning()
            
        case .resetting:
            self.clearDevices()
            
        case .unsupported:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // Get the device name
        let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey)
            as? String
        
        if let device = device  {
            deviceName = device
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.disconnected)) {
            // Retain the peripheral before trying to connect
            self.peripheralBLE = peripheral
            
            // Reset service
            self.bleService = nil
            
            // Connect to peripheral
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            self.bleService = BTService(initWithPeripheral: peripheral)
        }
        
        // Stop scanning for new devices
        central.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was our peripheral that disconnected
        if (peripheral == self.peripheralBLE) {
            self.bleService = nil;
            self.peripheralBLE = nil;
        }
    }
    
    // MARK: - Private
    
    func clearDevices() {
        if let peripheral = self.peripheralBLE {
            print("cancel connection")
            self.centralManager?.cancelPeripheralConnection(peripheral)
        }
        self.bleService = nil
        self.peripheralBLE = nil
    }
    
}

