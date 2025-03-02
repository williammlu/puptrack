import SwiftUI
import PhotosUI

struct PupLogView: View {
    @EnvironmentObject var viewModel: PupViewModel
    @State private var showPhotoUpdater = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Display photo for the current time slot
                let slot = viewModel.currentPhotoSlot()
                if let image = viewModel.photoDict[slot] ?? nil {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text("No \(slot.displayName) Photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // Show pills for selected tasks
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.tasks.filter {$0.isSelected}) { t in
                            Button {
                                viewModel.logTask(t.name)
                            } label: {
                                VStack {
                                    Circle()
                                        .fill(t.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(Text(t.name.prefix(1)))
                                    Text(t.name)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Show logs
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
                }
            }
            .navigationTitle("\(viewModel.dogName)’s Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
}