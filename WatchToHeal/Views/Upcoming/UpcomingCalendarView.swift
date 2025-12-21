import SwiftUI

struct UpcomingCalendarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var selectedMovie: Movie?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Feature 12: Search & Month Filtering
    @State private var searchText = ""
    @State private var selectedMonth: Int? = nil // nil shows all upcoming
    
    private let months = [
        "JAN", "FEB", "MAR", "APR", "MAY", "JUN", 
        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                } else {
                    VStack(spacing: 0) {
                        // Premium Header with Search & Months
                        VStack(spacing: 16) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.appTextSecondary)
                                TextField("Search upcoming movies...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.appText)
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Month Selector
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        selectedMonth = nil
                                    }) {
                                        Text("ALL")
                                            .font(.system(size: 13, weight: .black))
                                            .foregroundColor(selectedMonth == nil ? .black : .appTextSecondary)
                                            .frame(width: 60, height: 36)
                                            .background(selectedMonth == nil ? Color.appPrimary : Color.white.opacity(0.05))
                                            .cornerRadius(18)
                                    }
                                    
                                    ForEach(0..<12, id: \.self) { index in
                                        let monthNum = index + 1
                                        Button(action: {
                                            selectedMonth = monthNum
                                        }) {
                                            Text(months[index])
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(selectedMonth == monthNum ? .black : .appTextSecondary)
                                                .frame(width: 60, height: 36)
                                                .background(selectedMonth == monthNum ? Color.appPrimary : Color.white.opacity(0.05))
                                                .cornerRadius(18)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color.appBackground)
                        
                        if filteredAndGroupedMovies.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.appTextSecondary)
                                Text("No matches found for this month")
                                    .font(.title3)
                                    .foregroundColor(.appTextSecondary)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(filteredAndGroupedMovies.keys.sorted(), id: \.self) { date in
                                        CalendarSectionHeader(title: formatDate(date))
                                        
                                        LazyVStack(spacing: 16) {
                                            ForEach(filteredAndGroupedMovies[date] ?? []) { movie in
                                                TimelineMovieRow(movie: movie) {
                                                    selectedMovie = movie
                                                } onRemindMe: {
                                                    Task {
                                                        let result = await calendarManager.addMovieReminder(movie: movie)
                                                        await MainActor.run {
                                                            alertMessage = result.success ? "Reminder added to your calendar!" : (result.error ?? "Failed to add reminder")
                                                            showingAlert = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 24)
                                    }
                                }
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coming Soon")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !calendarManager.isAuthorized {
                        Button("Allow Calendar") {
                            Task {
                                _ = await calendarManager.requestAccess()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                    }
                }
            }
            .task {
                await loadUpcoming()
            }
            .fullScreenCover(item: $selectedMovie) { movie in
                MovieDetailView(movieId: movie.id)
            }
            .alert("Calendar", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    
    private var filteredAndGroupedMovies: [String: [Movie]] {
        let filtered = movies.filter { movie in
            let matchesSearch = searchText.isEmpty || movie.title.localizedCaseInsensitiveContains(searchText) || movie.overview.localizedCaseInsensitiveContains(searchText)
            
            let matchesMonth: Bool = {
                guard let selectedMonth = selectedMonth else { return true }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: movie.releaseDate) {
                    return Calendar.current.component(.month, from: date) == selectedMonth
                }
                return false
            }()
            
            return matchesSearch && matchesMonth
        }
        
        let sorted = filtered.sorted { $0.releaseDate < $1.releaseDate }
        return Dictionary(grouping: sorted, by: { $0.releaseDate })
    }
    
    private func loadUpcoming() async {
        do {
            movies = try await TMDBService.shared.fetchUpcomingWithinDays(days: 180, region: appViewModel.userProfile?.preferredRegion ?? "US")
            isLoading = false
        } catch {
            print("Failed to load upcoming: \(error)")
            isLoading = false
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) { return "TODAY" }
        if Calendar.current.isDateInTomorrow(date) { return "TOMORROW" }
        
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date).uppercased()
    }
}

struct CalendarSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appPrimary)
                .kerning(1)
            Spacer()
            Rectangle()
                .fill(Color.appPrimary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color.appBackground.opacity(0.95))
    }
}

struct TimelineMovieRow: View {
    let movie: Movie
    let onTap: () -> Void
    let onRemindMe: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack(spacing: 16) {
                    // Poster with Shadow
                    CachedAsyncImage(url: movie.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.1))
                    }
                    .frame(width: 90, height: 130)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                            .lineLimit(2)
                        
                        Text(movie.overview)
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: onRemindMe) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 12))
                                    Text("REMIND ME")
                                        .font(.system(size: 11, weight: .black))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.appPrimary)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.appPrimary.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
