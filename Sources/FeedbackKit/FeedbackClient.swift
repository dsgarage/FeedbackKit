import Foundation
import UIKit

/// フィードバック送信クライアント
public actor FeedbackClient {
    /// 共有インスタンス
    public static let shared = FeedbackClient()

    private init() {}

    /// フィードバックを送信
    /// - Parameters:
    ///   - category: フィードバックのカテゴリ
    ///   - title: タイトル
    ///   - body: 詳細説明
    ///   - screenshot: スクリーンショット画像（任意）
    /// - Returns: サーバーからのレスポンス
    public func submit(
        category: FeedbackCategory,
        title: String,
        body: String,
        screenshot: UIImage?
    ) async throws -> FeedbackResponse {
        let apiURL = FeedbackKit.apiURL
        let apiKey = FeedbackKit.apiKey
        let repo = FeedbackKit.repo

        guard !apiURL.isEmpty else {
            throw FeedbackError.notConfigured
        }

        guard let url = URL(string: "\(apiURL)/api/issues") else {
            throw FeedbackError.invalidURL
        }

        // スクリーンショットを base64 に変換
        let screenshotBase64: String? = screenshot.flatMap { image in
            image.jpegData(compressionQuality: 0.7)?.base64EncodedString()
        }

        // メタデータを自動取得
        let metadata = await FeedbackMetadata.current(
            appName: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown"
        )

        let request = FeedbackRequest(
            repo: repo,
            category: category.rawValue,
            title: title,
            body: body,
            screenshot: screenshotBase64,
            metadata: metadata
        )

        // URLRequest を構築
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        // 送信
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw FeedbackError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FeedbackResponse.self, from: data)
    }
}

/// フィードバック送信エラー
public enum FeedbackError: LocalizedError, Sendable {
    case notConfigured
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "FeedbackKit が設定されていません。FeedbackKit.configure() を呼び出してください。"
        case .invalidURL:
            return "無効な API URL です。"
        case .invalidResponse:
            return "サーバーからの応答が不正です。"
        case .serverError(let statusCode, let message):
            return "サーバーエラー (\(statusCode)): \(message)"
        }
    }
}
