import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tripManager: TripManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Painel", systemImage: "gauge.with.needle")
                }
                .tag(0)

            DriversListView()
                .tabItem {
                    Label("Motoristas", systemImage: "person.2.fill")
                }
                .tag(1)

            TripsListView()
                .tabItem {
                    Label("Viagens", systemImage: "map.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(TripManager.shared)
        .environmentObject(LocationService.shared)
}
