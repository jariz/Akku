import Foundation
import IOBluetooth

class Driver: NSObject {
    
    // MARK: -
    // MARK: Initialisation
    
    init (appProtocol: AppProtocol?) {
        self.appProtocol = appProtocol
    }
    
    // MARK: -
    // MARK: Private IOKit variables
    
    fileprivate var connection: io_connect_t = 0
    fileprivate var mem_addr: mach_vm_address_t = 0;
    
    // MARK: -
    // MARK: Private variables
    
    fileprivate var timer: Timer?;
    fileprivate let appProtocol: AppProtocol?;
    fileprivate let packetParser = PacketParser()
    
    // MARK: -
    // MARK: Internal IOBluetoothHCIController communication
    
    public func open () throws {
        // get driver
        let port = kIOMasterPortDefault;
        
        var serviceName = "IOBluetoothHCIController";
        
        if #available(OSX 10.15, *) {
            serviceName = "IOBluetoothPacketLogger";
        }
        
        let service = IOServiceGetMatchingService(port, IOServiceMatching(serviceName))
        
        if (service == 0) {
            throw BluetoothHCIError.driverNotFound
        }
        
        // open connnection
        var ret = IOServiceOpen(service, mach_task_self_, UInt32((arc4random() << 8) + 1), &connection)
        IOObjectRelease(service)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.failedToOpen(ioError: ret.string)
        }
        
        // map memory
        var mem_size: mach_vm_size_t = 0
        ret = IOConnectMapMemory64(self.connection, 0xffff, mach_task_self_, &self.mem_addr, &mem_size, 1)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.mapMemoryFail(ioError: ret.string)
        }
    }
    
    fileprivate func dump () throws {
        // instruct controller to dump log to our memory
        var input: UInt64 = 0;
        var inputStruct = 1;
        
        var output: UInt64 = 0;
        var outputCnt: UInt32 = 1;
        var outputStruct = 0;
        var outputStructCnt = 0;
        
        let ret = IOConnectCallMethod(connection, 0, &input, 0, &inputStruct, 0, &output, &outputCnt, &outputStruct, &outputStructCnt)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.methodCallFail(ioError: ret.string)
        }
    }
    
    fileprivate func openDataQueue () throws -> Bool {
        let queuePointer = UnsafeMutablePointer<IODataQueueMemory>(bitPattern: Int(self.mem_addr));
        
        if queuePointer == nil {
            return false
        }
        
        repeat {
            let entryPointer = IODataQueuePeek(queuePointer)
            if entryPointer == nil {
                return false
            }
            
            let dequeue = IODataQueueDequeue(queuePointer, nil, nil)
            
            if (dequeue != kIOReturnSuccess) {
                throw BluetoothHCIError.dataQueueReadFail(ioError: dequeue.string)
            }
            
            let offset = unsafeBitCast(entryPointer, to: Int.self)
            _ = packetParser.read(offset)

        } while IODataQueueDataAvailable(queuePointer)
        
        for battInfo in packetParser.batteryInfos {
            if let appProtocol = self.appProtocol, let connection = battInfo.connection {
                if let docked = battInfo.docked {
                    appProtocol.reportDockChange(address: connection.addr, docked: docked)
                }
                
                if let percentage = battInfo.percentage {
                    appProtocol.reportBatteryChange(address: connection.addr, percentage: percentage)
                }
            }
        }
        
        return true
    }
    
    // MARK: -
    // MARK: Public interface
    
    func process () throws {
        var opened: Bool
        repeat {
            try self.dump()
            opened = try self.openDataQueue()
        } while opened
    }
    
    func poll () {
        self.timer = Timer(timeInterval: 5, target: self, selector: #selector(timerHit), userInfo: nil, repeats: true)
        
        OperationQueue.main.addOperation {
            RunLoop.current.add(self.timer!, forMode: .common)
        }
    }
    
    @objc
    func timerHit () {
        do {
            try self.process()
        } catch {
            log.error(error.localizedDescription)
        }
    }
}
