import SwiftUI
import PhotosUI

struct PupLogView: View {
    @EnvironmentObject var viewModel: PupViewModel
    @State private var showPhotoUpdater = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show the photo in a square ratio, no cropping for landscape
                let slot = viewModel.currentPhotoSlot()
                if let uiImage = viewModel.getPhoto(slot: slot) {
                    GeometryReader { geo in
                        // We'll match the width of the screen, and make the height = width
                        let size = geo.size.width
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
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
                List {
                    if viewModel.logs.isEmpty {
                        Text("No activities yet")
                            .foregroundColor(.secondary)
                    } else {
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
            }
            .sheet(isPresented: $showPhotoUpdater) {
                PupPhotoUpdateView()
            }
        }
    }
    
    /// Called by onDelete for the logs
    private func deleteLogs(at offsets: IndexSet) {
        viewModel.removeLogs(atOffsets: offsets)
    }
}
