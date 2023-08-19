
Pod::Spec.new do |s|

  s.name         = "CameraBackground"
  s.version      = "1.6.6"
  s.summary      = "Show camera layer as a background to any UIView."

  s.description  = <<-DESC
Features:

* Both **front and back** camera supported.
* **Flash** modes: auto, on, off.
* Countdown **timer**.
* Tap to **focus**.
* Pinch to **zoom**.

Usage:

```swift
view.addCameraBackground()
// ...
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
// ...
view.removeCameraBackground()
```
                   DESC

  s.homepage     = "https://github.com/yonat/CameraBackground"
  s.screenshots  = "https://raw.githubusercontent.com/yonat/CameraBackground/master/screenshots/focus.png", "https://raw.githubusercontent.com/yonat/CameraBackground/master/screenshots/countdown.png"

  s.license      = { :type => "MIT", :file => "LICENSE.txt" }

  s.author             = { "Yonat Sharon" => "yonat@ootips.org" }
  s.social_media_url   = "https://twitter.com/yonatsharon"

  s.swift_versions = ['5.0']
  s.platform     = :ios, "11.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/yonat/CameraBackground.git", :tag => s.version }
  s.source_files  = "Sources/*.swift"
  s.resources = ['PrivacyInfo.xcprivacy']
  s.subspec 'Resources' do |resources|
    resources.resource_bundle = {s.name => 'Sources/*.png'}
  end

  s.dependency 'SweeterSwift'
  s.dependency 'MultiToggleButton'
end
