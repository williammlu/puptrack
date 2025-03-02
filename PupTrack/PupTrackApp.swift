import SwiftUI

@main
struct PupTrackApp: App {
    @StateObject private var viewModel = PupViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.light)  // Force Light Mode
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: PupViewModel
    
    var body: some View {
        Group {
            if viewModel.hasOnboarded {
                MainTabView()
            } else {
                OnboardingView() // The multi-page onboarding
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PupLogView()
                .tabItem {
                    Image(systemName: "pawprint.circle.fill")
                    Text("Log")
                }
            PupCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
        }
    }
}
