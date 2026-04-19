import AuthenticationServices
import Foundation

struct AccessToken: Codable {
    let accessToken:  String
    let tokenType:    String
    let expiresIn:    Int?
    let refreshToken: String?
    let scope:        String?
    let createdAt:    Int?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case createdAt    = "created_at"
    }
}

enum OAuthError: Error {
    case invalidCallback
    case missingCode
    case stateMismatch
    case tokenRequestFailed(String)
    case decodeFailed(String)
}

@MainActor
final class OAuthClient: NSObject {
    private var anchorProvider: PresentationAnchorProvider?
    private var currentSession: ASWebAuthenticationSession?

    func login(presentingAnchor: ASPresentationAnchor) async throws -> AccessToken {
        let codeVerifier  = PKCE.generateCodeVerifier()
        let codeChallenge = PKCE.codeChallenge(for: codeVerifier)
        let state         = UUID().uuidString

        let authURL = buildAuthorizeURL(state: state, codeChallenge: codeChallenge)
        let callback = try await performWebAuth(url: authURL, anchor: presentingAnchor)

        let (code, returnedState) = try parseCallback(url: callback)
        guard returnedState == state else { throw OAuthError.stateMismatch }

        return try await exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
    }

    // MARK: - private

    private func buildAuthorizeURL(state: String, codeChallenge: String) -> URL {
        var comps = URLComponents(url: OAuthConfig.authorizeURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "client_id",             value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri",          value: OAuthConfig.redirectURI),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: OAuthConfig.scope),
            URLQueryItem(name: "state",                 value: state),
            URLQueryItem(name: "code_challenge",        value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt",                value: "login")
        ]
        return comps.url!
    }

    private func performWebAuth(url: URL, anchor: ASPresentationAnchor) async throws -> URL {
        let provider = PresentationAnchorProvider(anchor: anchor)
        self.anchorProvider = provider

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: OAuthConfig.callbackScheme
            ) { callbackURL, error in
                if let error { continuation.resume(throwing: error); return }
                guard let callbackURL else {
                    continuation.resume(throwing: OAuthError.invalidCallback); return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = provider
            session.prefersEphemeralWebBrowserSession = false
            self.currentSession = session
            session.start()
        }
    }

    private func parseCallback(url: URL) throws -> (code: String, state: String?) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else {
            throw OAuthError.invalidCallback
        }
        guard let code = items.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingCode
        }
        let state = items.first(where: { $0.name == "state" })?.value
        return (code, state)
    }

    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws -> AccessToken {
        var req = URLRequest(url: OAuthConfig.tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "grant_type",    value: "authorization_code"),
            URLQueryItem(name: "code",          value: code),
            URLQueryItem(name: "redirect_uri",  value: OAuthConfig.redirectURI),
            URLQueryItem(name: "client_id",     value: OAuthConfig.clientID),
            URLQueryItem(name: "client_secret", value: OAuthConfig.clientSecret),
            URLQueryItem(name: "code_verifier", value: codeVerifier)
        ]
        req.httpBody = comps.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OAuthError.tokenRequestFailed(body)
        }

        do {
            return try JSONDecoder().decode(AccessToken.self, from: data)
        } catch {
            throw OAuthError.decodeFailed("\(error)")
        }
    }
}

private final class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) { self.anchor = anchor }
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
}
