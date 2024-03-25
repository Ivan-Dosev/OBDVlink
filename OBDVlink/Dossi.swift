//
//  Dossi.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 14.01.24.
//

import Foundation
/*
 class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

 var centralManager = CBCentralManager()
 var peripherals = [CBPeripheral]()
 @IBOutlet weak var outputTextView: UITextView!

 override func viewDidLoad() {
     super.viewDidLoad()
     centralManager.delegate = self
 }

 override func didReceiveMemoryWarning() {
     super.didReceiveMemoryWarning()
 }

 func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
     print("connected to \(peripheral.name ?? "unnamed")")
     peripheral.delegate = self
     peripheral.discoverServices([CBUUID(string:"E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")])
 }

 func centralManagerDidUpdateState(_ central: CBCentralManager) {
     if central.state == .poweredOn {
         central.scanForPeripherals(withServices: nil, options: nil)
     }
 }

 func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
     if peripheral.name == "IOS-Vlink" {
         peripherals.append(peripheral)
         print(peripheral.name ?? "peripheral has no name")
         print(peripheral.description)
         central.connect(peripheral, options: nil)
         central.stopScan()
     }

 }

 func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
     guard let services = peripheral.services else {
         return
     }
     for service in services {
         peripheral.discoverCharacteristics([CBUUID(string:"BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")], for: service)
     }
 }

 func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
     guard let chars = service.characteristics else {
         return
     }
     guard chars.count > 0 else {
         return
     }
     let char = chars[0]
     peripheral.setNotifyValue(true, for: char)
     peripheral.discoverDescriptors(for: char)

     print (char.properties)
     peripheral.writeValue("ATZ\r\n".data(using: .utf8)!, for: char, type: CBCharacteristicWriteType.withResponse)

     peripheral.readValue(for: char)
     if let value = char.value {
         print(String(data:value, encoding:.utf8) ?? "bad utf8 data")
     }
 }

 func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
     if let value = characteristic.value {
         print(String(data:value, encoding:.utf8)!)
     }
 }
 func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
     print(characteristic.descriptors ?? "bad didDiscoverDescriptorsFor")
 }
 func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
     if let error = error {
         print(error)
     }
     print("wrote to \(characteristic)")
     if let value = characteristic.value {
         print(String(data:value, encoding:.utf8)!)
     }
 }
 }
 */
