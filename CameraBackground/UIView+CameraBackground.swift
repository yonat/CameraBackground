//
//  UIView+CameraBackground.swift
//  Show camera input as a background to any UIView.
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import AVFoundation
import UIKit

extension UIView {
    // MARK: - Public Camera Interface

    func toggleCameraBackground(position: AVCaptureDevicePosition = .Unspecified, buttonMargins: UIEdgeInsets = UIEdgeInsetsZero) {
        if let _ = cameraLayer {
            removeCameraBackground()
        }
        else {
            addCameraBackground(position, buttonMargins: buttonMargins)
        }
    }

    func removeCameraBackground() {
        removeCameraControls()
        cameraLayer?.removeFromSuperlayer()
    }

    func addCameraBackground(position: AVCaptureDevicePosition = .Unspecified, buttonMargins: UIEdgeInsets = UIEdgeInsetsZero) {
        let session = AVCaptureSession.stillCamreaCaptureSession(position)
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        if session == nil {
            cameraLayer.backgroundColor = UIColor.blackColor().CGColor
        }
        else {
            cameraLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        }

        layer.insertBackgroundLayer(cameraLayer, name: theCameraLayerName)
        addCameraControls(buttonMargins)
    }

    func takeCameraSnapshot(onTime: (() -> Void)?, completion: ((capturedImage: UIImage?, error: NSError?) -> ())? = nil) {
        if let cameraLayer = cameraLayer {
            performWithTimer(timerInterval) {
                onTime?()
                cameraLayer.connection.enabled = false // to freeze image
                cameraLayer.captureStillImage( {(capturedImage, error) in
                    cameraLayer.session.stopRunning()
                    completion?(capturedImage: capturedImage, error: error)
                })
            }
        }
    }

    func freeCameraSnapshot() {
        cameraLayer?.connection.enabled = true // to unfreeze image
        cameraLayer?.session.startRunning()
        removeFocusBox()
    }

    var cameraLayer: AVCaptureVideoPreviewLayer? {
        return layer.sublayerNamed(theCameraLayerName) as? AVCaptureVideoPreviewLayer
    }
    
    // MARK: - Private Camera Controls
    
    private var device: AVCaptureDevice? {
        return (cameraLayer?.session?.inputs?.first as? AVCaptureDeviceInput)?.device
    }

    private func addCameraControls(margins: UIEdgeInsets = UIEdgeInsetsZero) {
        // buttons panel
        let panel = UIView()
        panel.tag = thePanelViewTag
        panel.tintColor = UIColor.whiteColor()
        addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false
        constrain(panel, at: .Top, diff: margins.top)
        constrain(panel, at: .Left, diff: margins.left)
        constrain(panel, at: .Right, diff: -margins.right)
        
        // timer button
        let timerButton = ToggleButton(image: UIImage.template("camera-timer"), states: ["", "3s", "10s"], colors: [nil, UIColor.cameraOnColor(), UIColor.cameraOnColor(), UIColor.cameraOnColor()])
        panel.addTaggedSubview(timerButton, tag: theTimerButtonTag, constrain: .Top, .CenterX, .Bottom) // .Bottom constraint sets panel height
        
        // flash button
        let flashButton = ToggleButton(image: UIImage.template("camera-flash"), states: ["Off", "On", "Auto"], colors: [nil, UIColor.cameraOnColor()]) { (sender) -> () in
            self.setFlashMode(sender.currentStateIndex)
        }
        panel.addTaggedSubview(flashButton, tag: theFlashButtonTag, constrain: .Top, .Left)
        updateFlashButtonState()
        
        // switch camera button
        if AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count > 1 || UIDevice.isSimulator {
            let cameraButton = UIButton.buttonWithImage(UIImage.template("camera-switch")!, target: self, action: "switchCamera:")
            panel.addTaggedSubview(cameraButton, tag: theSwitchButtonTag, constrain: .Top, .Right)
        }
        
        // focus and zoom gestures - uses gesture subclass to make it identifiable when removing camera
        addGestureRecognizer( CameraPinchGestureRecognizer(target: self, action: "pinchToZoom:") )
        addGestureRecognizer( CameraTapGestureRecognizer(target: self, action: "tapToFocus:") )
        device?.changeMonitoring(true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeFocusBox", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: nil)
    }
    
    private func removeCameraControls() {
        // remove focus and zoom gestures
        gestureRecognizerOfType(CameraPinchGestureRecognizer.self)?.removeFromView()
        gestureRecognizerOfType(CameraTapGestureRecognizer.self)?.removeFromView()
        layer.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: nil)

        // remove controls
        viewWithTag(thePanelViewTag)?.removeFromSuperview()
    }
    
