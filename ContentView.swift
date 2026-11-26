import SwiftUI
import Combine

class Vehicle: Identifiable {
    let id = UUID()
    let vehicleID: String
    var brand: String
    var model: String
    var dailyRate: Double
    var isAvailable: Bool

    init(vehicleID: String, brand: String, model: String, dailyRate: Double) {
        self.vehicleID = vehicleID
        self.brand = brand
        self.model = model
        self.dailyRate = dailyRate
        self.isAvailable = true
    }

    var type: String { "Vehicle" }

    func calculateRentalCost(days: Int) -> Double {
        dailyRate * Double(days)
    }

    func details() -> String {
        "\(brand) \(model) - \(type)"
    }
}

class Car: Vehicle {
    var seatingCapacity: Int
    var serviceCharge: Double

    init(vehicleID: String, brand: String, model: String, dailyRate: Double, seatingCapacity: Int, serviceCharge: Double) {
        self.seatingCapacity = seatingCapacity
        self.serviceCharge = serviceCharge
        super.init(vehicleID: vehicleID, brand: brand, model: model, dailyRate: dailyRate)
    }

    override var type: String { "Car" }

    override func calculateRentalCost(days: Int) -> Double {
        dailyRate * Double(days) + serviceCharge
    }

    override func details() -> String {
        "\(super.details()), Seats: \(seatingCapacity), Service fee: \(serviceCharge)"
    }
}

class Motorcycle: Vehicle {
    var engineCapacity: Int

    init(vehicleID: String, brand: String, model: String, dailyRate: Double, engineCapacity: Int) {
        self.engineCapacity = engineCapacity
        super.init(vehicleID: vehicleID, brand: brand, model: model, dailyRate: dailyRate)
    }

    override var type: String { "Motorcycle" }

    override func calculateRentalCost(days: Int) -> Double {
        let categoryFee = engineCapacity > 150 ? 50000.0 : 20000.0
        return dailyRate * Double(days) + categoryFee
    }

    override func details() -> String {
        "\(super.details()), Engine: \(engineCapacity) cc"
    }
}

class ElectricBicycle: Vehicle {
    var batteryRange: Double
    var batteryFee: Double

    init(vehicleID: String, brand: String, model: String, dailyRate: Double, batteryRange: Double, batteryFee: Double) {
        self.batteryRange = batteryRange
        self.batteryFee = batteryFee
        super.init(vehicleID: vehicleID, brand: brand, model: model, dailyRate: dailyRate)
    }

    override var type: String { "Electric Bicycle" }

    override func calculateRentalCost(days: Int) -> Double {
        dailyRate * Double(days) + batteryFee
    }

    override func details() -> String {
        "\(super.details()), Battery range: \(batteryRange) km, Battery fee: \(batteryFee)"
    }
}

class Customer: Identifiable {
    let id = UUID()
    let customerID: String
    var name: String
    var phone: String
    var email: String

    init(customerID: String, name: String, phone: String, email: String) {
        self.customerID = customerID
        self.name = name
        self.phone = phone
        self.email = email
    }
}

class Rental: Identifiable {
    let id = UUID()
    let vehicle: Vehicle
    let customer: Customer
    let days: Int
    let totalCost: Double
    var isReturned = false

    init(vehicle: Vehicle, customer: Customer, days: Int) {
        self.vehicle = vehicle
        self.customer = customer
        self.days = days
        self.totalCost = vehicle.calculateRentalCost(days: days)
    }
}

class RentalSystem: ObservableObject {
    @Published var vehicles: [Vehicle] = [
        Car(vehicleID: "C01", brand: "Toyota", model: "Vios", dailyRate: 500000, seatingCapacity: 5, serviceCharge: 100000),
        Car(vehicleID: "C02", brand: "Honda", model: "City", dailyRate: 600000, seatingCapacity: 5, serviceCharge: 120000),
        Motorcycle(vehicleID: "M01", brand: "Honda", model: "Winner", dailyRate: 150000, engineCapacity: 150),
        Motorcycle(vehicleID: "M02", brand: "Yamaha", model: "Exciter", dailyRate: 180000, engineCapacity: 155),
        ElectricBicycle(vehicleID: "B01", brand: "VinFast", model: "E-Bike", dailyRate: 80000, batteryRange: 80, batteryFee: 20000)
    ]

