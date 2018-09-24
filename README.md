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

**Important:** Remeber to add `NSCameraUsageDescription` to your `Info.plist`.

## Installation

### CocoaPods:

```ruby
pod 'CameraBackground'
```

Legacy versions:

| Swift version | CameraBackground version |
| :---: | :--- |
| 4.0 (Xcode 9.4) | `pod 'MiniLayout', '~> 1.2.1'`<br>`pod 'MultiToggleButton', '~> 1.7.1'`<br>`pod 'CameraBackground', '~> 1.4.1'` |
| 3 | `pod 'MiniLayout', '~> 1.1.0'`<br>`pod 'MultiToggleButton', '~> 1.5.2'`<br>`pod 'CameraBackground', '~> 1.2'` |
| 2.3 | `pod 'MiniLayout', '~> 1.0.1'`<br>`pod 'MultiToggleButton', '~> 1.4.0'`<br>`pod 'CameraBackground', '~> 1.0.2'` |

### Manually:

Copy `Sources/*` to your Xcode project.

## Meta

[@yonatsharon](https://twitter.com/yonatsharon)

[https://github.com/yonat/CameraBackground](https://github.com/yonat/CameraBackground)

[swift-image]:https://img.shields.io/badge/swift-4.2-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE.txt
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
