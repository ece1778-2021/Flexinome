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
    private var beatCount = 0
    private var sequencerData = [SequencerData]()
    private var currentSequence = 0 // the sequence currently playing
    private var currentBar = 0 // the bar currently playing
    private var notesInBar = 0 // the number of notes in a bar
    private var notesCounter = 0 // the number of notes played, used to update bar status
    
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
    
    /* Logic used to calculate the correct tempo and time signature in a sequence
       as well as the way to update UI
     */
    func sequencerLogic() {
        beatCount += 1
        notesCounter += 1
        
        // update bar number at the start of a bar
        if notesCounter - 1 == notesInBar {
            notesCounter = 1
            currentBar += 1
            DispatchQueue.main.async {
                self.barIndicatorLabel.text = "Bar# " + String(self.currentBar)
            }
        }
        
        // update tempo and time sig at the start of a sequence
        if beatCount == sequencerData[currentSequence].nextSequenceStartAtBeat {
            
            if sequencerData[currentSequence].isEndOfSong {
                metronome.stop()
                metronome.reset()
                beatCount = 0
                currentSequence = 0
                
                currentBar = 0
                notesCounter = 0
                // update UI
                DispatchQueue.main.async {
                    self.playButton.setTitle("Start", for: .normal)
                }
            }
            else {
                currentSequence += 1
                let tempo = sequencerData[currentSequence].tempo
                metronome.tempo = tempo
                metronome.subdivision = sequencerData[currentSequence].beatValue
                
                notesInBar = metronome.subdivision
                
                //update UI
                let ts = String(sequencerData[currentSequence].beatValue) + "/" + String(sequencerData[currentSequence].noteValue)
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
        
        //print(sequencerData)
    }
    
    /* Clean data when exiting sequencer mode*/
    func exitSequencerMode() {
        sequencerData.removeAll()
        sequencerDictionay.removeAll()
        beatCount = 0
        currentSequence = 0
        sequencerMode = false
        metronome.callback = {}
        currentBar = 0
        notesCounter = 0
        notesInBar = 0
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
                if currentSequence == 0 {
                    //metronome.callback = sequencerLogic
                    metronome.tempo = self.sequencerData[0].tempo
                    metronome.subdivision = self.sequencerData[0].beatValue
                    
                    notesInBar = metronome.subdivision
                    notesCounter = 0
                    currentBar = 1
                    
                    // update UI
                    tempoTextField.text = String(Int(metronome.tempo))
                    barIndicatorLabel.text = "Bar# " + String(currentBar)
                    
                    let ts = String(self.sequencerData[0].beatValue) + "/" + String(self.sequencerData[0].noteValue)
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
                let beatsPerMeasure = String(Array((timeSignatureButton.titleLabel?.text)!)[0])
                metronome.subdivision = Int(beatsPerMeasure)!
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

        let beatVal = Int(String(Array((timeSignatureButton.titleLabel?.text)!)[0]))!
        let noteVal = Int(String(Array((timeSignatureButton.titleLabel?.text)!)[2]))!

        pdfVC.configureMetronomeData(data: MetronomeData(tempo: Double(tempoTextField.text!)!, beatValue: beatVal, noteValue: noteVal))
        
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
            
            let beatVal = Int(String(Array((timeSignatureButton.titleLabel?.text)!)[0]))!
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
