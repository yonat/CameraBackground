//
//  AppDelegate.swift
//  CameraBackgroundDemo
//
//  Created by Yonat Sharon on 19.02.2015.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import UIKit

class CameraBackgroundViewController: UIViewController {
    
    override func viewDidLoad() {
        let shootButton = UIButton(type: .Custom)
        shootButton.setImage(UIImage(named: "record")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        shootButton.addTarget(self, action: "shoot", forControlEvents: .TouchUpInside)
        shootButton.tag = 7

        view.layoutMargins = UIEdgeInsets(top: 30, left: 10, bottom: 10, right: 10)
        view.addConstrainedSubview(shootButton, constrain: .CenterX, .Bottom)
        view.addCameraBackground(.Back, buttonMargins: view.layoutMargins)
    }
    
    func shoot() {
        view.takeCameraSnapshot( {
                // animate snapshot capture
                self.view.alpha = 0
                UIView.animateWithDuration(1) { self.view.alpha = 1 }
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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.backgroundColor = UIColor.whiteColor()
        window.rootViewController = CameraBackgroundViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

