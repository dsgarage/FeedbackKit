import Foundation

/// FeedbackKit の設定・初期化
public enum FeedbackKit {
    /// API サーバーの URL
    public static var apiURL: String = ""
    /// API キー
    public static var apiKey: String = ""
    /// リポジトリ（owner/repo 形式）
    public static var repo: String = ""
    /// ベータモード
    public static var isBeta: Bool = true

    /// 初期化
    public static func configure(apiURL: String, apiKey: String, repo: String, isBeta: Bool = true) {
        self.apiURL = apiURL
        self.apiKey = apiKey
        self.repo = repo
        self.isBeta = isBeta
    }
}
