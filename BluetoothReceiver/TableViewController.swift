//
//  TableViewController.swift
//  BluetoothReceiver
//
//  Created by Jay Tucker on 9/24/14.
//  Copyright (c) 2014 Jay. All rights reserved.
//

import UIKit
import CoreBluetooth

class TableViewController: UITableViewController {
    
    let serviceUUIDs = [
        "7AC5A6A8-4DD7-4386-9CD7-D6DF5155A131",
        "84F00541-B4F8-44CC-B96A-C8872CF164BB",
        "59541099-A405-4947-BA70-4D777F38DB8F",
        "B427777C-0153-4486-A87C-FE153686D754",
        "D1517163-EA5E-4F51-9DBD-B0E8D7BB5F55",
        "594B5A2A-1D8C-4D9D-ACA3-B371969DADF0",
        "B590B847-9804-46E3-9818-B5D81118FCFD",
        "24BBB39B-01AA-45C5-9827-9F2582656E29",
    ]
    
    let characteristicUUIDs = [
        "F93047DC-870A-4172-8B91-AD8F4EFBF21D",
        "E8C9186B-3B16-469B-BEAD-44BDF1CAB2B8",
        "9F7FD713-4357-4D41-A588-58560CDF7D81",
        "31A1ECA2-7AAF-4CBD-956E-21EF295E0A5C",
        "6EB70B8B-0D1D-408A-8174-3B6F9CE33766",
        "BADF0FEC-0616-4C28-B3DE-5CA1981E72AD",
        "968D7D5F-BB21-4028-87A3-33E6631156E0",
        "886484C7-DF60-4C05-A9EF-51D26EAFF309",
    ]
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var isPoweredOn = false
    var scanTimer: NSTimer!
    // use this to disconnect after all the requested characteristic values have been read
    var nCharacteristicsRequested = 0
    var alertMessage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // helper func
    
    func indexOfString(string: String, inArray array: [String]) -> Int {
        for i in 0 ..< array.count {
            if array[i] == string {
                return i
            }
        }
        return -1
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceUUIDs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServiceCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = "Service \(indexPath.row + 1)"
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if isPoweredOn {
            startScanForPeripheralWithService(serviceUUIDs[indexPath.row])
        }
    }
    
    func startScanForPeripheralWithService(uuid: String) {
        let i = indexOfString(uuid, inArray: serviceUUIDs) + 1
        println("startScanForPeripheralWithService \(i) \(uuid)")
        centralManager.stopScan()
        scanTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: Selector("timeout"), userInfo: nil, repeats: false)
        centralManager.scanForPeripheralsWithServices([CBUUID(string: uuid)], options: nil)
    }
    
    func timeout() {
        println("timed out")
        centralManager.stopScan()
    }

}

extension TableViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        var caseString: String!
        switch centralManager.state {
        case .Unknown:
            caseString = "Unknown"
        case .Resetting:
            caseString = "Resetting"
        case .Unsupported:
            caseString = "Unsupported"
        case .Unauthorized:
            caseString = "Unauthorized"
        case .PoweredOff:
            caseString = "PoweredOff"
        case .PoweredOn:
            caseString = "PoweredOn"
        default:
            caseString = "WTF"
        }
        println("centralManagerDidUpdateState \(caseString)")
        isPoweredOn = (centralManager.state == .PoweredOn)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("centralManager didDiscoverPeripheral")
        scanTimer.invalidate()
        centralManager.stopScan()
        self.peripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("centralManager didConnectPeripheral")
        self.peripheral.delegate = self
        let indexPath = tableView.indexPathForSelectedRow()
        if let row = indexPath?.row {
            peripheral.discoverServices([CBUUID(string: serviceUUIDs[row])])
        }
    }
    
}

extension TableViewController: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            println("peripheral didDiscoverServices ok")
        } else {
            println("peripheral didDiscoverServices error \(error.localizedDescription)")
            return
        }
        for service in peripheral.services {
            let uuid = "\(service.UUID)"
            let i = indexOfString(uuid, inArray: serviceUUIDs) + 1
            println("service \(i) \(uuid)")
            var uuids = [CBUUID]()
            for i in 0 ..< characteristicUUIDs.count {
                // TODO
            }
            peripheral.discoverCharacteristics(nil, forService: service as! CBService)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error == nil {
            let uuid = "\(service.UUID)"
            let i = indexOfString(uuid, inArray: serviceUUIDs) + 1
            println("peripheral didDiscoverCharacteristicsForService \(i) ok")
        } else {
            println("peripheral didDiscoverCharacteristicsForService error \(error.localizedDescription)")
            return
        }
        nCharacteristicsRequested = service.characteristics.count
        alertMessage = ""
        for characteristic in service.characteristics {
            let uuid = "\(characteristic.UUID)"
            let i = indexOfString(uuid, inArray: characteristicUUIDs) + 1
            println("characteristic \(i) \(uuid)")
            peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            let uuid = "\(characteristic.UUID)"
            let i = indexOfString(uuid, inArray: characteristicUUIDs) + 1
            println("peripheral didUpdateValueForCharacteristic \(i) ok")
        } else {
            println("peripheral didUpdateValueForCharacteristic error \(error.localizedDescription)")
            return
        }
        let value: String = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)! as String
        println("  \(value)")
        // let shorterValue = value.substringFromIndex(advance(value.startIndex, 20))
        nCharacteristicsRequested--;
        if alertMessage.isEmpty {
            alertMessage = value
        } else {
            alertMessage += "\n" + value
        }
        if nCharacteristicsRequested == 0 {
            println("disconnecting")
            centralManager.cancelPeripheralConnection(peripheral)
            let serviceUUID = characteristic.service.UUID.UUIDString
            let i = indexOfString(serviceUUID, inArray: serviceUUIDs) + 1
            let alert = UIAlertView(title: "Service \(i)", message: alertMessage, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
}

