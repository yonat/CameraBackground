//
//  CountdownLabel.swift
//  CameraBackground
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import UIKit

/// counts down seconds, and then performs an action.
class CountdownLabel: UILabel {
    var remainingSeconds: Int = 0
    let action: () -> Void
    private var dispatchWorkItem: DispatchWorkItem?

    init(seconds: Int, action: @escaping () -> Void) {
        self.action = action
        remainingSeconds = seconds
        super.init(frame: .zero)

        textColor = .white
        shadowColor = UIColor.black.withAlphaComponent(0.5)
        let fontSize = min(UIScreen.main.bounds.width / 2, UIScreen.main.bounds.height / 3)
        font = .boldSystemFont(ofSize: fontSize)
        shadowOffset = CGSize(width: fontSize / 30, height: fontSize / 15)

        countdown()
    }

    required init?(coder: NSCoder) {
        action = {}
        super.init(coder: coder)
    }

    deinit {
        dispatchWorkItem?.cancel()
    }

    private func countdown() {
        if remainingSeconds > 0 {
            text = "\(remainingSeconds)"
            remainingSeconds -= 1
            let countdownWorkItem = DispatchWorkItem { [weak self] in self?.countdown() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: countdownWorkItem)
            dispatchWorkItem = countdownWorkItem
        } else {
            removeFromSuperview()
            action()
        }
    }
}
