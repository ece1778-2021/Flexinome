//
//  SequencerViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-03-13.
//

import UIKit
import SpreadsheetView
import KBNumberPad

class SequencerViewController: UIViewController, SpreadsheetViewDataSource, SpreadsheetViewDelegate {
    
    @IBOutlet weak var songTitle: UITextField!
    
    private let spreadsheetView = SpreadsheetView()
    let headers = ["Bar", "Repetition", "Tempo", "Time Signature", "Turn"]
    var sequencerDict: [String: Dictionary<String,String>] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self
        spreadsheetView.register(InputCell.self, forCellWithReuseIdentifier: InputCell.identifier)
        spreadsheetView.register(LabelCell.self, forCellWithReuseIdentifier: LabelCell.identifier)
        spreadsheetView.register(TimeSignatureCell.self, forCellWithReuseIdentifier: TimeSignatureCell.identifier)
        view.addSubview(spreadsheetView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spreadsheetView.frame = CGRect(x: 25, y: 130, width: view.frame.size.width-50, height: view.frame.size.height-130)
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
        if (indexPath.row == 0) {
            cell.backgroundColor = .systemBlue
            cell.label.textColor = .white
            cell.label.text = self.headers[indexPath.column]
        }
        else {
            if (indexPath.column == 3) {
                let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: TimeSignatureCell.identifier, for: indexPath) as! TimeSignatureCell
                cell.setup()
                return cell
            }
            else {
                let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: InputCell.identifier, for: indexPath) as! InputCell
                cell.setup()
                return cell
            }
        }
        return cell
    }
    
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return 5
    }
    
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 11
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        return (view.frame.size.width-56) / 5
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        return 80
    }

    @IBAction func saveSequencer(_ sender: Any) {
        var isEmpty: Bool = false
        loops:
        for row in 1...10 {
            var dict: [String: String] = [:]
            for col in 0...4 {
                if (col == 3) {
                    let cell = spreadsheetView.cellForItem(at: NSIndexPath(row: row, section: col) as IndexPath) as! TimeSignatureCell
                    dict[headers[col]] = cell.textField.text!
                }
                else {
                    let cell = spreadsheetView.cellForItem(at: NSIndexPath(row: row, section: col) as IndexPath) as! InputCell
                    if (col == 0 && cell.textField.text! == "") {
                        if (row == 1) {
                            isEmpty = true
                        }
                        break loops
                    }
                    dict[headers[col]] = cell.textField.text!
                }
            }
            sequencerDict[String(row)] = dict
        }
        if (isEmpty) {
            self.showMessagePrompt(message: "No data has been entered!")
        }
        else {
            if (self.songTitle.text == "") {
                self.showMessagePrompt(message: "Please enter a song title!")
            }
            else {
                do {
                    // here "jsonData" is the dictionary encoded in JSON data
                    let jsonData = try JSONSerialization.data(withJSONObject: sequencerDict, options: .prettyPrinted)
                    
                    // write json to file
                    let fileManager = FileManager.default
                    let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let jsonPath = documentsURL.appendingPathComponent("json")
                    do
                    {
                        try FileManager.default.createDirectory(atPath: jsonPath.path, withIntermediateDirectories: true, attributes: nil)
                        let actualPath = jsonPath.appendingPathComponent(self.songTitle.text! + ".json")
                        do {
                            try jsonData.write(to: actualPath)
                            print("file successfully saved!")
                            self.navigationController?.popViewController(animated: true)
                        } catch {
                            print("file could not be saved")
                            print(error.localizedDescription)
                        }
                    }
                    catch let error as NSError
                    {
                        NSLog("Unable to create directory \(error.debugDescription)")
                    }

                    // here "decoded" is of type `Any`, decoded from JSON data
                    let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])

                    // you can now cast it with the right type
                    if let dictFromJSON = decoded as? [String:Dictionary<String,String>] {
                        print(dictFromJSON)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func showMessagePrompt(message: String) {
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class CustomAlertController : UIAlertController, KBNumberPadDelegate {
    private let textField = UITextField()
    let numberPad = KBNumberPad()
    
    override func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        numberPad.delegate = self
        textField.inputView = numberPad
    }
    
    func onNumberClicked(numberPad: KBNumberPad, number: Int) {
        textField.text?.append(String(number))
    }

    func onDoneClicked(numberPad: KBNumberPad) {
        UIApplication.shared.endEditing() // Call to dismiss keyboard
    }

    func onClearClicked(numberPad: KBNumberPad) {
        NSLog("Clear clicked")
        if (!textField.text!.isEmpty) {
            textField.text?.removeLast()
        }
    }
}

class InputCell: Cell, KBNumberPadDelegate{

    static let identifier = "InputCell"

    public let textField = UITextField()
    let numberPad = KBNumberPad()

    public func setup() {
        numberPad.delegate = self
        textField.inputView = numberPad
        textField.textAlignment = .center
        textField.font = UIFont.init(name: (textField.font?.fontName)!, size: 24.0)
        textField.textColor = .black
        contentView.addSubview(textField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textField.frame = contentView.bounds
    }

    func onNumberClicked(numberPad: KBNumberPad, number: Int) {
        textField.text?.append(String(number))
    }

    func onDoneClicked(numberPad: KBNumberPad) {
        UIApplication.shared.endEditing() // Call to dismiss keyboard
    }

    func onClearClicked(numberPad: KBNumberPad) {
        NSLog("Clear clicked")
        if (!textField.text!.isEmpty) {
            textField.text?.removeLast()
        }
    }
}

class TimeSignatureCell: Cell, UIPickerViewDelegate, UIPickerViewDataSource {

    static let identifier = "TimeSignatureCell"

    public let textField = UITextField()
    let timeSignatures = ["", "1/4", "2/4", "3/4", "4/4", "5/4", "6/4", "7/4", "9/4", "2/8", "3/8", "6/8", "9/8", "12/8"]

    public func setup() {
        let picker = UIPickerView()
        picker.delegate = self
        textField.inputView = picker
        textField.textAlignment = .center
        textField.font = UIFont.init(name: (textField.font?.fontName)!, size: 24.0)
        textField.textColor = .black
        contentView.addSubview(textField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textField.frame = contentView.bounds
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeSignatures.count
    }

    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
     return timeSignatures[row]
    }

    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textField.text = timeSignatures[row]
    }
}

class LabelCell: Cell {
    
    static let identifier = "LabelCell"
    
    public let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.font = UIFont.systemFont(ofSize: 22.0)
        label.textAlignment = .center

        contentView.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
