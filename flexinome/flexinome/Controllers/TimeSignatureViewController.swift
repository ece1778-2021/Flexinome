//
//  TimeSignatureViewController.swift
//  flexinome
//
//  Created by Kevin Yang on 2021-03-06.
//

import UIKit

class TimeSignatureViewController: UIViewController {


    @IBOutlet weak var beatStepper: UIStepper!
    @IBOutlet weak var finishButtton: UIButton!
    @IBOutlet weak var noteStepper: UIStepper!
    @IBOutlet weak var beatLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    
    var timeSignatureIsSet:Bool = false
    var previousTempo:Double = 120
    
    var beat = "4"
    var note = "4"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // initialize beat and note steppers

        beatLabel.text = beat
        noteLabel.text = note
        self.beatStepper.value = Double(beat) ?? 4
        self.noteStepper.value = Double(note) ?? 4

    }
 
    public func memorizePreviousTempo(tempo: Double) {
        self.previousTempo = tempo
    }
    
    public func setTimeSignature(timeSignature: String) {
        self.beat = String(Array(timeSignature)[0])
        self.note = String(Array(timeSignature)[2])
    }

    //MARK: - Interaction

    @IBAction func beatStepperChanged(_ sender: Any) {
        self.beatLabel.text = String(Int(beatStepper.value))
    }
    
    
    @IBAction func noteStepperChanged(_ sender: Any) {
        self.noteLabel.text = String(Int(noteStepper.value))
    }
    
    // go back to metronome screen
    @IBAction func finishButtonTapped(_ sender: Any) {
        
        let ts = beatLabel.text! + "/" + noteLabel.text!
        
        guard let parent = self.presentingViewController else { return }
        
        
        if parent.isKind(of: MetronomeViewController.self) {
            let pvc = self.presentingViewController as! MetronomeViewController
            pvc.setTimeSignature(timeSignature: ts)
            self.dismiss(animated: true, completion:nil)
        }
        else if parent.isKind(of: UINavigationController.self) {
            let pvc = self.presentingViewController as! UINavigationController
            let metronomeVC = pvc.topViewController as! MetronomeViewController
            metronomeVC.setTimeSignature(timeSignature: ts)
            self.dismiss(animated: true, completion: nil)
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
