//
//  AppDelegate.swift
//  CameraBackgroundDemo
//
//  Created by Yonat Sharon on 19.02.2015.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import UIKit
import CameraBackground
import MiniLayout

class CameraBackgroundViewController: UIViewController {
    
    override func viewDidLoad() {
        let shootButton = UIButton(type: .custom)
        shootButton.setImage( bundeledCameraTemplateImage("record"), for: .normal)
        shootButton.addTarget(self, action: #selector(shoot), for: .touchUpInside)
        shootButton.tag = 7

        view.layoutMargins = UIEdgeInsets(top: 30, left: 10, bottom: 10, right: 10)
        view.addConstrainedSubview(shootButton, constrain: .centerX, .bottom)
        view.addCameraBackground(.back, buttonMargins: view.layoutMargins)
    }
    
    @objc func shoot() {
        view.takeCameraSnapshot( {
                // animate snapshot capture
                self.view.alpha = 0
                UIView.animate(withDuration: 1) { self.view.alpha = 1 }
            },
            completion: { (capturedImage, error) -> () in
                self.view.freeCameraSnapshot() // unfreeze image
                // ... handle capturedImage and error
            }
        )
    }
}

@UIApplicationMain
class CameraBackgroundDemo: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.rootViewController = CameraBackgroundViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

