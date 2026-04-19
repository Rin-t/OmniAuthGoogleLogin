import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    let onInterceptLogin: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onInterceptLogin: onInterceptLogin)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onInterceptLogin: () -> Void

        init(onInterceptLogin: @escaping () -> Void) {
            self.onInterceptLogin = onInterceptLogin
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url, url.path == "/auth/google" {
                decisionHandler(.cancel)
                onInterceptLogin()
                return
            }
            decisionHandler(.allow)
        }
    }
}
