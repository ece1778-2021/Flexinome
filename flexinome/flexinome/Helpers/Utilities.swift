//
//  Utilities.swift
//  flexinome
//
//  Created by Kevin Yang on 2021-02-26.
//

import Foundation
import UIKit

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func hideNavigationBarWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dissmissOrShowNavBar))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dissmissOrShowNavBar() {
        if self.navigationController?.isNavigationBarHidden == true {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    struct MetronomeData {
        let tempo: Double
        let beatValue: Int  // beats per measure
        let noteValue: Int  // note value in a time signature
    }
    
    struct SequencerData {
        var startAtBeat: Int
        var tempo: Double
        var beatValue: Int
        var noteValue: Int
        var turnPage: Bool = false
        var nextSequenceStartAtBeat: Int // The position to play next pattern
        var isEndOfSong: Bool = false // set to true for the last sequence 
    }

    struct SequencerTracking {
        var beatCount = 0       // the beats played since start of the sequencer
        var currentSequence = 0 // the sequence # currently playing
        var currentBar = 0      // the bar # currently playing
        var notesInBar = 0      // the number of notes in a bar
        var notesCounter = 0    // the number of notes played, used to update bar status
        
        mutating func cleanAll() {
            self.beatCount = 0
            self.currentSequence = 0
            self.currentBar = 0
            self.notesInBar = 0
            self.notesCounter = 0
        }
    }
    
}
