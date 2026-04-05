import Foundation
import CoreData
import CoreLocation

@objc(Trip)
public class Trip: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var totalKm: Double
    @NSManaged public var maxSpeed: Double          // km/h
    @NSManaged public var minSpeed: Double          // km/h (only while moving)
    @NSManaged public var maxSpeedLatitude: Double
    @NSManaged public var maxSpeedLongitude: Double
    @NSManaged public var minSpeedLatitude: Double
    @NSManaged public var minSpeedLongitude: Double
    @NSManaged public var isActive: Bool
    @NSManaged public var driver: Driver?
    @NSManaged public var routePoints: NSOrderedSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        startDate = Date()
        totalKm = 0
        maxSpeed = 0
        minSpeed = Double.greatestFiniteMagnitude
        isActive = true
    }

    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var maxSpeedLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: maxSpeedLatitude, longitude: maxSpeedLongitude)
    }

    var minSpeedLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: minSpeedLatitude, longitude: minSpeedLongitude)
    }

    var orderedRoutePoints: [RoutePoint] {
        (routePoints?.array as? [RoutePoint]) ?? []
    }
}

extension Trip: Identifiable {}

extension Trip {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    static func allTripsRequest() -> NSFetchRequest<Trip> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        return request
    }

    static func tripsForDriver(_ driver: Driver) -> NSFetchRequest<Trip> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "driver == %@", driver)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        return request
    }

    static func activeTrip() -> NSFetchRequest<Trip> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        return request
    }
}
