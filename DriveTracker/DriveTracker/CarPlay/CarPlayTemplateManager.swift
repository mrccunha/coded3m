import CarPlay
import CoreData
import Combine

class CarPlayTemplateManager: NSObject {

    private let interfaceController: CPInterfaceController
    private let tripManager = TripManager.shared
    private let locationService = LocationService.shared
    private let persistence = PersistenceController.shared

    private var cancellables = Set<AnyCancellable>()
    private var speedUpdateTimer: Timer?

    // Live dashboard template (shown during active trip)
    private var dashboardTemplate: CPInformationTemplate?
    // Driver selection list
    private var driverListTemplate: CPListTemplate?

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        super.init()
        observeChanges()
    }

    // MARK: - Entry point

    func present() {
        if tripManager.activeTrip != nil {
            showDashboard()
        } else {
            showDriverSelection()
        }
    }

    // MARK: - Driver Selection

    func showDriverSelection() {
        let drivers = fetchDrivers()
        let items = drivers.map { driver -> CPListItem in
            let item = CPListItem(
                text: driver.name,
                detailText: "CNH \(driver.licenseCategory) · \(driver.licenseNumber)"
            )
            item.handler = { [weak self] _, completion in
                self?.tripManager.startTrip(driver: driver)
                self?.showDashboard()
                completion()
            }
            return item
        }

        let addItem = CPListItem(text: "Cadastrar motorista no iPhone", detailText: nil)

        let section = CPListSection(items: items)
        let addSection = CPListSection(items: [addItem])

        let template = CPListTemplate(
            title: "Selecione o Motorista",
            sections: drivers.isEmpty ? [addSection] : [section, addSection]
        )
        driverListTemplate = template

        interfaceController.setRootTemplate(template, animated: true, completion: nil)
    }

    // MARK: - Live Dashboard

    func showDashboard() {
        let template = buildDashboardTemplate()
        dashboardTemplate = template
        interfaceController.setRootTemplate(template, animated: true, completion: nil)
        startSpeedUpdates()
    }

    private func buildDashboardTemplate() -> CPInformationTemplate {
        let trip = tripManager.activeTrip
        let driver = tripManager.activeDriver

        let items: [CPInformationItem] = [
            CPInformationItem(title: "Motorista", detail: driver?.name ?? "—"),
            CPInformationItem(title: "Velocidade", detail: formattedSpeed(locationService.currentSpeedKmh)),
            CPInformationItem(title: "Vel. Máxima", detail: formattedSpeed(trip?.maxSpeed ?? 0)),
            CPInformationItem(title: "Vel. Mínima", detail: formattedSpeed(safeMínimo(trip?.minSpeed))),
            CPInformationItem(title: "Distância", detail: formattedKm(trip?.totalKm ?? 0)),
            CPInformationItem(title: "Início", detail: formattedDate(trip?.startDate)),
            CPInformationItem(title: "Duração", detail: trip?.formattedDuration ?? "00:00:00"),
        ]

        let stopButton = CPTextButton(
            title: "Encerrar Viagem",
            textStyle: .confirm
        ) { [weak self] _ in
            self?.tripManager.stopTrip()
            self?.showDriverSelection()
        }

        let template = CPInformationTemplate(
            title: "Viagem em Andamento",
            layout: .leading,
            items: items,
            actions: [stopButton]
        )
        return template
    }

    private func startSpeedUpdates() {
        speedUpdateTimer?.invalidate()
        speedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshDashboard()
        }
    }

    private func refreshDashboard() {
        guard tripManager.activeTrip != nil else {
            speedUpdateTimer?.invalidate()
            return
        }
        let newTemplate = buildDashboardTemplate()
        dashboardTemplate = newTemplate
        // CPInformationTemplate does not support in-place updates, so we push/pop
        if interfaceController.topTemplate is CPInformationTemplate {
            interfaceController.setRootTemplate(newTemplate, animated: false, completion: nil)
        }
    }

    // MARK: - Helpers

    private func observeChanges() {
        tripManager.$activeTrip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] trip in
                if trip == nil {
                    self?.speedUpdateTimer?.invalidate()
                }
            }
            .store(in: &cancellables)
    }

    private func fetchDrivers() -> [Driver] {
        let request = Driver.allDriversRequest()
        return (try? persistence.viewContext.fetch(request)) ?? []
    }

    private func formattedSpeed(_ kmh: Double?) -> String {
        guard let kmh = kmh, kmh > 0 else { return "0 km/h" }
        return String(format: "%.0f km/h", kmh)
    }

    private func formattedKm(_ km: Double) -> String {
        if km < 1 {
            return String(format: "%.0f m", km * 1000)
        }
        return String(format: "%.2f km", km)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func safeMínimo(_ value: Double?) -> Double {
        guard let v = value, v < Double.greatestFiniteMagnitude else { return 0 }
        return v
    }
}
