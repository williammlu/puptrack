import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: PupViewModel
    
    // We'll have 4 pages total now:
    // 1) Welcome
    // 2) Dog name
    // 3) Tasks
    // 4) Photos
    @State private var currentPage: Int = 1
    
    var body: some View {
        ZStack {
            switch currentPage {
            case 1:
                OnboardingWelcomePage(currentPage: $currentPage)
            case 2:
                OnboardingNamePage(currentPage: $currentPage)
            case 3:
                OnboardingTaskPage(currentPage: $currentPage, isOnboardingFlow: true)
            case 4:
                OnboardingPhotoPage(currentPage: $currentPage)
            default:
                EmptyView()
            }
        }
    }
}

//
// MARK: - Page 1: Welcome
//
struct OnboardingWelcomePage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "pawprint.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.orange)
                .frame(width: 80, height: 80)
            
            Text("Welcome to PupTrack")
                .font(.largeTitle).bold()
            
            Text("Your dog's daily care companion.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button("Continue") {
                currentPage = 2
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

//
// MARK: - Page 2: Dog Name
//
struct OnboardingNamePage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("What is your dog’s name?")
                .font(.title).bold()
            
            TextField("Enter dog's name...", text: $viewModel.dogName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Continue") {
                currentPage = 3
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .disabled(viewModel.dogName.trimmingCharacters(in: .whitespaces).isEmpty)
            
            Spacer()
        }
        // Keep button at bottom even with keyboard
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

//
// MARK: - Page 3: Tasks
//
struct OnboardingTaskPage: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    var isOnboardingFlow: Bool
    
    // For adding a new task
    @State private var customTaskName: String = ""
    
    // Predefined color list
    @State private var colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Top bar with back
                if (isOnboardingFlow){
                    HStack {
                        Button {
                            currentPage = 2
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
              
                Text("Select Care Tasks")
                    .font(.title).bold()
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.tasks) { task in
                            PillRowView(task: task)
                                .onTapGesture {
                                    viewModel.toggleTask(task)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Custom task row
                HStack {
                    TextField("Add custom task (max 25)", text: $customTaskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        let trimmed = customTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        
                        let color = colorOptions[(viewModel.tasks.count) % colorOptions.count]
                        viewModel.tasks.append(
                            PupTask(name: trimmed, isSelected: true, colorName: String(describing: color))
                        )
                        customTaskName = ""
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                Button(action: {
                    if (isOnboardingFlow){
                        currentPage = 4
                    }else {
                        dismiss()
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                // Disable if no tasks are selected
                .disabled(viewModel.tasks.allSatisfy { !$0.isSelected })
            }
            .padding(.top, 20)
        }
    }
}

//
// MARK: - Page 4: Photos
//
struct OnboardingPhotoPage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    // Local states for photo pickers
    @State private var morningPickerItem: PhotosPickerItem?
    @State private var afternoonPickerItem: PhotosPickerItem?
    @State private var nightPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Top bar with back
                HStack {
                    Button {
                        currentPage = 3
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                Text("Choose Photos")
                    .font(.title).bold()
                Text("Pick a photo for morning, afternoon, and night.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                ScrollView {
                    photoSection(slot: .morning, pickerItem: $morningPickerItem)
                    photoSection(slot: .afternoon, pickerItem: $afternoonPickerItem)
                    photoSection(slot: .night, pickerItem: $nightPickerItem)
                }
                
                Spacer()
                
                Button {
                    // finalize onboarding
                    viewModel.completeOnboarding()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .disabled(!allPhotosChosen)
            }
            .onChange(of: morningPickerItem) { newItem in
                loadPhoto(item: newItem, slot: .morning)
            }
            .onChange(of: afternoonPickerItem) { newItem in
                loadPhoto(item: newItem, slot: .afternoon)
            }
            .onChange(of: nightPickerItem) { newItem in
                loadPhoto(item: newItem, slot: .night)
            }
            .padding(.top, 20)
        }
    }
    
    private var allPhotosChosen: Bool {
        // returns false if any slot is still nil
        (viewModel.photoDict[.morning] != nil)
        && (viewModel.photoDict[.afternoon] != nil)
        && (viewModel.photoDict[.night] != nil)
    }
    
    private func photoSection(slot: PupPhotoSlot, pickerItem: Binding<PhotosPickerItem?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.displayName)
                .font(.headline)
            
            ZStack {
                
                if let image = viewModel.getPhoto(slot: slot) ?? nil {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        )
                }
                
                // Make the entire rectangle clickable for the PhotosPicker
                PhotosPicker(selection: pickerItem, matching: .images, photoLibrary: .shared()) {
                    Rectangle()
                        .fill(Color.clear)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    private func loadPhoto(item: PhotosPickerItem?, slot: PupPhotoSlot) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                viewModel.setPhoto(slot: slot, image: uiImage)
            }
        }
    }
}

// A pill row with a circular check if selected, used for creating tasks
struct PillRowView: View {
    let task: PupTask
    
    var body: some View {
        HStack {
            ZStack {
                if task.isSelected {
                    // we map colorName -> actual SwiftUI color in PupTask extension
                    Circle()
                        .fill(task.color)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(task.color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.trailing, 4)
            
            Text(task.name)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(task.color.opacity(0.15))
        .cornerRadius(16)
    }
}
