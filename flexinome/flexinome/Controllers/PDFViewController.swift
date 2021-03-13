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
    
    private let metronomeButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "metronome_color"), for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(pdfView)
        view.addSubview(metronomeButton)
        metronomeButton.addTarget(self, action: #selector(metronomeButtonTapped), for: .touchUpInside)
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.displayMode = .singlePage
            pdfView.autoScales = true
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(true)
            pdfView.document = document
        }
        self.hideNavigationBarWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        pdfView.frame = view.frame
        
        metronomeButton.frame = CGRect(x: view.frame.maxX-70 , y: view.frame.maxY*0.9, width: 60, height: 60)
    }
    
    // open metronome page in a modal view
    @IBAction func metronomeButtonTapped() {
        
        let vc = self.storyboard?.instantiateViewController(identifier: "MetronomeViewController")
        self.present(vc!, animated: true, completion: nil)
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
