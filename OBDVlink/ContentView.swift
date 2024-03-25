//
//  ContentView.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 14.01.24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var vm = CoreBLE()
    @State var commantText : String = ""
    @State var responseString : [String] = ["nil"]
    
    @State var flueType : String = ""
    @State var temperature : String = ""
    @State var vin : String = ""
    @State var km : String = ""
    
    var body: some View {
      
            ScrollView {
                VStack {

                    
                    Text("peripheral: \n\(vm.peripheral?.name ?? "not name")")
                        .font(.system(size: 16))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("characteristic: \n\(vm.characteristic?.uuid.uuidString ?? "not name")")
                        .font(.system(size: 16))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                
                        ForEach(OBDCommands.allCases , id:\.self) { item in
                            Button(action: {
                                commantText = item.hex
                                vm.codeToRun = item.codeText
                            }, label: {
                                Text("\(item.hex) : \(item.description)  [\(item.hex == commantText ? item.decodeFunc(item: String(responseString[0].dropFirst(4))) : "[]")]")
                                    .font(.system(size:  item.hex == commantText ? 20 : 14))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            })
                            .buttonStyle(.bordered)
                        }
                    
                    
                    ForEach(vm.dossiValue , id:\.self) { item in
                        Text("\(item)")
                    }

                    
                    HStack{
                        TextField("enter command", text: $commantText)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                         Button(action: {
                          //   vm.sendToOBD2(commant: commantText)
                             
                               Task{
                                   do{
                                       self.responseString = try await  vm.sendMessageAsyncArda(commantText)
                                   }catch(let error){
                                       self.responseString = ["\(error.localizedDescription)"]
                                   }
                             
                               }
                              
                             DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                       commantText = ""
                                      
                             }
                        
                         }, label: {
                                Text("Send")
                                 .padding()
                                 .background(Capsule().fill(Color.purple))
                                 .foregroundColor(.white)
                         })
                    }
                }
                .padding()

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

enum OBDCommands : Identifiable ,Hashable , CaseIterable {
   
    case ATD
    case ATZ
    case ATE0
    case ATL0
    case ATS0
    case ATH0
    case ATSP0
    case ATSP
    case ATDPN
    case vin
    case RPM
    case distance
    case km
    case temperature
    
    var id: String { self.description}
    var hex : String {
        switch self {
            
        case .ATD: return "ATD"
        case .ATZ: return "ATZ"
        case .ATE0: return "ATE0"
        case .ATL0: return "ATL0"
        case .ATS0: return "ATS0"
        case .ATH0: return "ATH0"
        case .ATSP0: return "ATSP0"
        case .ATSP: return "ATSP"
        case .ATDPN: return "ATDPN"
        case .vin: return "0902"
        case .RPM:  return "010C"
        case .distance: return "0131"
        case .km: return "01A6"
        case .temperature: return "0105"
        }
    }
    
    var codeText : String {
        switch self {
        case .vin: return "090"
        case .RPM:  return "010"
        case .distance: return "013"
        case .km: return "01A"
        case .temperature: return "010"
        default: return "XYZ"
        }
    }
    
    var description : String {
        switch self {
            
        case .ATD: return "Set all defaults"
        case .ATZ: return "Reset OBD"
        case .ATE0: return "Eho off"
        case .ATL0: return "Line feed off"
        case .ATS0: return "Space off"
        case .ATH0: return "Headers off"
        case .ATSP0: return "Set protocol 0"
        case .ATSP: return "Set protocol N"
        case .ATDPN: return "View protocol"
        case .vin:   return "vin"
        case .RPM: return "RPM"
        case .distance: return "Distance since last clear"
        case .km: return "km"
        case .temperature: return "temperature"
        }
    }
    
    func  decodeFunc(item: String) -> String {
        
        switch self {
        case .vin:   return "vin"
        case .RPM: return "\(Int(item, radix: 16))"
        case .distance: return "\(Int(item, radix: 16))"
        case .km: return "km"
        case .temperature: return "\(Int(item, radix: 16))"
        default:  return ""
        }
    }

}

/*
 P0 = "0: Automatic",
 P1 = "1: SAE J1850 PWM (41.6 kbaud)",
 P2 = "2: SAE J1850 VPW (10.4 kbaud)",
 P3 = "3: ISO 9141-2 (5 baud init, 10.4 kbaud)",
 P4 = "4: ISO 14230-4 KWP (5 baud init, 10.4 kbaud)",
 P5 = "5: ISO 14230-4 KWP (fast init, 10.4 kbaud)",
 P6 = "6: ISO 15765-4 CAN (11 bit ID,500 Kbaud)",
 P7 = "7: ISO 15765-4 CAN (29 bit ID,500 Kbaud)",
 P8 = "8: ISO 15765-4 CAN (11 bit ID,250 Kbaud)",
 P9 = "9: ISO 15765-4 CAN (29 bit ID,250 Kbaud)",
 PA = "A: SAE J1939 CAN (11* bit ID, 250* kbaud)",
 PB = "B: USER1 CAN (11* bit ID, 125* kbaud)",
 PC = "B: USER1 CAN (11* bit ID, 50* kbaud)",
 */

