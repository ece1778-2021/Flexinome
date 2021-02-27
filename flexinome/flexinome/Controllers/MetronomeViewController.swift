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
    
    private let metronome = AKMetronome()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
        AKManager.output = metronome
        do { try AKManager.start() }
        catch {
            print("Error: cannot start AudioKit")
            return
        }
        tempoStepper.value = 120
    }
    
    func sanitizeTempoTextField() {
        
        // filter out non-numeric values
        let result = tempoTextField.text?.filter("0123456789".contains)
        tempoTextField.text = result
        
        if tempoTextField.text == "" {
            tempoTextField.text = "120"
        }
    }
    
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

}
