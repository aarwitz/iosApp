// APIClient.swift
// EliteProAIDemo
//
// Production networking layer — typed, async/await, token-refreshing HTTP client.

import Foundation

// MARK: – Configuration

enum APIEnvironment {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development: return URL(string: "http://localhost:8080/api/v1")!
        case .staging:     return URL(string: "https://backend-production-1013.up.railway.app/api/v1")!
        case .production:  return URL(string: "https://api.eliteproai.com/api/v1")!
        }
    }
}

// MARK: – Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int, message: String?)
    case decodingFailed(Error)
    case networkFailure(Error)
    case tokenExpired
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:                       return "Invalid URL."
        case .invalidRequest:                   return "Invalid request."
        case .unauthorized:                     return "Session expired. Please log in again."
        case .forbidden:                        return "You don't have permission to do that."
        case .notFound:                         return "Resource not found."
        case .serverError(let code, let msg):   return msg ?? "Server error (\(code))."
        case .decodingFailed(let err):          return "Data error: \(err.localizedDescription)"
        case .networkFailure(let err):          return "Network error: \(err.localizedDescription)"
        case .tokenExpired:                     return "Your session has expired."
        case .unknown:                          return "Something went wrong."
        }
    }
}

// MARK: – Generic API Response Envelope

/// Standard JSON envelope returned by the backend.
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let errors: [String]?
}

/// For paginated collections.
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
}

// MARK: – HTTP Method

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: – APIClient

/// Singleton HTTP client for all server communication.
/// Uses async/await with automatic token injection and refresh.
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    #if DEBUG
    // Use .staging to test on a physical device against Railway.
    // Switch to .development when running in the Simulator with a local server.
    var environment: APIEnvironment = .staging
    #else
    var environment: APIEnvironment = .production
    #endif

    // MARK: Init

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10   // Fail fast — never freeze the UI for 30s+
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false      // Fail immediately when offline; callers handle the error
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: – Public Request API

    /// Perform an authenticated request that decodes the response body.
    @discardableResult
    func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let urlRequest = try await buildRequest(method, path: path, body: body, queryItems: queryItems, authenticated: authenticated)
        return try await execute(urlRequest)
    }

    /// Perform a request that returns the full `APIResponse` envelope.
    func requestEnvelope<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws -> APIResponse<T> {
        let urlRequest = try await buildRequest(method, path: path, body: body, queryItems: queryItems, authenticated: authenticated)
        return try await execute(urlRequest)
    }

    /// Fire-and-forget: ignores the response body (e.g. DELETE).
    func requestVoid(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws {
        let urlRequest = try await buildRequest(method, path: path, body: body, queryItems: nil, authenticated: authenticated)
        let (_, response) = try await session.data(for: urlRequest)
        try validateHTTPResponse(response)
    }

    /// Upload multipart form data (e.g. profile photo).
    func upload<T: Decodable>(
        path: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String] = [:]
    ) async throws -> T {
        var urlRequest = try await buildRequest(.post, path: path, body: nil, queryItems: nil, authenticated: true)

        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var bodyData = Data()
        for (key, value) in additionalFields {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        bodyData.append(fileData)
        bodyData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody = bodyData

        return try await execute(urlRequest)
    }

    // MARK: – Private Helpers

    private func buildRequest(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]?,
        authenticated: Bool
    ) async throws -> URLRequest {
        var components = URLComponents(url: environment.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        // Inject bearer token
        if authenticated {
            if let token = KeychainManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkFailure(error)
        }

        try validateHTTPResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch http.statusCode {
        case 200...299:
            return // success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: http.statusCode, message: nil)
        }
    }
}

// MARK: – Type-Erased Encodable Wrapper

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self.encodeFunc = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
