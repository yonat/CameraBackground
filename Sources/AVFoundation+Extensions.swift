//
//  AVFoundation+Extensions.swift
//  CameraBackground
//
//  Created by Yonat Sharon on 11/1/15.
//  Copyright (c) 2015 Yonat Sharon. All rights reserved.
//

import AVFoundation

extension AVCaptureSession {
    class func stillCameraCaptureSession(_ position: AVCaptureDevice.Position) -> AVCaptureSession? {
        #if targetEnvironment(simulator)
            return nil
        #endif
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        session.addCameraInput(position)
        session.addOutput(AVCaptureStillImageOutput())
        session.startRunning()
        return session
    }

    func addCameraInput(_ position: AVCaptureDevice.Position) {
        guard let device = AVCaptureDevice.deviceWithPosition(position) else { return }
        if device.hasFlash {
            device.changeFlashMode(.auto)
        }

        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if canAddInput(deviceInput) {
                addInput(deviceInput)
            } else {
                NSLog("Can't add camera input for position \(position.rawValue)")
            }
        } catch {
            NSLog("Can't access camera")
        }
    }
}

extension AVCaptureDevice.Position {
    func opposite() -> AVCaptureDevice.Position {
        switch self {
        case .front: return .back
        case .back: return .front
        default: return self
        }
    }
}

extension AVCaptureDevice {
    class func deviceWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position != .unspecified, let device = devices(for: AVMediaType.video).first(where: { $0.position == position }) {
            return device
        }
        return AVCaptureDevice.default(for: AVMediaType.video)
    }

    func changeFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        performWithLock {
            self.flashMode = mode
        }
    }

    func changeInterestPoint(_ point: CGPoint) {
        performWithLock {
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

    func changeMonitoring(_ isOn: Bool) {
        performWithLock {
            self.isSubjectAreaChangeMonitoringEnabled = isOn
        }
    }

    func changeZoomFactor(_ zoomFactor: CGFloat) {
        let effectiveZoomFactor = min(max(zoomFactor, 1), 4)
        performWithLock {
            self.videoZoomFactor = effectiveZoomFactor
        }
    }

    func performWithLock(_ block: () -> Void) {
        do {
            try lockForConfiguration()
            block()
            unlockForConfiguration()
        } catch let error as NSError {
            NSLog("Failed to acquire AVCaptureDevice.lockForConfiguration: \(error.localizedDescription)")
        }
    }
}

extension AVCaptureVideoPreviewLayer {
    func captureStillImage(_ completion: ((_ capturedImage: UIImage?, _ error: NSError?) -> Void)?) {
        let errorCompletion = { (code: Int, description: String) -> Void in
            completion?(nil, NSError(domain: "AVCaptureError", code: code, userInfo: [NSLocalizedDescriptionKey: description]))
            return
        }

        if let imageOutput = imageOutput {
            if let videoConnection = imageOutput.videoConnection {
                imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { imageBuffer, error in
                    if let error = error {
                        completion?(nil, error as NSError?)
                    } else if let imageBuffer = imageBuffer {
                        if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer),
                            var image = UIImage(data: imageData) {
                            if (self.session?.inputs.first as? AVCaptureDeviceInput)?.device.position == .front { // flip front camera
                                // swiftlint:disable force_unwrapping
                                image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .rightMirrored)
                                // swiftlint:enable force_unwrapping
                            }
                            completion?(image, nil)
                        } else {
                            errorCompletion(1, "Can't create UIImage from captured image data")
                        }
                    }
                })
            } else {
                errorCompletion(2, "Can't find video AVCaptureConnection")
            }
        } else {
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
        return connections.first(where: { connection in connection.inputPorts.contains { $0.mediaType == .video } })
    }
}
