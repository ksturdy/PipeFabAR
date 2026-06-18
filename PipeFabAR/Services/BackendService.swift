import Foundation

final class BackendService {
    static let shared = BackendService()

    #if DEBUG
    private let baseURL = "http://localhost:3000/api"
    #else
    private let baseURL = "https://pipefabar-backend.onrender.com/api"
    #endif

    private let tokenKey = "backend_jwt"
    private let userIdKey = "backend_user_id"

    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    var userId: Int? {
        get {
            let v = UserDefaults.standard.integer(forKey: userIdKey)
            return v == 0 ? nil : v
        }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    var isSignedIn: Bool { token != nil && userId != nil }

    // MARK: - Sign In with Apple

    func signInWithApple(identityToken: String, fullName: String?) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/apple")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["identityToken": identityToken, "fullName": fullName as Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, data: data)

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        token = decoded.token
        userId = decoded.user.id
    }

    // MARK: - Promo Code

    func checkPromoStatus() async -> Date? {
        guard let token else { return nil }
        var request = URLRequest(url: URL(string: "\(baseURL)/promo/status")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let status = try? JSONDecoder().decode(PromoStatusResponse.self, from: data),
              status.hasPromoAccess else { return nil }
        return status.expiresAt
    }

    func redeemPromoCode(_ code: String) async throws -> String {
        guard let token else { throw BackendError.notSignedIn }

        var request = URLRequest(url: URL(string: "\(baseURL)/promo/redeem")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["code": code])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateStatus(response, data: data)

        let result = try JSONDecoder().decode(RedeemResponse.self, from: data)
        return result.message
    }

    // MARK: - Helpers

    private func validateStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error ?? "Request failed"
            throw BackendError.apiError(msg)
        }
    }

    // MARK: - Response types

    private struct AuthResponse: Decodable {
        let token: String
        let user: UserInfo
        struct UserInfo: Decodable { let id: Int; let email: String? }
    }

    private struct PromoStatusResponse: Decodable {
        let hasPromoAccess: Bool
        let expiresAt: Date?
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            hasPromoAccess = try c.decode(Bool.self, forKey: .hasPromoAccess)
            if let s = try? c.decodeIfPresent(String.self, forKey: .expiresAt) {
                expiresAt = ISO8601DateFormatter().date(from: s)
            } else { expiresAt = nil }
        }
        enum CodingKeys: String, CodingKey { case hasPromoAccess, expiresAt }
    }

    private struct RedeemResponse: Decodable { let message: String }
    private struct ErrorResponse: Decodable { let error: String }

    enum BackendError: LocalizedError {
        case notSignedIn
        case apiError(String)
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "Please sign in first"
            case .apiError(let m): return m
            }
        }
    }
}
