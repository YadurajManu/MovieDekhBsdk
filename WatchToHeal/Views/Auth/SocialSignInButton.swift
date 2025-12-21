//
//  SocialSignInButton.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

enum SignInProvider {
    case apple
    case google
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .apple: return "Continue with Apple"
        case .google: return "Continue with Google"
        }
    }
}

struct SocialSignInButton: View {
    let provider: SignInProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.icon)
                    .font(.system(size: 20))
                
                Text(provider.title)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.appText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
