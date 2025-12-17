import SwiftUI

/// A card containing status icon, label, and slider for Daily Tracker Step 1
/// Uses continuous 0-100 scale for smooth sliding experience
public struct StatusSliderCard<Level: StatusLevel>: View {
    let title: String
    @Binding var value: Int  // 0-100 continuous value
    let levelType: Level.Type
    
    public init(
        title: String,
        value: Binding<Int>,
        levelType: Level.Type
    ) {
        self.title = title
        self._value = value
        self.levelType = levelType
    }
    
    private var currentLevel: Level {
        Level.from(value)
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Icon
            if #available(iOS 17.0, *) {
                Image(systemName: currentLevel.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(currentLevel.statusColor)
                    .symbolEffect(.bounce, value: value / 15) // Trigger on level change
            } else {
                Image(systemName: currentLevel.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(currentLevel.statusColor)
            }
            
            // Label
            Text(Localization.tr(currentLevel.titleKey))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(currentLevel.statusColor)
            
            // Continuous Slider (0-100)
            ThickSlider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let newInt = Int(round(newValue))
                        if newInt != value {
                            value = max(0, min(100, newInt))
                        }
                    }
                ),
                range: 0...100,
                step: 1,
                leftText: Localization.tr(Level.minLevel.titleKey),
                rightText: Localization.tr(Level.maxLevel.titleKey),
                accent: currentLevel.statusColor
            )
            .frame(height: 44)
        }
        .padding(.vertical, 16)
    }
}

/// Protocol for status levels (Body Energy and Mood Weather)
public protocol StatusLevel {
    var iconName: String { get }
    var titleKey: String { get }
    var statusColor: Color { get }
    
    static func from(_ value: Int) -> Self
    static var minLevel: Self { get }
    static var maxLevel: Self { get }
}

// MARK: - BodyEnergyLevel Conformance

extension BodyEnergyLevel: StatusLevel {
    /// Returns Color for StatusLevel protocol (alias for color property)
    public var statusColor: Color { color }
    
    // Note: from(_:) is defined in DailyTrackerModels.swift
    
    public static var minLevel: BodyEnergyLevel { .collapsed }
    public static var maxLevel: BodyEnergyLevel { .unstoppable }
}

// MARK: - MindValence Conformance

extension MindValence: StatusLevel {
    /// Returns Color for StatusLevel protocol (converts from String color name)
    public var statusColor: Color {
        switch self {
        case .veryUnpleasant, .unpleasant:
            return Color(red: 0.90, green: 0.50, blue: 0.55)
        case .slightlyUnpleasant:
            return Color(red: 0.94, green: 0.60, blue: 0.64)
        case .neutral:
            return Colors.systemGray
        case .slightlyPleasant:
            return Color(red: 0.38, green: 0.74, blue: 0.52)
        case .pleasant, .veryPleasant:
            return Color(red: 0.32, green: 0.68, blue: 0.50)
        }
    }
    
    /// Map 0-100 continuous value to 7 levels
    public static func from(_ value: Int) -> MindValence {
        // 0-100 → 7 levels (each ~14.3 points)
        switch value {
        case 0..<15: return .veryUnpleasant
        case 15..<29: return .unpleasant
        case 29..<43: return .slightlyUnpleasant
        case 43..<57: return .neutral
        case 57..<71: return .slightlyPleasant
        case 71..<86: return .pleasant
        default: return .veryPleasant
        }
    }
    
    public static var minLevel: MindValence { .veryUnpleasant }
    public static var maxLevel: MindValence { .veryPleasant }
}

// MARK: - Convenience Initializers

public struct BodyEnergySliderCard: View {
    @Binding var value: Int
    
    public init(value: Binding<Int>) {
        self._value = value
    }
    
    public var body: some View {
        StatusSliderCard(
            title: Localization.tr("body_energy"),
            value: $value,
            levelType: BodyEnergyLevel.self
        )
    }
}

public struct MoodWeatherSliderCard: View {
    @Binding var value: Int
    
    public init(value: Binding<Int>) {
        self._value = value
    }
    
    public var body: some View {
        StatusSliderCard(
            title: Localization.tr("mood_weather"),
            value: $value,
            levelType: MindValence.self
        )
    }
}
