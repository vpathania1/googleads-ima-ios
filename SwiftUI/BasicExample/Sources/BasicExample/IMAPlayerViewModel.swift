// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AVFoundation
import GoogleInteractiveMediaAds
import Observation

/// View model that owns the AVPlayer and drives all IMA SDK interactions.
///
/// Content plays full-screen in 9:16. The ad container passed to IMA is sized
/// 16:9 (set by AdContainerView's SwiftUI frame), so IMA requests and renders
/// a landscape pre-roll inside the portrait player.
@Observable
final class IMAPlayerViewModel: NSObject {

  // Bundled 9:16 vertical content video (1080x1920).
  static let contentURL: URL = Bundle.main.url(forResource: "vertical_test", withExtension: "mp4")!

  // 16:9 linear pre-roll ad tag — sz=640x480 is the reliable IMA test inventory size.
  // The 16:9 aspect ratio is enforced by sizing the ad container to 16:9 in SwiftUI.
  static let adTagURLString =
    "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
    + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&"
    + "gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator="

  let player = AVPlayer(url: contentURL)
  var isPlayButtonVisible = true

  private let adsLoader = IMAAdsLoader()
  private var adsManager: IMAAdsManager?

  // Strong reference — avoids the weak ref being nil'd when SwiftUI re-renders
  // AdContainerView between isPlayButtonVisible=false and requestAds() executing.
  private var adContainerView: UIView?
  private weak var presentingViewController: UIViewController?

  // Flag set in play(); checked in configure() so requestAds fires after the
  // view hierarchy is guaranteed live (solves the race on first tap).
  private var pendingPlay = false

  private var contentPlayhead: IMAAVPlayerContentPlayhead!

  override init() {
    super.init()
    contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
    adsLoader.delegate = self
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(contentDidFinishPlaying),
      name: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem)
  }

  /// Called by AdContainerView every time its UIView updates and is in the window.
  func configure(adContainer: UIView, presentingViewController: UIViewController) {
    NSLog("[IMA] configure called — container: \(adContainer.frame), vc: \(presentingViewController)")
    self.adContainerView = adContainer
    self.presentingViewController = presentingViewController
    if pendingPlay {
      pendingPlay = false
      requestAds()
    }
  }

  func play() {
    NSLog("[IMA] play() tapped — adContainer: \(String(describing: adContainerView)), vc: \(String(describing: presentingViewController))")
    isPlayButtonVisible = false
    if adContainerView != nil && presentingViewController != nil {
      requestAds()
    } else {
      // Container not yet live — set flag; configure() will fire requestAds once ready.
      pendingPlay = true
    }
  }

  private func requestAds() {
    guard let adContainerView, let presentingViewController else {
      NSLog("[IMA] requestAds() — guard failed: container=\(String(describing: adContainerView)) vc=\(String(describing: presentingViewController))")
      return
    }
    NSLog("[IMA] requestAds() — firing ad request to: \(Self.adTagURLString)")
    let adDisplayContainer = IMAAdDisplayContainer(
      adContainer: adContainerView,
      viewController: presentingViewController,
      companionSlots: nil)
    let request = IMAAdsRequest(
      adTagUrl: Self.adTagURLString,
      adDisplayContainer: adDisplayContainer,
      contentPlayhead: contentPlayhead,
      userContext: nil)
    adsLoader.requestAds(with: request)
  }

  @objc private func contentDidFinishPlaying(_ notification: Notification) {
    if notification.object as? AVPlayerItem == player.currentItem {
      adsLoader.contentComplete()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    adsManager?.destroy()
  }
}

// MARK: - IMAAdsLoaderDelegate

extension IMAPlayerViewModel: IMAAdsLoaderDelegate {
  func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
    NSLog("[IMA] adsLoaded — initialising ads manager")
    adsManager = adsLoadedData.adsManager
    adsManager?.delegate = self
    let settings = IMAAdsRenderingSettings()
    settings.linkOpenerPresentingController = presentingViewController
    adsManager?.initialize(with: settings)
  }

  func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
    NSLog("[IMA] ad load FAILED: \(adErrorData.adError.message ?? "unknown")")
    player.play()
  }
}

// MARK: - IMAAdsManagerDelegate

extension IMAPlayerViewModel: IMAAdsManagerDelegate {
  func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
    NSLog("[IMA] ad event: \(event.type.rawValue)")
    if event.type == .LOADED {
      adsManager.start()
    }
  }

  func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
    NSLog("[IMA] ad manager error: \(error.message ?? "unknown")")
    player.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
    NSLog("[IMA] content pause requested")
    player.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
    NSLog("[IMA] content resume requested")
    player.play()
  }
}
