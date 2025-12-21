//
//  ContentView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        Group {
            if appViewModel.isCheckingAuth {
                SplashView()
            } else if !appViewModel.isAuthenticated {
                WelcomeView()
            } else if !appViewModel.hasCompletedOnboarding {
                OnboardingContainerView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appViewModel.isCheckingAuth)
        .animation(.easeInOut, value: appViewModel.isAuthenticated)
        .animation(.easeInOut, value: appViewModel.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}
