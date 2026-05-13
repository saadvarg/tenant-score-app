//
//  NetworkService.swift
//  TenantScore
//
//  Created by Saad EL Mouataz on 6/5/2026.
//
import Foundation

final class NetworkService {
    static let shared = NetworkService()

    private let baseURL = URL(string: "http://localhost:5050/api")

    private init() {}

    func request(endpoint: String) {
        guard let url = baseURL?.appending(path: endpoint) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            print(data ?? "No data")
        }.resume()
    }
}
