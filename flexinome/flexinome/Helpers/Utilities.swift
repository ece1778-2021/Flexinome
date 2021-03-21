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
        var nextSequenceStartAtBeat: Int // The position to play next pattern
        var isEndOfSong: Bool = false // set to true for the last sequence 
    }

    
}
