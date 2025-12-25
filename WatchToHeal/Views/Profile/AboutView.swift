//
//  AboutView.swift
//  WatchToHeal
//
//  Created by Auto-Agent on 25/12/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon & Version
                    VStack(spacing: 16) {
                        Image("AppIconPlaceholder") // Assuming asset exists or using system placeholder
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: .appPrimary.opacity(0.3), radius: 20)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        VStack(spacing: 4) {
                            Text("WatchToHeal")
                                .font(.custom("AlumniSansSC-Black", size: 32))
                                .foregroundColor(.appText)
                            
                            Text("Version 1.0.0 (1)")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Mission Statement
                    VStack(alignment: .leading, spacing: 16) {
                        Text("OUR MISSION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .tracking(1.5)
                        
                        Text("Cinema as Therapy")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text("WatchToHeal believes in the transformative power of storytelling. We curate movies not just for entertainment, but for their ability to heal, inspire, and connect us. Whether you're looking for catharsis, joy, or a fresh perspective, we help you find the right film for your soul.")
                            .font(.system(size: 16))
                            .foregroundColor(.appText.opacity(0.8))
                            .lineSpacing(6)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    
                    // Data Source (TMDB)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DATA & ATTRIBUTION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .tracking(1.5)
                        
                        HStack(alignment: .top, spacing: 16) {
                            Image("tmdb_logo") // You might need to add this asset or use text if image unavailable
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80)
                                .colorInvert() // Adjust based on logo color
                            
                            Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                    
                    // Credits
                    VStack(spacing: 16) {
                        Text("Designed & Developed with ❤️")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://watchtoheal.app/privacy")!)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appPrimary)
                        
                        Link("Terms of Service", destination: URL(string: "https://watchtoheal.app/terms")!)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("About")
                    .font(.custom("AlumniSansSC-Bold", size: 20))
                    .foregroundColor(.appText)
            }
        }
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
