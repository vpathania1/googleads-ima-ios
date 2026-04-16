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

import SwiftUI
import UIKit

/// A transparent UIView overlay that provides the IMA SDK with a UIView ad container
/// and a UIViewController presenter — the two UIKit requirements IMA still needs.
struct AdContainerView: UIViewRepresentable {
  let viewModel: IMAPlayerViewModel

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // Defer one run-loop tick so the UIView is guaranteed to be embedded
    // in a window before we walk the responder chain.
    DispatchQueue.main.async {
      NSLog("[IMA] AdContainerView updateUIView — window: \(String(describing: uiView.window)), frame: \(uiView.frame)")
      guard uiView.window != nil else {
        NSLog("[IMA] AdContainerView — view not yet in window, skipping configure")
        return
      }
      var responder: UIResponder? = uiView
      while let next = responder?.next {
        if let viewController = next as? UIViewController {
          NSLog("[IMA] AdContainerView — found vc: \(viewController), calling configure")
          viewModel.configure(adContainer: uiView, presentingViewController: viewController)
          return
        }
        responder = next
      }
      NSLog("[IMA] AdContainerView — no UIViewController found in responder chain")
    }
  }
}
