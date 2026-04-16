# IMA SDK SwiftUI Basic Example

A modern SwiftUI implementation of the [Google IMA SDK](https://developers.google.com/interactive-media-ads/docs/sdks/ios) basic pre-roll ad example for iOS 17+.

## Key differences from the existing `Swift/BasicExample`

| | `Swift/BasicExample` | `SwiftUI/BasicExample` |
|---|---|---|
| Player view | `UIViewControllerRepresentable` wrapping `AVPlayerLayer` | Native `AVKit.VideoPlayer` |
| State management | `@State` + UIKit delegate callbacks | `@Observable` view model |
| Dependencies | CocoaPods (`Podfile`) | Swift Package Manager (`Package.swift`) |
| Min iOS | iOS 14 | iOS 17 |
| IMA bridge | Full `UIViewController` wrapper | Minimal `UIViewRepresentable` overlay only |

## Architecture

```
ContentView                   (SwiftUI)
  ├── VideoPlayer              (AVKit — native SwiftUI)
  ├── AdContainerView          (UIViewRepresentable — minimal UIKit bridge for IMA)
  └── Play button overlay

IMAPlayerViewModel (@Observable)
  ├── AVPlayer
  ├── IMAAdsLoader
  └── IMAAdsManager
```

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+

## Setup

1. Open the package in Xcode:
   ```
   open SwiftUI/BasicExample/Package.swift
   ```
2. Xcode will resolve the `GoogleInteractiveMediaAds` SPM dependency automatically.
3. Run on a device or simulator.

## How it works

- `IMAPlayerViewModel` owns the `AVPlayer` and all IMA SDK logic (`IMAAdsLoader`, `IMAAdsManager`).
- `AdContainerView` is a transparent `UIViewRepresentable` overlay. Its only job is to hand a live `UIView` and a `UIViewController` presenter to the IMA SDK — the two UIKit requirements IMA still has.
- `ContentView` composes everything in a `ZStack`: native `VideoPlayer` underneath, `AdContainerView` overlay on top, play button on top of that.
