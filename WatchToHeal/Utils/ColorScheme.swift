//
//  ColorScheme.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

extension Color {
    // App Color Scheme - Black and Light Slate Yellow
    static let appBackground = Color.black
    static let appPrimary = Color(red: 0.96, green: 0.87, blue: 0.70) // Light slate yellow
    static let appSecondary = Color(red: 0.85, green: 0.75, blue: 0.55) // Darker yellow
    static let appAccent = Color(red: 1.0, green: 0.92, blue: 0.80) // Very light yellow
    static let appText = Color.white
    static let appTextSecondary = Color.white.opacity(0.6)
    static let appCardBackground = Color(white: 0.1) // Dark gray for cards
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
