import SwiftUI
import FirebaseAuth
struct MyCommunityListsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = CommunityListsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showCreateList = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    
                    Spacer()
                    
                    Text("MY COLLECTIONS")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.appPrimary)
                    
                    Spacer()
                    
                    Button(action: { showCreateList = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appText)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.appPrimary.opacity(0.8)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                if viewModel.isLoading && viewModel.userLists.isEmpty {
                    ProgressView().tint(.appPrimary).frame(maxHeight: .infinity)
                } else if viewModel.userLists.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.1))
                        
                        Text("No lists created yet.\nTap + to start curating.")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.userLists) { list in
                                NavigationLink(destination: ListDetailView(list: list)) {
                                    CommunityListCard(list: list)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteList(list)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCreateList) {
            CreateCommunityListView()
        }
        .onAppear {
            if let userId = appViewModel.currentUser?.uid {
                Task {
                    await viewModel.fetchUserLists(userId: userId)
                }
            }
        }
    }
    
    private func deleteList(_ list: CommunityList) {
        Task {
            do {
                try await FirestoreService.shared.deleteCommunityList(listId: list.id)
                if let userId = appViewModel.currentUser?.uid {
                    await viewModel.fetchUserLists(userId: userId)
                }
            } catch {
                print("Failed to delete list: \(error)")
            }
        }
    }
}
