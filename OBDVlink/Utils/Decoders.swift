//
//  Decoders.swift
//  OBDVlink
//
//  Created by Dosi Dimitrov on 21.01.24.
//

import Foundation

func bytesToInt(_ byteArray: Data) -> Int {
    var value = 0
    var power = 0

    for byte in byteArray.reversed() {
        value += Int(byte) << power
        power += 8
    }
    return value
}

enum OBDDecodeResult {
    case stringResult(String)
    case statusResult(Status)
    case measurementResult(Measurement<Unit>)
    case measurementMonitor(Monitor)
    case troubleCode([TroubleCode])
    case noResult
}

struct FuelStatus {
}

struct Status {
    var MIL: Bool = false
    var dtcCount: UInt8 = 0
    var ignitionType: String = ""

    var misfireMonitoring: StatusTest
    var fuelSystemMonitoring: StatusTest
    var componentMonitoring: StatusTest

    // Add other properties for SPARK_TESTS and COMPRESSION_TESTS here
    init() {
        misfireMonitoring = StatusTest()
        fuelSystemMonitoring = StatusTest()
        componentMonitoring = StatusTest()
    }
}

struct BitArray {
    let data: Data
    var binaryArray: [Int] {
       // Convert Data to binary array representation
       var result = [Int]()
       for byte in data {
           for i in 0..<8 {
               // Extract each bit of the byte
               let bit = (byte >> (7 - i)) & 1
               result.append(Int(bit))
           }
       }
       return result
    }

    func index(of value: Int) -> Int? {
           // Find the index of the given value (1 or 0)
           return binaryArray.firstIndex(of: value)
    }

    func value(at range: Range<Int>) -> UInt8 {
        var value: UInt8 = 0
        for bit in range {
            value = value << 1
            value = value | UInt8(binaryArray[bit])
        }
        return value
    }
}

struct UAS {
    let signed: Bool
    let scale: Double
    let unit: Unit
    let offset: Double

    init(signed: Bool, scale: Double, unit: Unit, offset: Double = 0.0) {
        self.signed = signed
        self.scale = scale
        self.unit = unit
        self.offset = offset
    }

    func decode(bytes: Data) -> Measurement<Unit>? {
        var value = bytesToInt(bytes)

        if signed {
            value = twosComp(value, length: bytes.count * 8)
        }

        let scaledValue = Double(value) * scale + offset
        return Measurement(value: scaledValue, unit: unit)
    }
}

func twosComp(_ value: Int, length: Int) -> Int {
    let mask = (1 << length) - 1
    return value & mask
}

extension Unit {
    static let percent = Unit(symbol: "%")
    static let count = Unit(symbol: "count")
    static let celsius = Unit(symbol: "°C")
    static let degrees = Unit(symbol: "°")
    static let gramsPerSecond = Unit(symbol: "g/s")
    static let none = Unit(symbol: "")
    static let kmh = Unit(symbol: "km/h")
    static let rpm = Unit(symbol: "rpm")
    static let kPa = Unit(symbol: "kPa")
    static let bar = Unit(symbol: "bar")
}

let uasIDS: [UInt8: UAS] = [
    // Unsigned
    0x01: UAS(signed: false, scale: 1.0, unit: Unit.count),
    0x02: UAS(signed: false, scale: 0.1, unit: Unit.count),
    0x07: UAS(signed: false, scale: 0.25, unit: Unit.rpm),
    0x09: UAS(signed: false, scale: 1, unit: Unit.kmh),
    0x12: UAS(signed: false, scale: 1, unit: UnitDuration.seconds),

    0x27: UAS(signed: false, scale:  0.01, unit: Unit.gramsPerSecond),

    // Signed
    0x81: UAS(signed: true, scale: 1.0, unit: Unit.count),
    0x82: UAS(signed: true, scale: 0.1, unit: Unit.count)
]



enum Decoder: Codable {
    case pid
    case status
    case singleDTC
    case fuelStatus
    case percent
    case temp
    case percentCentered
    case fuelPressure
    case pressure
    case uas0x07
    case uas0x09
    case uas0x12
    case timingAdvance
    case uas0x27
    case airStatus
    case o2Sensors
    case sensorVoltage
    case obdCompliance
    case o2SensorsAlt
    case auxInputStatus
    case uas0x25
    case uas0x19
    case uas0x1B
    case uas0x01
    case uas0x16
    case uas0x0B
    case uas0x1E
    case evapPressure
    case sensorVoltageBig
    case currentCentered
    case absoluteLoad
    case uas0x34
    case maxMaf
    case fuelType
    case absEvapPressure
    case evapPressureAlt
    case injectTiming
    case dtc
    case fuelRate
    case monitor
    case count
    case cvn
    case encoded_string
    case none

