import UIKit
import CoreBluetooth
import TSLAsciiCommands // Import TSL SDK

class ViewController: UIViewController, TSLAsciiCommandResponder {
    var response: [Any] = []
    
    var isSuccessful: Bool = false
    
    var errorCode: String?
    
    var messages: [Any]?
    
    var parameters: [Any]?
    
    var synchronousCommandDelegate: (any TSLAsciiCommandResponderDelegate)?
    
    func clearLastResponse() {
        <#code#>
    }
    
    func reset() {
        <#code#>
    }
    
    
    // UI Elements
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var reader: TSLAsciiCommander!
    private var scannedTags: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupReader()
    }
    
    private func setupUI() {
        connectionStatusLabel.text = "Disconnected"
        scanButton.isEnabled = false
        tableView.dataSource = self
    }
    
    private func setupReader() {
        reader = TSLAsciiCommander()
        reader.add(self)
        TSLBluetoothDeviceManager.shared().delegate = self
    }
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if reader.isConnected {
            reader.disconnect()
            updateUI(forConnection: false)
        } else {
            TSLBluetoothDeviceManager.shared().searchForDevices()
        }
    }
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        guard reader.isConnected else { return }
        scannedTags.removeAll()
        tableView.reloadData()
        
        let command = TSLInventoryCommand()
        command.includeTransponderRSSI = true
        command.transponderReceived = { [weak self] transponder in
            guard let self = self else { return }
            if let epc = transponder.epc {
                self.scannedTags.append(epc)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        reader.execute(command)
    }
    
    private func updateUI(forConnection connected: Bool) {
        connectionStatusLabel.text = connected ? "Connected" : "Disconnected"
        connectButton.setTitle(connected ? "Disconnect" : "Connect", for: .normal)
        scanButton.isEnabled = connected
    }
}

// MARK: - TSLBluetoothDeviceManagerDelegate
extension ViewController: TSLBluetoothDeviceManagerDelegate {
    func bluetoothDeviceManager(_ manager: TSLBluetoothDeviceManager, didDiscover device: CBPeripheral) {
        reader.connect(device)
    }
    
    func bluetoothDeviceManager(_ manager: TSLBluetoothDeviceManager, didConnect device: CBPeripheral) {
        updateUI(forConnection: true)
    }
    
    func bluetoothDeviceManager(_ manager: TSLBluetoothDeviceManager, didDisconnect device: CBPeripheral) {
        updateUI(forConnection: false)
    }
}

// MARK: - TSLAsciiCommanderResponder
extension ViewController: TSLAsciiCommanderResponder {
    func processReceivedLine(_ fullLine: String, moreLinesAvailable moreAvailable: Bool) -> Bool {
        print("Reader Line: \(fullLine)")
        return true
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath)
        cell.textLabel?.text = scannedTags[indexPath.row]
        return cell
    }
}

