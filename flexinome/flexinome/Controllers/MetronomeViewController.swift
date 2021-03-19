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
    
    private let metronome = AKMetronome()
    
    // When this is set, this VC will only be used to set the parameters of another metronome
    public var embededMode = false
    
    public var sequencerMode = false // play a preconfigured pattern (song)
    private var beatCount = 0
    private var sequencerData = [SequencerData]()
    private var barCount = 0
    
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
            //self.metronome.callback = sequencerLogic
            //self.barIndicatorLabel.isHidden = false
        }
        else {
            self.barIndicatorLabel.isHidden = true
            syncMetronome()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if embededMode {
            self.playButton.isHidden = true
            self.setButton.isHidden = false
            self.setButton.frame = playButton.frame
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // turn off the metronome
        self.metronome.stop()
        self.playButton.setTitle("Start", for: .normal)
        
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
    
    func sequencerLogic() {
        self.beatCount += 1
        // do some checking, update tempo and time sig
    }
    
//    func loadSequencerData(data: jsonData) {
//
//        for i = 0 to data.length - 2 {
//
//            self.sequencerData.append(
//                SequencerData(nextTempo: data[i].tempo,
//                            nextBeatValue: data[i].timeSignature[0],
//                            nextNoteValue: data[i].timeSignature[3],
//                            nextSequenceStartAtBeat: data[i].bar + (data[i].timeSignature.top * data[i].repetition,
//                            isEndOfSong: false))
//                )
//        }
//
//        // last sequence
//        let e = data.length - 1
//        self.sequencerData.append(
//            SequencerData(nextTempo: data[e].tempo,
//                        nextBeatValue: data[e].timeSignature[0],
//                        nextNoteValue: data[e].timeSignature[3],
//                        nextSequenceStartAtBeat: data[e].bar + (data[e].timeSignature.top * data[e].repetition,
//                        isEndOfSong: true))
//            )
//
//    }
    
    
// MARK: Interaction Action
    
// Start or stop the metronome
    @IBAction func playButtonTapped(_ sender: Any) {
        
        if sequencerMode {
            
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
        }
        

    }

}