    private func updateFlashButtonState() {
        if let device = device {
            if let flashButton = viewWithTag(theFlashButtonTag) as? ToggleButton {
                if device.hasFlash {
                    flashButton.hidden = false
                    flashButton.currentStateIndex = device.flashMode.rawValue
                }
                else {
                    flashButton.hidden = true
                }
            }
        }
    }
    
    // MARK: - Action: Switch Front/Back Camera

    func switchCamera(sender: UIButton) {
        // TODO: animate
        if let session = cameraLayer?.session {
            var cameraPosition = AVCaptureDevicePosition.Unspecified
            if let input = session.inputs?.first as? AVCaptureDeviceInput {
                cameraPosition = input.device.position
                session.removeInput(input)
            }
            session.addCameraInput(cameraPosition.opposite())
            updateFlashButtonState()
            removeFocusBox()
        }
    }
    
    // MARK: - Action: Toggle Flash Mode

    func setFlashMode(rawValue: NSInteger) {
        if let device = device {
            if device.hasFlash {
                if let newMode = AVCaptureFlashMode(rawValue: rawValue) {
                    device.changeFlashMode(newMode)
                }
            }
        }
    }
    
    // MARK: - Action: Toggle Timer

    var timerInterval: Int {
        if let numberInTitle = (viewWithTag(theTimerButtonTag) as? UIButton)?.currentTitle?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " s")) {
            return Int(numberInTitle) ?? 0
        }
        return 0
    }
    
    private func performWithTimer(interval: Int, block: () -> ()) {
        if interval > 0 {
            showCountdown(interval)
            delay(Double(interval), block: block)
        }
        else {
            block()
        }
    }
    
    private func showCountdown(interval: Int) {
        // add countdown label
        let countdownLabel = UILabel()
        countdownLabel.textColor = UIColor.whiteColor()
        countdownLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        let fontSize = min(bounds.width / 2, bounds.height / 3)
        countdownLabel.font = UIFont.boldSystemFontOfSize(fontSize)
        countdownLabel.shadowOffset = CGSize(width: fontSize/30, height: fontSize/15)
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        addTaggedSubview(countdownLabel, tag: theCountdownLabelTag, constrain: .CenterX, .CenterY)
        
        // set timer
        countdown()
    }
    
    private func countdown() {
        // change countdown label until it is 0
        if let countdownLabel = viewWithTag(theCountdownLabelTag) as? UILabel {
            let secondsLeft = (Int(countdownLabel.text ?? "") ?? timerInterval + 1) - 1
            if secondsLeft > 0 {
                countdownLabel.text = "\(secondsLeft)"
                delay(1) {
                    self.countdown()
                }
            }
            else {
                countdownLabel.removeFromSuperview()
            }
        }
    }

    // MARK: - Action: Pinch to Zoom

    func pinchToZoom(sender: UIPinchGestureRecognizer) {
        struct Static {
            static var initialZoom: CGFloat = 1
        }
        if let device = device {
            if sender.state == .Began {
                Static.initialZoom = device.videoZoomFactor
            }
            device.changeZoomFactor(sender.scale * Static.initialZoom)
        }
    }
    
    // MARK: - Action: Tap to Focus

    func tapToFocus(sender: UITapGestureRecognizer) {
        let focusPoint = sender.locationInView(self)

        if let device = device {
            if !device.focusPointOfInterestSupported && !device.exposurePointOfInterestSupported {
                return
            }
            
            let interestPoint = CGPoint(x: (focusPoint.y - bounds.minY) / bounds.height, y: 1 - (focusPoint.x - bounds.minX) / bounds.width)
            device.changeInterestPoint(interestPoint)
            showFocusBox(focusPoint)
        }
        else if UIDevice.isSimulator {
            showFocusBox(focusPoint)
        }
    }
    
    private func showFocusBox(center: CGPoint) {
        cameraLayer?.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        let focusLayer = FocusBoxLayer(center: center)
        focusLayer.name = theFocusLayerName
        cameraLayer?.addSublayer(focusLayer)
    }
    
    func removeFocusBox() { // not private because it is a selector for AVCaptureDeviceSubjectAreaDidChangeNotification
        cameraLayer?.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        if let device = device {
            let interestPoint = device.focusPointOfInterestSupported ? device.focusPointOfInterest : device.exposurePointOfInterest
            let center = CGPoint(x: 0.5, y: 0.5)
            if !CGPointEqualToPoint(interestPoint, center) {
                device.changeInterestPoint(center)
            }
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

// MARK: - Useful Extensions

extension UIDevice {
    class var isSimulator: Bool {
        return currentDevice().model.hasSuffix("Simulator")
    }
}

extension UIView {
    func gestureRecognizerOfType<T: UIGestureRecognizer>(type: T.Type) -> UIGestureRecognizer? {
        if let gestureRecognizers = gestureRecognizers {
            for g in gestureRecognizers {
                if let gt = g as? T {
                    return gt as UIGestureRecognizer
                }
            }
        }
        return nil
    }
    
    func addTaggedSubview(subview: UIView, tag: Int, constrain: NSLayoutAttribute...) {
        subview.tag = tag
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        constrain.forEach { self.constrain(subview, at: $0) }
    }
}

extension UIGestureRecognizer {
    func removeFromView() {
        view?.removeGestureRecognizer(self)
    }
}

extension CALayer {
    func sublayerNamed(name: String) -> CALayer? {
        guard let sublayers = sublayers else  {return nil}
        for s in sublayers {
            if let sName = s.name {
                if sName == name {
                    return s
                }
            }
        }
        return nil
    }

    func insertBackgroundLayer(layer: CALayer, name: String? = nil) {
        layer.frame = bounds
        insertSublayer(layer, atIndex: 0)
        if let name = name {
            layer.name = name
        }
    }
}

extension UIImage {
    class func template(template: String) -> UIImage? {
        return UIImage(named: template)?.imageWithRenderingMode(.AlwaysTemplate)
    }
}

extension UIButton {
    class func buttonWithImage(image: UIImage, target: AnyObject, action: Selector) -> UIButton {
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        return button
    }
}

// MARK: - Focus Box

class FocusBoxLayer : CAShapeLayer {
    convenience init(center: CGPoint) {
        self.init()
        path = UIBezierPath(focusBoxAround: center, big: true).CGPath
        strokeColor = UIColor.cameraOnColor().CGColor
        fillColor = UIColor.clearColor().CGColor
        
        async_main {
            self.path = UIBezierPath(focusBoxAround: center, big: false).CGPath
        }
        
        delay(1) {
            self.opacity = 0.5
        }
    }
    
    override func actionForKey(event: String) -> CAAction? { // animate changes to 'path'
        switch event {
        case "path":
            let animation = CABasicAnimation(keyPath: event)
            animation.duration = CATransaction.animationDuration()
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            return animation
            
        default:
            return super.actionForKey(event)
        }
    }
}

extension UIBezierPath {
    convenience init(focusBoxAround center: CGPoint, big: Bool = false) {
        let size: CGFloat = big ? 150 : 75
        let lineSize: CGFloat = 5
        let square = CGRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size)
        self.init(rect: square)
        moveToPoint(CGPoint(x: center.x, y: square.minY))
        addLineToPoint(CGPoint(x: center.x, y: square.minY + lineSize))
        moveToPoint(CGPoint(x: center.x, y: square.maxY))
        addLineToPoint(CGPoint(x: center.x, y: square.maxY - lineSize))
        moveToPoint(CGPoint(x: square.minX, y: center.y))
        addLineToPoint(CGPoint(x: square.minX + lineSize, y: center.y))
        moveToPoint(CGPoint(x: square.maxX, y: center.y))
        addLineToPoint(CGPoint(x: square.maxX - lineSize, y: center.y))
    }
}

// MARK: - Identifiable Gesture Recognizers

class CameraTapGestureRecognizer : UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delegate = self
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }
}

