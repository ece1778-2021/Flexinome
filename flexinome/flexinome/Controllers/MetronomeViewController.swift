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
    
    
    private let metronome = AKMetronome()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
        AKManager.output = metronome
        do { try AKManager.start() }
        catch {
            print("Error: cannot start AudioKit engine")
            return
        }
        
        // initialize tempo and time signature
        tempoTextField.text = "120"
        tempoStepper.value = 120

        timeSignatureButton.setTitle("4/4", for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.metronome.stop()
        do { try AKManager.stop() }
        catch {
            print("Error: cannot stop AudioKit engine")
            return
        }
    }
    
    func sanitizeTempoTextField() {
        
        // filter out non-numeric values
        let result = tempoTextField.text?.filter("0123456789".contains)
        tempoTextField.text = result
        
        if tempoTextField.text == "" {
            tempoTextField.text = "120"
        }
    }


    // set the time signature of the beats (used by TimeSignatureViewController)
    public func setTimeSignature(timeSignature: String) {
        self.timeSignatureButton.setTitle(timeSignature, for: .normal)
        
        // update the metronome
        let beatsPerMeasure = String(Array(timeSignature)[0])
        metronome.subdivision = Int(beatsPerMeasure)!
    }
    
    
// MARK: Interaction Action
    
// Start or stop the metronome
    @IBAction func playButtonTapped(_ sender: Any) {
        
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
    
    @IBAction func tempoStepperChanged(_ sender: Any) {
        
        tempoTextField.text = String(Int(tempoStepper.value))
        if metronome.isPlaying {
            metronome.tempo = tempoStepper.value
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "timeSignatureSegue" {
            
            let ts = self.timeSignatureButton.titleLabel?.text ?? "4/4"
            let controller = segue.destination as! TimeSignatureViewController
            controller.setTimeSignature(timeSignature: ts)
            
        }
    }

}