    func decode(data: Data) -> OBDDecodeResult? {
        switch self {
        case .pid:
            return nil
        case .status:
            return .statusResult(status(data))
        case .uas0x09:
            guard let measurement = decodeUAS(data, id: 0x09) else { return .noResult }
            return .measurementResult(measurement)
        case .uas0x07:
            guard let measurement = decodeUAS(data, id: 0x07) else { return .noResult }
            return .measurementResult(measurement)
        case .temp:
            guard let temp = temp(data) else { return .noResult }
            return .measurementResult(temp)
        case .percent:
            guard let percent = percent(data) else { return .noResult }
            return .measurementResult(percent)
        case .currentCentered:
            guard let currentCentered = currentCentered(data) else { return .noResult }
            return .measurementResult(currentCentered)
        case .airStatus:
            guard let airStatus = currentCentered(data) else { return .noResult }
            return .measurementResult(airStatus)
        case .singleDTC:
            guard let dtc = singleDtc(data) else { return .noResult }
            return .troubleCode([dtc])

            // TODO : add fuel status return type
        case .fuelStatus:
            guard let fuelStatus = fuelStatus(data) else { return .noResult }
            return .stringResult(fuelStatus)

        case .percentCentered:
            guard let percentCentered = percent(data) else { return .noResult }
            return .measurementResult(percentCentered)
        case .fuelPressure:
            guard let fuelPressure = fuelPressure(data) else { return .noResult }
            return .measurementResult(fuelPressure)
        case .pressure:
            guard let pressure = pressure(data) else { return .noResult }
            return .measurementResult(pressure)
        case .timingAdvance:
            guard let timingAdvance = timingAdvance(data) else { return .noResult }
            return .measurementResult(timingAdvance)
            // TODO : add obd Compliance return type

        case .obdCompliance:
            guard let obdCompliance = obdCompliance(data) else { return .noResult }
            return .stringResult(obdCompliance)

        case .o2SensorsAlt:
            guard let o2SensorsAlt = o2SensorsAlt(data) else { return .noResult }
            return .stringResult(o2SensorsAlt)

        case .uas0x12:
            guard let uasValue =  decodeUAS(data, id: 0x12) else { return .noResult }
            return .measurementResult(uasValue)

        case .o2Sensors:
            guard let o2Sensors = o2Sensors(data) else { return .noResult }
            return .stringResult(o2Sensors)

        case .sensorVoltage:
            guard let voltage = voltage(data) else { return .noResult }
            return .measurementResult(voltage)

        case .auxInputStatus:
            return nil

        case .uas0x19:
            guard let uasValue = decodeUAS(data, id: 0x19) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x1B:
            guard let uasValue = decodeUAS(data, id: 0x1B) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x01:
            guard let uasValue = decodeUAS(data, id: 0x01) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x16:
            guard let uasValue = decodeUAS(data, id: 0x16) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x0B:
            guard let uasValue = decodeUAS(data, id: 0x0B) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x1E:
            guard let uasValue = decodeUAS(data, id: 0x1E) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x25:
            guard let uasValue = decodeUAS(data, id: 0x25) else { return .noResult }
            return .measurementResult(uasValue)
        case .uas0x27:
            guard let uasValue = decodeUAS(data, id: 0x27) else { return .noResult }
            return .measurementResult(uasValue)

        case .sensorVoltageBig:
            guard let voltage = sensorVoltage(data) else { return .noResult }
            return .measurementResult(voltage)

        case .evapPressure:
             guard let pressure = evapPressure(data) else { return .noResult }
             return .measurementResult(pressure)
        case .none:
            return nil
        case .absoluteLoad:
            guard let load = absoluteLoad(data) else { return .noResult }
            return .measurementResult(load)
        case .uas0x34:
            guard let uasValue = decodeUAS(data, id: 0x34) else { return .noResult }
            return .measurementResult(uasValue)
        case .maxMaf:
            guard let maf = maxMaf(data) else { return .noResult }
            return .measurementResult(maf)
        case .fuelType:
            guard let type = fuelType(data) else { return .noResult }
            return .stringResult(type)
        case .absEvapPressure:
            guard let pressure = absEvapPressure(data) else { return .noResult }
            return .measurementResult(pressure)
        case .evapPressureAlt:
            guard let pressure = evapPressureAlt(data) else { return .noResult }
            return .measurementResult(pressure)
        case .injectTiming:
            guard let timing = injectTiming(data) else { return .noResult }
            return .measurementResult(timing)
        case .dtc:
            guard let troubleCodes = dtc(data) else { return .noResult }
            return .troubleCode(troubleCodes)
        case .fuelRate:
            guard let rate = fuelRate(data) else { return .noResult }
            return .measurementResult(rate)
        case .monitor:
            guard let monitor = monitor(data) else { return .noResult }
            return .measurementMonitor(monitor)
        case .count:
            return nil
        case .cvn:
            return nil
        case .encoded_string:
            return nil
        }
    }

