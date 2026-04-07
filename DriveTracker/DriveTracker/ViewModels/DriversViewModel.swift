import Foundation
import CoreData
import UIKit
import Combine

class DriversViewModel: ObservableObject {
    private let persistence: PersistenceController

    @Published var drivers: [Driver] = []
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        loadDrivers()
        observeContext()
    }

    // MARK: - CRUD

    func addDriver(name: String, licenseNumber: String, licenseCategory: String, photo: UIImage?) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "O nome não pode ser vazio."
            return
        }
        guard !licenseNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Informe o número da CNH."
            return
        }

        let ctx = persistence.viewContext
        let driver = Driver(context: ctx)
        driver.name = name.trimmingCharacters(in: .whitespaces)
        driver.licenseNumber = licenseNumber.trimmingCharacters(in: .whitespaces)
        driver.licenseCategory = licenseCategory
        driver.photoData = photo?.jpegData(compressionQuality: 0.7)

        persistence.save()
        loadDrivers()
    }

    func updateDriver(_ driver: Driver, name: String, licenseNumber: String, licenseCategory: String, photo: UIImage?) {
        driver.name = name.trimmingCharacters(in: .whitespaces)
        driver.licenseNumber = licenseNumber.trimmingCharacters(in: .whitespaces)
        driver.licenseCategory = licenseCategory
        if let photo = photo {
            driver.photoData = photo.jpegData(compressionQuality: 0.7)
        }
        persistence.save()
        loadDrivers()
    }

    func deleteDriver(_ driver: Driver) {
        let ctx = persistence.viewContext
        ctx.delete(driver)
        persistence.save()
        loadDrivers()
    }

    // MARK: - Private

    private func loadDrivers() {
        let request = Driver.allDriversRequest()
        drivers = (try? persistence.viewContext.fetch(request)) ?? []
    }

    private func observeContext() {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: persistence.viewContext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadDrivers() }
            .store(in: &cancellables)
    }
}
