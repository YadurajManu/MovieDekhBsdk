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
    
    var body: some View {
        ZStack {
            // Dynamic Movie Poster Background with Ken Burns Effect
            if !viewModel.movies.isEmpty {
                TabView(selection: $currentPosterIndex) {
                    ForEach(Array(viewModel.movies.prefix(10).enumerated()), id: \.element.id) { index, movie in
                        CachedAsyncImage(url: movie.backdropURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .scaleEffect(currentPosterIndex == index ? 1.2 : 1.0)
                                .offset(x: currentPosterIndex == index ? 20 : 0)
                                .animation(.linear(duration: 8).repeatForever(autoreverses: true), value: currentPosterIndex)
                                .clipped()
                        } placeholder: {
                            Color.black
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // Premium Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .black.opacity(0.4),
                        .black.opacity(0.8),
                        .black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Branding
                VStack(spacing: 16) {
                    Text("WatchToHeal")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 60))
                        .foregroundColor(.appPrimary)
                        .shadow(color: .appPrimary.opacity(0.3), radius: 20)
                    
                    Text("Transform your relationship with cinema.\nTrack, Log & Heal.")
                        .font(.system(size: 18, weight: .light))
                        .italic()
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Cinematic Action Buttons
                VStack(spacing: 20) {
                    Button(action: { showLogin = true }) {
                        Text("Explore Again")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.appPrimary)
                                    .shadow(color: .appPrimary.opacity(0.4), radius: 15, x: 0, y: 8)
                            )
                    }
                    
                    Button(action: { showSignup = true }) {
                        Text("Join the Circle")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
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
                withAnimation(.easeInOut(duration: 2.0)) {
                    if !viewModel.movies.isEmpty {
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
