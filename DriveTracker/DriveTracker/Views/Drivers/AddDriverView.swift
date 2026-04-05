import SwiftUI
import PhotosUI

struct AddDriverView: View {
    @ObservedObject var viewModel: DriversViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var licenseNumber = ""
    @State private var licenseCategory = "B"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let categories = ["A", "B", "C", "D", "E", "AB", "AC", "AD", "AE"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Foto") {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Group {
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 90))
                                        .foregroundStyle(.blue)
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(.white, .blue)
                                    .font(.title3)
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    selectedImage = img
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Dados Pessoais") {
                    TextField("Nome completo", text: $name)
                        .textContentType(.name)
                }

                Section("CNH") {
                    TextField("Número da CNH", text: $licenseNumber)
                        .keyboardType(.numberPad)
                    Picker("Categoria", selection: $licenseCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Novo Motorista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.addDriver(
                            name: name,
                            licenseNumber: licenseNumber,
                            licenseCategory: licenseCategory,
                            photo: selectedImage
                        )
                        if viewModel.errorMessage == nil { dismiss() }
                    }
                    .disabled(name.isEmpty || licenseNumber.isEmpty)
                }
            }
        }
    }
}

struct EditDriverView: View {
    let driver: Driver
    @ObservedObject var viewModel: DriversViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var licenseNumber: String
    @State private var licenseCategory: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let categories = ["A", "B", "C", "D", "E", "AB", "AC", "AD", "AE"]

    init(driver: Driver, viewModel: DriversViewModel) {
        self.driver = driver
        self.viewModel = viewModel
        _name = State(initialValue: driver.name)
        _licenseNumber = State(initialValue: driver.licenseNumber)
        _licenseCategory = State(initialValue: driver.licenseCategory)
        if let data = driver.photoData {
            _selectedImage = State(initialValue: UIImage(data: data))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Foto") {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Group {
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 90))
                                        .foregroundStyle(.blue)
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(.white, .blue)
                                    .font(.title3)
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    selectedImage = img
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Dados Pessoais") {
                    TextField("Nome completo", text: $name)
                }

                Section("CNH") {
                    TextField("Número da CNH", text: $licenseNumber)
                        .keyboardType(.numberPad)
                    Picker("Categoria", selection: $licenseCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Editar Motorista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.updateDriver(
                            driver,
                            name: name,
                            licenseNumber: licenseNumber,
                            licenseCategory: licenseCategory,
                            photo: selectedImage != UIImage(data: driver.photoData ?? Data()) ? selectedImage : nil
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || licenseNumber.isEmpty)
                }
            }
        }
    }
}