    func dtc(_ data: Data) -> [TroubleCode]? {
        // converts a frame of 2-byte DTCs into a list of DTCs
        let data = Data(data[1...])
        var codes: [TroubleCode] = []
        // send data to parceDtc 2 byte at a time
        for n in stride(from: 0, to: data.count - 1, by: 2) {
            let endIndex = min(n + 1, data.count - 1)
            print(data[n...endIndex])
            guard let dtc = parseDTC(data[n...endIndex]) else {
                continue
            }
            codes.append(dtc)
        }
        return codes
    }

    func monitor(_ data: Data) -> Monitor? {
        let databytes = data

        let mon = Monitor()

//        let extra_bytes = data.count % 9

//        if extra_bytes != 0 {
//            print("Encountered monitor message with non-multiple of 9 bytes. Truncating...")
//            databytes = data[..<(data.count - extra_bytes)]
//        }

        for n in stride(from: 0, to: databytes.count - 1, by: 2) {
            let test = parse_monitor_test(databytes[n...(n + 1)], mon)
            print(test?.description ?? "No test")
            if let test = test,
               let tid = test.tid {
                mon.tests[tid] = test
            }
        }

        return mon
    }

    func parse_monitor_test(_ data: Data, _ mon: Monitor) -> MonitorTest? {
        var test = MonitorTest()
        let bits = BitArray(data: data).binaryArray
        let tid = data[0]
        print(tid)
        if let testInfo = TestIds(rawValue: tid) {
            test.name = testInfo.name
            test.desc = testInfo.desc

        } else {
            print("Encountered unknown Test ID")
            test.name = "Unknown"
            test.desc = "Unknown"
        }

        let uasId = Int(data[1])
        guard let uas = uasIDS.first(where: { $0.key == uasId }) else {
            print("Encountered Unknown Units and Scaling ID")
            return nil
        }

        let valueRange = Array(bits[3..<5])
        let minRange =   Array(bits[5..<7])
        let maxRange =   Array(bits[7..<9]) // Assuming data length is at least 9

        let multiplier = uas.value.scale

        test.tid = tid
        test.value = bytesToDouble(valueRange) * multiplier
        test.min = bytesToDouble(minRange) * multiplier
        test.max = bytesToDouble(maxRange) * multiplier

        return test
    }

    func bytesToDouble(_ data: [Int]) -> Double {
        var value = 0.0
        for (index, bit) in data.enumerated() {
            value += Double(bit) * pow(2.0, Double(index))
        }
        return value
    }

    func fuelRate(_ data: Data) -> Measurement<Unit>? {
        let value = Double(bytesToInt(data)) * 0.05
        return Measurement(value: Double(value), unit: UnitFuelEfficiency.litersPer100Kilometers)
    }

    func injectTiming(_ data: Data) -> Measurement<Unit>? {
        let value = (bytesToInt(data) - 26880) / 128
        return Measurement(value: Double(value), unit: UnitPressure.degrees)
    }

