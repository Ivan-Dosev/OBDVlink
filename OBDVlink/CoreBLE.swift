//
//  CoreBLE.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 14.01.24.
//

import Foundation
import CoreBluetooth

class CoreBLE : NSObject, ObservableObject {
    
    private    var nameOBD2          : String = "989149728950"
    private    var serviceUUID       : String = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    private    var caracteristicUUID : String = "49535343-1E4D-4BD9-BA61-23C647249616"
  //  private    var caracteristicUUID : String = "49535343-8841-43F4-A8D4-ECBE34729BB3"
    
    @Published var peripheral    : CBPeripheral?     = nil
    @Published var characteristic: CBCharacteristic? = nil

    @Published var dossiValue    :  [String] = []
    @Published var codeToRun     : String = ""
    
    private var buffer = Data()
    var sendMessageCompletion: (([String]?, Error?) -> Void)?
    var idBits : Int = 11
    
    private var centralManager: CBCentralManager!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    
    func sendToOBD2(commant : String) {
        
        guard let peripheralNew = self.peripheral, let characteristicNew = characteristic else { return }
        
        peripheralNew.writeValue("\(commant)\r".data(using: .utf8)!, for: characteristicNew, type: CBCharacteristicWriteType.withResponse)
      
 
        peripheralNew.readValue(for: characteristicNew)
      //sendMessageAsyncwithTimeoutSecs(temperature, withTimeoutSecs: 3)
        
    }
    
    private func decodeVIN(response: String) async -> String {
        // Find the index of the occurrence of "49 02"
        guard let prefixIndex = response.range(of: "49 02")?.upperBound else {
            print("Prefix not found in the response")
            return ""
        }
        // Extract the VIN hex string after "49 02"
        let vinHexString = response[prefixIndex...]
            .split(separator: " ")
            .joined() // Remove spaces
    
        // Convert the hex string to ASCII characters
        var asciiString = ""
        var hex = vinHexString
        while !hex.isEmpty {
            let startIndex = hex.startIndex
            let endIndex = hex.index(startIndex, offsetBy: 2)
    
            if let hexValue = UInt8(hex[startIndex..<endIndex], radix: 16) {
                let unicodeScalar = UnicodeScalar(hexValue)
                asciiString.append(Character(unicodeScalar))
            } else {
                print("Error converting hex to UInt8")
            }
            hex.removeFirst(2)
        }
        // Remove non-alphanumeric characters from the VIN
        let vinNumber = asciiString.replacingOccurrences(
            of: "[^a-zA-Z0-9]",
            with: "",
            options: .regularExpression
        )
        // getvininfo
        return vinNumber
    }
    
    
    func sendMessageAsyncwithTimeoutSecs(_ message: String, withTimeoutSecs: TimeInterval = 5) async throws -> [String] {
        let response: [String] = try await withTimeout(seconds: withTimeoutSecs) {
            let res = try await self.sendMessageAsyncArda(message)
            
            return res
        }
        return response
      
    }
    
    func sendMessageAsyncArda(_ message: String, characteristic: CBCharacteristic? = nil) async throws -> [String] {
        // ... (sending message logic)
      
        let message = "\(message)\r"

        guard let connectedPeripheral = self.peripheral,
              let characteristic = self.characteristic,
              let data = message.data(using: .ascii
              ) else { return ["..."]}

        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<[String], Error>) in
            // Set up a timeout timer
          
                
                self!.sendMessageCompletion = { response, error in
                    if let response = response {
                        continuation.resume(returning: response)
                        self!.dossiValue = response
                       // print("...\(response)")

                    } else if let error = error {
                        continuation.resume(throwing: error)

                    }
            
            }

            connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
           // connectedPeripheral.readValue(for: characteristic)
        }
    }
    
    func didUpdateValueArda(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) {
        
      

        guard let characteristicValue = characteristic.value else { return }
        
        if characteristicValue == self.characteristic?.value {
          
            processReceivedDataArda(characteristicValue, completion: sendMessageCompletion)
        }
    }
    
    func processReceivedDataArda(_ data: Data, completion: (([String]?, Error?) -> Void)?) {
        
        buffer.append(data)
        guard var string = String(data: buffer, encoding: .utf8) else {
         
            buffer.removeAll()
            return
        }

        if string.contains(">") ||  string.contains(codeToRun){

            string = string
                .replacingOccurrences(of: "\u{00}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Split into lines while removing empty lines
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            // remove the last line
            lines.removeLast()
            print("🐸 \(lines)")
            completion?(lines, nil)
            buffer.removeAll()
        }
    }
    

    func disconnectPeripheral() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func connectTo(peripheral: CBPeripheral) {
        
        self.peripheral = peripheral
        centralManager.connect(peripheral)
    }
}

extension CoreBLE: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral,advertisementData: [String : Any],rssi RSSI: NSNumber) {
        
        if peripheral.name == nameOBD2 {
            self.peripheral = peripheral

            central.connect(peripheral, options: nil)
            central.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("connected to \(peripheral.name ?? "unnamed")")
        peripheral.delegate = self
      //  peripheral.discoverServices([CBUUID(string:"E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")])
        peripheral.discoverServices([CBUUID(string: serviceUUID)])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral) {
       
     
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        guard error == nil else { return }
 
    }
}


extension CoreBLE: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("service: \(service.uuid)")
            peripheral.discoverCharacteristics([CBUUID(string:caracteristicUUID)], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics ?? [] {
            print("characteristic: \(characteristic.uuid)")
            if (String(describing: characteristic.uuid)) == caracteristicUUID {
                
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                self.characteristic =  characteristic
            //    if characteristic.properties.contains(.write) {
            //
            //
            //                           // "010D\r\n"
            //        peripheral.writeValue("\(time_run_km)\n\r".data(using: .utf8)!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            //    }
            //
            //    if characteristic.properties.contains(.read) {
            //
            //        peripheral.readValue(for: characteristic)
            //    }
            }
        }

    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
   //   if let error = error {
   //       print(error)
   //   }
   //   print("wrote to \(characteristic)")
   //   if let value = characteristic.value {
   //       var stringValue = String(data:value, encoding:.utf8) ?? "bad utf8 data didWriteValueFor"
   //       self.writeValue  = stringValue
   //       print("writeValue: \(writeValue)")
   //   }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
          didUpdateValueArda(peripheral, characteristic: characteristic, error: error)
        
//   if let value = characteristic.value {
//
//
//      let stringValue = String(data:value, encoding: .utf8) ?? "bad utf8 data didUpdateValueFor"
//      print("update🦁: \(stringValue)")
//
//   }
//
//    guard var string = String(data: characteristic.value!, encoding: .utf8) else {
//        print("bad utf8 data didUpdateValueFor")
//        return
//    }
//        print("stringII: \(string)")
//        if string.contains(">") {
//
//            string = string
//                .replacingOccurrences(of: "\u{00}", with: "")
//                .trimmingCharacters(in: .whitespacesAndNewlines)
//
//            // Split into lines while removing empty lines
//            var lines = string
//                .components(separatedBy: .newlines)
//                .filter { !$0.isEmpty }
//
//            // remove the last line
//            lines.removeLast()
//
//               print("Response: \(lines)")
//
//
//        }else {
//            print(">>>\(string)")
//        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
            print("didDiscoverDescriptorsFor")
            print(characteristic.descriptors ?? "bad didDiscoverDescriptorsFor")
    }
    
}





//MARK:
   extension Data {
       var hexDescription: String {
           return reduce("") {$0 + String(format: "%02x", $1)}
       }
   }


extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

extension Double {
    var km: Double { return self * 1_000.0 }
    var m: Double { return self }
    var cm: Double { return self / 100.0 }
    var mm: Double { return self / 1_000.0 }
    var ft: Double { return self / 3.28084 }
}

//let oneInch = 25.4.mm
//print("One inch is \(oneInch) meters") // 输出 "One inch is 0.0254 meters"

