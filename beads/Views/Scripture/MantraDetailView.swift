// MARK: - 檔案說明
/// MantraDetailView.swift
/// 咒語詳情畫面 - 顯示單一咒語的完整資訊，包含原文、拼音、說明及建議持誦次數
/// 模組：Views/Scripture

//
//  MantraDetailView.swift
//  beads
//
//  Created by firstfu on 2026/2/25.
//

import SwiftUI

// MARK: - 字體大小列舉

/// 經文字體大小選項
enum ScriptureFontSize: Int, CaseIterable {
    case small = 16
    case medium = 20
    case large = 24

    var label: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }

    var iconName: String {
        switch self {
        case .small: return "textformat.size.smaller"
        case .medium: return "textformat.size"
        case .large: return "textformat.size.larger"
        }
    }
}

// MARK: - MantraDetailView

/// 咒語詳情視圖
/// 以捲動頁面的形式展示咒語的完整內容，包含名稱、原文、拼音、說明和建議持誦次數
struct MantraDetailView: View {
    /// 要顯示的咒語資料模型
    let mantra: Mantra

    /// 經文字體大小偏好，使用 @AppStorage 持久化
    @AppStorage("scriptureFontSize") private var fontSizeRawValue: Int = ScriptureFontSize.medium.rawValue

    /// 拼音區塊是否展開
    @State private var isPinyinExpanded = false

    /// 是否顯示複製成功提示
    @State private var showCopiedToast = false

    /// 當前選擇的字體大小
    private var fontSize: ScriptureFontSize {
        ScriptureFontSize(rawValue: fontSizeRawValue) ?? .medium
    }

    /// 視圖主體
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                originalTextSection
                pinyinSection
                descriptionSection
                suggestedCountSection
            }
            .padding()
        }
        .overlay(alignment: .top) {
            copiedToastOverlay
        }
        .navigationTitle(mantra.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                copyButton
                fontSizeMenu
            }
        }
    }

    // MARK: - 原文區塊

    /// 經文原文卡片區塊，使用較大字體和良好的行距以提升長文可讀性
    private var originalTextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("原文", systemImage: "book")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(mantra.originalText)
                .font(.system(size: CGFloat(fontSizeRawValue)))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 拼音區塊

    /// 拼音區塊，使用 DisclosureGroup 可展開/收合以節省空間
    @ViewBuilder
    private var pinyinSection: some View {
        if !mantra.pinyinText.isEmpty {
            DisclosureGroup(isExpanded: $isPinyinExpanded) {
                Text(mantra.pinyinText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } label: {
                Label("拼音", systemImage: "character.phonetic")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 說明區塊

    /// 咒語功德說明區塊
    @ViewBuilder
    private var descriptionSection: some View {
        if !mantra.descriptionText.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("說明", systemImage: "text.quote")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(mantra.descriptionText)
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 建議持誦次數區塊

    /// 建議持誦次數與分類資訊卡片
    private var suggestedCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title3)
                Text("建議每次持誦 \(mantra.suggestedCount) 遍")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.orange)

            HStack(spacing: 8) {
                Label(mantra.category, systemImage: "tag")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 工具列按鈕

    /// 複製經文按鈕
    private var copyButton: some View {
        Button {
            copyOriginalText()
        } label: {
            Image(systemName: "doc.on.doc")
        }
    }

    /// 字體大小選擇選單
    private var fontSizeMenu: some View {
        Menu {
            ForEach(ScriptureFontSize.allCases, id: \.rawValue) { size in
                Button {
                    fontSizeRawValue = size.rawValue
                } label: {
                    Label(size.label, systemImage: size.iconName)
                    if fontSizeRawValue == size.rawValue {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: "textformat.size")
        }
    }

    // MARK: - 複製成功提示

    /// 複製成功時顯示的浮動提示
    @ViewBuilder
    private var copiedToastOverlay: some View {
        if showCopiedToast {
            Text("已複製經文")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
        }
    }

    // MARK: - 操作方法

    /// 複製原文到剪貼簿並顯示提示
    private func copyOriginalText() {
        #if os(iOS)
        UIPasteboard.general.string = mantra.originalText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(mantra.originalText, forType: .string)
        #endif

        withAnimation(.easeInOut(duration: 0.3)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopiedToast = false
            }
        }
    }
}
