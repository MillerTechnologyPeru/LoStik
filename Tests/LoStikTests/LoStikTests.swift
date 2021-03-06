import Foundation
import XCTest
@testable import LoStik

final class LoStikTests: XCTestCase {
    
    static var allTests = [
        ("testCommand", testCommand),
        ("testVersion", testVersion),
        ("testHardwareIdentifier", testHardwareIdentifier)
        ]
    
    func testCommand() {
        
        let commands: [(Command, String)] = [
            (.system(.sleep(120)), "sys sleep 120"),
            (.system(.reset), "sys reset"),
            (.system(.eraseFirmware), "sys eraseFW"),
            (.system(.factoryReset), "sys factoryRESET"),
            (.system(.set(.rom(.min, 0xA5))), "sys set nvm 300 A5"),
            (.system(.set(.digitalPin(.gpio5, .on))), "sys set pindig GPIO5 1"),
            (.system(.set(.pinMode(.gpio5, .analog))), "sys set pinmode GPIO5 ana"),
            (.system(.get(.version)), "sys get ver"),
            (.system(.get(.rom(.min))), "sys get nvm 300"),
            (.system(.get(.voltage)), "sys get vdd"),
            (.system(.get(.identifier)), "sys get hweui"),
            (.system(.get(.digitalPin(.gpio5))), "sys get pindig GPIO5"),
            (.system(.get(.analogPin(.gpio0))), "sys get pinana GPIO0"),
            (.mac(.reset), "mac reset"),
            (.mac(.pause), "mac pause"),
            (.mac(.forceEnable), "mac forceENABLE"),
            (.mac(.transmit(.confirmed, LoStik.Mac.Port(rawValue: 4)!, Data([0x5A, 0x5B, 0x5B]))), "mac tx cnf 4 5A5B5B"),
            (.radio(.receive(0)), "radio rx 0"),
            (.radio(.transmit(Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))), "radio tx 48656C6C6F")
        ]
        
        for (command, string) in commands {
            XCTAssertEqual(command.description, string)
        }
    }
    
    func testVersion() {
        
        let string = "RN2903 1.0.3 Aug 8 2017 15:11:09"
        
        guard let version = Version(rawValue: string)
            else { XCTFail("Invalid string \(string)"); return }
        
        XCTAssertEqual(version.rawValue, string)
        XCTAssertEqual(version.description, string)
    }
    
    func testHardwareIdentifier() {
        
        let values: [(String, UInt64)] = [
            ("0004A30B0026A211", 0x0004A30B0026A211),
            ("0004A30B00274135", 0x0004A30B00274135)
        ]
        
        for (string, value) in values {
            XCTAssertEqual(string, HardwareIdentifier(rawValue: value).description)
        }
    }
    
    #if LOSTIK
    func testConnection() {
        
        #if os(Linux)
        let port = "/dev/ttyUSB0"
        #elseif os(macOS)
        let port = "/dev/cu.wchusbserial14230"
        #endif
        
        do {
            let loStik = try LoStik(port: port)
            let version = try loStik.system.version()
            print("Version: \(version)")
            let hardwareIdentifier = try loStik.system.hardwareIdentifier()
            print("Hardware Identifier: \(hardwareIdentifier)")
            // blink leds
            try loStik.system.setPin(.gpio10, state: .on)
            usleep(100_000)
            try loStik.system.setPin(.gpio10, state: .off)
            try loStik.system.setPin(.gpio11, state: .on)
            usleep(100_000)
            try loStik.system.setPin(.gpio11, state: .off)
            // stop LoRaWan
            let pauseDuration = try loStik.mac.pause()
            print("Pausing LoRaWAN for \(pauseDuration) miliseconds")
            // send data
            try loStik.radio.transmit(Data("test \(Date())".utf8))
            let recievedData = try loStik.radio.recieve(windowSize: 100)
            print("Recieved \(recievedData)")
        }
        catch { XCTFail("Error: \(error)") }
    }
    #endif
}
