//
//  SongListViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-03-14.
//

import UIKit

class SongListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var editMode = false
    var sequencerDict: [String: Dictionary<String,String>] = [:]
    var song = ""
    var URLs: [URL] = []
    var songTitles: [String] = []
    let cellID = "cellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (editMode == false) {
            navigationItem.rightBarButtonItems = [addButton, editButton]
        }
        self.URLs.removeAll()
        self.songTitles.removeAll()
        self.sequencerDict.removeAll()
        self.loadSongList()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! SequencerViewController
        if (self.editMode) {
            SequencerViewController.GlobalVariable.sequencerDict = self.sequencerDict
            destinationVC.song = self.song
            destinationVC.editMode = true
        }
    }
    
    func loadSongList() {
        if #available(iOS 10.0, *) {
            do {
                let fileManager = FileManager.default
                let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let jsonPath = documentsURL.appendingPathComponent("json")
                let contents = try FileManager.default.contentsOfDirectory(at: jsonPath, includingPropertiesForKeys: [.fileResourceTypeKey], options: .skipsHiddenFiles)
                for url in contents {
                    self.URLs.append(url)
                    let filename = url.deletingPathExtension().lastPathComponent
                    self.songTitles.append(filename)
                }
                self.tableView.reloadData()
            } catch {
                print("could not locate json file !!!!!!!")
            }
        }
    }
    
    @IBAction func editSongList(_ sender: Any) {
        navigationItem.rightBarButtonItems = [doneButton]
        self.editMode = true
    }
    
    @IBAction func doneEditing(_ sender: Any) {
        navigationItem.rightBarButtonItems = [addButton, editButton]
        self.editMode = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.default,reuseIdentifier: cellID)
        }
        cell?.textLabel?.text = self.songTitles[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do {
            self.song = URLs[indexPath.row].deletingPathExtension().lastPathComponent
            let jsonData = try Data(contentsOf: URLs[indexPath.row])
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! Dictionary<String, Dictionary<String,String>>
            
            if (self.editMode) {
                self.sequencerDict = json
                self.performSegue(withIdentifier: "sequencerSegue", sender: self)
            }
            else {
                let pvc = self.parent as! UINavigationController
                let count = pvc.viewControllers.count
                let vc = pvc.viewControllers[count - 2] as! MetronomeViewController
                
                vc.sequencerMode = true
                vc.sequencerDictionay = json
                self.navigationController?.popViewController(animated: true)
            }
       }
       catch {
           print(error)
       }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { // delete song from song list
            do {
                let fileManager = FileManager.default
                try fileManager.removeItem(at: URLs[indexPath.row])
            }
            catch {
                print(error)
            }
            self.songTitles.remove(at: indexPath.row)
            self.URLs.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
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
