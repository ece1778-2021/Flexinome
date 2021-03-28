//
//  MetronomeViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-23.
//

import UIKit
import AudioKit

class MetronomeViewController: UIViewController {

    @IBOutlet weak var tempoTextField: UITextField!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var tempoStepper: UIStepper!
    @IBOutlet weak var timeSignatureButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var barIndicatorLabel: UILabel!
    @IBOutlet weak var sequencerModeIndicatorLabel: UILabel!
    
    private let metronome = AKMetronome()
    
    // When this is set, this VC will only be used to set the parameters of another metronome
    public var embededMode = false
    
    /* data for sequencer */
    public var sequencerDictionay: [String: Dictionary<String,String>] = [:]
    public var sequencerMode = false // play a preconfigured pattern (song)
    
    private var sequencerData = [SequencerData]()
    private var sequencerTracking = SequencerTracking()
    
    // metronome data used to sync between VCs
    private var metronomeData = MetronomeData(tempo: 120, beatValue: 4, noteValue: 4)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AKManager.output = metronome
        do { try AKManager.start() }
        catch {
            print("Error: cannot start AudioKit engine")
            return
        }
        
        if sequencerMode {
            metronome.callback = sequencerLogic
            loadSequencerData()
            barIndicatorLabel.isHidden = false
            sequencerModeIndicatorLabel.isHidden = false
        }
        else {
            barIndicatorLabel.isHidden = true
            sequencerModeIndicatorLabel.isHidden = true
            syncMetronome()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if embededMode {
            playButton.isHidden = true
            setButton.isHidden = false
            setButton.frame = playButton.frame
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // turn off the metronome
        metronome.stop()
        playButton.setTitle("Start", for: .normal)
        
        if sequencerMode {
            exitSequencerMode()
        }
        
        do { try AKManager.stop() }
        catch {
            print("Error: cannot stop AudioKit engine")
            return
        }
    }
    
    
    // MARK: - Metronome logic
    
    func sanitizeTempoTextField() {
        
        // filter out non-numeric values
        let result = tempoTextField.text?.filter("0123456789".contains)
        tempoTextField.text = result
        
        if tempoTextField.text == "" {
            tempoTextField.text = "120"
        }
    }
    
    
    // call by other VCs to sync metronome data
    public func configureMetronomeData(data: MetronomeData) {
        self.metronomeData = data
    }
    
    public func syncMetronome() {
        let ts = String(metronomeData.beatValue) + "/" + String(metronomeData.noteValue)
        timeSignatureButton.setTitle(ts, for: .normal)
        tempoTextField.text = String(Int(metronomeData.tempo))
        tempoStepper.value = metronomeData.tempo
        
        metronome.subdivision = metronomeData.beatValue
        metronome.tempo = metronomeData.tempo
    }
    
    /* Callback logic used to display beat visuals */
    func beatVisualCallback() {
        
    }
    
    
    /* Callback logic used to calculate the correct tempo and time signature in a sequence
       as well as the way to update UI */
    func sequencerLogic() {
        sequencerTracking.beatCount += 1
        sequencerTracking.notesCounter += 1
        
        // update bar number at the start of a bar
        if sequencerTracking.notesCounter - 1 == sequencerTracking.notesInBar {
            sequencerTracking.notesCounter = 1
            sequencerTracking.currentBar += 1
            DispatchQueue.main.async {
                self.barIndicatorLabel.text = "Bar# " + String(self.sequencerTracking.currentBar)
            }
        }
        
        // update tempo and time sig at the start of a sequence
        if sequencerTracking.beatCount == sequencerData[sequencerTracking.currentSequence].nextSequenceStartAtBeat {
            
            if sequencerData[sequencerTracking.currentSequence].isEndOfSong {
                metronome.stop()
                metronome.reset()
                sequencerTracking.cleanAll()
                // update UI
                DispatchQueue.main.async {
                    self.playButton.setTitle("Start", for: .normal)
                }
            }
            else {
                sequencerTracking.currentSequence += 1
                let tempo = sequencerData[sequencerTracking.currentSequence].tempo
                metronome.tempo = tempo
                metronome.subdivision = sequencerData[sequencerTracking.currentSequence].beatValue
                
                sequencerTracking.notesInBar = metronome.subdivision
                
                //update UI
                let ts = String(sequencerData[sequencerTracking.currentSequence].beatValue) + "/" + String(sequencerData[sequencerTracking.currentSequence].noteValue)
                DispatchQueue.main.async {
                    self.tempoTextField.text = String(Int(tempo))
                    self.tempoStepper.value = tempo
                    self.timeSignatureButton.setTitle(ts, for: .normal)
                }
            }
        }
    }
    
    func loadSequencerData() {
                
        for i in 1...sequencerDictionay.count {
            let bar = Int(sequencerDictionay[String(i)]!["Bar"]!)!
            let repetition = Int(sequencerDictionay[String(i)]!["Repetition"]!)!
            let tempo = Double(sequencerDictionay[String(i)]!["Tempo"]!)!
            let timeSignatureTop = Int(sequencerDictionay[String(i)]!["Time Signature"]!.prefix(1))!
            let timeSignatureBottom = Int(sequencerDictionay[String(i)]!["Time Signature"]!.suffix(1))!
            let turn = sequencerDictionay[String(i)]!["Turn"]!
            var endOfSong = false
            
            if (i == sequencerDictionay.count) {
                endOfSong = true
            }
            
            if i == 1 {
                let nextStart = bar + (timeSignatureTop * repetition)
                self.sequencerData.append(
                    SequencerData(startAtBeat: bar,
                                  tempo: tempo,
                                  beatValue: timeSignatureTop,
                                  noteValue: timeSignatureBottom,
                                  nextSequenceStartAtBeat: nextStart,
                                  isEndOfSong: endOfSong)
                )
            }
            else {
                let start = self.sequencerData[i - 2].nextSequenceStartAtBeat
                let nextStart = start + (timeSignatureTop * repetition)
                
                self.sequencerData.append(
                    SequencerData(startAtBeat: start,
                                  tempo: tempo,
                                  beatValue: timeSignatureTop,
                                  noteValue: timeSignatureBottom,
                                  nextSequenceStartAtBeat: nextStart,
                                  isEndOfSong: endOfSong)
                )
            }
        }
    }
    
    /* Clean data when exiting sequencer mode*/
    func exitSequencerMode() {
        sequencerData.removeAll()
        sequencerDictionay.removeAll()
        sequencerMode = false
        metronome.callback = {}
        sequencerTracking.cleanAll()
        barIndicatorLabel.isHidden = true
        sequencerModeIndicatorLabel.isHidden = true
    }
    
    
// MARK: Interaction Action
    
// Start or stop the metronome
    @IBAction func playButtonTapped(_ sender: Any) {
        
        if sequencerMode {
            if metronome.isPlaying {
                metronome.stop()
                playButton.setTitle("Start", for: .normal)
            }
            else {
                if sequencerTracking.currentSequence == 0 {
                    // initialize metronome with sequencer data
                    metronome.tempo = sequencerData[0].tempo
                    metronome.subdivision = sequencerData[0].beatValue
                    
                    sequencerTracking.notesInBar = metronome.subdivision
                    sequencerTracking.notesCounter = 0
                    sequencerTracking.currentBar = 1
                    
                    // update UI
                    tempoTextField.text = String(Int(metronome.tempo))
                    barIndicatorLabel.text = "Bar# " + String(sequencerTracking.currentBar)
                    
                    let ts = String(sequencerData[0].beatValue) + "/" + String(sequencerData[0].noteValue)
                    timeSignatureButton.setTitle(ts, for: .normal)
                    playButton.setTitle("Stop", for: .normal)
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
                metronome.reset()
                playButton.setTitle("Start", for: .normal)
            }
            else {
                sanitizeTempoTextField()
                metronome.reset()
                metronome.tempo = Double(tempoTextField.text!)!
                let tsLen = timeSignatureButton.titleLabel?.text?.count
                if tsLen == 3 {
                    // single digit beat
                    let beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0])
                    metronome.subdivision = Int(beatsPerMeasure)!
                }
                else if tsLen == 4 {
                    // double digits beat
                    let beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0]) +
                        String(Array((timeSignatureButton.titleLabel?.text)!)[1])
                    metronome.subdivision = Int(beatsPerMeasure)!
                }
                
                metronome.restart()
                playButton.setTitle("Stop", for: .normal)
            }
        }
         
    }
    
    @IBAction func tempoStepperChanged(_ sender: Any) {
        
        if sequencerMode{
            exitSequencerMode()
        }
        
        tempoTextField.text = String(Int(tempoStepper.value))
        if metronome.isPlaying {
            metronome.tempo = tempoStepper.value
        }
    }
    
    @IBAction func setButtonTapped(_ sender: Any) {
        
        let pvc = self.parent as! UINavigationController
        let count = pvc.viewControllers.count
        let pdfVC = pvc.viewControllers[count - 2] as! PDFViewController

        
        if sequencerMode {
            pdfVC.configureSequencerData(data: sequencerData)
        }
        else {
            let tsLen = timeSignatureButton.titleLabel?.text?.count
            var beatsPerMeasure: String = "4"
            if tsLen == 3 {
                // single digit beat
                beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0])
                
            }
            else if tsLen == 4 {
                // double digits beat
                beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0]) +
                    String(Array((timeSignatureButton.titleLabel?.text)!)[1])
            }
            let beatVal = Int(beatsPerMeasure)!
            let noteVal = Int(String(Array((timeSignatureButton.titleLabel?.text)!)[2]))!

            pdfVC.configureMetronomeData(data: MetronomeData(tempo: Double(tempoTextField.text!)!, beatValue: beatVal, noteValue: noteVal))
        }
        
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "timeSignatureSegue" {
            
            let tsLen = timeSignatureButton.titleLabel?.text?.count
            var beatsPerMeasure: String = "4"
            if tsLen == 3 {
                // single digit beat
                beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0])
                
            }
            else if tsLen == 4 {
                // double digits beat
                beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0]) +
                    String(Array((timeSignatureButton.titleLabel?.text)!)[1])
            }
            
            let beatVal = Int(beatsPerMeasure)!
            let noteVal = Int(String(Array((timeSignatureButton.titleLabel?.text)!)[2]))!
            let tempo = Double(tempoTextField.text!)!
            
            let controller = segue.destination as! TimeSignatureViewController
            controller.configureMetronomeData(data: MetronomeData(tempo: tempo, beatValue: beatVal, noteValue: noteVal))
            
            if sequencerMode {
                exitSequencerMode()
            }
        }

    }

}
