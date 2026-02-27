// MARK: - 檔案說明
/// DedicationSheetView.swift
/// 迴向功德 Sheet - 修行結束後選擇迴向文模板並輸入迴向對象
/// 模組：Views

import SwiftUI

/// 迴向功德 Sheet 視圖
/// 修行結束後彈出，讓使用者選擇迴向文模板並輸入迴向對象
struct DedicationSheetView: View {
    /// 選中的迴向文模板
    @State private var selectedTemplate: DedicationTemplate = .universal
    /// 迴向對象（自由輸入）
    @State private var dedicationTarget: String = ""
    /// 確認迴向時的回呼，傳回迴向文和迴向對象
    var onConfirm: (String, String?) -> Void
    /// 跳過迴向時的回呼
    var onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    templateSelectionSection
                    fullTextSection
                    targetInputSection
                }
                .padding()
            }
            .navigationTitle("迴向功德")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳過") {
                        onSkip()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認迴向") {
                        let target = dedicationTarget.trimmingCharacters(in: .whitespacesAndNewlines)
                        onConfirm(selectedTemplate.fullText, target.isEmpty ? nil : target)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 子視圖

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "hands.and.sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.yellow.opacity(0.8))
            Text("將修行功德迴向給有緣眾生")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇迴向文")
                .font(.headline)

            ForEach(DedicationTemplate.allCases) { template in
                templateRow(template)
            }
        }
    }

    private func templateRow(_ template: DedicationTemplate) -> some View {
        let isSelected = selectedTemplate == template
        return Button {
            selectedTemplate = template
        } label: {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(template.name)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var fullTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("迴向文全文")
                .font(.headline)

            Text(selectedTemplate.fullText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    private var targetInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("迴向對象（選填）")
                .font(.headline)

            TextField("例如：父母、家人、一切有情眾生...", text: $dedicationTarget)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    DedicationSheetView(
        onConfirm: { text, target in
            print("迴向: \(text), 對象: \(target ?? "無")")
        },
        onSkip: {
            print("跳過迴向")
        }
    )
}
