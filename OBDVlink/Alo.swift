//
//  Alo.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 25.01.24.
//

import SwiftUI

struct Alo: View {
    
    @State var text : String = "49 02 01 53 42 31 5A 45 33 4A 45 33 30 45 30 39 31 35 32 31"
    @State var dossiText : String = "4902015342315A45334A45333045303931353231"
    @State var result : String = ""
    
    @State var dossi : String = "A1C7"
    @State var dossiInt : Int = 0
    
    // let value = UInt32(hex.dropFirst(2), radix: 16) ?? 0
    // print(text.split(separator: " ", maxSplits: 2))
    var body: some View {
        VStack{
            
   Text("DosiInt: \(String(dossiInt - 40))")
        Text("result: \(result)")
        Button(action: {
            let str = "Dossi"
            let data = Data(str.utf8)
            let hexString = data.map{ String(format:"%02x", $0) }.joined()
            
            
            self.result = hexString
            print(hexString)
          
        }, label: {
            Text("V I N")
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).fill(.gray))
                .foregroundColor(.white)
        })
            
            Button(action: {
                let components = Array(dossiText)
              var i = 0
                for  com in components {
                    i += 1
                    if i % 2 == 1{
                        result +=   " "
                    }
                        result +=  String(com)

                   
                }
                print(result)
               
            }, label: {
                Text("Dossi")
            })
      }
    }
    
    private func dossiFunc() -> Int {
        let d4 = Int(dossi, radix: 16)!
        return d4
    }
    
    private func decode_VIN(response: String) async -> String {
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
    
    func smartString(text: String) {

        let data = Data(text.utf8)
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        
        let counts = 64 - hexString.count
        let newString = hexString + String(repeating:  "0", count: counts)
    }
    
}

struct Alo_Previews: PreviewProvider {
    static var previews: some View {
        Alo()
    }
}
