// APIClientTests.swift
// EliteProAIDemoTests
//
// Unit tests for the API client networking layer.

import XCTest
@testable import EliteProAIDemo

final class APIClientTests: XCTestCase {

    // MARK: – Environment Configuration

    func testDevelopmentBaseURL() {
        let client = APIClient.shared
        client.environment = .development
        XCTAssertEqual(client.environment.baseURL.absoluteString, "http://localhost:8080/api/v1")
    }

    func testStagingBaseURL() {
        let client = APIClient.shared
        client.environment = .staging
        XCTAssertEqual(client.environment.baseURL.absoluteString, "https://staging-api.eliteproai.com/api/v1")
    }

    func testProductionBaseURL() {
        let client = APIClient.shared
        client.environment = .production
        XCTAssertEqual(client.environment.baseURL.absoluteString, "https://api.eliteproai.com/api/v1")
    }

    // MARK: – APIError Descriptions

    func testErrorDescriptions() {
        XCTAssertNotNil(APIError.unauthorized.errorDescription)
        XCTAssertNotNil(APIError.forbidden.errorDescription)
        XCTAssertNotNil(APIError.notFound.errorDescription)
        XCTAssertNotNil(APIError.tokenExpired.errorDescription)
        XCTAssertNotNil(APIError.invalidURL.errorDescription)
        XCTAssertNotNil(APIError.serverError(statusCode: 500, message: nil).errorDescription)
        XCTAssertNotNil(APIError.serverError(statusCode: 500, message: "Internal").errorDescription)
    }

    // MARK: – Response Envelope Decoding

    func testAPIResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "data": {"name": "Test User"},
            "message": null,
            "errors": null
        }
        """.data(using: .utf8)!

        struct UserData: Decodable {
            let name: String
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(APIResponse<UserData>.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data?.name, "Test User")
        XCTAssertNil(response.message)
    }

    func testPaginatedResponseDecoding() throws {
        let json = """
        {
            "items": [{"id": 1}, {"id": 2}],
            "page": 1,
            "per_page": 20,
            "total": 2,
            "total_pages": 1
        }
        """.data(using: .utf8)!

        struct Item: Decodable {
            let id: Int
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<Item>.self, from: json)

        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.page, 1)
        XCTAssertEqual(response.total, 2)
    }
}
