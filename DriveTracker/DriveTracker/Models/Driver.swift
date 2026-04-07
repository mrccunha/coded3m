import Foundation
import CoreData

@objc(Driver)
public class Driver: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var licenseNumber: String
    @NSManaged public var licenseCategory: String
    @NSManaged public var photoData: Data?
    @NSManaged public var createdAt: Date
    @NSManaged public var trips: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
    }

    var totalKm: Double {
        let tripsArray = (trips?.allObjects as? [Trip]) ?? []
        return tripsArray.compactMap { $0.totalKm }.reduce(0, +)
    }

    var tripsCount: Int {
        trips?.count ?? 0
    }
}

extension Driver: Identifiable {}

extension Driver {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Driver> {
        return NSFetchRequest<Driver>(entityName: "Driver")
    }

    static func allDriversRequest() -> NSFetchRequest<Driver> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Driver.name, ascending: true)]
        return request
    }
}
