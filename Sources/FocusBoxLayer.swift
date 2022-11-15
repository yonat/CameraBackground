//
//  FocusBoxLayer.swift
//  CameraBackground
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import UIKit

/// shows a focus box, similar to the built-in camera.
class FocusBoxLayer: CAShapeLayer {
    convenience init(center: CGPoint) {
        self.init()
        path = UIBezierPath(focusBoxAround: center, big: true).cgPath
        strokeColor = UIColor.cameraOnColor.cgColor
        fillColor = UIColor.clear.cgColor

        DispatchQueue.main.async {
            self.path = UIBezierPath(focusBoxAround: center, big: false).cgPath
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.opacity = 0.5
        }
    }

    override func action(forKey event: String) -> CAAction? { // animate changes to 'path'
        switch event {
        case "path":
            let animation = CABasicAnimation(keyPath: event)
            animation.duration = CATransaction.animationDuration()
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            return animation

        default:
            return super.action(forKey: event)
        }
    }
}

extension UIBezierPath {
    convenience init(focusBoxAround center: CGPoint, big: Bool = false) {
        let size: CGFloat = big ? 150 : 75 // swiftlint:disable:this numbers_smell
        let lineSize: CGFloat = 5
        let square = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
        self.init(rect: square)
        move(to: CGPoint(x: center.x, y: square.minY))
        addLine(to: CGPoint(x: center.x, y: square.minY + lineSize))
        move(to: CGPoint(x: center.x, y: square.maxY))
        addLine(to: CGPoint(x: center.x, y: square.maxY - lineSize))
        move(to: CGPoint(x: square.minX, y: center.y))
        addLine(to: CGPoint(x: square.minX + lineSize, y: center.y))
        move(to: CGPoint(x: square.maxX, y: center.y))
        addLine(to: CGPoint(x: square.maxX - lineSize, y: center.y))
    }
}
