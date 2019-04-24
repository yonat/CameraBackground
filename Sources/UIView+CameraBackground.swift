//
//  UIView+CameraBackground.swift
//  Show camera input as a background to any UIView.
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import AVFoundation
import MiniLayout
import MultiToggleButton
import UIKit

public extension UIView {
    // MARK: - Public Camera Interface

    /// Change the current camera background layer, e.g. when a user taps a camera on/off button.
    @objc func toggleCameraBackground(
        _ position: AVCaptureDevice.Position = .unspecified,
        showButtons: Bool = true,
        buttonMargins: UIEdgeInsets = .zero,
        buttonsLocation: NSLayoutConstraint.Attribute = .top
    ) {
        if nil != cameraLayer {
            removeCameraBackground()
        } else {
            addCameraBackground(position, showButtons: showButtons, buttonMargins: buttonMargins, buttonsLocation: buttonsLocation)
        }
    }

    /// Remove camera background layer
    @objc func removeCameraBackground() {
        removeCameraControls()
        cameraLayer?.removeFromSuperlayer()
    }

    /// Add camera background layer
    @objc func addCameraBackground(
        _ position: AVCaptureDevice.Position = .unspecified,
        showButtons: Bool = true,
        buttonMargins: UIEdgeInsets = .zero,
        buttonsLocation: NSLayoutConstraint.Attribute = .top
    ) {
        let session = AVCaptureSession.stillCameraCaptureSession(position)
        let cameraLayer = CameraLayer(session: session ?? AVCaptureSession())
        if session == nil {
            cameraLayer.backgroundColor = UIColor.black.cgColor
        } else {
            cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }

        layer.insertBackgroundLayer(cameraLayer, name: theCameraLayerName)
        if showButtons {
            addCameraControls(margins: buttonMargins, location: buttonsLocation)
        }
    }

    /// Take snapshot of the camera input shown in the background layer.
    /// - Parameters:
    ///   - onTime: action to perform when the timer completes countdown. E.g., make a click sound and/or show a flash.
    ///   - completion: handle captured image.
    @objc func takeCameraSnapshot(_ onTime: (() -> Void)?, completion: ((_ capturedImage: UIImage?, _ error: NSError?) -> Void)? = nil) {
        guard let cameraLayer = cameraLayer else { return }
        viewWithTag(theCountdownLabelTag)?.removeFromSuperview()
        performWithTimer(timerInterval) {
            onTime?()
            cameraLayer.connection?.isEnabled = false // to freeze image
            cameraLayer.captureStillImage { capturedImage, error in
                cameraLayer.session?.stopRunning()
                completion?(capturedImage, error)
            }
        }
    }

    /// Re-start streaming input from camera into background layer.
    @objc func freeCameraSnapshot() {
        cameraLayer?.connection?.isEnabled = true // to unfreeze image
        cameraLayer?.session?.startRunning()
        removeFocusBox()
    }

    /// The background layer showing camera input stream.
    @objc var cameraLayer: AVCaptureVideoPreviewLayer? {
        return layer.sublayerNamed(theCameraLayerName) as? AVCaptureVideoPreviewLayer
    }

    // MARK: - Private Camera Controls

    private var device: AVCaptureDevice? {
        return (cameraLayer?.session?.inputs.first as? AVCaptureDeviceInput)?.device
    }

    private func addCameraControls(margins: UIEdgeInsets = .zero, location: NSLayoutConstraint.Attribute = .top) {
        // buttons panel
        let panel = UIStackView(side: location)
        panel.tag = thePanelViewTag
        panel.tintColor = .white
        addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false
        constrain(panel, at: .top, diff: margins.top)
        constrain(panel, at: .left, diff: margins.left)
        constrain(panel, at: .right, diff: -margins.right)

        // switch camera button
        if AVCaptureDevice.devices(for: AVMediaType.video).count > 1 || UIDevice.isSimulator {
            let cameraButton = UIButton.buttonWithImage(bundledCameraTemplateImage("camera-switch"), target: self, action: #selector(switchCamera))
            cameraButton.tag = theSwitchButtonTag
            panel.addArrangedSubview(cameraButton)
        }

        // timer button
        let timerButton = MultiToggleButton(
            image: bundledCameraTemplateImage("camera-timer"),
            states: ["", "3s", "10s"],
            colors: [nil, .cameraOnColor, .cameraOnColor, .cameraOnColor]
        )
        timerButton.tag = theTimerButtonTag
        panel.addArrangedSubview(timerButton)

        // flash button
        let flashButton = MultiToggleButton(
            image: bundledCameraTemplateImage("camera-flash"),
            states: ["Off", "On", "Auto"],
            colors: [nil, .cameraOnColor]
        ) { sender in
            self.setFlashMode(sender.currentStateIndex)
        }
        flashButton.tag = theFlashButtonTag
        panel.addArrangedSubview(flashButton)
        updateFlashButtonState()

        // focus and zoom gestures - uses gesture subclass to make it identifiable when removing camera
        addGestureRecognizer(CameraPinchGestureRecognizer(target: self, action: #selector(pinchToZoom)))
        addGestureRecognizer(CameraTapGestureRecognizer(target: self, action: #selector(tapToFocus)))
        device?.changeMonitoring(true)
        NotificationCenter.default.addObserver(self, selector: #selector(removeFocusBox), name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }

    private func removeCameraControls() {
        // remove focus and zoom gestures
        gestureRecognizerOfType(CameraPinchGestureRecognizer.self)?.removeFromView()
        gestureRecognizerOfType(CameraTapGestureRecognizer.self)?.removeFromView()
        layer.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)

        // remove controls
        viewWithTag(thePanelViewTag)?.removeFromSuperview()
        viewWithTag(theCountdownLabelTag)?.removeFromSuperview()
    }

    private func updateFlashButtonState() {
        if let device = device {
            if let flashButton = viewWithTag(theFlashButtonTag) as? MultiToggleButton {
                if device.hasFlash {
                    flashButton.isHidden = false
                    flashButton.currentStateIndex = device.flashMode.rawValue
                } else {
                    flashButton.isHidden = true
                }
            }
        }
    }

    // MARK: - Action: Switch Front/Back Camera

    @objc func switchCamera(_: UIButton) {
        if let session = cameraLayer?.session {
            var cameraPosition = AVCaptureDevice.Position.unspecified
            if let input = session.inputs.first as? AVCaptureDeviceInput {
                cameraPosition = input.device.position
                session.removeInput(input)
            }
            session.addCameraInput(cameraPosition.opposite())
            updateFlashButtonState()
            removeFocusBox()
        }
    }

    // MARK: - Action: Toggle Flash Mode

    func setFlashMode(_ rawValue: NSInteger) {
        if let device = device {
            if device.hasFlash {
                if let newMode = AVCaptureDevice.FlashMode(rawValue: rawValue) {
                    device.changeFlashMode(newMode)
                }
            }
        }
    }

    // MARK: - Action: Toggle Timer

    var timerInterval: Int {
        if let numberInTitle = (viewWithTag(theTimerButtonTag) as? UIButton)?.currentTitle?.trimmingCharacters(in: CharacterSet(charactersIn: " s")) {
            return Int(numberInTitle) ?? 0
        }
        return 0
    }

    private func performWithTimer(_ interval: Int, block: @escaping () -> Void) {
        if interval > 0 {
            let countdownLabel = CoundownLabel(seconds: interval, action: block)
            countdownLabel.tag = theCountdownLabelTag
            addConstrainedSubview(countdownLabel, constrain: .centerX, .centerY)
        } else {
            block()
        }
    }

    // MARK: - Action: Pinch to Zoom

    @objc func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        enum Static {
            static var initialZoom: CGFloat = 1
        }
        if let device = device {
            if sender.state == .began {
                Static.initialZoom = device.videoZoomFactor
            }
            device.changeZoomFactor(sender.scale * Static.initialZoom)
        }
    }

    // MARK: - Action: Tap to Focus

    @objc func tapToFocus(_ sender: UITapGestureRecognizer) {
        let focusPoint = sender.location(in: self)

        if let device = device {
            if !device.isFocusPointOfInterestSupported && !device.isExposurePointOfInterestSupported {
                return
            }

            let interestPoint = CGPoint(x: (focusPoint.y - bounds.minY) / bounds.height, y: 1 - (focusPoint.x - bounds.minX) / bounds.width)
            device.changeInterestPoint(interestPoint)
            showFocusBox(focusPoint)
        } else if UIDevice.isSimulator {
            showFocusBox(focusPoint)
        }
    }

    private func showFocusBox(_ center: CGPoint) {
        cameraLayer?.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        let focusLayer = FocusBoxLayer(center: center)
        focusLayer.name = theFocusLayerName
        cameraLayer?.addSublayer(focusLayer)
    }

    @objc func removeFocusBox() { // not private because it is a selector for AVCaptureDeviceSubjectAreaDidChangeNotification
        cameraLayer?.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        if let device = device {
            let interestPoint = device.isFocusPointOfInterestSupported ? device.focusPointOfInterest : device.exposurePointOfInterest
            let center = CGPoint(x: 0.5, y: 0.5)
            if !interestPoint.equalTo(center) {
                device.changeInterestPoint(center)
            }
        }
    }
}

class CameraLayer: AVCaptureVideoPreviewLayer {
    override init(session: AVCaptureSession) {
        super.init(session: session)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        setup()
    }

    private func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateCameraFrameAndOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func updateCameraFrameAndOrientation() {
        guard let superlayer = superlayer else { return }
        frame = superlayer.bounds
        guard let connection = connection, connection.isVideoOrientationSupported,
            let appOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)
        else { return }
        connection.videoOrientation = appOrientation
    }
}

extension CALayer {
    func sublayerNamed(_ name: String) -> CALayer? {
        guard let sublayers = sublayers else { return nil }
        for sublayer in sublayers {
            if let sName = sublayer.name {
                if sName == name {
                    return sublayer
                }
            }
        }
        return nil
    }

    func insertBackgroundLayer(_ layer: CALayer, name: String? = nil) {
        layer.frame = bounds
        insertSublayer(layer, at: 0)
        if let name = name {
            layer.name = name
        }
    }
}

// MARK: - Private Constants

private let thePanelViewTag = 98765
private let theSwitchButtonTag = thePanelViewTag + 1
private let theFlashButtonTag = thePanelViewTag + 2
private let theTimerButtonTag = thePanelViewTag + 3
private let theCountdownLabelTag = thePanelViewTag + 4
private let theCameraLayerName = "camera"
private let theFocusLayerName = "focusSquare"

// MARK: - Identifiable Gesture Recognizers

class CameraTapGestureRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delegate = self
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }
}

private class CameraPinchGestureRecognizer: UIPinchGestureRecognizer {}
