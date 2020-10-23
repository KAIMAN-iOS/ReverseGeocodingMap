//
//  ViewController.swift
//  iOS-Example
//
//  Created by GG on 22/10/2020.
//

import UIKit
import ReverseGeocodingMap

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    let map = ReverseGeocodingMap.create()
    @IBAction func show(_ sender: Any) {
        map.geocodingCompletion = { res in
            print("🎃 \(res)")
        }
        map.countdownValue = 1
        navigationController?.pushViewController(map, animated: true)
    }
}

