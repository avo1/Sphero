//
//  ConnectViewController.swift
//  CoDrone
//
//  Created by Dave Vo on 11/27/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import UIKit
import CoreBluetooth

//let DRONE_NAME = "PETRONE 7118"
//let DRONE_SERVICE_UUID = CBUUID(string: "C320DF00-7891-11E5-8BCF-FEFF819CDC9F")
//let DRONE_DATA_UUID =    CBUUID(string: "C320DF01-7891-11E5-8BCF-FEFF819CDC9F")  // Notify
//let DRONE_CONF_UUID =    CBUUID(string: "C320DF02-7891-11E5-8BCF-FEFF819CDC9F")  // Write

class ConnectViewController: UIViewController {
    
    var manager: CBCentralManager!
    var peripheral: CBPeripheral?
    var writeCommandCharacteristic: CBCharacteristic?
    var readDataCharacteristic: CBCharacteristic?
    
    var isConnected = false
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var mfgLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        manager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scanPeripheral(_ sender: UIButton) {
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    

    @IBAction func takeOff(_ sender: UIButton) {
        print("send command: take off")
        writeCommand([0x11, 0x22, 0x01])  //u8: 0x22: Flight Event, then 0x01: Takeoff
    }
    
    @IBAction func landing(_ sender: UIButton) {
        print("send command: landing")
        writeCommand([0x11, 0x22, 0x06])  //u8: 0x22: Flight Event, then 0x06: Landing
    }
    
}

extension ConnectViewController: CBCentralManagerDelegate, CBPeripheralDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            //            central.scanForPeripherals(withServices: nil, options: nil)
            print("Peripheral is On and ready.")
        } else {
            print("Bluetooth not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey)
            as? String
        
        if let device = device  {
            deviceLabel.text = device
            
            self.manager.stopScan()
            
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            
            manager.connect(peripheral, options: nil)
            print("found \(device)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = (peripheral.state == CBPeripheralState.connected)
        
        if isConnected {
            peripheral.discoverServices(nil)
            print("connected")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            print("Discovered service: \(service.uuid)")
            
            if service.uuid == DRONE_SERVICE_UUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            print("char: \(thisCharacteristic.uuid)")
            self.peripheral?.readValue(for: thisCharacteristic)
            
            if thisCharacteristic.uuid == DRONE_CONF_UUID {
                writeCommandCharacteristic = thisCharacteristic
                //self.peripheral?.setNotifyValue(true, for: thisCharacteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //var mfgName = ""
        print("did update value for characteristic: \(characteristic.value)")
        //        if characteristic.uuid == CODRONE_SERVICE_UUID {
        //            mfgName = characteristic.value! // .copyBytes(to: &count, count: MemoryLayout<UInt32>.size)
        //            mfgLabel.text = mfgName
        //        }
    }
    
    
    func writeCommand(_ cmd: [UInt8]) {
        // See if characteristic has been discovered before writing to it
        if let cmdCharacteristic = self.writeCommandCharacteristic {
            let data = Data(bytes: cmd)
            self.peripheral?.writeValue(data, for: cmdCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    
    
}