    func evapPressureAlt(_ data: Data) -> Measurement<Unit>? {
        let value = bytesToInt(data) - 32767
        return Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    func absEvapPressure(_ data: Data) -> Measurement<Unit>? {
        let value = bytesToInt(data) / 200
        return Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    func fuelType(_ data: Data) -> String? {
        let i = data[0]
        var value: String?
        if i < FuelTypes.count {
            value = FuelTypes[Int(i)]
        }
        return value
    }

    func maxMaf(_ data: Data) -> Measurement<Unit>? {
        let value = data[0] * 10
        return Measurement(value: Double(value), unit: Unit.gramsPerSecond)
    }

    func absoluteLoad(_ data: Data) -> Measurement<Unit>? {
        let value = (bytesToInt(data) * 100) / 255
        return Measurement(value: Double(value), unit: Unit.percent)
    }

    func evapPressure(_ data: Data) -> Measurement<Unit>? {
        let a = twosComp(Int(data[0]), length: 8)
        let b = twosComp(Int(data[1]), length: 8)

        let value = ((Double(a) * 256.0) + Double(b)) / 4.0
        return Measurement(value: value, unit: UnitPressure.kilopascals)
    }

    func sensorVoltage(_ data: Data) -> Measurement<Unit>? {
        let value = bytesToInt(data[2..<4])
        let voltage = (Double(value) * 8.0) / 65535
        return Measurement(value: voltage, unit: UnitElectricPotentialDifference.volts)
    }

    func auxInputStatus(_ data: Data) -> Bool? {
        return ((data[0] >> 7) & 1) == 1
    }

    func o2Sensors(_ data: Data) -> String? {
        let bits = BitArray(data: data)
//        return (
//                (),  # bank 0 is invalid
//                tuple(bits[:2]),  # bank 1
//                tuple(bits[2:4]),  # bank 2
//                tuple(bits[4:6]),  # bank 3
//                tuple(bits[6:]),  # bank 4
//            )

        let bank1 = Array(bits.binaryArray[0..<4])
        let bank2 = Array(bits.binaryArray[4..<8])

        return "\(bank1), \(bank2)"
    }

    func o2SensorsAlt(_ data: Data) -> String? {
        let bits = BitArray(data: data)
//        return (
//                (),  # bank 0 is invalid
//                tuple(bits[:2]),  # bank 1
//                tuple(bits[2:4]),  # bank 2
//                tuple(bits[4:6]),  # bank 3
//                tuple(bits[6:]),  # bank 4
//            )

        let bank1 = Array(bits.binaryArray[0..<2])
        let bank2 = Array(bits.binaryArray[2..<4])
        let bank3 = Array(bits.binaryArray[4..<6])
        let bank4 = Array(bits.binaryArray[6..<8])
        
        return "\(bank1), \(bank2), \(bank3), \(bank4)"
    }

    func obdCompliance(_ data: Data) -> String? {
        let i = data[1]

        if i < OBD_COMPLIANCE.count {
            return OBD_COMPLIANCE[Int(i)]
        } else {
            print("Invalid response for OBD compliance (no table entry)")
            return nil
        }
    }

    func fuelStatus(_ data: Data) -> String? {
        let bits = BitArray(data: data)
        var status_1: String?
        var status_2: String?

        let highBits = Array(bits.binaryArray[0..<8])
        let lowBits = Array(bits.binaryArray[8..<16])
        print(highBits)

        if highBits.filter({ $0 == 1 }).count == 1, let index = highBits.firstIndex(of: 1) {
            if 7 - index < FUEL_STATUS.count {
                       status_1 = FUEL_STATUS[7 - index]
            } else {
               print("Invalid response for fuel status (high bits set)")
            }
        } else {
            print("Invalid response for fuel status (multiple/no bits set)")
        }

        if lowBits.filter({ $0 == 1 }).count == 1, let index = lowBits.firstIndex(of: 1) {
                if 7 - index < FUEL_STATUS.count {
                    status_2 = FUEL_STATUS[7 - index]
                } else {
                    print("Invalid response for fuel status (low bits set)")
                }
        } else {
            print("Invalid response for fuel status (multiple/no bits set in low bits)")
        }

        if let status_1 = status_1, let status_2 = status_2 {
               return "Status 1: \(status_1), Status 2: \(status_2)"
       } else if let status = status_1 ?? status_2 {
           return "Status: \(status)"
       } else {
           print("No valid status found.")
           return nil
       }
    }

    // 0 to 1.275 volts
    func voltage(_ data: Data) -> Measurement<Unit>? {
        guard data.count == 2 else { return nil }
        let voltage = Double(data.first ?? 0) / 200
        return Measurement(value: voltage, unit: UnitElectricPotentialDifference.volts)
    }

    func decodeUAS(_ data: Data, id: UInt8) -> Measurement<Unit>? {
        return uasIDS[id]?.decode(bytes: data)
    }

    func singleDtc(_ data: Data) -> TroubleCode? {
        return parseDTC(data)
    }

    func parseDTC(_ data: Data) -> TroubleCode? {
        print(data.compactMap { String(format: "%02X", $0) }.joined(separator: " "))

        if (data.count != 2) || (data == Data([0x00, 0x00])) {
            print("error")
            return nil
        }
        let binary = BitArray(data: data).binaryArray
        print(binary)

        // BYTES: (16,      35      )
        // HEX:    4   1    2   3
        // BIN:    01000001 00100011
        //         [][][  in hex   ]
        //         | / /
        // DTC:    C0123
        var dtc = ["P", "C", "B", "U"][Int(data[0]) >> 6]  // the last 2 bits of the first byte
//        dtc += String((data[0] >> 4) & 0b0011)  // the next pair of 2 bits. Mask off the bits we read above
        dtc += String(format: "%04X", (UInt16(data[0]) & 0x3F) << 8 | UInt16(data[1]))

//        dtc += bytes_to_hex(_bytes)[1:4]
//        dtc += bytesToHex(data)
        print(dtc)
        return TroubleCode(rawValue: dtc)
    }

    func bytesToHex(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined()
    }

    // 0 to 765 kPa
    func fuelPressure(_ data: Data) -> Measurement<Unit>? {
        print(data.compactMap { String(format: "%02X", $0) }.joined(separator: " "))
        var value = data.first ?? 0
        value *= 3
        return  Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    // 0 to 255 kPa
    func pressure(_ data: Data) -> Measurement<Unit>? {
        let value = data[0]
        return Measurement(value: Double(value), unit: UnitPressure.kilopascals)
    }

    func percent(_ data: Data) -> Measurement<Unit>? {
        var value = Double(data.first ?? 0)
        value = value * 100.0 / 255.0
        return Measurement(value: value, unit: Unit.percent)
    }

    func percentCentered(_ data: Data) -> Measurement<Unit>? {
        var value = Double(data.first ?? 0)
        value = (value - 128) * 100.0 / 128.0
        return Measurement(value: value, unit: Unit.percent)
    }

    func currentCentered(_ data: Data) -> Measurement<Unit>? {
         let value = Double(data.first ?? 0) - 128
         return Measurement(value: value, unit: UnitElectricCurrent.amperes)
     }

    func airStatus(_ data: Data) -> Measurement<Unit>? {
           let bits = BitArray(data: data).binaryArray

           let numSet = bits.filter { $0 == 1 }.count
           if numSet == 1 {
               let index = 7 - bits.firstIndex(of: 1)!
               return Measurement(value: Double(index), unit: UnitElectricCurrent.amperes)
           }
           return nil
    }

    func temp(_ data: Data) -> Measurement<Unit>? {
        let value = Double(bytesToInt(data)) - 40.0
        return Measurement(value: value, unit: UnitTemperature.celsius)
    }

    func timingAdvance(_ data: Data) -> Measurement<Unit>? {
            let value = Double(data.first ?? 0) / 2.0 - 64.0
            return  Measurement(value: value, unit: UnitAngle.degrees)
    }

    func status(_ data: Data) -> Status {
        let IGNITIONTYPE = ["Spark", "Compression"]

        //            ┌Components not ready
        //            |┌Fuel not ready
        //            ||┌Misfire not ready
        //            |||┌Spark vs. Compression
        //            ||||┌Components supported
        //            |||||┌Fuel supported
        //  ┌MIL      ||||||┌Misfire supported
        //  |         |||||||
        //  10000011 00000111 11111111 00000000
        //  00000000 00000111 11100101 00000000
        //  10111110 00011111 10101000 00010011
        //   [# DTC] X        [supprt] [~ready]

        // convert to binaryarray
        let bits = BitArray(data: data)

        var output = Status()
        output.MIL = bits.binaryArray[0] == 1
        output.dtcCount = bits.value(at: 1..<8)
        output.ignitionType = IGNITIONTYPE[bits.binaryArray[12]]

        // load the 3 base tests that are always present

        for (index, name) in baseTests.reversed().enumerated() {
            processBaseTest(name, index, bits, &output)
        }
        return output
    }

    func processBaseTest(_ testName: String, _ index: Int, _ bits: BitArray, _ output: inout Status) {
        let test = StatusTest(testName, (bits.binaryArray[13 + index] != 0), (bits.binaryArray[9 + index] == 0))
        switch testName {
        case "MISFIRE_MONITORING":
            output.misfireMonitoring = test
        case "FUEL_SYSTEM_MONITORING":
            output.fuelSystemMonitoring = test
        case "COMPONENT_MONITORING":
            output.componentMonitoring = test
        default:
            break
        }
    }


    //    func fuelStatus(_ messages: [Message]) -> (String?, String?) {
    //        guard let data = messages.first?.data.dropFirst(2) else {
    //            return (nil, nil)
    //        }
    //
    //        let FUEL_STATUS = ["Status1", "Status2", "Status3"]
    //
    //        let bits = BitArray(data: data).binaryArray
    //
    //        var status1: String? = nil
    //        var status2: String? = nil
    //
    //        if bits[0..<8].count(1) == 1 {
    //                if let index = bits[0..<8].firstIndex(of: true), 7 - index < FUEL_STATUS.count {
    //                    status1 = FUEL_STATUS[7 - index]
    //                } else {
    //                    NSLog("Invalid response for fuel status (high bits set)")
    //                }
    //            } else {
    //                NSLog("Invalid response for fuel status (multiple/no bits set)")
    //            }
    //
    //            if bits[8..<16].count(true) == 1 {
    //                if let index = bits[8..<16].firstIndex(of: true), 7 - index < FUEL_STATUS.count {
    //                    status2 = FUEL_STATUS[7 - index]
    //                } else {
    //                    NSLog("Invalid response for fuel status (high bits set)")
    //                }
    //            } else {
    //                NSLog("Invalid response for fuel status (multiple/no bits set)")
    //            }
    //
    //            return (status1, status2)
    //    }
}

class Monitor {
    var tests: [UInt8: MonitorTest] = [:]

    init() {
        for value in TestIds.allCases {
            tests[value.rawValue] = MonitorTest(tid: value.rawValue, name: value.name, desc: value.desc, value: nil, min: nil, max: nil)
        }
    }

    func add(test: MonitorTest) {
        if let tid = test.tid {
            self.tests[tid] = test
        }
    }
}

struct MonitorTest {
    var tid: UInt8?
    var name: String?
    var desc: String?
    var value: Double?
    var min: Double?
    var max: Double?

    var passed: Bool {
        guard let value = value, let min = min, let max = max else {
            return false
        }
        return value >= min && value <= max
    }

    var isNull: Bool {
        return tid == nil || value == nil || min == nil || max == nil
    }

    var description: String {
        return "\(desc ?? "") : \(value ?? 0) [\(passed ? "PASSED" : "FAILED")]"
    }
}



let baseTests = [
    "MISFIRE_MONITORING",
    "FUEL_SYSTEM_MONITORING",
    "COMPONENT_MONITORING"
]

let sparkTests = [
    "CATALYST_MONITORING",
    "HEATED_CATALYST_MONITORING",
    "EVAPORATIVE_SYSTEM_MONITORING",
    "SECONDARY_AIR_SYSTEM_MONITORING",
    nil,
    "OXYGEN_SENSOR_MONITORING",
    "OXYGEN_SENSOR_HEATER_MONITORING",
    "EGR_VVT_SYSTEM_MONITORING"
]

let compressionTests = [
    "NMHC_CATALYST_MONITORING",
    "NOX_SCR_AFTERTREATMENT_MONITORING",
    nil,
    "BOOST_PRESSURE_MONITORING",
    nil,
    "EXHAUST_GAS_SENSOR_MONITORING",
    "PM_FILTER_MONITORING",
    "EGR_VVT_SYSTEM_MONITORING"
]

let FUEL_STATUS = [
    "Open loop due to insufficient engine temperature",
    "Closed loop, using oxygen sensor feedback to determine fuel mix",
    "Open loop due to engine load OR fuel cut due to deceleration",
    "Open loop due to system failure",
    "Closed loop, using at least one oxygen sensor but there is a fault in the feedback system",
]

let FuelTypes = [
    "Not available",
    "Gasoline",
    "Methanol",
    "Ethanol",
    "Diesel",
    "LPG",
    "CNG",
    "Propane",
    "Electric",
    "Bifuel running Gasoline",
    "Bifuel running Methanol",
    "Bifuel running Ethanol",
    "Bifuel running LPG",
    "Bifuel running CNG",
    "Bifuel running Propane",
    "Bifuel running Electricity",
    "Bifuel running electric and combustion engine",
    "Hybrid gasoline",
    "Hybrid Ethanol",
    "Hybrid Diesel",
    "Hybrid Electric",
    "Hybrid running electric and combustion engine",
    "Hybrid Regenerative",
    "Bifuel running diesel",
]

let OBD_COMPLIANCE = [
    "Undefined",
    "OBD-II as defined by the CARB",
    "OBD as defined by the EPA",
    "OBD and OBD-II",
    "OBD-I",
    "Not OBD compliant",
    "EOBD (Europe)",
    "EOBD and OBD-II",
    "EOBD and OBD",
    "EOBD, OBD and OBD II",
    "JOBD (Japan)",
    "JOBD and OBD II",
    "JOBD and EOBD",
    "JOBD, EOBD, and OBD II",
    "Reserved",
    "Reserved",
    "Reserved",
    "Engine Manufacturer Diagnostics (EMD)",
    "Engine Manufacturer Diagnostics Enhanced (EMD+)",
    "Heavy Duty On-Board Diagnostics (Child/Partial) (HD OBD-C)",
    "Heavy Duty On-Board Diagnostics (HD OBD)",
    "World Wide Harmonized OBD (WWH OBD)",
    "Reserved",
    "Heavy Duty Euro OBD Stage I without NOx control (HD EOBD-I)",
    "Heavy Duty Euro OBD Stage I with NOx control (HD EOBD-I N)",
    "Heavy Duty Euro OBD Stage II without NOx control (HD EOBD-II)",
    "Heavy Duty Euro OBD Stage II with NOx control (HD EOBD-II N)",
    "Reserved",
    "Brazil OBD Phase 1 (OBDBr-1)",
    "Brazil OBD Phase 2 (OBDBr-2)",
    "Korean OBD (KOBD)",
    "India OBD I (IOBD I)",
    "India OBD II (IOBD II)",
    "Heavy Duty Euro OBD Stage VI (HD EOBD-IV)",
]

enum TestIds: UInt8, CaseIterable {
    case RTLThresholdVoltage = 0x01
    case LTRThresholdVoltage = 0x02
    case LowVoltageSwitchTime = 0x03
    case HighVoltageSwitchTime = 0x04
    case RTLSwitchTime = 0x05
    case LTRSwitchTime = 0x06
    case MINVoltage = 0x07
    case MAXVoltage = 0x08
    case TransitionTime = 0x09
    case SensorPeriod = 0x0A
    case MisFireAverage = 0x0B
    case MisFireCount = 0x0C

    var name: String {
        switch self {
        case .RTLThresholdVoltage:
            return "RTLThresholdVoltage"
        case .LTRThresholdVoltage:
            return "LTRThresholdVoltage"
        case .LowVoltageSwitchTime:
            return "LowVoltageSwitchTime"
        case .HighVoltageSwitchTime:
            return "HighVoltageSwitchTime"
        case .RTLSwitchTime:
            return "RTLSwitchTime"
        case .LTRSwitchTime:
            return "LTRSwitchTime"
        case .MINVoltage:
            return "MINVoltage"
        case .MAXVoltage:
            return "MAXVoltage"
        case .TransitionTime:
            return "TransitionTime"
        case .SensorPeriod:
            return "SensorPeriod"
        case .MisFireAverage:
            return "MisFireAverage"
        case .MisFireCount:
            return "MisFireCount"
        }
    }

    var desc: String {
           switch self {
           case .RTLThresholdVoltage:
               return "Rich to lean sensor threshold voltage"
           case .LTRThresholdVoltage:
               return "Lean to rich sensor threshold voltage"
           case .LowVoltageSwitchTime:
               return "Low sensor voltage for switch time calculation"
           case .HighVoltageSwitchTime:
               return "High sensor voltage for switch time calculation"
           case .RTLSwitchTime:
               return "Rich to lean sensor switch time"
           case .LTRSwitchTime:
               return "Lean to rich sensor switch time"
           case .MINVoltage:
               return "Minimum sensor voltage for test cycle"
           case .MAXVoltage:
               return "Maximum sensor voltage for test cycle"
           case .TransitionTime:
               return "Time between sensor transitions"
           case .SensorPeriod:
               return "Sensor period"
           case .MisFireAverage:
               return "Average misfire counts for last ten driving cycles"
           case .MisFireCount:
               return "Misfire counts for last/current driving cycles"
           }
       }
}
