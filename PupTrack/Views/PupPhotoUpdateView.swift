import SwiftUI
import PhotosUI

/// Lets user update morning/afternoon/night photos after onboarding
struct PupPhotoUpdateView: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedSlot: PupPhotoSlot = .morning
    @State private var pickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Choose Time Slot") {
                    Picker("Time Slot", selection: $selectedSlot) {
                        ForEach(PupPhotoSlot.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Update Photo") {
                    PhotosPicker("Pick Photo", selection: $pickerItem, matching: .images)
                }
            }
            .navigationTitle("Update Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: pickerItem) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.setPhoto(slot: selectedSlot, image: uiImage)
                    }
                }
            }
        }
    }
}