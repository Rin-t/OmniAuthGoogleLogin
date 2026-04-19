import Foundation

enum OAuthConfig {
    static let baseURL          = URL(string: "http://localhost:3001")!
    static let clientID         = ""
    static let clientSecret     = ""
    static let redirectURI      = "googleloginsample://callback"
    static let callbackScheme   = "googleloginsample"
    static let scope            = "read"

    static var authorizeURL: URL { baseURL.appendingPathComponent("/oauth/authorize") }
    static var tokenURL:     URL { baseURL.appendingPathComponent("/oauth/token") }
    static var meURL:        URL { baseURL.appendingPathComponent("/api/v1/me") }
}
