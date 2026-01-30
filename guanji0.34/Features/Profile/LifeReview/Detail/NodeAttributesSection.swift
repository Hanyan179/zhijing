import SwiftUI

// MARK: - NodeAttributesSection

/// 节点属性区块 - 显示 subsystem 类型节点的属性键值对
///
/// 设计特点：
/// - 清晰展示属性名称和值
/// - 属性名格式化显示（snake_case -> Title Case）
/// - 支持多种属性值类型
/// - 支持 VoiceOver 无障碍访问
///
/// 使用示例：
/// ```swift
/// NodeAttributesSection(attributes: node.attributes, color: .blue)
/// ```
///
/// - Requirements: REQ-7.1
public struct NodeAttributesSection: View {
    
    // MARK: - Properties
    
    /// 属性字典
    let attributes: [String: AttributeValue]
    
    /// 主题色
    let color: Color
    
    // MARK: - Initialization
    
    public init(attributes: [String: AttributeValue], color: Color) {
        self.attributes = attributes
        self.color = color
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(color)
                
                Text("属性详情")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            // 属性列表
            VStack(spacing: 0) {
                ForEach(Array(attributes.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    attributeRow(key: key, value: value)
                    
                    if key != attributes.keys.sorted().last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Subviews
    
    /// 单个属性行
    private func attributeRow(key: String, value: AttributeValue) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 属性名（直接显示，支持中英文）
            Text(key)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .leading)
            
            // 属性值
            Text(value.displayValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key)：\(value.displayValue)")
    }
}

// MARK: - Preview

#if DEBUG
struct NodeAttributesSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                NodeAttributesSection(
                    attributes: [
                        "结婚纪念日": .string("2020-05-20"),
                        "女儿生日": .string("2022-08-15"),
                        "血型": .string("A"),
                        "身高": .int(175),
                        "体重": .double(68.5)
                    ],
                    color: .indigo
                )
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif
