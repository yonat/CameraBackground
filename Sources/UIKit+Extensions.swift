//
//  UIKit+Extensions.swift
//  CameraBackground
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import UIKit

extension UIColor {
    class var cameraOnColor: UIColor {
        return UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
    }
}

public extension UITraitEnvironment {
    public func bundledCameraImage(_ named: String) -> UIImage? {
        if let image = UIImage(named: named) {
            return image
        }
        let podBundle = Bundle(for: FocusBoxLayer.self)
        if let url = podBundle.url(forResource: "CameraBackground", withExtension: "bundle") {
            return UIImage(named: named, in: Bundle(url: url), compatibleWith: traitCollection)
        }
        return nil
    }

    public func bundledCameraTemplateImage(_ named: String) -> UIImage? {
        return bundledCameraImage(named)?.withRenderingMode(.alwaysTemplate)
    }
}

extension UIDevice {
    class var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

extension UIView {
    func gestureRecognizerOfType<T: UIGestureRecognizer>(_: T.Type) -> UIGestureRecognizer? {
        if let gestureRecognizers = gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let tRecognizer = gestureRecognizer as? T {
                    return tRecognizer as UIGestureRecognizer
                }
            }
        }
        return nil
    }
}

extension UIGestureRecognizer {
    func removeFromView() {
        view?.removeGestureRecognizer(self)
    }
}

extension UIButton {
    class func buttonWithImage(_ image: UIImage?, target: AnyObject, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}

extension UIStackView {
    convenience init(side: NSLayoutConstraint.Attribute) {
        self.init()
        distribution = .equalCentering

        switch side {
        case .left, .leftMargin, .leading, .leadingMargin:
            alignment = .leading
        case .right, .rightMargin, .trailing, .trailingMargin:
            alignment = .trailing
        default:
            semanticContentAttribute = .forceRightToLeft
        }
        if alignment != .fill {
            axis = .vertical
            spacing = 24
        }
    }
}
