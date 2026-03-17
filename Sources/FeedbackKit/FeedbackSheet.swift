import SwiftUI
import PhotosUI
import UIKit

/// フィードバック送信シート
public struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// カテゴリ選択
    @State private var selectedCategory: FeedbackCategory = .bug
    /// タイトル
    @State private var title: String = ""
    /// 詳細
    @State private var detail: String = ""
    /// スクリーンショット画像
    @State private var screenshot: UIImage?
    /// PhotosPicker で選択したアイテム
    @State private var selectedPhotoItem: PhotosPickerItem?
    /// 送信中フラグ
    @State private var isSubmitting = false
    /// 送信結果
    @State private var submitResult: SubmitResult?
    /// エラーメッセージ
    @State private var errorMessage: String?

    /// 送信結果の種類
    private enum SubmitResult {
        case success(issueURL: String?)
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // カテゴリ選択
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // タイトル・詳細入力
                Section("内容") {
                    TextField("タイトル", text: $title)

                    VStack(alignment: .leading) {
                        Text("詳細")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $detail)
                            .frame(minHeight: 80, maxHeight: 160)
                    }
                }

                // スクリーンショット
                Section("スクリーンショット") {
                    if let screenshot {
                        Image(uiImage: screenshot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button("画像を削除", role: .destructive) {
                            self.screenshot = nil
                            self.selectedPhotoItem = nil
                        }
                    }

                    // 画面キャプチャボタン
                    Button {
                        captureScreen()
                    } label: {
                        Label("画面をキャプチャ", systemImage: "camera.viewfinder")
                    }

                    // フォトライブラリから選択
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Label("ライブラリから選択", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                screenshot = image
                            }
                        }
                    }
                }

                // 環境情報
                Section("環境情報") {
                    let bundle = Bundle.main
                    let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                    let buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

                    LabeledContent("デバイス", value: UIDevice.current.model)
                    LabeledContent("OS", value: "iPadOS \(UIDevice.current.systemVersion)")
                    LabeledContent("アプリ", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("ロケール", value: Locale.current.identifier)
                }

                // 送信結果表示
                if let result = submitResult {
                    Section("送信結果") {
                        switch result {
                        case .success(let issueURL):
                            VStack(alignment: .leading, spacing: 8) {
                                Label("送信完了！", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.headline)

                                if let urlString = issueURL, let url = URL(string: urlString) {
                                    Link("Issue を確認する", destination: url)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // エラー表示
                if let errorMessage {
                    Section("エラー") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.subheadline)

                            Button("リトライ") {
                                self.errorMessage = nil
                                submitFeedback()
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィードバック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("送信") {
                            submitFeedback()
                        }
                        .disabled(title.isEmpty || submitResult != nil)
                    }
                }
            }
        }
    }

    /// 現在の画面をキャプチャ
    private func captureScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        screenshot = image
    }

    /// フィードバックを送信
    private func submitFeedback() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let response = try await FeedbackClient.shared.submit(
                    category: selectedCategory,
                    title: title,
                    body: detail,
                    screenshot: screenshot
                )

                if response.success {
                    submitResult = .success(issueURL: response.issue_url)
                } else {
                    errorMessage = response.error ?? "不明なエラーが発生しました"
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }
}
