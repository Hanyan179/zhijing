import Foundation
#if canImport(WeatherKit)
import WeatherKit
import CoreLocation
#endif

public final class WeatherService {
    public static let shared = WeatherService()
    private init() {}
    
    // Cache to prevent excessive calls
    private var lastFetchTime: Date?
    private var lastLat: Double?
    private var lastLng: Double?
    private var lastResult: (String, String)?
    private var isFetching: Bool = false
    
    // Returns (SymbolName, TemperatureString)
    public func fetchCurrentWeather(lat: Double, lng: Double, completion: @escaping (String, String) -> Void) {
        // Simple cache check: same location (approx) and < 10 mins ago
        if let lastTime = lastFetchTime,
           let lastLat = lastLat,
           let lastLng = lastLng,
           let result = lastResult,
           abs(lastLat - lat) < 0.001,
           abs(lastLng - lng) < 0.001,
           Date().timeIntervalSince(lastTime) < 600 {
            completion(result.0, result.1)
            return
        }
        
        // Prevent concurrent fetches
        guard !isFetching else { return }
        isFetching = true
        
        #if canImport(WeatherKit) && os(iOS)
        if #available(iOS 16.0, *) {
            Task {
                do {
                    // WeatherService.shared refers to the class itself, but WeatherKit's service is also named WeatherService.
                    // We need to distinguish them. Since we are inside our own WeatherService class, 
                    // we should use the WeatherKit.WeatherService explicit type or rename our singleton/class.
                    // However, standard practice: use WeatherKit.WeatherService.shared
                    let weather = try await WeatherKit.WeatherService.shared.weather(for: CLLocation(latitude: lat, longitude: lng))
                    let symbol = weather.currentWeather.symbolName
                    let temp = weather.currentWeather.temperature.formatted()
                    
                    self.lastFetchTime = Date()
                    self.lastLat = lat
                    self.lastLng = lng
                    self.lastResult = (symbol, temp)
                    self.isFetching = false
                    
                    DispatchQueue.main.async { completion(symbol, temp) }
                } catch {
                    print("WeatherKit Error: \(error)")
                    self.isFetching = false
                    // Don't cache errors, but maybe cooldown?
                    DispatchQueue.main.async { completion("cloud", "--") }
                }
            }
        } else {
            isFetching = false
            completion("cloud.sun", "20°C") // Fallback
        }
        #else
        // Mock fallback for non-iOS or no WeatherKit capability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isFetching = false
            completion("cloud.drizzle", "18°C")
        }
        #endif
    }
}