private class CameraPinchGestureRecognizer : UIPinchGestureRecognizer {
}

// MARK: - Private AV Extensions

private extension UIColor {
    class func cameraOnColor() -> UIColor {
        return UIColor(red: 0.99, green: 0.79, blue: 0.19, alpha: 1)
    }
}

private extension AVCaptureSession {
    class func stillCamreaCaptureSession(position: AVCaptureDevicePosition) -> AVCaptureSession? {
        if UIDevice.isSimulator {return nil}
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        session.addCameraInput(position)
        session.addOutput( AVCaptureStillImageOutput() )
        session.startRunning()
        return session
    }

    func addCameraInput(position: AVCaptureDevicePosition) {
        guard let device = AVCaptureDevice.deviceWithPosition(position) else {return}
        if device.hasFlash {
            device.changeFlashMode(.Auto)
        }

        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if canAddInput(deviceInput) { addInput(deviceInput) }
            else { trace("Can't add camera input for position \(position.rawValue)") }
        }
        catch {
            trace("Can't access camera")
        }
    }
}

private extension AVCaptureDevicePosition {
    func opposite() -> AVCaptureDevicePosition {
        switch self {
        case .Front:  return .Back
        case .Back: return .Front
        default: return self
        }
    }
}

private extension AVCaptureDevice {
    class func deviceWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        if position != .Unspecified {
            guard let devices = devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice] else {return nil}
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        return defaultDeviceWithMediaType(AVMediaTypeVideo)
    }
    
    func changeFlashMode(mode: AVCaptureFlashMode) {
        performWithLock() {
            self.flashMode = mode
        }
    }
    
    func changeInterestPoint(point: CGPoint) {
        performWithLock() {
            if self.focusPointOfInterestSupported {
                self.focusPointOfInterest = point
                self.focusMode = .ContinuousAutoFocus
            }
            if self.exposurePointOfInterestSupported {
                self.exposurePointOfInterest = point
                self.exposureMode = .ContinuousAutoExposure
            }
        }
    }
    
    func changeMonitoring(on: Bool) {
        performWithLock() {
            self.subjectAreaChangeMonitoringEnabled = on
        }
    }
    
    func changeZoomFactor(zoomFactor: CGFloat) {
        let effectiveZoomFactor = min( max(zoomFactor, 1), 4)
        performWithLock() {
            self.videoZoomFactor = effectiveZoomFactor
        }
    }
    
    func performWithLock(block: ()->()) {
        var error: NSError?
        do {
            try lockForConfiguration()
            block()
            unlockForConfiguration()
        } catch let error1 as NSError {
            error = error1
            trace("Failed to acquire AVCaptureDevice.lockForConfiguration: \(error?.localizedDescription)")
        }
    }
}

