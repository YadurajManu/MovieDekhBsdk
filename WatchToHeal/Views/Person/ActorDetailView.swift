import SwiftUI

struct ActorDetailView: View {
    let actorId: Int
    @StateObject private var viewModel = ActorDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var isBioExpanded = false
    @State private var selectedCredit: CombinedCredit?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let person = viewModel.person {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header Profile Image
                            ZStack(alignment: .bottom) {
                                CachedAsyncImage(url: person.profileURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Color.appCardBackground)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                                .clipped()
                                
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .appBackground.opacity(0.8), location: 0.8),
                                        .init(color: .appBackground, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                
                                VStack(spacing: 8) {
                                    Text(person.name)
                                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 48))
                                        .foregroundColor(.appText)
                                        .multilineTextAlignment(.center)
                                        .shadow(color: .black.opacity(0.5), radius: 10)
                                    
                                    if let department = person.knownForDepartment {
                                        Text(department.uppercased())
                                            .font(.system(size: 12, weight: .black))
                                            .kerning(2)
                                            .foregroundColor(.appPrimary)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                            
                            VStack(alignment: .leading, spacing: 32) {
                                // Personal Info Grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                    ForEach(person.personalInfo, id: \.title) { info in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(info.title.uppercased())
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.appPrimary.opacity(0.7))
                                            Text(info.detail)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.appText)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(20)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(16)
                                
                                // Biography
                                if let biography = person.biography, !biography.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("BIOGRAPHY")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        Text(biography)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.appTextSecondary)
                                            .lineLimit(isBioExpanded ? nil : 5)
                                            .lineSpacing(4)
                                        
                                        Button(action: { withAnimation { isBioExpanded.toggle() } }) {
                                            Text(isBioExpanded ? "Read Less" : "Read More")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                }
                                
                                // Top Credits
                                if !viewModel.topCredits.isEmpty {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text("KNOWN FOR")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.appPrimary)
                                            .kerning(1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.topCredits) { credit in
                                                    Button(action: { selectedCredit = credit }) {
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            CachedAsyncImage(url: credit.posterURL) { image in
                                                                image.resizable().scaledToFill()
                                                            } placeholder: {
                                                                RoundedRectangle(cornerRadius: 12).fill(Color.appCardBackground)
                                                            }
                                                            .frame(width: 120, height: 180)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                            
                                                            Text(credit.displayTitle)
                                                                .font(.system(size: 12, weight: .bold))
                                                                .foregroundColor(.appText)
                                                                .lineLimit(1)
                                                            
                                                            if let role = credit.character ?? credit.job {
                                                                Text(role)
                                                                    .font(.system(size: 10))
                                                                    .foregroundColor(.appTextSecondary)
                                                                    .lineLimit(1)
                                                            }
                                                        }
                                                        .frame(width: 120)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                        }
                    }
                    .ignoresSafeArea()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Text("Oops!")
                            .font(.title)
                            .foregroundColor(.appText)
                        Text(error)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.loadActorDetail(id: actorId) }
                        }
                        .padding()
                        .background(Color.appPrimary)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Back Button
                GlassBackButton(action: { dismiss() })
                    .padding(.top, 16)
                    .padding(.leading, 16)
            }
        }
        .task {
            await viewModel.loadActorDetail(id: actorId)
        }
        .fullScreenCover(item: $selectedCredit) { credit in
            if credit.mediaType == .movie {
                MovieDetailView(movieId: credit.id)
            } else {
                SeriesDetailView(seriesId: credit.id)
            }
        }
        .navigationBarHidden(true)
    }
}
