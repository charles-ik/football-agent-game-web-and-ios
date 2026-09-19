import SwiftUI
import UIKit
import WebKit

@MainActor
final class BrowserState: ObservableObject {
    @Published var isLoading = true
    @Published var error: String?
}

struct ContentView: View {
    let url: URL
    @StateObject private var state = BrowserState()
    @State private var retryID = UUID()

    var body: some View {
        ZStack {
            GameWebView(url: url, retryID: $retryID, state: state)
                .ignoresSafeArea()

            if state.isLoading {
                ProgressView("Opening Football Agent…")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }

            if let error = state.error {
                VStack(spacing: 14) {
                    Text("Football Agent is not running")
                        .font(.headline)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        state.error = nil
                        state.isLoading = true
                        retryID = UUID()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: 340)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct GameWebView: UIViewRepresentable {
    let url: URL
    @Binding var retryID: UUID
    @ObservedObject var state: BrowserState

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, retryID: retryID, state: state)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.refresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.retryID != retryID else { return }
        context.coordinator.retryID = retryID
        webView.load(URLRequest(url: url))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let url: URL
        var retryID: UUID
        let state: BrowserState
        weak var webView: WKWebView?

        init(url: URL, retryID: UUID, state: BrowserState) {
            self.url = url
            self.retryID = retryID
            self.state = state
        }

        @objc func refresh() {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.refreshControl?.endRefreshing()
            state.isLoading = false
            state.error = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            show(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            show(error)
        }

        private func show(_ error: Error) {
            webView?.scrollView.refreshControl?.endRefreshing()
            state.isLoading = false
            state.error = "Run ‘make dev-ios’ on this Mac, then keep the Mac and iPhone on the same network.\n\n\(error.localizedDescription)"
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let destination = navigationAction.request.url,
                  destination.host != url.host else {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(destination)
            decisionHandler(.cancel)
        }
    }
}