private extension AVCaptureVideoPreviewLayer {
    func captureStillImage( completion: ((capturedImage: UIImage?, error: NSError?) -> ())? ) {

        let errorCompletion = {(code: Int, description: String) -> () in
            completion?(capturedImage: nil, error: NSError(domain: "AVCaptureError", code: code, userInfo: [NSLocalizedDescriptionKey: description]))
            return
        }

        if let imageOutput = imageOutput {
            if let videoConnection = imageOutput.videoConnection {
                imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(imageBuffer, error) in
                    if let error = error {
                        completion?(capturedImage: nil, error: error)
                    }
                    else {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
                        if var image = UIImage(data: imageData) {
                            if (self.session?.inputs?.first as? AVCaptureDeviceInput)?.device.position == .Front { // flip front camera
                                image = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: .RightMirrored)
                            }
                            completion?(capturedImage: image, error: nil)
                        }
                        else {
                            errorCompletion(1, "Can't create UIImage from captured image data")
                        }
                    }
                });
            }
            else {
                errorCompletion(2, "Can't find video AVCaptureConnection")
            }
        }
        else {
            errorCompletion(3, "Can't find AVCaptureStillImageOutput")
        }
    }

    var imageOutput: AVCaptureStillImageOutput? {
        if let session = session {
            for videoOutput in session.outputs {
                if let imageOutput = videoOutput as? AVCaptureStillImageOutput {
                    return imageOutput
                }
            }
        }
        return nil
    }
}

private extension AVCaptureOutput {
    var videoConnection: AVCaptureConnection? {
        for connection in connections as! [AVCaptureConnection] {
            for port in connection.inputPorts as! [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    return connection
                }
            }
        }
        return nil
    }
}
