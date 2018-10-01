# BFRadioPlayer

[![CI Status](https://img.shields.io/travis/bananafish911/BFRadioPlayer.svg?style=flat)](https://travis-ci.org/bananafish911/BFRadioPlayer)
[![Version](https://img.shields.io/cocoapods/v/BFRadioPlayer.svg?style=flat)](https://cocoapods.org/pods/BFRadioPlayer)
[![License](https://img.shields.io/cocoapods/l/BFRadioPlayer.svg?style=flat)](https://cocoapods.org/pods/BFRadioPlayer)
[![Platform](https://img.shields.io/cocoapods/p/BFRadioPlayer.svg?style=flat)](https://cocoapods.org/pods/BFRadioPlayer)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

If you are going to use http addresses (instead only https), you will need to change whitelist domains in your app by adding the following to your application's plist (often called "Info.plist"):
```ruby
<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key><true/>
</dict>
```

## Installation

BFRadioPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BFRadioPlayer'
```

## Author

bananafish911, victor.dombrovskiy@gmail.com

## License

BFRadioPlayer is available under the MIT license. See the LICENSE file for more info.
