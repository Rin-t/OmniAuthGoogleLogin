import AuthenticationServices
import SwiftUI

struct ContentView: View {
    @State private var status: String = "未ログイン"
    @State private var accessToken: String?
    @State private var meResponse: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WebViewContainer(url: OAuthConfig.baseURL) {
                    Task { await login() }
                }

                Divider()

                statusPanel
                    .padding()
                    .background(.thinMaterial)
            }
            .navigationTitle("GoogleLoginSample")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status).font(.callout).bold()

            if let token = accessToken {
                Text("token: \(token.prefix(24))...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if let me = meResponse {
                ScrollView(.horizontal) {
                    Text(me)
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 80)
            }

            HStack {
                Button("トークンなしで /me") {
                    Task { await fetchMe(withToken: false) }
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)

                Button("トークン付きで /me") {
                    Task { await fetchMe(withToken: true) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || accessToken == nil)

                if isLoading { ProgressView() }
            }
        }
    }

    private func login() async {
        guard let anchor = currentAnchor() else {
            status = "presentation anchor 取得失敗"
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try await OAuthClient().login(presentingAnchor: anchor)
            accessToken = token.accessToken
            status = "ログイン成功"
        } catch {
            status = "失敗: \(error)"
        }
    }

    private func fetchMe(withToken: Bool) async {
        isLoading = true
        defer { isLoading = false }

        var req = URLRequest(url: OAuthConfig.meURL)
        if withToken, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let label = withToken ? "[with token]" : "[no token]"
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            meResponse = "\(label) HTTP \(httpStatus)\n\(body)"
        } catch {
            meResponse = "\(label) 失敗: \(error)"
        }
    }

    private func currentAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

#Preview {
    ContentView()
}
