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
@Observable
final class IMAPlayerViewModel: NSObject {
  static let contentURL = URL(
    string: "https://storage.googleapis.com/gvabox/media/samples/stock.mp4")!

  static let adTagURLString =
    "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
    + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&"
    + "gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator="

  let player = AVPlayer(url: contentURL)
  var isPlayButtonVisible = true

  private let adsLoader = IMAAdsLoader()
  private var adsManager: IMAAdsManager?

  // Weak references set by AdContainerView once its UIView is in the hierarchy.
  private weak var adContainerView: UIView?
  private weak var presentingViewController: UIViewController?

  private lazy var contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)

  override init() {
    super.init()
    adsLoader.delegate = self
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(contentDidFinishPlaying),
      name: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem)
  }

  /// Called by AdContainerView once its UIView is live in the window.
  func configure(adContainer: UIView, presentingViewController: UIViewController) {
    self.adContainerView = adContainer
    self.presentingViewController = presentingViewController
  }

  func play() {
    isPlayButtonVisible = false
    requestAds()
  }

  private func requestAds() {
    guard let adContainerView, let presentingViewController else { return }
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
    adsManager = adsLoadedData.adsManager
    adsManager?.delegate = self
    let settings = IMAAdsRenderingSettings()
    settings.linkOpenerPresentingController = presentingViewController
    adsManager?.initialize(with: settings)
  }

  func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
    print("Error loading ads: \(adErrorData.adError.message ?? "unknown")")
    player.play()
  }
}

// MARK: - IMAAdsManagerDelegate

extension IMAPlayerViewModel: IMAAdsManagerDelegate {
  func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
    if event.type == .LOADED {
      adsManager.start()
    }
  }

  func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
    print("AdsManager error: \(error.message ?? "unknown")")
    player.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
    player.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
    player.play()
  }
}
