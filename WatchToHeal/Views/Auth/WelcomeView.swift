//
//  WelcomeView.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = MoviesViewModel()
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var currentPosterIndex = 0
    @State private var timer: Timer?
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                // Dynamic Movie Poster Background
                GeometryReader { geometry in
                    if !viewModel.movies.isEmpty {
                        ZStack {
                            ForEach(Array(viewModel.movies.prefix(10).enumerated()), id: \.element.id) { index, movie in
                                CachedAsyncImage(url: movie.backdropURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                } placeholder: {
                                    Color.black
                                }
                                .scaleEffect(currentPosterIndex == index ? 1.05 : 1.0) // Subtle Ken Burns
                                .opacity(currentPosterIndex == index ? 1 : 0)
                                .animation(.easeInOut(duration: 1.5), value: currentPosterIndex)
                            }
                        }
                        .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
                .ignoresSafeArea()
                .scaleEffect(scrollOffset > 0 ? 1 + (scrollOffset / outerGeometry.size.height) : 1)
                .offset(y: scrollOffset < 0 ? scrollOffset / 2 : 0) // Parallax Effect
                
                // Content with ScrollView for Parallax
                ScrollView(showsIndicators: false) {
                    ZStack {
                        // Offset Reader
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ViewOffsetKey.self,
                                value: proxy.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // Content
                            VStack(spacing: 24) {
                                
                                VStack(spacing: 8) {
                                    Text("WatchToHeal")
                                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 64))
                                        .foregroundColor(.appPrimary)
                                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                                    
                                    Text("Cinema as Therapy")
                                        .font(.system(size: 16, weight: .medium))
                                        .tracking(2)
                                        .foregroundColor(.white.opacity(0.8))
                                        .textCase(.uppercase)
                                }
                                
                                Spacer().frame(height: 20)
                                
                                // Main Buttons
                                VStack(spacing: 16) {
                                    Button(action: { showSignup = true }) {
                                        Text("Get Started")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(Color.appPrimary)
                                            .cornerRadius(16)
                                    }
                                    
                                    Button(action: { showLogin = true }) {
                                        Text("I have an account")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.bottom, 50)
                            .padding(.top, 100) // Allow some scroll space
                        }
                        .frame(minHeight: outerGeometry.size.height)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    // Improve bounds to prevent glitches
                    scrollOffset = value
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $showLogin) { LoginView() }
        .fullScreenCover(isPresented: $showSignup) { SignupView() }
        .task {
            await viewModel.loadTopMovies()
            startPosterRotation()
        }
        .onDisappear { stopPosterRotation() }
    }
    
    private func startPosterRotation() {
        timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            Task { @MainActor in
                if !viewModel.movies.isEmpty {
                    withAnimation(.linear(duration: 6.0)) { // Smooth continuous transition
                         currentPosterIndex = (currentPosterIndex + 1) % min(10, viewModel.movies.count)
                    }
                }
            }
        }
    }
    
    private func stopPosterRotation() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    WelcomeView()
}
