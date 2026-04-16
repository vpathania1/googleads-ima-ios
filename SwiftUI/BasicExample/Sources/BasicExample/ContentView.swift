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
import SwiftUI

struct ContentView: View {
  @State private var viewModel = IMAPlayerViewModel()

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.black.ignoresSafeArea()

        // 9:16 full-screen vertical content video (aspect-fill covers the full portrait frame).
        VerticalVideoPlayer(player: viewModel.player)
          .ignoresSafeArea()

        // 16:9 ad container centred vertically within the 9:16 screen.
        // IMA renders the ad inside this view — its 16:9 size tells the SDK
        // to serve a landscape ad even though the content is portrait.
        AdContainerView(viewModel: viewModel)
          .frame(width: geo.size.width, height: geo.size.width * 9 / 16)

        if viewModel.isPlayButtonVisible {
          Button {
            viewModel.play()
          } label: {
            Image(systemName: "play.fill")
              .resizable()
              .frame(width: 64, height: 64)
              .foregroundStyle(.white)
              .shadow(radius: 8)
          }
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .ignoresSafeArea()
    .statusBarHidden()
    .preferredColorScheme(.dark)
    .onAppear {
      // Auto-play after 3 s so the ad container is fully live in the window hierarchy.
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        viewModel.play()
      }
    }
  }
}

// MARK: - VerticalVideoPlayer

/// Full-screen AVPlayer view using AVPlayerLayer with resizeAspectFill
/// so vertical content fills the entire 9:16 frame without letterboxing.
private struct VerticalVideoPlayer: UIViewRepresentable {
  let player: AVPlayer

  func makeUIView(context: Context) -> PlayerLayerView {
    let view = PlayerLayerView()
    view.playerLayer.player = player
    view.playerLayer.videoGravity = .resizeAspectFill
    view.backgroundColor = .black
    return view
  }

  func updateUIView(_ uiView: PlayerLayerView, context: Context) {}
}

private final class PlayerLayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}

#Preview {
  ContentView()
}
