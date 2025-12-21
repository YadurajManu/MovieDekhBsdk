import SwiftUI

struct IntegratedFilterBar: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appViewModel: AppViewModel

    
    var body: some View {
        VStack(spacing: 0) {
            // Horizontal Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchViewModel.FilterPanel.allCases) { panel in
                        FilterPill(
                            title: panel.rawValue,
                            isActive: viewModel.activeFilterPanel == panel,
                            hasValue: hasFilterValue(for: panel)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if viewModel.activeFilterPanel == panel {
                                    viewModel.activeFilterPanel = nil
                                } else {
                                    viewModel.activeFilterPanel = panel
                                }
                            }
                        }
                    }
                    
                    // Reset Button
                    if isAnyFilterActive() {
                        Button(action: {
                            withAnimation {
                                viewModel.resetFilters()
                                viewModel.activeFilterPanel = nil
                                viewModel.applyFilters(region: appViewModel.userProfile?.preferredRegion ?? "US")
                            }
                        }) {
                            Text("Reset")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            // Expanded Filter Panels
            if let panel = viewModel.activeFilterPanel {
                VStack(spacing: 0) {
                    Divider().background(Color.appTextSecondary.opacity(0.2))
                    
                    switch panel {
                    case .sort:
                        SortPanel(viewModel: viewModel)
                    case .genre:
                        GenrePanel(viewModel: viewModel)
                    case .year:
                        YearPanel(viewModel: viewModel)
                    case .rating:
                        RatingPanel(viewModel: viewModel)
                    }
                    
                    Divider().background(Color.appTextSecondary.opacity(0.2))
                }
                .background(Color.appCardBackground)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.appBackground)
    }
    
    private func isAnyFilterActive() -> Bool {
        !viewModel.filterState.selectedGenres.isEmpty ||
        viewModel.filterState.yearRange.lowerBound > 1970 ||
        viewModel.filterState.yearRange.upperBound < 2025 ||
        viewModel.filterState.minVoteAverage > 0
    }
    
    private func hasFilterValue(for panel: SearchViewModel.FilterPanel) -> Bool {
        switch panel {
        case .sort:
            return viewModel.filterState.sortOption != .popularityDesc
        case .genre:
            return !viewModel.filterState.selectedGenres.isEmpty
        case .year:
            return viewModel.filterState.yearRange.lowerBound > 1970 || viewModel.filterState.yearRange.upperBound < 2025
        case .rating:
            return viewModel.filterState.minVoteAverage > 0
        }
    }
}

// MARK: - Subcomponents

struct FilterPill: View {
    let title: String
    let isActive: Bool
    let hasValue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .rotationEffect(.degrees(isActive ? 180 : 0))
            }
            .foregroundColor(isActive || hasValue ? .appBackground : .appText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive || hasValue ? Color.appPrimary : Color.appCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.appPrimary : Color.appTextSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct SortPanel: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(SortOption.allCases) { option in
                Button(action: {
                    viewModel.filterState.sortOption = option
                    viewModel.applyFilters(region: appViewModel.userProfile?.preferredRegion ?? "US")
                    withAnimation { viewModel.activeFilterPanel = nil }
                }) {
                    HStack {
                        Text(option.displayName)
                            .foregroundColor(viewModel.filterState.sortOption == option ? .appPrimary : .appText)
                        Spacer()
                        if viewModel.filterState.sortOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                if option != SortOption.allCases.last {
                    Divider().padding(.leading, 20).background(Color.appTextSecondary.opacity(0.1))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct GenrePanel: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(viewModel.availableGenres, id: \.self) { genre in
                    Button(action: {
                        viewModel.toggleGenre(genre)
                        // Don't auto-close panel for multi-select
                    }) {
                        Text(genre.name)
                            .font(.system(size: 13))
                            .foregroundColor(viewModel.filterState.selectedGenres.contains(genre) ? .appBackground : .appText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(viewModel.filterState.selectedGenres.contains(genre) ? Color.appPrimary : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
        }
        .frame(maxHeight: 250)
        
        // Apply Button
        Button(action: {
            viewModel.applyFilters(region: appViewModel.userProfile?.preferredRegion ?? "US")
            withAnimation { viewModel.activeFilterPanel = nil }
        }) {
            Text("Apply Filters")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appPrimary)
                .padding(20)
        }
    }
}

struct YearPanel: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Year Range")
                    .foregroundColor(.appText)
                Spacer()
                Text("\(String(format: "%d", Int(viewModel.filterState.yearRange.lowerBound))) - \(String(format: "%d", Int(viewModel.filterState.yearRange.upperBound)))")
                    .foregroundColor(.appPrimary)
                    .fontWeight(.bold)
            }
            
            // Reusing basic slider approach for now, splitting bounds
            VStack {
                HStack {
                    Text("From")
                    Slider(value: $viewModel.filterState.yearRange.lowerBound, in: 1970...2025, step: 1) {
                        Text("Start Year")
                    } minimumValueLabel: {
                        Text(String(format: "%d", Int(viewModel.filterState.yearRange.lowerBound)))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    } maximumValueLabel: {
                        Text("")
                    }
                    .tint(.appPrimary)
                }
                HStack {
                    Text("To")
                    Slider(value: $viewModel.filterState.yearRange.upperBound, in: 1970...2025, step: 1) {
                        Text("End Year")
                    } minimumValueLabel: {
                         Text("")
                    } maximumValueLabel: {
                        Text(String(format: "%d", Int(viewModel.filterState.yearRange.upperBound)))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .tint(.appPrimary)
                }
            }
            .onChange(of: viewModel.filterState.yearRange) { _ in
                 // Ensure bounds validity
                 if viewModel.filterState.yearRange.lowerBound > viewModel.filterState.yearRange.upperBound {
                     viewModel.filterState.yearRange = viewModel.filterState.yearRange.upperBound...viewModel.filterState.yearRange.upperBound
                 }
            }
            
            Button(action: {
                viewModel.applyFilters(region: appViewModel.userProfile?.preferredRegion ?? "US")
                withAnimation { viewModel.activeFilterPanel = nil }
            }) {
                Text("Apply")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary)
                    .cornerRadius(8)
            }
        }
        .padding(20)
    }
}

extension Binding where Value == ClosedRange<Double> {
    var lowerBound: Binding<Double> {
        Binding<Double>(get: { self.wrappedValue.lowerBound }, set: { self.wrappedValue = $0...self.wrappedValue.upperBound })
    }
    var upperBound: Binding<Double> {
         Binding<Double>(get: { self.wrappedValue.upperBound }, set: { self.wrappedValue = self.wrappedValue.lowerBound...$0 })
    }
}


struct RatingPanel: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Minimum Rating")
                    .foregroundColor(.appText)
                Spacer()
                Text(String(format: "%.1f", viewModel.filterState.minVoteAverage))
                    .foregroundColor(.appPrimary)
                    .fontWeight(.bold)
                Text("+")
                    .foregroundColor(.appTextSecondary)
            }
            
            Slider(value: $viewModel.filterState.minVoteAverage, in: 0...9, step: 0.5)
                .tint(.appPrimary)
            
            Button(action: {
                viewModel.applyFilters(region: appViewModel.userProfile?.preferredRegion ?? "US")
                withAnimation { viewModel.activeFilterPanel = nil }
            }) {
                Text("Apply")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary)
                    .cornerRadius(8)
            }
        }
        .padding(20)
    }
}
