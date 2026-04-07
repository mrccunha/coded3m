import SwiftUI

struct TripsListView: View {
    @StateObject private var viewModel = TripsViewModel()
    @StateObject private var driversVM = DriversViewModel()
    @State private var selectedDriver: Driver?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.displayedTrips.isEmpty {
                    emptyState
                } else {
                    List {
                        summarySection
                        ForEach(viewModel.displayedTrips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                TripRow(trip: trip)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTrip(trip)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Viagens")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Todos os motoristas") {
                            selectedDriver = nil
                            viewModel.filterDriver = nil
                        }
                        Divider()
                        ForEach(driversVM.drivers) { driver in
                            Button(driver.name) {
                                selectedDriver = driver
                                viewModel.filterDriver = driver
                            }
                        }
                    } label: {
                        Label(selectedDriver?.name ?? "Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    var summarySection: some View {
        Section {
            HStack {
                Label("Total percorrido", systemImage: "road.lanes")
                Spacer()
                Text(String(format: "%.2f km", viewModel.totalKmAll))
                    .fontWeight(.semibold)
            }
            HStack {
                Label("Viagens finalizadas", systemImage: "checkmark.circle")
                Spacer()
                Text("\(viewModel.displayedTrips.filter { !$0.isActive }.count)")
                    .fontWeight(.semibold)
            }
        } header: {
            Text("Resumo")
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("Nenhuma viagem registrada")
                .font(.title3)
            Text("Inicie uma viagem no painel principal")
                .foregroundStyle(.secondary)
        }
    }
}

struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(trip.isActive ? Color.green : Color.blue)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.driver?.name ?? "—")
                        .font(.headline)
                    if trip.isActive {
                        StatusBadge(label: "AO VIVO", color: .green)
                    }
                }
                Text(trip.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(String(format: "%.1f km", trip.totalKm), systemImage: "road.lanes")
                    Label(String(format: "%.0f km/h max", trip.maxSpeed), systemImage: "arrow.up.circle")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
