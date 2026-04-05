import SwiftUI

@main
struct DriveTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(TripManager.shared)
                .environmentObject(LocationService.shared)
        }
    }
}
