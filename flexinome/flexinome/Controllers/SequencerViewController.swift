//
//  SequencerViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-03-13.
//

import UIKit
import SpreadsheetView

class SequencerViewController: UIViewController, SpreadsheetViewDataSource, SpreadsheetViewDelegate {
    
    private let spreadsheetView = SpreadsheetView()
    
    let headers = ["Bar", "Repetition", "Tempo", "Time Signature", "Turn"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self
        spreadsheetView.gridStyle = .solid(width: 1, color: .link)
        spreadsheetView.register(InputCell.self, forCellWithReuseIdentifier: InputCell.identifier)
        spreadsheetView.register(LabelCell.self, forCellWithReuseIdentifier: LabelCell.identifier)
        view.addSubview(spreadsheetView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spreadsheetView.frame = CGRect(x: 25, y: 200, width: view.frame.size.width-50, height: view.frame.size.height-200)
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        if (indexPath.row == 0) {
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
            cell.setup(with: self.headers[indexPath.column])
            return cell
        }
        else {
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: InputCell.identifier, for: indexPath) as! InputCell
            cell.setup()
            return cell
        }
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class InputCell: Cell {
    
    static let identifier = "InputCell"
    
    private let input = UITextField()
    
    public func setup() {
        input.textAlignment = .center
        input.font = UIFont.init(name: (input.font?.fontName)!, size: 30.0)
        contentView.addSubview(input)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        input.frame = contentView.bounds
    }
    
}

class LabelCell: Cell {
    
    static let identifier = "LabelCell"
    
    private let label = UILabel()
    
    public func setup(with text: String) {
        label.text = text
        label.textAlignment = .center
        label.font = UIFont.init(name: (label.font?.fontName)!, size: 30.0)
        contentView.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
    
}
