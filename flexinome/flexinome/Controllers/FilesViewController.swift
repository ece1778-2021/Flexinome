//
//  FilesViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-23.
//

import UIKit
import PDFKit

class FilesViewController: UIViewController, DocumentDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    var documentPicker: DocumentPicker!
    var openURL: URL!
    var URLs: [URL] = []
    var filteredURLs: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
        let layout = UICollectionViewFlowLayout()
        collectionView.collectionViewLayout = layout
        collectionView.register(MyCollectionViewCell.nib(), forCellWithReuseIdentifier: MyCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        
        self.loadPDFs()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PDFViewController
        destinationVC.pdfURL = self.openURL
    }
    
    @IBAction func uploadFile(_ sender: Any) {
        documentPicker.displayPicker()
    }
    
    // callback from the document picker
    func didPickDocument(document: Document?) {
        if (document != nil) {
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Filename", message: "Enter a filename", preferredStyle: .alert)
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = ""
            }
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let filename = alert?.textFields![0] // Force unwrapping because we know it exists.
                if let pickedDoc = document {
                    let fileURL = pickedDoc.fileURL
                    let url = URL(string: fileURL.absoluteString)
                    let pdfData = try? Data.init(contentsOf: url!)
                    let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]
                    let pdfNameFromUrl = filename!.text! + ".pdf"
                    let actualPath = resourceDocPath.appendingPathComponent(pdfNameFromUrl)
                    do {
                        try pdfData?.write(to: actualPath, options: .atomic)
                        print("pdf successfully saved!")
                        self.URLs.insert(url!, at: 0)
                        self.filteredURLs.insert(url!, at: 0)
                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                    } catch {
                        print("Pdf could not be saved")
                        print(error.localizedDescription)
                    }

                }
            }))
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func loadPDFs() {
        if #available(iOS 10.0, *) {
            do {
                let docURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let contents = try FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: [.fileResourceTypeKey], options: .skipsHiddenFiles)
                for url in contents {
                    self.URLs.append(url)
                }
                self.collectionView.reloadData()
            } catch {
                print("could not locate pdf file !!!!!!!")
            }
        }
        filteredURLs = URLs
    }
    
    // This method updates filteredURLs based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredURLs is the same as the original URLs
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the URLs array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredURLs = searchText.isEmpty ? URLs : URLs.filter { (item: URL) -> Bool in
            // If dataItem matches the searchText, return true to include it
            let filename = item.lastPathComponent
            return filename.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        
        collectionView.reloadData()
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

//extension FilesViewController: UIDocumentInteractionControllerDelegate {
//    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
//        return self
//    }
//}

extension FilesViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.openURL = filteredURLs[indexPath.row]
        self.performSegue(withIdentifier: "pdfSegue", sender: self)
    }
}

extension FilesViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.identifier, for: indexPath) as! MyCollectionViewCell
        cell.configure(with: self.filteredURLs[indexPath.row])
        return cell
    }
    
}

extension FilesViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 10) / 3
        return CGSize(width: width, height: width * 1.3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}
