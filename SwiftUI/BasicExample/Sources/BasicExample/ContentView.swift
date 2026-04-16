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

import AVKit
import SwiftUI

struct ContentView: View {
  @State private var viewModel = IMAPlayerViewModel()

  var body: some View {
    VStack {
      Text("IMA SDK SwiftUI Example")
        .font(.headline)

      ZStack {
        // Native SwiftUI video player — no UIViewControllerRepresentable needed.
        VideoPlayer(player: viewModel.player)

        // Transparent overlay that gives IMA SDK the UIView/UIViewController it needs.
        AdContainerView(viewModel: viewModel)

        if viewModel.isPlayButtonVisible {
          Button {
            viewModel.play()
          } label: {
            Image(systemName: "play.fill")
              .resizable()
              .frame(width: 50, height: 50)
              .foregroundStyle(.white)
              .shadow(radius: 4)
          }
        }
      }
      .aspectRatio(16 / 9, contentMode: .fit)
      .padding()

      Spacer()
    }
    .padding(.top)
  }
}

#Preview {
  ContentView()
}
