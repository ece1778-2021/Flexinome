//
//  SongListViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-03-14.
//

import UIKit

class SongListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
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
        self.URLs.removeAll()
        self.songTitles.removeAll()
        self.loadSongList()
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
            let jsonData = try Data(contentsOf: URLs[indexPath.row])
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! Dictionary<String, Dictionary<String,String>>
            
            let pvc = self.parent as! UINavigationController
            let count = pvc.viewControllers.count
            let vc = pvc.viewControllers[count - 2] as! MetronomeViewController
            
            vc.sequencerMode = true
            vc.sequencerDictionay = json
            self.navigationController?.popViewController(animated: true)
       }
       catch {
           print(error)
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
