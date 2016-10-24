
Pod::Spec.new do |s|

  s.name         = "CameraBackground"
  s.version      = "1.0.1"
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
  s.social_media_url   = "http://twitter.com/yonatsharon"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/yonat/CameraBackground.git", :tag => s.version }

  s.source_files  = "CameraBackground/*"

  s.requires_arc = true

end
