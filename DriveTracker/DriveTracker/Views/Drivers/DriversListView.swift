import SwiftUI

struct DriversListView: View {
    @StateObject private var viewModel = DriversViewModel()
    @StateObject private var tripsVM = TripsViewModel()
    @State private var showAddDriver = false
    @State private var driverToEdit: Driver?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.drivers.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.drivers) { driver in
                            NavigationLink {
                                DriverDetailView(driver: driver, tripsVM: tripsVM)
                            } label: {
                                DriverListCell(driver: driver, totalKm: tripsVM.totalKm(for: driver))
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteDriver(driver)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                                Button {
                                    driverToEdit = driver
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Motoristas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddDriver = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDriver) {
                AddDriverView(viewModel: viewModel)
            }
            .sheet(item: $driverToEdit) { driver in
                EditDriverView(driver: driver, viewModel: viewModel)
            }
            .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text("Nenhum motorista cadastrado")
                .font(.title3)
            Button("Cadastrar Motorista") { showAddDriver = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct DriverListCell: View {
    let driver: Driver
    let totalKm: Double

    var body: some View {
        HStack(spacing: 12) {
            if let data = driver.photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.name).font(.headline)
                Text("CNH \(driver.licenseCategory) · \(driver.licenseNumber)")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(String(format: "%.1f km", totalKm), systemImage: "road.lanes")
                    Label("\(driver.tripsCount) viagem(ns)", systemImage: "mappin.and.ellipse")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DriverDetailView: View {
    let driver: Driver
    @ObservedObject var tripsVM: TripsViewModel

    var trips: [Trip] { tripsVM.allTrips.filter { $0.driver?.id == driver.id } }

    var body: some View {
        List {
            Section("Informações") {
                LabeledContent("Nome", value: driver.name)
                LabeledContent("CNH", value: driver.licenseNumber)
                LabeledContent("Categoria", value: driver.licenseCategory)
                LabeledContent("Cadastrado em", value: driver.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            Section("Resumo") {
                LabeledContent("Total de viagens", value: "\(trips.filter { !$0.isActive }.count)")
                LabeledContent("Total percorrido", value: String(format: "%.2f km", tripsVM.totalKm(for: driver)))
            }
            Section("Viagens") {
                if trips.isEmpty {
                    Text("Nenhuma viagem registrada").foregroundStyle(.secondary)
                } else {
                    ForEach(trips) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            TripRow(trip: trip)
                        }
                    }
                }
            }
        }
        .navigationTitle(driver.name)
        .navigationBarTitleDisplayMode(.large)
    }
}
