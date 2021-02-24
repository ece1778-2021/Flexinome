//
//  FilesViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-23.
//

import UIKit
import PDFKit

class FilesViewController: UIViewController, DocumentDelegate {
    
    var documentPicker: DocumentPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
    }
    
    /// callback from the document picker
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
                    
//                    DispatchQueue.main.async {
                    let url = URL(string: fileURL.absoluteString)
                    let pdfData = try? Data.init(contentsOf: url!)
                    let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))[0]
                    let pdfNameFromUrl = filename!.text! + ".pdf"
                    let actualPath = resourceDocPath.appendingPathComponent(pdfNameFromUrl)
                    do {
                        try pdfData?.write(to: actualPath, options: .atomic)
                        print("pdf successfully saved!")
                    } catch {
                        print("Pdf could not be saved")
                        print(error.localizedDescription)
                    }
//                    }

                }
            }))
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func viewPDF(_ sender: Any) {
        if #available(iOS 10.0, *) {
            do {
                let docURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let contents = try FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: [.fileResourceTypeKey], options: .skipsHiddenFiles)
                for url in contents {
                    if url.description.contains("test.pdf") {
                       // its your file! do what you want with it!
                        print(url)
                    }
                }
            } catch {
                print("could not locate pdf file !!!!!!!")
            }
        }
    }
    
    @IBAction func uploadFile(_ sender: Any) {
        documentPicker.displayPicker()
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
