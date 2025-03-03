import SwiftUI
import PhotosUI

struct PupLogView: View {
    @EnvironmentObject var viewModel: PupViewModel
    @State private var showPhotoUpdater = false
    @State private var showTaskEditor = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show the photo in a square ratio
                let slot = viewModel.currentPhotoSlot()
                if let uiImage = viewModel.getPhoto(slot: slot) {
                    GeometryReader { geo in
                        // We'll match the width of the screen, and make the height = width
                        let size = geo.size.width
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .frame(width: size, height: size)
                    }
                    .frame(height: UIScreen.main.bounds.width) // Reserve square space
                } else {
                    // No photo for this time slot
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: UIScreen.main.bounds.width)
                        .overlay(
                            Text("No \(slot.displayName) Photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // Horizontal scroll of selected tasks
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.tasks.filter { $0.isSelected }) { t in
                            Button {
                                viewModel.logTask(t.name)
                            } label: {
                                VStack {
                                    Circle()
                                        .fill(t.color)
                                        .frame(width: 50, height: 50)
                                        // Text is now black
                                        .overlay(Text(t.name.prefix(1))
                                            .foregroundColor(.black)
                                        )
                                    Text(t.name)
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // List of logs (with "No activities yet" if empty) + swipe-to-delete
                if viewModel.logs.isEmpty {
                        VStack{
                            Text("No activities yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                            Spacer()
                        }.background(Color(UIColor.systemGroupedBackground))
                } else {
                    List {
                        ForEach(viewModel.logs) { logItem in
                            VStack(alignment: .leading) {
                                Text(logItem.taskName)
                                    .font(.headline)
                                Text(logItem.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                }
            }
            .navigationTitle("\(viewModel.dogName)’s Log")
            .navigationBarTitleDisplayMode(.inline) // Keep title & camera icon on same horizontal line
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPhotoUpdater.toggle()
                    } label: {
                        Image(systemName: "camera.on.rectangle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showTaskEditor.toggle()
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
            }
            .sheet(isPresented: $showPhotoUpdater) {
                PupPhotoUpdateView()
            }
            .sheet(isPresented: $showTaskEditor) {
                @State var currentPage: Int = 3
                OnboardingTaskPage(currentPage: $currentPage, isOnboardingFlow: false)
            }
        }
    }
    
    /// Called by onDelete for the logs
    private func deleteLogs(at offsets: IndexSet) {
        viewModel.removeLogs(atOffsets: offsets)
    }
}
