import Foundation
import Combine

// MARK: - Model Capability Registry

/// 模型能力注册表
/// 存储所有可用模型及其能力配置的中心化数据结构
/// Validates: Requirements 1.5, 1.6, 6.2
@MainActor
public final class ModelCapabilityRegistry: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ModelCapabilityRegistry()
    
    // MARK: - Cache Configuration
    
    /// 缓存过期时间（24小时）
    private static let cacheExpiration: TimeInterval = 24 * 60 * 60
    
    /// UserDefaults 缓存键
    private static let capabilitiesCacheKey = "ModelCapabilities"
    private static let lastRefreshCacheKey = "ModelCapabilitiesLastRefresh"
    
    // MARK: - Published State
    
    /// 已注册的模型能力配置
    @Published private(set) var capabilities: [String: ModelCapability] = [:]
    
    /// 是否正在刷新
    @Published private(set) var isRefreshing: Bool = false
    
    // MARK: - Private State
    
    /// 上次刷新时间
    private var lastRefreshTime: Date?
    
    // MARK: - Initialization
    
    private init() {
        // 1. 加载本地默认配置
        loadDefaultCapabilities()
        // 2. 尝试从缓存加载
        loadFromCache()
    }
    
    // MARK: - Public API
    
    /// 获取模型能力配置
    /// - Parameter modelId: 模型唯一标识符
    /// - Returns: 对应的能力配置，如果不存在则返回 nil
    public func getCapability(for modelId: String) -> ModelCapability? {
        capabilities[modelId]
    }
    
    /// 获取所有可用模型
    /// - Returns: 按显示名称排序的模型能力配置数组
    public func getAllModels() -> [ModelCapability] {
        Array(capabilities.values).sorted { $0.displayName < $1.displayName }
    }
    
    /// 检查是否需要刷新缓存
    public var needsRefresh: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) > Self.cacheExpiration
    }
    
    /// 从后端刷新配置（预留接口）
    /// - Note: 当前版本使用本地默认配置，后续版本将实现后端 API 调用
    public func refreshFromBackend() async throws {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        // TODO: 实现后端 API 调用
        // let response = try await ClaudeflareClient.shared.getModels()
        // for model in response.models {
        //     capabilities[model.modelId] = model
        // }
        
        lastRefreshTime = Date()
        saveToCache()
    }
    
    /// 强制刷新缓存
    public func forceRefresh() async throws {
        lastRefreshTime = nil
        try await refreshFromBackend()
    }
    
    // MARK: - Private Methods
    
    /// 加载本地默认配置
    private func loadDefaultCapabilities() {
        let defaults = ModelCapability.allGeminiModels
        for capability in defaults {
            capabilities[capability.modelId] = capability
        }
    }
    
    /// 保存到缓存
    func saveToCache() {
        let capabilitiesArray = Array(capabilities.values)
        if let data = try? JSONEncoder().encode(capabilitiesArray) {
            UserDefaults.standard.set(data, forKey: Self.capabilitiesCacheKey)
            UserDefaults.standard.set(Date(), forKey: Self.lastRefreshCacheKey)
        }
    }
    
    /// 从缓存加载
    func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: Self.capabilitiesCacheKey),
           let cached = try? JSONDecoder().decode([ModelCapability].self, from: data) {
            for capability in cached {
                capabilities[capability.modelId] = capability
            }
            lastRefreshTime = UserDefaults.standard.object(forKey: Self.lastRefreshCacheKey) as? Date
        }
    }
    
    /// 清除缓存（用于测试）
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: Self.capabilitiesCacheKey)
        UserDefaults.standard.removeObject(forKey: Self.lastRefreshCacheKey)
        lastRefreshTime = nil
    }
}
