//
//  UIView+CameraBackground.swift
//  Show camera input as a background to any UIView.
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import AVFoundation
import UIKit
import MiniLayout
import MultiToggleButton

public extension UIView {
    // MARK: - Public Camera Interface

    /// Change the current camera background layer, e.g. when a user taps a camera on/off button.
    public func toggleCameraBackground(_ position: AVCaptureDevicePosition = .unspecified, buttonMargins: UIEdgeInsets = .zero) {
        if let _ = cameraLayer {
            removeCameraBackground()
        }
        else {
            addCameraBackground(position, buttonMargins: buttonMargins)
        }
    }
    /// Remove camera background layer
    public func removeCameraBackground() {
        removeCameraControls()
        cameraLayer?.removeFromSuperlayer()
    }

    /// Add camera background layer
    public func addCameraBackground(_ position: AVCaptureDevicePosition = .unspecified, buttonMargins: UIEdgeInsets = .zero) {
        let session = AVCaptureSession.stillCameraCaptureSession(position)
        let cameraLayer = CameraLayer(session: session)
        if session == nil {
            cameraLayer?.backgroundColor = UIColor.black.cgColor
        }
        else {
            cameraLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        }

        layer.insertBackgroundLayer(cameraLayer!, name: theCameraLayerName)
        addCameraControls(buttonMargins)
    }

    /// Take snapshot of the camera input shown in the background layer.
    /// - Parameters:
    ///   - onTime: action to perform when the timer completes countdown. E.g., make a click sound and/or show a flash.
    ///   - completion: handle captured image.
    public func takeCameraSnapshot(_ onTime: (() -> Void)?, completion: ((_ capturedImage: UIImage?, _ error: NSError?) -> ())? = nil) {
        if let cameraLayer = cameraLayer {
            viewWithTag(theCountdownLabelTag)?.removeFromSuperview()
            performWithTimer(timerInterval) {
                onTime?()
                cameraLayer.connection.isEnabled = false // to freeze image
                cameraLayer.captureStillImage( {(capturedImage, error) in
                    cameraLayer.session.stopRunning()
                    completion?(capturedImage, error)
                })
            }
        }
    }

    /// Re-start streaming input from camera into background layer.
    public func freeCameraSnapshot() {
        cameraLayer?.connection.isEnabled = true // to unfreeze image
        cameraLayer?.session.startRunning()
        removeFocusBox()
    }

    /// The background layer showing camera input stream.
    public var cameraLayer: AVCaptureVideoPreviewLayer? {
        return layer.sublayerNamed(theCameraLayerName) as? AVCaptureVideoPreviewLayer
    }
    
    // MARK: - Private Camera Controls
    
    private var device: AVCaptureDevice? {
        return (cameraLayer?.session?.inputs?.first as? AVCaptureDeviceInput)?.device
    }

    private func addCameraControls(_ margins: UIEdgeInsets = .zero) {
        // buttons panel
        let panel = UIView()
        panel.tag = thePanelViewTag
        panel.tintColor = .white
        addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false
        constrain(panel, at: .top, diff: margins.top)
        constrain(panel, at: .left, diff: margins.left)
        constrain(panel, at: .right, diff: -margins.right)
        
        // timer button
        let timerButton = MultiToggleButton(image: bundeledCameraTemplateImage("camera-timer"), states: ["", "3s", "10s"], colors: [nil, UIColor.cameraOnColor(), UIColor.cameraOnColor(), UIColor.cameraOnColor()])
        panel.addTaggedSubview(timerButton, tag: theTimerButtonTag, constrain: .top, .centerX, .bottom) // .bottom constraint sets panel height
        
        // flash button
        let flashButton = MultiToggleButton(image: bundeledCameraTemplateImage("camera-flash"), states: ["Off", "On", "Auto"], colors: [nil, UIColor.cameraOnColor()]) { (sender) -> () in
            self.setFlashMode(sender.currentStateIndex)
        }
        panel.addTaggedSubview(flashButton, tag: theFlashButtonTag, constrain: .top, .left)
        updateFlashButtonState()
        
        // switch camera button
        if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 1 || UIDevice.isSimulator {
            let cameraButton = UIButton.buttonWithImage(bundeledCameraTemplateImage("camera-switch")!, target: self, action: #selector(switchCamera(_:)))
            panel.addTaggedSubview(cameraButton, tag: theSwitchButtonTag, constrain: .top, .right)
        }
        
        // focus and zoom gestures - uses gesture subclass to make it identifiable when removing camera
        addGestureRecognizer( CameraPinchGestureRecognizer(target: self, action: #selector(pinchToZoom(_:))) )
        addGestureRecognizer( CameraTapGestureRecognizer(target: self, action: #selector(tapToFocus(_:))) )
        device?.changeMonitoring(true)
        NotificationCenter.default.addObserver(self, selector: #selector(removeFocusBox), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
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
                }
                else {
                    flashButton.isHidden = true
                }
            }
        }
    }
    
    // MARK: - Action: Switch Front/Back Camera

    func switchCamera(_ sender: UIButton) {
        // TODO: animate
        if let session = cameraLayer?.session {
            var cameraPosition = AVCaptureDevicePosition.unspecified
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

    func setFlashMode(_ rawValue: NSInteger) {
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
        if let numberInTitle = (viewWithTag(theTimerButtonTag) as? UIButton)?.currentTitle?.trimmingCharacters(in: CharacterSet(charactersIn: " s")) {
            return Int(numberInTitle) ?? 0
        }
        return 0
    }
    
    private func performWithTimer(_ interval: Int, block: @escaping () -> ()) {
        if interval > 0 {
            let countdownLabel = CoundownLabel(seconds: interval, action: block)
            addTaggedSubview(countdownLabel, tag: theCountdownLabelTag, constrain: .centerX, .centerY)
        }
        else {
            block()
        }
    }
    
    // MARK: - Action: Pinch to Zoom

    func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        struct Static {
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

    func tapToFocus(_ sender: UITapGestureRecognizer) {
        let focusPoint = sender.location(in: self)

        if let device = device {
            if !device.isFocusPointOfInterestSupported && !device.isExposurePointOfInterestSupported {
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
    
    private func showFocusBox(_ center: CGPoint) {
        cameraLayer?.sublayerNamed(theFocusLayerName)?.removeFromSuperlayer()
        let focusLayer = FocusBoxLayer(center: center)
        focusLayer.name = theFocusLayerName
        cameraLayer?.addSublayer(focusLayer)
    }
    
    func removeFocusBox() { // not private because it is a selector for AVCaptureDeviceSubjectAreaDidChangeNotification
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
    override init!(session: AVCaptureSession!) {
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange, object: nil, queue: nil) { [weak self] (notification) in
            self?.updateCameraFrameAndOrientation()
        }
    }

    func updateCameraFrameAndOrientation() {
        guard let superlayer = superlayer else {return}
        frame = superlayer.bounds
        guard let connection = connection, connection.isVideoOrientationSupported,
            let appOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)
            else {return}
        connection.videoOrientation = appOrientation
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

    public func bundeledCameraTemplateImage(_ named: String) -> UIImage? {
        return bundledCameraImage(named)?.withRenderingMode(.alwaysTemplate)
    }
}

extension UIDevice {
    class var isSimulator: Bool {
        return current.model.hasSuffix("Simulator")
    }
}

extension UIView {
    func gestureRecognizerOfType<T: UIGestureRecognizer>(_ type: T.Type) -> UIGestureRecognizer? {
        if let gestureRecognizers = gestureRecognizers {
            for g in gestureRecognizers {
                if let gt = g as? T {
                    return gt as UIGestureRecognizer
                }
            }
        }
        return nil
    }
    
    func addTaggedSubview(_ subview: UIView, tag: Int, constrain: NSLayoutAttribute...) {
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
    func sublayerNamed(_ name: String) -> CALayer? {
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

    func insertBackgroundLayer(_ layer: CALayer, name: String? = nil) {
        layer.frame = bounds
        insertSublayer(layer, at: 0)
        if let name = name {
            layer.name = name
        }
    }
}

extension UIButton {
    class func buttonWithImage(_ image: UIImage, target: AnyObject, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: UIControlState())
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}

// MARK: - Countdown Label

class CoundownLabel: UILabel {
    var remainingSeconds: Int = 0
    let action: ()->Void
    private var dispatchWorkItem: DispatchWorkItem?

    init(seconds: Int, action: @escaping ()->Void) {
        self.action = action
        remainingSeconds = seconds
        super.init(frame: .zero)

        textColor = .white
        shadowColor = UIColor.black.withAlphaComponent(0.5)
        let fontSize = min(UIScreen.main.bounds.width / 2, UIScreen.main.bounds.height / 3)
        font = .boldSystemFont(ofSize: fontSize)
        shadowOffset = CGSize(width: fontSize/30, height: fontSize/15)

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
            dispatchWorkItem = DispatchWorkItem {[weak self] in self?.countdown()}
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dispatchWorkItem!)
        }
        else {
            removeFromSuperview()
            action()
        }
    }
}


// MARK: - Focus Box

class FocusBoxLayer : CAShapeLayer {
    convenience init(center: CGPoint) {
        self.init()
        path = UIBezierPath(focusBoxAround: center, big: true).cgPath
        strokeColor = UIColor.cameraOnColor().cgColor
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
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            return animation
            
        default:
            return super.action(forKey: event)
        }
    }
}

extension UIBezierPath {
    convenience init(focusBoxAround center: CGPoint, big: Bool = false) {
        let size: CGFloat = big ? 150 : 75
        let lineSize: CGFloat = 5
        let square = CGRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size)
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

// MARK: - Identifiable Gesture Recognizers

class CameraTapGestureRecognizer : UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
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
    class func stillCameraCaptureSession(_ position: AVCaptureDevicePosition) -> AVCaptureSession? {
        if UIDevice.isSimulator {return nil}
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        session.addCameraInput(position)
        session.addOutput( AVCaptureStillImageOutput() )
        session.startRunning()
        return session
    }

    func addCameraInput(_ position: AVCaptureDevicePosition) {
        guard let device = AVCaptureDevice.deviceWithPosition(position) else {return}
        if device.hasFlash {
            device.changeFlashMode(.auto)
        }

        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if canAddInput(deviceInput) { addInput(deviceInput) }
            else { NSLog("Can't add camera input for position \(position.rawValue)") }
        }
        catch {
            NSLog("Can't access camera")
        }
    }
}

private extension AVCaptureDevicePosition {
    func opposite() -> AVCaptureDevicePosition {
        switch self {
        case .front:  return .back
        case .back: return .front
        default: return self
        }
    }
}

private extension AVCaptureDevice {
    class func deviceWithPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        if position != .unspecified {
            guard let devices = devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {return nil}
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        return defaultDevice(withMediaType: AVMediaTypeVideo)
    }
    
    func changeFlashMode(_ mode: AVCaptureFlashMode) {
        performWithLock() {
            self.flashMode = mode
        }
    }
    
    func changeInterestPoint(_ point: CGPoint) {
        performWithLock() {
            if self.isFocusPointOfInterestSupported {
                self.focusPointOfInterest = point
                self.focusMode = .continuousAutoFocus
            }
            if self.isExposurePointOfInterestSupported {
                self.exposurePointOfInterest = point
                self.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    func changeMonitoring(_ on: Bool) {
        performWithLock() {
            self.isSubjectAreaChangeMonitoringEnabled = on
        }
    }
    
    func changeZoomFactor(_ zoomFactor: CGFloat) {
        let effectiveZoomFactor = min( max(zoomFactor, 1), 4)
        performWithLock() {
            self.videoZoomFactor = effectiveZoomFactor
        }
    }
    
    func performWithLock(_ block: ()->()) {
        do {
            try lockForConfiguration()
            block()
            unlockForConfiguration()
        } catch let error as NSError {
            NSLog("Failed to acquire AVCaptureDevice.lockForConfiguration: \(error.localizedDescription)")
        }
    }
}

private extension AVCaptureVideoPreviewLayer {
    func captureStillImage( _ completion: ((_ capturedImage: UIImage?, _ error: NSError?) -> ())? ) {

        let errorCompletion = {(code: Int, description: String) -> () in
            completion?(nil, NSError(domain: "AVCaptureError", code: code, userInfo: [NSLocalizedDescriptionKey: description]))
            return
        }

        if let imageOutput = imageOutput {
            if let videoConnection = imageOutput.videoConnection {
                imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(imageBuffer, error) in
                    if let error = error {
                        completion?(nil, error as NSError?)
                    }
                    else {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
                        if var image = UIImage(data: imageData!) {
                            if (self.session?.inputs?.first as? AVCaptureDeviceInput)?.device.position == .front { // flip front camera
                                image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .rightMirrored)
                            }
                            completion?(image, nil)
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
