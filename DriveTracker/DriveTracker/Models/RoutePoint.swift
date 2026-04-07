import Foundation
import CoreData
import CoreLocation
import MapKit

@objc(RoutePoint)
public class RoutePoint: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var speed: Double     // km/h
    @NSManaged public var altitude: Double  // meters
    @NSManaged public var course: Double    // degrees
    @NSManaged public var trip: Trip?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        timestamp = Date()
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension RoutePoint: Identifiable {}

extension RoutePoint {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoutePoint> {
        return NSFetchRequest<RoutePoint>(entityName: "RoutePoint")
    }
}

// MKAnnotation support for map pins
class SpeedAnnotation: NSObject, MKAnnotation {
    enum AnnotationType {
        case maxSpeed, minSpeed, start, end
    }
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let type: AnnotationType

    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, type: AnnotationType) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}
