//
//  NetworkManager.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/22/25.
//

import Foundation

// MARK: - Network Error Types

enum NetworkError: Error {
    case invalidResponse
    case statusCodeError(Int)
    case noData
    case decodingError(Error)
}

// MARK: - NetworkManager Implementation Using Async/Await

final class NetworkManager {
    
    // Shared singleton instance
    static let shared = NetworkManager()
    
    // URLSession can be injected for testing/mocking purposes
    private let session: URLSession
    
    // Private initializer to enforce singleton usage
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Executes a network request and decodes the response into the expected type using async/await.
    /// - Parameter request: A configured URLRequest.
    /// - Returns: A decoded model of type T.
    /// - Throws: NetworkError or decoding errors based on the response.
    func request<T: Codable>(with request: URLRequest) async throws -> T {
        // Use URLSession's async API to perform the network call.
        let (data, response) = try await session.data(for: request)
        
        // Validate the response as HTTPURLResponse.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check that the status code is in the 200-299 range.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCodeError(httpResponse.statusCode)
        }
        
        // Decode the received data.
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
