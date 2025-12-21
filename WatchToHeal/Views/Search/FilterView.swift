import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Filters")
                        .font(.custom("AlumniSansSC-Italic-VariableFont_wght", size: 28))
                        .foregroundColor(.appText)
                    Spacer()
                    Button("Reset") {
                        withAnimation {
                            viewModel.resetFilters()
                        }
                    }
                    .foregroundColor(.appPrimary)
                    .font(.system(size: 16, weight: .medium))
                }
                .padding()
                .background(Color.appCardBackground)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Sort By
                        filterSection(title: "Sort By") {
                            Menu {
                                ForEach(SortOption.allCases) { option in
                                    Button(action: {
                                        viewModel.filterState.sortOption = option
                                    }) {
                                        HStack {
                                            Text(option.displayName)
                                            if viewModel.filterState.sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.filterState.sortOption.displayName)
                                        .foregroundColor(.appText)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.appTextSecondary)
                                }
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(10)
                            }
                        }
                        
                        // Genres
                        filterSection(title: "Genres") {
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.availableGenres, id: \.self) { genre in
                                    Button(action: {
                                        viewModel.toggleGenre(genre)
                                    }) {
                                        Text(genre.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(viewModel.filterState.selectedGenres.contains(genre) ? .white : .appTextSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(viewModel.filterState.selectedGenres.contains(genre) ? Color.appPrimary : Color.appCardBackground)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(viewModel.filterState.selectedGenres.contains(genre) ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Release Year
                        filterSection(title: "Release Year: \(Int(viewModel.filterState.yearRange.lowerBound)) - \(Int(viewModel.filterState.yearRange.upperBound))") {
                            RangeSlider(
                                range: $viewModel.filterState.yearRange,
                                bounds: 1970...2025,
                                step: 1
                            )
                            .tint(Color.appPrimary)
                        }
                        
                        // Minimum Rating
                        filterSection(title: "Min Rating: \(String(format: "%.1f", viewModel.filterState.minVoteAverage))") {
                            Slider(value: $viewModel.filterState.minVoteAverage, in: 0...10, step: 0.5)
                                .tint(Color.appPrimary)
                        }
                        
                        // Monetization matches
                        filterSection(title: "Ways to Watch") {
                            HStack(spacing: 12) {
                                ForEach(MonetizationType.allCases) { type in
                                    Button(action: {
                                        viewModel.toggleMonetization(type)
                                    }) {
                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(viewModel.filterState.monetizationTypes.contains(type) ? .white : .appText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(viewModel.filterState.monetizationTypes.contains(type) ? Color.appPrimary : Color.appCardBackground)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Show Adult
                        Toggle("Show Adult Content", isOn: $viewModel.filterState.showAdult)
                            .foregroundColor(.appText)
                            .tint(.appPrimary)
                            .padding(.horizontal, 4)
                        
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
                
                // Apply Button
                Button(action: {
                    viewModel.applyFilters()
                    dismiss()
                }) {
                    Text("Show Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }
                .padding(20)
                .background(Color.appBackground.opacity(0.9))
            }
        }
    }
    
    // Helper View Builder
    func filterSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appText)
            content()
        }
    }
}

// Minimal Custom Range Slider Wrapper (using standard Slider for now as native RangeSlider is not available in SwiftUI < 15 or requires custom implementation. SwiftUI 15 doesn't have RangeSlider either, just Slider. We will use two sliders or a custom one. For simplicity, let's use a custom lightweight implementation or just a dual slider approach if needed. Assuming user wants range, but standard Slider only does single value)
// Creating a simple custom RangeSlider here to avoid dependency issues
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack {
            Slider(value: Binding(get: { range.lowerBound }, set: { range = $0...max($0, range.upperBound) }), in: bounds, step: step)
            Slider(value: Binding(get: { range.upperBound }, set: { range = min($0, range.lowerBound)...$0 }), in: bounds, step: step)
        }
    }
}
