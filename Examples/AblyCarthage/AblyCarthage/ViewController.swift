//
//  ViewController.swift
//  AblyCarthage
//
//  Created by Admin on 17.07.2021.
//

import UIKit
import Ably

class ViewController: UIViewController {

    let client = ARTRest(options: ARTClientOptions(token: "erertwertwert"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func wowPressed(_ sender: UIButton) {
        print("\(client)")
        sender.setTitle("\(client)", for: .normal)
    }
}
