import Foundation
import CoreData
import Combine

class TripsViewModel: ObservableObject {
    private let persistence: PersistenceController

    @Published var allTrips: [Trip] = []
    @Published var filterDriver: Driver?

    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        loadTrips()
        observeContext()
    }

    var displayedTrips: [Trip] {
        if let driver = filterDriver {
            return allTrips.filter { $0.driver?.id == driver.id }
        }
        return allTrips
    }

    var totalKmAll: Double {
        allTrips.filter { !$0.isActive }.reduce(0) { $0 + $1.totalKm }
    }

    func totalKm(for driver: Driver) -> Double {
        allTrips
            .filter { $0.driver?.id == driver.id && !$0.isActive }
            .reduce(0) { $0 + $1.totalKm }
    }

    func deleteTrip(_ trip: Trip) {
        persistence.viewContext.delete(trip)
        persistence.save()
        loadTrips()
    }

    // MARK: - Private

    private func loadTrips() {
        let request = Trip.allTripsRequest()
        allTrips = (try? persistence.viewContext.fetch(request)) ?? []
    }

    private func observeContext() {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: persistence.viewContext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadTrips() }
            .store(in: &cancellables)
    }
}
