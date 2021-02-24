//
//  PDFViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-24.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController {
    
    var pdfView = PDFView()
        var pdfURL: URL!

        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.addSubview(pdfView)
            
            if let document = PDFDocument(url: pdfURL) {
                pdfView.displayMode = .singlePage
                pdfView.autoScales = true
                pdfView.displayDirection = .horizontal
                pdfView.usePageViewController(true)
                pdfView.document = document
            }
        }
        
        override func viewDidLayoutSubviews() {
            pdfView.frame = view.frame
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