    @Published var customers: [Customer] = [
        Customer(customerID: "U01", name: "Nguyen Van An", phone: "0900000001", email: "an@email.com")
    ]

    @Published var rentals: [Rental] = []
    @Published var message = ""

    func addVehicle(_ vehicle: Vehicle) {
        guard !vehicles.contains(where: { $0.vehicleID == vehicle.vehicleID }) else {
            message = "Vehicle ID already exists."
            return
        }
        vehicles.append(vehicle)
        message = "Vehicle added successfully."
    }

    func addCustomer(name: String, phone: String, email: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !phone.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "Please complete all customer fields."
            return
        }

        let customer = Customer(
            customerID: "U\(String(format: "%02d", customers.count + 1))",
            name: name,
            phone: phone,
            email: email
        )

        customers.append(customer)
        message = "Customer registered successfully."
    }

    func updateCustomer(_ customer: Customer, phone: String, email: String) {
        guard !phone.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "Phone and email cannot be empty."
            return
        }

        customer.phone = phone
        customer.email = email
        message = "Customer information updated."
    }

    func rentVehicle(vehicle: Vehicle, customer: Customer, days: Int) {
        guard days > 0 else {
            message = "Rental duration must be greater than zero."
            return
        }

        guard vehicle.isAvailable else {
            message = "Vehicle is not available."
            return
        }

        let rental = Rental(vehicle: vehicle, customer: customer, days: days)
        rentals.append(rental)
        vehicle.isAvailable = false
        message = "Rental successful. Total: \(rental.totalCost.formatted()) VND"
    }

    func returnVehicle(_ rental: Rental) {
        guard !rental.isReturned else {
            message = "This vehicle has already been returned."
            return
        }

        rental.isReturned = true
        rental.vehicle.isAvailable = true
        message = "Vehicle returned successfully."
    }
}

struct ContentView: View {
    @StateObject private var system = RentalSystem()

    var body: some View {
        TabView {
            VehicleView(system: system)
                .tabItem {
                    Label("Vehicles", systemImage: "car.fill")
                }

            CustomerView(system: system)
                .tabItem {
                    Label("Customers", systemImage: "person.fill")
                }

            RentalView(system: system)
                .tabItem {
                    Label("Rentals", systemImage: "key.fill")
                }
        }
        .alert("Notification", isPresented: Binding(
            get: { !system.message.isEmpty },
            set: { if !$0 { system.message = "" } }
        )) {
            Button("OK") {
                system.message = ""
            }
        } message: {
            Text(system.message)
        }
    }
}

struct VehicleView: View {
    @ObservedObject var system: RentalSystem
    @State private var showAddVehicle = false

    var body: some View {
        NavigationStack {
            List {
                Section("Vehicle List") {
                    ForEach(system.vehicles) { vehicle in
                        NavigationLink {
                            VehicleDetailView(system: system, vehicle: vehicle)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(vehicle.details())
                                    .font(.headline)

                                Text("ID: \(vehicle.vehicleID)")
                                    .font(.subheadline)

                                Text("Daily rate: \(vehicle.dailyRate.formatted()) VND")

                                Text(vehicle.isAvailable ? "Available" : "Rented")
                                    .foregroundStyle(vehicle.isAvailable ? .green : .red)
                            }
                        }
                    }
                }

                Section {
                    Button("Add Vehicle") {
                        showAddVehicle = true
                    }
                }
            }
            .navigationTitle("Vehicle Management")
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView(system: system)
            }
        }
    }
}

