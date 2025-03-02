import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: PupViewModel
    
    // We'll have 4 pages total now:
    // 1) Dog name
    // 2) Welcome
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
                OnboardingTaskPage(currentPage: $currentPage)
            case 4:
                // Photo page
                OnboardingPhotoPage(currentPage: $currentPage)
            default:
                EmptyView()
            }
        }
    }
}

//
// MARK: - Page 1: Collect the Dog's Name
//


struct OnboardingWelcomePage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "pawprint.fill") // replaced "paw.max.fill" with a valid SF Symbol
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
// MARK: - Page 2: Name
//
struct OnboardingNamePage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    // We’ll ensure the continue button is pinned even if the keyboard is open
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Your Dog’s Name")
                .font(.title).bold()
            
            TextField("Enter dog name...", text: $viewModel.dogName)
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
            // Disable if the user hasn't entered a name
            .disabled(viewModel.dogName.trimmingCharacters(in: .whitespaces).isEmpty)
            
            Spacer()
        }
        // Keep the button at bottom even when keyboard appears
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}


//
// MARK: - Page 3: Tasks
//
struct OnboardingTaskPage: View {
    @EnvironmentObject var viewModel: PupViewModel
    @Binding var currentPage: Int
    
    // For adding a new task
    @State private var customTaskName: String = ""
    
    // Predefined color list in the order you specified
    @State private var colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
//    @State private var colorIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // top bar with back button
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
                        
                        // pick the next color from colorOptions
                        let color = colorOptions[(viewModel.tasks.count) % colorOptions.count]
//                        colorIndex += 1
                        
                        viewModel.tasks.append(
                            PupTask(name: trimmed, isSelected: true, color: color)
                        )
                        customTaskName = ""
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // A single wide "Continue" button at the bottom
                Button(action: {
                    currentPage = 4
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
// MARK: - Page 4: Photos for morning/afternoon/night
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
                // top bar with back button
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
                
                // A "Done" button at bottom
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
                // Disable if not all three photos are chosen
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
                // Show chosen image or a placeholder
                if let image = viewModel.photoDict[slot] ?? nil {
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
                
                // Make the entire rectangle clickable (for the PhotosPicker)
                PhotosPicker(
                    selection: pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    // An invisible label that covers the entire area
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

// A pill row with a circular check if selected
struct PillRowView: View {
    let task: PupTask
    
    var body: some View {
        HStack {
            ZStack {
                // If selected, fill circle with pastel color
                // If not, outline with pastel color
                if task.isSelected {
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
        // Slight pastel background to highlight the pill
        .background(task.color.opacity(0.15))
        .cornerRadius(16)
    }
}
