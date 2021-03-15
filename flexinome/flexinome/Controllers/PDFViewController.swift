//
//  PDFViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-24.
//

import UIKit
import PDFKit
import AudioKit

class PDFViewController: UIViewController {
    
    var pdfView = PDFView()
    var pdfURL: URL!
    
    // metronome data used to sync between VCs
    private var metronomeData = MetronomeData(tempo: 120, beatValue: 4, noteValue: 4)
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        return button
    }()
    
    private let metronomeButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "metronome_color"), for: .normal)
        return button
    }()
    
    // metronome embed in the pdf reader
    private let metronome = AKMetronome()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(pdfView)
        view.addSubview(playButton)
        view.addSubview(metronomeButton)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        metronomeButton.addTarget(self, action: #selector(metronomeButtonTapped), for: .touchUpInside)
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.displayMode = .singlePage
            pdfView.autoScales = true
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(true)
            pdfView.document = document
        }
        
        //self.hideNavigationBarWhenTappedAround()
        
        //initialize metronome value
        metronome.tempo = 120
        metronome.subdivision = 4
    }
    
    override func viewDidLayoutSubviews() {
        pdfView.frame = view.frame
        playButton.frame = CGRect(x: view.frame.maxX-50 , y: view.frame.maxY*0.8, width: 30, height: 30)
        metronomeButton.frame = CGRect(x: view.frame.maxX-60 , y: playButton.frame.maxY + 10, width: 50, height: 50)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // setup AKManager Engine
        AKManager.output = metronome
        do { try AKManager.start() }
        catch {
            print(self.classForCoder, " Error: cannot start AudioKit engine")
            return
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        turnOffMetronomeCompletely()
    }
    
    
    // open metronome page in a modal view
    @IBAction func metronomeButtonTapped() {
        
        turnOffMetronomeCompletely()
        
        let vc = self.storyboard?.instantiateViewController(identifier: "MetronomeViewController") as! MetronomeViewController
        vc.modalPresentationStyle = .fullScreen
        vc.embededMode = true
        vc.configureMetronomeData(data: self.metronomeData)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func playButtonTapped() {
        
        if metronome.isPlaying {
            metronome.stop()
            playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        else {
            metronome.tempo = metronomeData.tempo
            metronome.subdivision = metronomeData.beatValue
            metronome.start()
            playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    public func configureMetronomeData(data:MetronomeData) {
        self.metronomeData = data
    }
    
    func turnOffMetronomeCompletely() {
        metronome.stop()
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        do { try AKManager.stop() }
        catch {
            print(self.classForCoder, " Error: cannot stop AudioKit engine")
            return
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
