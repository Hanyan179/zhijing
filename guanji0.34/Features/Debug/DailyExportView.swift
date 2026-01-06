import SwiftUI

// MARK: - Daily Export View

/// 每日数据导出视图 - 用于测试和调试 AI 养料
/// 调试功能，直接使用硬编码字符串
public struct DailyExportView: View {
    
    @State private var selectedDate: Date = Date()
    @State private var exportedText: String = ""
    @State private var isLoading: Bool = false
    @State private var exportFormat: ExportFormat = .json
    @State private var showCopiedAlert: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab: ExportTab = .daily
    
    // Context export states
    @State private var contextRequestJSON: String = ""
    @State private var showContextRequestInput: Bool = false
    
    // Import states
    @State private var importJSON: String = ""
    @State private var showImportInput: Bool = false
    @State private var importResult: String?
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case markdown = "Markdown"
        case apiRequest = "API请求体"
    }
    
    enum ExportTab: String, CaseIterable {
        case daily = "每日数据"
        case context = "上下文"
        case importData = "导入"
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("功能", selection: $selectedTab) {
                    ForEach(ExportTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // Content based on selected tab
                switch selectedTab {
                case .daily:
                    dailyExportContent
                case .context:
                    contextExportContent
                case .importData:
                    importContent
                }
            }
            .navigationTitle("AI知识提取工具")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    copyButton
                }
            }
            .alert("已复制到剪贴板", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Daily Export Content
    
    private var dailyExportContent: some View {
        VStack(spacing: 0) {
            // Date Picker & Format Selector
            VStack(spacing: 12) {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
                
                Picker("格式", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Export Button
            Button(action: exportDailyData) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("导出每日数据")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding()
            
            Divider()
            
            resultSection
        }
    }
    
    // MARK: - Context Export Content
    
    private var contextExportContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("导出上下文数据（用户画像 + 关系画像）")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Full context export button
                Button(action: exportFullContext) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "person.2.fill")
                        }
                        Text("导出完整上下文")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Divider()
                
                // Context request based export
                Text("或根据服务器请求导出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: { showContextRequestInput = true }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("输入上下文请求JSON")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            resultSection
        }
        .sheet(isPresented: $showContextRequestInput) {
            contextRequestInputSheet
        }
    }
    
    // MARK: - Import Content
    
    private var importContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("导入AI提取结果到本地数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showImportInput = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("输入提取结果JSON")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if let result = importResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("成功") ? .green : .orange)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // Sample JSON format
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("提取结果JSON格式示例:")
                        .font(.headline)
                    
                    Text(sampleExtractionResponseJSON)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $showImportInput) {
            importInputSheet
        }
    }
    
    // MARK: - Context Request Input Sheet
    
    private var contextRequestInputSheet: some View {
        NavigationStack {
            VStack {
                Text("粘贴服务器返回的上下文请求JSON")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                TextEditor(text: $contextRequestJSON)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("上下文请求")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showContextRequestInput = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导出") {
                        exportContextFromRequest()
                        showContextRequestInput = false
                    }
                    .disabled(contextRequestJSON.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Import Input Sheet
    
    private var importInputSheet: some View {
        NavigationStack {
            VStack {
                Text("粘贴服务器返回的提取结果JSON")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                TextEditor(text: $importJSON)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("导入结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showImportInput = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        performImport()
                        showImportInput = false
                    }
                    .disabled(importJSON.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Result Section
    
    private var resultSection: some View {
        Group {
            if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if exportedText.isEmpty {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("选择操作并点击导出")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(exportedText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Copy Button
    
    private var copyButton: some View {
        Button(action: copyToClipboard) {
            Image(systemName: "doc.on.doc")
        }
        .disabled(exportedText.isEmpty)
    }
    
    // MARK: - Actions
    
    private func exportDailyData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let dayId = formatDayId(selectedDate)
                let package = try await DailyExtractionService.shared.extractDailyPackage(for: dayId)
                
                let result: String
                switch exportFormat {
                case .json:
                    result = package.toJSON()
                case .markdown:
                    result = package.toMarkdown()
                case .apiRequest:
                    result = package.toAPIRequestBody()
                }
                
                await MainActor.run {
                    exportedText = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func exportFullContext() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let json = try KnowledgeExportService.shared.exportFullContext()
                await MainActor.run {
                    exportedText = json
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func exportContextFromRequest() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let request = try KnowledgeExportService.shared.parseContextRequest(from: contextRequestJSON)
                let json = try KnowledgeExportService.shared.exportContext(for: request)
                await MainActor.run {
                    exportedText = json
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func performImport() {
        do {
            let summary = try KnowledgeImportService.shared.importExtractedResults(json: importJSON)
            importResult = summary.description
            importJSON = ""
        } catch {
            importResult = "导入失败: \(error.localizedDescription)"
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = exportedText
        showCopiedAlert = true
    }
    
    private func formatDayId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Sample JSON
    
    private var sampleExtractionResponseJSON: String {
        """
        {
          "success": true,
          "dayId": "2024.12.22",
          "results": [
            {
              "type": "knowledge_node",
              "target": "user",
              "data": {
                "nodeType": "hobby",
                "name": "阅读",
                "description": "喜欢阅读科幻小说",
                "confidence": 0.85,
                "tags": ["休闲", "学习"]
              }
            },
            {
              "type": "relationship_attribute",
              "target": "[REL_abc123:小明]",
              "data": {
                "nodeType": "shared_memory",
                "name": "一起看电影",
                "description": "周末一起看了新上映的电影",
                "confidence": 0.9
              }
            }
          ]
        }
        """
    }
}

// MARK: - Preview

#Preview {
    DailyExportView()
}