struct VehicleDetailView: View {
    @ObservedObject var system: RentalSystem
    let vehicle: Vehicle

    @State private var selectedCustomerID = ""
    @State private var days = 1

    var selectedCustomer: Customer? {
        system.customers.first {
            $0.customerID == selectedCustomerID
        }
    }

    var body: some View {
        Form {
            Section("Vehicle Information") {
                Text("ID: \(vehicle.vehicleID)")
                Text("Type: \(vehicle.type)")
                Text("Brand: \(vehicle.brand)")
                Text("Model: \(vehicle.model)")
                Text("Daily rate: \(vehicle.dailyRate.formatted()) VND")
                Text(vehicle.details())
                Text(vehicle.isAvailable ? "Available" : "Rented")
            }

            if vehicle.isAvailable {
                Section("Rent Vehicle") {
                    Picker("Customer", selection: $selectedCustomerID) {
                        Text("Select customer").tag("")
                        ForEach(system.customers) { customer in
                            Text(customer.name)
                                .tag(customer.customerID)
                        }
                    }

                    Stepper("Rental days: \(days)", value: $days, in: 1...365)

                    Text("Total: \(vehicle.calculateRentalCost(days: days).formatted()) VND")

                    Button("Confirm Rental") {
                        guard let customer = selectedCustomer else {
                            system.message = "Please select a customer."
                            return
                        }

                        system.rentVehicle(
                            vehicle: vehicle,
                            customer: customer,
                            days: days
                        )
                    }
                }
            }
        }
        .navigationTitle("Vehicle Details")
    }
}

struct AddVehicleView: View {
    @ObservedObject var system: RentalSystem
    @Environment(\.dismiss) private var dismiss

    @State private var vehicleType = "Car"
    @State private var vehicleID = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var dailyRate = "100000"
    @State private var seatingCapacity = "5"
    @State private var serviceCharge = "100000"
    @State private var engineCapacity = "150"
    @State private var batteryRange = "80"
    @State private var batteryFee = "20000"

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Information") {
                    Picker("Vehicle Type", selection: $vehicleType) {
                        Text("Car").tag("Car")
                        Text("Motorcycle").tag("Motorcycle")
                        Text("Electric Bicycle").tag("Electric Bicycle")
                    }

                    TextField("Vehicle ID", text: $vehicleID)
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    TextField("Daily Rate", text: $dailyRate)
                        .keyboardType(.numberPad)
                }

                if vehicleType == "Car" {
                    Section("Car Details") {
                        TextField("Seating Capacity", text: $seatingCapacity)
                            .keyboardType(.numberPad)

                        TextField("Service Charge", text: $serviceCharge)
                            .keyboardType(.numberPad)
                    }
                }

                if vehicleType == "Motorcycle" {
                    Section("Motorcycle Details") {
                        TextField("Engine Capacity (cc)", text: $engineCapacity)
                            .keyboardType(.numberPad)
                    }
                }

                if vehicleType == "Electric Bicycle" {
                    Section("Electric Bicycle Details") {
                        TextField("Battery Range (km)", text: $batteryRange)
                            .keyboardType(.decimalPad)

                        TextField("Battery Fee", text: $batteryFee)
                            .keyboardType(.numberPad)
                    }
                }

                Button("Save Vehicle") {
                    saveVehicle()
                }
            }
            .navigationTitle("Add Vehicle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveVehicle() {
        guard !vehicleID.trimmingCharacters(in: .whitespaces).isEmpty,
              !brand.trimmingCharacters(in: .whitespaces).isEmpty,
              !model.trimmingCharacters(in: .whitespaces).isEmpty,
              let rate = Double(dailyRate),
              rate > 0 else {
            system.message = "Enter valid vehicle information."
            return
        }

        let vehicle: Vehicle

        switch vehicleType {
        case "Car":
            guard let seats = Int(seatingCapacity),
                  seats > 0,
                  let fee = Double(serviceCharge),
                  fee >= 0 else {
                system.message = "Enter valid car details."
                return
            }

            vehicle = Car(
                vehicleID: vehicleID,
                brand: brand,
                model: model,
                dailyRate: rate,
                seatingCapacity: seats,
                serviceCharge: fee
            )

        case "Motorcycle":
            guard let engine = Int(engineCapacity), engine > 0 else {
                system.message = "Enter a valid engine capacity."
                return
            }

            vehicle = Motorcycle(
                vehicleID: vehicleID,
                brand: brand,
                model: model,
                dailyRate: rate,
                engineCapacity: engine
            )

        default:
            guard let range = Double(batteryRange),
                  range > 0,
                  let fee = Double(batteryFee),
                  fee >= 0 else {
                system.message = "Enter valid battery details."
                return
            }

            vehicle = ElectricBicycle(
                vehicleID: vehicleID,
                brand: brand,
                model: model,
                dailyRate: rate,
                batteryRange: range,
                batteryFee: fee
            )
        }

        let oldCount = system.vehicles.count
        system.addVehicle(vehicle)

        if system.vehicles.count > oldCount {
            dismiss()
        }
    }
}

