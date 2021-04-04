//
//  SettingsViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-04-03.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var pageTurningSensitivitySlider: UISlider!
    @IBOutlet weak var pageTurningSensitivity: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let defaults = UserDefaults.standard
        pageTurningSensitivitySlider.value = defaults.float(forKey: "PageTurningSensitivity")
        pageTurningSensitivity.text = String(format:"%.1f", defaults.float(forKey: "PageTurningSensitivity"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
    }

    @IBAction func changePageTurningSensitivity(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(pageTurningSensitivitySlider.value, forKey: "PageTurningSensitivity")
        pageTurningSensitivity.text = String(format:"%.1f", defaults.float(forKey: "PageTurningSensitivity"))
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
