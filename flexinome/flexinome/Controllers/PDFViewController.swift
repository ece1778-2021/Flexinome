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
    
    @IBOutlet weak var cameraView: FacialGestureCameraView!
    
    var pdfView = PDFView()
    var pdfURL: URL!
    
    private var blinkTimerStarted = false
    private var blinkCount = 0
    
    // metronome embed in the pdf reader
    private let metronome = AKMetronome()
    
    // metronome data used to sync between VCs
    private var metronomeData = MetronomeData(tempo: 120, beatValue: 4, noteValue: 4)
    
    private var sequencerMode = false
    private var sequencerData = [SequencerData]()
    private var sequencerTracking = SequencerTracking()
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = UIColor.systemBlue
        return button
    }()
    
    private let metronomeButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCameraViewDelegate()
        view.addSubview(pdfView)
        view.addSubview(playButton)
        view.addSubview(metronomeButton)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        metronomeButton.addTarget(self, action: #selector(metronomeButtonTapped), for: .touchUpInside)
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .horizontal
            pdfView.document = document
        }
        
        //initialize metronome value
        metronome.tempo = 120
        metronome.subdivision = 4
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pdfView.autoScales = true
        pdfView.usePageViewController(true, withViewOptions: nil)
        startGestureDetection()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopGestureDetection()
    }

    override func viewDidLayoutSubviews() {
        let navBarFrame = self.navigationController?.navigationBar.frame
        pdfView.frame = CGRect(x: 0, y: navBarFrame!.maxY, width: view.bounds.width, height: view.bounds.height - navBarFrame!.height)
        playButton.frame = CGRect(x: view.frame.maxX-50 , y: view.frame.maxY*0.8, width: 30, height: 30)
        metronomeButton.frame = CGRect(x: view.frame.maxX-60 , y: playButton.frame.maxY + 10, width: 50, height: 50)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setGradientBackground()
        
        // setup AKManager Engine
        AKManager.output = metronome
        do { try AKManager.start() }
        catch {
            print(self.classForCoder, " Error: cannot start AudioKit engine")
            return
        }
        
        if sequencerMode {
            metronomeButton.setBackgroundImage(UIImage(named: "song"), for: .normal)
        }
        else {
            metronomeButton.setBackgroundImage(UIImage(named: "metronome_color"), for: .normal)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        turnOffMetronomeCompletely()
        exitSequencerMode()
    }
    
// MARK: - Metronome
    
    public func configureMetronomeData(data:MetronomeData) {
        metronomeData = data
        sequencerMode = false
    }
    
    // open metronome page in a modal view
    @IBAction func metronomeButtonTapped() {
        
        turnOffMetronomeCompletely()
        
        let vc = self.storyboard?.instantiateViewController(identifier: "MetronomeViewController") as! MetronomeViewController
        vc.modalPresentationStyle = .fullScreen
        vc.embededMode = true
        vc.configureMetronomeData(data: metronomeData)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func playButtonTapped() {
        
        if sequencerMode {
            if metronome.isPlaying {
                metronome.stop()
                playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            }
            else {
                if sequencerTracking.currentSequence == 0 {
                    // initialize metronome with sequencer data
                    metronome.callback = sequencerLogic
                    metronome.tempo = sequencerData[0].tempo
                    metronome.subdivision = sequencerData[0].beatValue
                    
                    sequencerTracking.notesInBar = metronome.subdivision
                    sequencerTracking.notesCounter = 0
                    sequencerTracking.currentBar = 1
                    
                    playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
                    metronome.restart()
                }
                else {
                    metronome.start()
                }
            }
        }
        else {
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
   
    // MARK: - Sequencer
    
    public func configureSequencerData(data:[SequencerData]) {
        sequencerData = data
        sequencerMode = true
    }
    
    /* Callback logic used to calculate the correct tempo and time signature in a sequence */
    func sequencerLogic() {
        sequencerTracking.beatCount += 1
        sequencerTracking.notesCounter += 1
        
        // update bar number at the start of a bar
        if sequencerTracking.notesCounter - 1 == sequencerTracking.notesInBar {
            sequencerTracking.notesCounter = 1
            sequencerTracking.currentBar += 1

        }
        
        // update tempo and time sig at the start of a sequence
        if sequencerTracking.beatCount == sequencerData[sequencerTracking.currentSequence].nextSequenceStartAtBeat {
            
            if sequencerData[sequencerTracking.currentSequence].isEndOfSong {
                metronome.stop()
                metronome.reset()
                sequencerTracking.cleanAll()
                
                DispatchQueue.main.async {
                    self.playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
                }
            }
            else {
                // turn page decision made at the end of the sequence
                let turn = sequencerData[sequencerTracking.currentSequence].turnPage
                
                sequencerTracking.currentSequence += 1
                let tempo = sequencerData[sequencerTracking.currentSequence].tempo
                metronome.tempo = tempo
                metronome.subdivision = sequencerData[sequencerTracking.currentSequence].beatValue
                sequencerTracking.notesInBar = metronome.subdivision
                
                if turn {
                    DispatchQueue.main.async {
                        self.pdfView.go(to: self.pdfView.visiblePages[0])
                        self.pdfView.goToNextPage(self)
                    }
                }
            }
        }
    }
    
    
    /* Clean data when exiting sequencer mode*/
    func exitSequencerMode() {
        sequencerData.removeAll()
        sequencerMode = false
        metronome.callback = {}
        sequencerTracking.cleanAll()
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


extension PDFViewController {
    
    func addCameraViewDelegate() {
        cameraView.delegate = self
    }
    
    func startGestureDetection() {
        cameraView.beginSession()
    }
    
    func stopGestureDetection() {
        cameraView.stopSession()
    }
    
}

extension PDFViewController: FacialGestureCameraViewDelegate {
   
    func doubleEyeBlinkDetected() {
        if (self.blinkTimerStarted == false) {
            self.blinkTimerStarted = true
            var seconds = 0
            self.blinkCount = 1
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
//                print("Timer fired!")
                seconds += 1

                if seconds == 2 {
                    if (self.blinkCount >= 3) {
                        print("Double Eye Blink Detected")
                        print(self.blinkCount)
                    }
                    self.blinkTimerStarted = false
                    self.blinkCount = 0
                    timer.invalidate()
                }
            }
        }
        else {
            self.blinkCount += 1
        }
    }

    func smileDetected() {
        print("Smile Detected")
    }

    func nodLeftDetected() {
        print("Nod Left Detected")
        pdfView.go(to: pdfView.visiblePages[0]) // sync page history with visible page
        pdfView.goToPreviousPage(self)
    }

    func nodRightDetected() {
        print("Nod Right Detected")
        pdfView.go(to: pdfView.visiblePages[0])
        pdfView.goToNextPage(self)
    }

    func leftEyeBlinkDetected() {
//        print("Left Eye Blink Detected")
    }

    func rightEyeBlinkDetected() {
//        print("Right Eye Blink Detected")
    }
    
}
