# UIView+CameraBackground
Show camera layer as a background to any UIView.

[![Swift Version][swift-image]][swift-url]
[![Build Status][travis-image]][travis-url]
[![License][license-image]][license-url]
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/CameraBackground.svg)](https://img.shields.io/cocoapods/v/CameraBackground.svg)  
[![Platform](https://img.shields.io/cocoapods/p/CameraBackground.svg?style=flat)](http://cocoapods.org/pods/CameraBackground)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

## Features
* Both **front and back** camera supported.
* **Flash** modes: auto, on, off.
* Countdown **timer**.
* Tap to **focus**.
* Pinch to **zoom**.

<p align="center">
<img src="screenshots/focus.png"> &nbsp; <img src="screenshots/countdown.png">
</p>

## Usage

```swift
view.addCameraBackground()
// ...
view.takeCameraSnapshot( {
      // animate snapshot capture
      self.view.alpha = 0
      UIView.animate(withDuration: 1) { self.view.alpha = 1 }
  },
  completion: { (capturedImage, error) -> () in
      self.view.freeCameraSnapshot() // unfreeze image
      // ... handle capturedImage and error
  }
)
// ...
view.removeCameraBackground()
```

**Important:** Remember to add `NSCameraUsageDescription` to your `Info.plist`.

### Layout

You can change the location of the camera controls (flash, timer, and front/back camera selection) or hide them altogether:

```swift
view.addCameraBackground(
   showButtons: true,
   buttonMargins: UIEdgeInsets(top: 30, left: 10, bottom: 10, right: 10),
   buttonsLocation: .left
)
```

## Installation

### CocoaPods:

```ruby
pod 'CameraBackground'
```

### Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yonat/CameraBackground", from: "1.7.2")
]
```

## Meta

[@yonatsharon](https://twitter.com/yonatsharon)

[https://github.com/yonat/CameraBackground](https://github.com/yonat/CameraBackground)

[swift-image]:https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE.txt
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
