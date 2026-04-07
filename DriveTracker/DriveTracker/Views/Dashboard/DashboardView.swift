import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var locationService: LocationService
    @StateObject private var driversVM = DriversViewModel()

    @State private var showDriverPicker = false

    var body: some View {
        NavigationStack {
            if let trip = tripManager.activeTrip {
                ActiveTripView(trip: trip)
            } else {
                idleView
            }
        }
        .navigationTitle("DriveTracker")
    }

    // MARK: - Idle (no active trip)

    var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Nenhuma viagem em andamento")
                .font(.title2)
                .multilineTextAlignment(.center)

            if driversVM.drivers.isEmpty {
                VStack(spacing: 12) {
                    Text("Cadastre um motorista para começar")
                        .foregroundStyle(.secondary)
                    NavigationLink("Cadastrar Motorista") {
                        AddDriverView(viewModel: driversVM)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button {
                    showDriverPicker = true
                } label: {
                    Label("Iniciar Viagem", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .sheet(isPresented: $showDriverPicker) {
            DriverPickerSheet(drivers: driversVM.drivers) { driver in
                tripManager.startTrip(driver: driver)
                showDriverPicker = false
            }
        }
    }
}

// MARK: - Active trip live panel

struct ActiveTripView: View {
    @ObservedObject var trip: Trip
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var locationService: LocationService

    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(trip.driver?.name ?? "Motorista")
                            .font(.title2.bold())
                        Text(trip.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(label: "AO VIVO", color: .green)
                }
                .padding(.horizontal)

                // Current speed – big display
                SpeedGauge(speed: locationService.currentSpeedKmh)
                    .frame(height: 180)
                    .padding(.horizontal)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Vel. Máxima", value: formattedSpeed(trip.maxSpeed), icon: "arrow.up.circle.fill", color: .red)
                    StatCard(title: "Vel. Mínima", value: formattedSpeed(safeMínimo(trip.minSpeed)), icon: "arrow.down.circle.fill", color: .blue)
                    StatCard(title: "Distância", value: formattedKm(trip.totalKm), icon: "road.lanes", color: .orange)
                    StatCard(title: "Duração", value: trip.formattedDuration, icon: "timer", color: .purple)
                }
                .padding(.horizontal)

                // Stop button
                Button(role: .destructive) {
                    tripManager.stopTrip()
                } label: {
                    Label("Encerrar Viagem", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onReceive(timer) { _ in
            elapsed += 1
        }
    }

    func formattedSpeed(_ kmh: Double) -> String {
        String(format: "%.0f km/h", kmh)
    }
    func formattedKm(_ km: Double) -> String {
        km < 1 ? String(format: "%.0f m", km * 1000) : String(format: "%.2f km", km)
    }
    func safeMínimo(_ v: Double) -> Double {
        v >= Double.greatestFiniteMagnitude ? 0 : v
    }
}

// MARK: - Driver Picker Sheet

struct DriverPickerSheet: View {
    let drivers: [Driver]
    let onSelect: (Driver) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(drivers) { driver in
                Button {
                    onSelect(driver)
                } label: {
                    DriverRow(driver: driver)
                }
            }
            .navigationTitle("Selecione o Motorista")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reusable components

struct StatusBadge: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SpeedGauge: View {
    let speed: Double

    var color: Color {
        switch speed {
        case ..<60: return .green
        case 60..<100: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 18)
            Circle()
                .trim(from: 0, to: min(speed / 200, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: speed)
            VStack(spacing: 2) {
                Text(String(format: "%.0f", speed))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text("km/h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DriverRow: View {
    let driver: Driver
    var body: some View {
        HStack(spacing: 12) {
            if let data = driver.photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading) {
                Text(driver.name).font(.headline)
                Text("CNH \(driver.licenseCategory) · \(driver.licenseNumber)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
