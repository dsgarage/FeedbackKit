import SwiftUI

/// フローティングフィードバックボタン
/// アプリの View に `.overlay { FeedbackButton() }` で追加可能
public struct FeedbackButton: View {
    /// ドラッグ中のオフセット
    @State private var offset: CGSize = .zero
    /// ドラッグ開始時のオフセット
    @State private var lastOffset: CGSize = .zero
    /// フィードバックシートの表示状態
    @State private var showingSheet = false

    public init() {}

    public var body: some View {
        // ベータモードでない場合は非表示
        if FeedbackKit.isBeta {
            GeometryReader { geometry in
                Button {
                    showingSheet = true
                } label: {
                    Image(systemName: "bubble.left.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.blue.opacity(0.75))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .offset(x: offset.width, y: offset.height)
                .position(
                    x: 50,
                    y: geometry.size.height - 80
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            }
            .sheet(isPresented: $showingSheet) {
                FeedbackSheet()
            }
        }
    }
}
