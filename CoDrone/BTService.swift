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

/* Services & Characteristics UUIDs */
let DRONE_NAME = "PETRONE 7118"
let DRONE_SERVICE_UUID = CBUUID(string: "C320DF00-7891-11E5-8BCF-FEFF819CDC9F")
let DRONE_DATA_UUID =    CBUUID(string: "C320DF01-7891-11E5-8BCF-FEFF819CDC9F")  // Notify
let DRONE_CONF_UUID =    CBUUID(string: "C320DF02-7891-11E5-8BCF-FEFF819CDC9F")  // Write

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"
let BatteryStatusNotification = "kBatteryStatusNotification"


class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var writeCommandCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([DRONE_SERVICE_UUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForBTService: [CBUUID] = [DRONE_DATA_UUID, DRONE_CONF_UUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.uuid == DRONE_SERVICE_UUID {
                peripheral.discoverCharacteristics(uuidsForBTService, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for aChar in characteristics {
                if aChar.uuid == DRONE_CONF_UUID {
                    self.writeCommandCharacteristic = aChar
                    peripheral.setNotifyValue(true, for: aChar)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                    
                } else if aChar.uuid == DRONE_DATA_UUID {
                    peripheral.setNotifyValue(true, for: aChar)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var batteryPercentage: UInt8 = 0
        
        if characteristic.uuid == DRONE_DATA_UUID {
            if let data = characteristic.value {
                batteryPercentage = UInt8(data.last!)
                // Send notification that battery status is constantly updated
                self.sendBTServiceNotificationWithBatteryStatus(batteryPercentage)
            }
        }
    }
    
    // Mark: - Private
    
    func writeCommand(_ command: [UInt8]) {
        // See if characteristic has been discovered before writing to it
        if let writeCommandCharacteristic = self.writeCommandCharacteristic {
            let data = Data(bytes: command)
            self.peripheral?.writeValue(data, for: writeCommandCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
    }
    
    func sendBTServiceNotificationWithBatteryStatus(_ batteryLevel: UInt8) {
        let battery = ["battery": batteryLevel]
        NotificationCenter.default.post(name: Notification.Name(rawValue: BatteryStatusNotification), object: self, userInfo: battery)
    }
    
}
