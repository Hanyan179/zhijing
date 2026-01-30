import SwiftUI

public struct EditCardBoundsKey: PreferenceKey {
    public static var defaultValue: CGRect? = nil
    public static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) { let v = nextValue(); if v != nil { value = v } }
}