struct CustomerView: View {
    @ObservedObject var system: RentalSystem
    @State private var showAddCustomer = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(system.customers) { customer in
                    NavigationLink {
                        CustomerDetailView(system: system, customer: customer)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(customer.name)
                                .font(.headline)

                            Text("ID: \(customer.customerID)")
                            Text(customer.phone)
                            Text(customer.email)
                        }
                    }
                }

                Button("Register Customer") {
                    showAddCustomer = true
                }
            }
            .navigationTitle("Customers")
            .sheet(isPresented: $showAddCustomer) {
                AddCustomerView(system: system)
            }
        }
    }
}

struct AddCustomerView: View {
    @ObservedObject var system: RentalSystem
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Full Name", text: $name)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)

                Button("Register") {
                    let oldCount = system.customers.count
                    system.addCustomer(name: name, phone: phone, email: email)

                    if system.customers.count > oldCount {
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CustomerDetailView: View {
    @ObservedObject var system: RentalSystem
    let customer: Customer

    @State private var phone = ""
    @State private var email = ""

    var customerRentals: [Rental] {
        system.rentals.filter {
            $0.customer.id == customer.id
        }
    }

    var body: some View {
        Form {
            Section("Customer Information") {
                Text("ID: \(customer.customerID)")
                Text(customer.name)

                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)

                Button("Update Contact") {
                    system.updateCustomer(
                        customer,
                        phone: phone,
                        email: email
                    )
                }
            }

            Section("Rental History") {
                if customerRentals.isEmpty {
                    Text("No rental history.")
                }

                ForEach(customerRentals) { rental in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(rental.vehicle.details())
                        Text("Days: \(rental.days)")
                        Text("Cost: \(rental.totalCost.formatted()) VND")
                        Text(rental.isReturned ? "Returned" : "Currently rented")
                    }
                }
            }
        }
        .navigationTitle("Customer Details")
        .onAppear {
            phone = customer.phone
            email = customer.email
        }
    }
}

struct RentalView: View {
    @ObservedObject var system: RentalSystem

    var body: some View {
        NavigationStack {
            List {
                if system.rentals.isEmpty {
                    Text("No rental records.")
                }

                ForEach(system.rentals) { rental in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(rental.vehicle.details())
                            .font(.headline)

                        Text("Customer: \(rental.customer.name)")
                        Text("Duration: \(rental.days) days")
                        Text("Total: \(rental.totalCost.formatted()) VND")

                        Text(rental.isReturned ? "Returned" : "Currently rented")
                            .foregroundStyle(rental.isReturned ? .green : .orange)

                        if !rental.isReturned {
                            Button("Return Vehicle") {
                                system.returnVehicle(rental)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Rental Management")
        }
    }
}

