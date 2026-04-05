import SwiftUI
import MapKit

struct TripDetailView: View {
    @ObservedObject var trip: Trip

    var safeMinSpeed: Double {
        trip.minSpeed >= Double.greatestFiniteMagnitude ? 0 : trip.minSpeed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Map
                TripMapView(trip: trip)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Distância", value: formattedKm(trip.totalKm), icon: "road.lanes", color: .blue)
                    StatCard(title: "Duração", value: trip.formattedDuration, icon: "timer", color: .purple)
                    StatCard(title: "Vel. Máxima", value: String(format: "%.0f km/h", trip.maxSpeed), icon: "arrow.up.circle.fill", color: .red)
                    StatCard(title: "Vel. Mínima", value: String(format: "%.0f km/h", safeMinSpeed), icon: "arrow.down.circle.fill", color: .green)
                }
                .padding(.horizontal)

                // Timestamps
                GroupBox("Horários") {
                    VStack(spacing: 8) {
                        LabeledContent("Início", value: trip.startDate.formatted(date: .abbreviated, time: .standard))
                        if let end = trip.endDate {
                            LabeledContent("Fim", value: end.formatted(date: .abbreviated, time: .standard))
                        } else {
                            LabeledContent("Fim", value: "Em andamento")
                        }
                    }
                }
                .padding(.horizontal)

                // Speed events with GPS coordinates
                GroupBox("Pontos de Velocidade") {
                    VStack(spacing: 12) {
                        SpeedEventRow(
                            title: "Velocidade Máxima",
                            speed: trip.maxSpeed,
                            coordinate: trip.maxSpeedLocation,
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                        Divider()
                        SpeedEventRow(
                            title: "Velocidade Mínima",
                            speed: safeMinSpeed,
                            coordinate: trip.minSpeedLocation,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)

                // Route points list
                if !trip.orderedRoutePoints.isEmpty {
                    GroupBox("Histórico de Pontos (\(trip.orderedRoutePoints.count))") {
                        RoutePointsTable(points: trip.orderedRoutePoints)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(trip.driver?.name ?? "Viagem")
        .navigationBarTitleDisplayMode(.large)
    }

    func formattedKm(_ km: Double) -> String {
        km < 1 ? String(format: "%.0f m", km * 1000) : String(format: "%.2f km", km)
    }
}

// MARK: - Speed event row with coordinate copy

struct SpeedEventRow: View {
    let title: String
    let speed: Double
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let color: Color

    @State private var copied = false

    var coordText: String {
        String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline.bold())
                Spacer()
                Text(String(format: "%.0f km/h", speed))
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(coordText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Button {
                    UIPasteboard.general.string = coordText
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied ? .green : .blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Route points scrollable table

struct RoutePointsTable: View {
    let points: [RoutePoint]
    @State private var showAll = false

    var displayedPoints: [RoutePoint] {
        showAll ? points : Array(points.prefix(20))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Hora").frame(width: 70, alignment: .leading)
                Text("Vel.").frame(width: 60, alignment: .trailing)
                Text("Latitude").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Longitude").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            Divider()

            ForEach(displayedPoints) { point in
                HStack {
                    Text(point.timestamp.formatted(date: .omitted, time: .shortened))
                        .frame(width: 70, alignment: .leading)
                    Text(String(format: "%.0f", point.speed))
                        .frame(width: 60, alignment: .trailing)
                    Text(String(format: "%.5f", point.latitude))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(String(format: "%.5f", point.longitude))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption2)
                .padding(.vertical, 2)
                Divider()
            }

            if points.count > 20 && !showAll {
                Button("Ver todos \(points.count) pontos") { showAll = true }
                    .font(.caption)
                    .padding(.top, 6)
            }
        }
    }
}
