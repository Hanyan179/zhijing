# Guanji (iOS App)

Guanji is a native iOS journaling and life-tracking application designed with a "Fluid Native Experience" philosophy. It leverages SwiftUI to provide a seamless, animated, and responsive interface for recording daily moments, tracking mind states, and reflecting on personal history.

## Technical Overview

*   **Platform**: iOS 16.1+
*   **Language**: Swift 5.0
*   **Framework**: SwiftUI
*   **Architecture**: MVVM (Model-View-ViewModel) + Modular Directory Structure
*   **Design System**: Atomic Design (Atoms, Molecules, Organisms)

## Project Structure

The project follows a strict layered architecture:

### 1. Features (`/Features`)
Contains the core business logic modules, each with its own `Screen` (View) and `ViewModel`.
*   **Timeline**: The main journal feed (`TimelineScreen`).
*   **Input**: Data entry interfaces (`CapsuleCreatorSheet`, `InputViewModel`).
*   **Profile**: User settings and personal center (`ProfileScreen`).
*   **MindState**: Mood and emotion tracking (`MindStateFlowScreen`).
*   **History**: Historical data review (`HistorySidebar`, `GlobalHistoryView`).
*   **Insight**: Data analysis and visualization (`InsightSheet`).

### 2. UI Components (`/UI`)
Reusable UI components organized by complexity (Atomic Design).
*   **Atoms**: Basic controls (e.g., `CapsuleTextEditor`, `RoundIconButton`).
*   **Molecules**: Compound components (e.g., `JournalRow`, `CapsuleCard`).
*   **Organisms**: Complex business blocks (e.g., `InputDock`, `MorningBriefing`, `ResonanceHub`).

### 3. Core (`/Core`)
The foundation of the application.
*   **DesignSystem**: Source of Truth for `Colors`, `Typography`, and `Icons`.
*   **Models**: Data models (e.g., `JournalEntry`, `MindStateRecord`).
*   **Utilities**: Helper functions (`DateUtilities`).

### 4. Data Layer (`/DataLayer`)
Handles data persistence and system interactions.
*   **Repositories**: Data access objects (`TimelineRepository`, `MindStateRepository`).
*   **SystemServices**: Hardware and system integrations (`LocationService`, `HealthKitService`, `WeatherService`).

### 5. Resources (`/Resources`)
*   **Localization**: `Localizable.strings` for multi-language support (zh-Hans, en, etc.).
*   **Assets**: Images and colors.

## Key Features

### Timeline
*   **Dynamic Feed**: Displays journal entries, weather info, and "Resonance" (past memories).
*   **Scene & Journey**: Distinguishes between stationary moments (`SceneBlock`) and movement (`JourneyBlock`).
*   **Native Animations**: Smooth transitions and interactions.

### Input System
*   **Input Dock**: Persistent bottom bar for quick entry.
*   **Rich Media**: Support for text, photos, and voice recordings.
*   **Time Capsules**: "Write to future" functionality.

### Personal Center (Profile)
*   **Management**: Notifications, Data Maintenance.
*   **Insights**: Membership plans, Component Gallery.
*   **System**: Language settings, About page.

### Mind State
*   **Flow**: Dedicated interface for logging emotions and contributing factors.
*   **Analysis**: Heatmaps and trend tracking.

## Getting Started

1.  Open `guanji0.34.xcodeproj` in Xcode 14+.
2.  Ensure the deployment target is set to iOS 16.1 or higher.
3.  Build and run on a simulator or device.

## Localization
The app supports multiple languages including Simplified Chinese (`zh-Hans`), English (`en`), and others. New strings must be added to `Resources/Localizable.strings`.

## Design Philosophy
*   **Native First**: Prioritize standard SwiftUI components (`List`, `NavigationStack`).
*   **No Hardcoded Strings**: Always use `Localization.tr()`.
*   **No Magic Numbers**: Use Design System constants.
