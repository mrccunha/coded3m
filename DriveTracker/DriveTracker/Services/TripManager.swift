import Foundation
import CoreData
import CoreLocation
import Combine

class TripManager: ObservableObject {
    static let shared = TripManager()

    private let persistence = PersistenceController.shared
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var activeTrip: Trip?
    @Published var activeDriver: Driver?

    private var lastLocation: CLLocation?
    private var accumulatedDistance: Double = 0   // meters

    // Minimum speed (km/h) to record as "moving" – ignore near-zero GPS noise
    private let movingThreshold: Double = 3.0

    init() {
        resumeActiveTrip()
        subscribeToLocation()
    }

    // MARK: - Public API

    func startTrip(driver: Driver) {
        let ctx = persistence.viewContext
        let trip = Trip(context: ctx)
        trip.driver = driver
        trip.isActive = true
        trip.minSpeed = Double.greatestFiniteMagnitude   // will be updated on first valid point

        activeDriver = driver
        activeTrip = trip

        persistence.save()
        locationService.startTracking()
    }

    func stopTrip() {
        guard let trip = activeTrip else { return }
        let ctx = persistence.viewContext

        trip.isActive = false
        trip.endDate = Date()

        // If minSpeed was never set, clear it
        if trip.minSpeed == Double.greatestFiniteMagnitude {
            trip.minSpeed = 0
        }

        persistence.save()
        locationService.stopTracking()

        activeTrip = nil
        activeDriver = nil
        accumulatedDistance = 0
        lastLocation = nil
    }

    // MARK: - Private

    private func subscribeToLocation() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.processLocation(location)
            }
            .store(in: &cancellables)
    }

    private func processLocation(_ location: CLLocation) {
        guard let trip = activeTrip else { return }
        let ctx = persistence.viewContext
        let speedKmh = max(location.speed, 0) * 3.6

        // Accumulate distance
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 0 && delta < 500 {   // ignore GPS jumps > 500 m
                accumulatedDistance += delta
                trip.totalKm = accumulatedDistance / 1000.0
            }
        }
        lastLocation = location

        // Track max speed
        if speedKmh > trip.maxSpeed {
            trip.maxSpeed = speedKmh
            trip.maxSpeedLatitude = location.coordinate.latitude
            trip.maxSpeedLongitude = location.coordinate.longitude
        }

        // Track min speed (only while moving)
        if speedKmh >= movingThreshold && speedKmh < trip.minSpeed {
            trip.minSpeed = speedKmh
            trip.minSpeedLatitude = location.coordinate.latitude
            trip.minSpeedLongitude = location.coordinate.longitude
        }

        // Store route point every ~5 seconds or ~10 meters
        let shouldRecord = shouldRecordPoint(location: location)
        if shouldRecord {
            let point = RoutePoint(context: ctx)
            point.latitude = location.coordinate.latitude
            point.longitude = location.coordinate.longitude
            point.speed = speedKmh
            point.altitude = location.altitude
            point.course = location.course
            point.timestamp = location.timestamp
            point.trip = trip
        }

        persistence.save()
    }

    private var lastRecordedLocation: CLLocation?
    private var lastRecordedTime: Date = Date.distantPast

    private func shouldRecordPoint(location: CLLocation) -> Bool {
        let minTimeDelta: TimeInterval = 5
        let minDistanceDelta: Double = 10  // meters

        let timeSinceLast = location.timestamp.timeIntervalSince(lastRecordedTime)
        let distanceSinceLast = lastRecordedLocation.map {
            location.distance(from: $0)
        } ?? Double.greatestFiniteMagnitude

        if timeSinceLast >= minTimeDelta || distanceSinceLast >= minDistanceDelta {
            lastRecordedLocation = location
            lastRecordedTime = location.timestamp
            return true
        }
        return false
    }

    private func resumeActiveTrip() {
        let ctx = persistence.viewContext
        let request = Trip.activeTrip()
        if let trip = try? ctx.fetch(request).first {
            activeTrip = trip
            activeDriver = trip.driver
            accumulatedDistance = trip.totalKm * 1000
            locationService.startTracking()
        }
    }
}
