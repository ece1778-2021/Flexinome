//
//  ViewController.swift
//  flexinome
//
//  Created by Lexi Jasper Zhu on 2021-02-22.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGradientBackground()
        navigationController?.navigationBar.barTintColor = UIColor(red: 25.0/255.0, green: 70.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        super.viewWillAppear(animated)
    }


}

