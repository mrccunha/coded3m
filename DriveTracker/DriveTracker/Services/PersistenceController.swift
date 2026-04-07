import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DriveTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    // MARK: - Preview / Test support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.viewContext

        let driver = Driver(context: ctx)
        driver.name = "João Silva"
        driver.licenseNumber = "00123456789"
        driver.licenseCategory = "B"

        let trip = Trip(context: ctx)
        trip.driver = driver
        trip.startDate = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        trip.endDate = Date()
        trip.totalKm = 34.7
        trip.maxSpeed = 110.5
        trip.minSpeed = 20.0
        trip.maxSpeedLatitude = -23.5505
        trip.maxSpeedLongitude = -46.6333
        trip.minSpeedLatitude = -23.5600
        trip.minSpeedLongitude = -46.6200
        trip.isActive = false

        try? ctx.save()
        return controller
    }()
}
