import Foundation
import UIKit

/// フィードバックのカテゴリ
public enum FeedbackCategory: String, CaseIterable, Sendable {
    case bug = "バグ報告"
    case crash = "クラッシュ"
    case feature = "機能要望"
    case ux = "UI/UX改善"
    case performance = "パフォーマンス"
    case question = "質問"
    case other = "その他"

    /// SF Symbol アイコン名
    public var icon: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .crash: return "exclamationmark.triangle.fill"
        case .feature: return "lightbulb.fill"
        case .ux: return "paintbrush.fill"
        case .performance: return "gauge.with.dots.needle.33percent"
        case .question: return "questionmark.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// フィードバック送信リクエスト
public struct FeedbackRequest: Codable, Sendable {
    public let repo: String
    public let category: String
    public let title: String
    public let body: String
    public let screenshot: String?
    public let metadata: FeedbackMetadata

    public init(repo: String, category: String, title: String, body: String, screenshot: String?, metadata: FeedbackMetadata) {
        self.repo = repo
        self.category = category
        self.title = title
        self.body = body
        self.screenshot = screenshot
        self.metadata = metadata
    }
}

/// デバイス・アプリのメタデータ
public struct FeedbackMetadata: Codable, Sendable {
    // swiftlint:disable identifier_name
    public let app_name: String
    public let app_version: String
    public let build: String
    public let device: String
    public let os_version: String
    public let locale: String
    // swiftlint:enable identifier_name

    public init(appName: String, appVersion: String, build: String, device: String, osVersion: String, locale: String) {
        self.app_name = appName
        self.app_version = appVersion
        self.build = build
        self.device = device
        self.os_version = osVersion
        self.locale = locale
    }

    /// 現在のデバイス情報を自動取得
    @MainActor
    public static func current(appName: String) -> FeedbackMetadata {
        let bundle = Bundle.main
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let device = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        let locale = Locale.current.identifier

        return FeedbackMetadata(
            appName: appName,
            appVersion: appVersion,
            build: buildNumber,
            device: device,
            osVersion: osVersion,
            locale: locale
        )
    }
}

/// フィードバック送信レスポンス
public struct FeedbackResponse: Codable, Sendable {
    public let success: Bool
    // swiftlint:disable identifier_name
    public let issue_url: String?
    public let issue_number: Int?
    // swiftlint:enable identifier_name
    public let error: String?

    public init(success: Bool, issueURL: String?, issueNumber: Int?, error: String?) {
        self.success = success
        self.issue_url = issueURL
        self.issue_number = issueNumber
        self.error = error
    }
}
