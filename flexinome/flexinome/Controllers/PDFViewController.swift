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
    
    private var previousBarButtonSet = false
    private var nextBarButtonSet = false
    
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
    
    private let previousBarButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(systemName: "arrow.backward.square"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let nextBarButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(systemName: "arrow.forward.square"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let barIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "# 1"
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCameraViewDelegate()
        view.addSubview(pdfView)
        view.addSubview(playButton)
        view.addSubview(metronomeButton)
        view.addSubview(previousBarButton)
        view.addSubview(nextBarButton)
        view.addSubview(barIndicatorLabel)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        metronomeButton.addTarget(self, action: #selector(metronomeButtonTapped), for: .touchUpInside)
        previousBarButton.addTarget(self, action: #selector(previousBarButtonTapped), for: .touchUpInside)
        nextBarButton.addTarget(self, action: #selector(nextBarButtonTapped), for: .touchUpInside)
        
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
        
        previousBarButton.frame = CGRect(x: view.frame.maxX-50 , y: metronomeButton.frame.maxY+10, width: 30, height: 30)
        
        barIndicatorLabel.frame = CGRect(x: view.frame.maxX-70 , y: previousBarButton.frame.maxY+10, width: 70, height: 30)
        
        nextBarButton.frame = CGRect(x: view.frame.maxX-50 , y: barIndicatorLabel.frame.maxY+10, width: 30, height: 30)
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
            previousBarButton.isHidden = false
            nextBarButton.isHidden = false
            barIndicatorLabel.isHidden = false
        }
        else {
            metronomeButton.setBackgroundImage(UIImage(named: "metronome_color"), for: .normal)
            previousBarButton.isHidden = true
            nextBarButton.isHidden = true
            barIndicatorLabel.isHidden = true
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
                previousBarButton.isEnabled = true
                nextBarButton.isEnabled = true
            }
            else {
                previousBarButton.isEnabled = false
                nextBarButton.isEnabled = false
                if previousBarButtonSet || nextBarButtonSet {
                    previousBarButtonSet = false
                    nextBarButtonSet = false
                    metronome.restart()
                    return
                }
                
                if sequencerTracking.currentSequence == 0 {
                    // initialize metronome with sequencer data
                    metronome.callback = sequencerLogic
                    metronome.tempo = sequencerData[0].tempo
                    metronome.subdivision = sequencerData[0].beatValue
                    
                    sequencerTracking.notesInBar = metronome.subdivision
                    sequencerTracking.notesCounter = 0
                    sequencerTracking.currentBar = 1
                    
                    playButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
                    barIndicatorLabel.text = "# " + String(sequencerTracking.currentBar)
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
            DispatchQueue.main.async {
                self.barIndicatorLabel.text = "# " + String(self.sequencerTracking.currentBar)
            }
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
    
    @IBAction func previousBarButtonTapped() {
        
        if previousBarButtonSet || nextBarButtonSet {
            // move to the correct bar
            sequencerTracking.beatCount += 1
            sequencerTracking.notesCounter += 1
        }
        
        playButton.isEnabled = false
        previousBarButtonSet = true
        if sequencerTracking.currentBar < 2 {
            // go to the start of the same bar if this is the very first bar
            sequencerTracking.beatCount -= sequencerTracking.notesCounter
            sequencerTracking.notesCounter = 0
            playButton.isEnabled = true
            return
        }
        
        sequencerTracking.currentBar -= 1
        barIndicatorLabel.text = "# " + String(sequencerTracking.currentBar)
        
        // rewind the notes and beats counter to the start of current bar
        sequencerTracking.beatCount = sequencerTracking.beatCount - sequencerTracking.notesCounter + 1
        sequencerTracking.notesCounter = 0
        
        // corner case: before change is at start of a sequence
        if sequencerTracking.currentSequence > 0 {
            if sequencerTracking.beatCount == sequencerData[sequencerTracking.currentSequence - 1].nextSequenceStartAtBeat {
                // now go to the previous sequence
                sequencerTracking.currentSequence -= 1
            }
        }
        
        // update the sequencer and metronome
        let tempo = sequencerData[sequencerTracking.currentSequence].tempo
        metronome.tempo = tempo
        let beatValue = sequencerData[sequencerTracking.currentSequence].beatValue
        metronome.subdivision = beatValue
        sequencerTracking.notesInBar = beatValue
        
        // rewind the beat counter further to the point where the desired bar is about to begin
        sequencerTracking.beatCount = sequencerTracking.beatCount - beatValue - 1
        
        playButton.isEnabled = true
    }
    
    @IBAction func nextBarButtonTapped() {
        
        if previousBarButtonSet || nextBarButtonSet {
            // move to the correct bar
            sequencerTracking.beatCount += 1
            sequencerTracking.notesCounter += 1
        }
        
        playButton.isEnabled = false
        nextBarButtonSet = true
        
        
        // corner case: before change is at end of a sequence
        let lastBarStartAtBeat = sequencerData[sequencerTracking.currentSequence].nextSequenceStartAtBeat - sequencerTracking.notesInBar
        if sequencerTracking.beatCount >= lastBarStartAtBeat {
            if sequencerData[sequencerTracking.currentSequence].isEndOfSong {
                // go to the start of the same bar if this is the last bar of the last sequence
                sequencerTracking.beatCount -= sequencerTracking.notesCounter
                sequencerTracking.notesCounter = 0
                playButton.isEnabled = true
                return
            }
            else {
                // go to the next sequence
                sequencerTracking.currentSequence += 1
            }
        }
        
        // rewind the notes and beats counter to the point where the desired bar is about to begin
        sequencerTracking.beatCount = sequencerTracking.beatCount - sequencerTracking.notesCounter + sequencerTracking.notesInBar
        sequencerTracking.notesCounter = 0
        
        // update the sequencer and metronome
        let tempo = sequencerData[sequencerTracking.currentSequence].tempo
        metronome.tempo = tempo
        let beatValue = sequencerData[sequencerTracking.currentSequence].beatValue
        metronome.subdivision = beatValue
        sequencerTracking.notesInBar = beatValue
        
        
        
        // UI
        sequencerTracking.currentBar += 1
        barIndicatorLabel.text = "# " + String(sequencerTracking.currentBar)
        
        playButton.isEnabled = true
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
