//
//  ViewController.swift
//  MotionLoggerZombieIssue
//
//  Created by Colm Du Ve on 10/12/2016.
//  Copyright © 2016 dooversoft. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let motionManager = MotionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.start()
    }

}

