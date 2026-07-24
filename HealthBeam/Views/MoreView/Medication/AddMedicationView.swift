import SwiftUI
import Combine
import CoreData

// (Enum definitions remain unchanged)
enum MedicationType: String, CaseIterable, Identifiable {
    case tablet = "Tablet", capsule = "Capsule", liquid = "Liquid", topical = "Topical"
    case cream = "Cream", device = "Device", drops = "Drops", foam = "Foam"
    case gel = "Gel", inhaler = "Inhaler", injection = "Injection", lotion = "Lotion"
    case ointment = "Ointment", patch = "Patch", powder = "Powder"
    case spray = "Spray", suppository = "Suppository"
    
    var id: String { self.rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }
    
    var icon: String {
        switch self {
        case .tablet: return "pills.fill"
        case .capsule: return "pills.circle.fill"
        case .liquid: return "drop.fill"
        case .topical: return "hand.point.up.left.fill"
        case .cream: return "drop.triangle.fill"
        case .device: return "ivfluid.bag.fill"
        case .drops: return "drop.degreesign"
        case .foam: return "bubbles.and.sparkles.fill"
        case .gel: return "drop.circle.fill"
        case .inhaler: return "air.purifier.fill"
        case .injection: return "syringe.fill"
        case .lotion: return "humidity.fill"
        case .ointment: return "paintbrush.pointed.fill"
        case .patch: return "bandage.fill"
        case .powder: return "snowflake"
        case .spray: return "aqi.medium"
        case .suppository: return "capsule.portrait.fill"
        }
    }
    
    var availableUnits: [String] {
        switch self {
        case .tablet, .capsule, .suppository, .powder: return ["mg", "mcg", "g", "IU"]
        case .liquid, .lotion, .gel, .foam: return ["ml", "%", "mg/ml"]
        case .injection: return ["ml", "Units", "mg"]
        case .drops: return ["drops", "ml", "mg"]
        case .inhaler: return ["mcg", "puffs", "mg"]
        case .spray: return ["sprays", "mcg", "ml"]
        case .cream, .ointment, .topical: return ["%", "mg", "g"]
        case .patch: return ["patch", "mg/24h", "mg"]
        case .device: return ["units"]
        }
    }
    
    var doseLabel: String {
        switch self {
        case .tablet, .capsule, .suppository: return "Pills per take"
        case .liquid: return "Volume (ml) per take"
        case .drops: return "Drops per take"
        case .inhaler: return "Puffs per take"
        case .spray: return "Sprays per take"
        case .injection: return "Units/ml per take"
        case .patch: return "Patches per take"
        default: return "Amount per take"
        }
    }
    
    var boxLabel: String {
        switch self {
        case .inhaler, .spray: return "Total Puffs/Sprays in Canister"
        case .liquid, .drops: return "Total Volume (ml) in Bottle"
        default: return "Total Quantity in Box"
        }
    }
}

private enum MedicationLocalizationCatalog {
    static let strings: [LocalizedStringResource] = [
        "Tablet", "Capsule", "Liquid", "Topical", "Cream", "Device", "Drops", "Foam",
        "Gel", "Inhaler", "Injection", "Lotion", "Ointment", "Patch", "Powder", "Spray", "Suppository"
    ]
}

enum AddStep: Int, CaseIterable {
    case name = 0, type = 1, strength = 2, inventory = 3, schedule = 4
}

struct AddMedicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: AddStep = .name
    @State private var name = ""
    @State private var selectedType: MedicationType = .tablet
    @State private var selectedColor: Color = .blue
    @State private var amount = ""
    @State private var unit = "mg"
    @State private var boxQuantity = ""
    @State private var doseQuantity = "1"
    @State private var dailyFrequency = 1
    @State private var reminders: [Date] = [Date()]
    @State private var showMoreTypes = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Professional Solid Background
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Indicator
                    headerProgressBar
                    
                    // Main Content Area
                    TabView(selection: $currentStep) {
                        nameStepView.tag(AddStep.name)
                        typeStepView.tag(AddStep.type)
                        strengthStepView.tag(AddStep.strength)
                        inventoryStepView.tag(AddStep.inventory)
                        scheduleStepView.tag(AddStep.schedule)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Disable swipe/dots, controlled by buttons
                    .animation(.snappy, value: currentStep)
                    
                    // Bottom Navigation
                    bottomControlBar
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: selectedType) { oldType, newType in
            unit = newType.availableUnits.first ?? "mg"
        }
    }
    
    // MARK: - STEPS UI
    
    // 1. Name Step: Clean Input
    var nameStepView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(selectedColor)
                .padding()
                .background(Circle().fill(selectedColor.opacity(0.1)))
            
            VStack(spacing: 8) {
                Text("Medication Name")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("What is the name of the medicine?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            TextField("e.g. Ibuprofen", text: $name)
                .font(.title3)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 30)
                .multilineTextAlignment(.center)
                .submitLabel(.next)
            
            Spacer()
            Spacer()
        }
    }
    
    // 2. Type Step: Grid & Colors
    var typeStepView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                
                // Color Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLOR MARKER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach([Color.blue, .red, .orange, .green, .purple, .pink, .mint, .indigo], id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .opacity(selectedColor == color ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        withAnimation(.snappy) { selectedColor = color }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // Type Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("MEDICATION FORM")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(mainTypes, id: \.self) { type in
                            MedicationTypeCard(type: type, selectedType: $selectedType, color: selectedColor)
                        }
                        if showMoreTypes {
                            ForEach(moreTypes, id: \.self) { type in
                                MedicationTypeCard(type: type, selectedType: $selectedType, color: selectedColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: { withAnimation { showMoreTypes.toggle() } }) {
                        Text(showMoreTypes ? "Show Less" : "Show More Forms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // 3. Strength Step: Unified Row
    var strengthStepView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "scalemass")
                .font(.system(size: 50))
                .foregroundColor(selectedColor)
            
            Text("Strength")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 0) {
                TextField("500", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title3)
                    .multilineTextAlignment(.trailing)
                    .padding()
                    .frame(height: 55)
                
                Divider().frame(height: 30)
                
                Menu {
                    ForEach(selectedType.availableUnits, id: \.self) { u in
                        Button(u) { unit = u }
                    }
                } label: {
                    HStack {
                        Text(unit)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(height: 55)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
    
    // 4. Inventory Step: Grouped Form Look
    var inventoryStepView: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Duration Card
                if let duration = calculateDuration(), duration > 0 {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Estimated Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(duration) Days")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(selectedColor)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Form Sections
                VStack(spacing: 1) {
                    // Row 1
                    HStack {
                        Text("Total Stock")
                        Spacer()
                        TextField("e.g. 30", text: $boxQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(selectedType.boxLabel.components(separatedBy: " ").first ?? "Qty") // Short label
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    
                    // Row 2
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        TextField("e.g. 1", text: $doseQuantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("pills")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                }
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Frequency Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("DAILY FREQUENCY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        Button(action: { if dailyFrequency > 1 { dailyFrequency -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(dailyFrequency)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(selectedColor)
                            Text("times daily")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { if dailyFrequency < 10 { dailyFrequency += 1 } }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(selectedColor)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // 5. Schedule Step: Standard List
    var scheduleStepView: some View {
        List {
            Section(header: Text("Reminder Times")) {
                ForEach(reminders.indices, id: \.self) { i in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(selectedColor)
                        Text("Dose \(i+1)")
                            .fontWeight(.medium)
                        Spacer()
                        DatePicker("", selection: $reminders[i], displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - COMPONENTS
    
    var headerProgressBar: some View {
        HStack(spacing: 4) {
            Button("Cancel") { dismiss() }
                .font(.body)
                .foregroundColor(.red)
            
            Spacer()
            
            // Minimal Dots
            HStack(spacing: 6) {
                ForEach(AddStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(currentStep.rawValue >= step.rawValue ? selectedColor : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            // Invisible spacer to balance the "Cancel" button for centering
            Text("Cancel").opacity(0)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    var bottomControlBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if currentStep != .name {
                    Button(action: goBack) {
                        Text("Back")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                    }
                } else {
                    Spacer().frame(width: 60) // Spacer for alignment
                }
                
                Spacer()
                
                Button(action: goNext) {
                    Text(currentStep == .schedule ? "Save Medication" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(isNextDisabled ? Color.gray : selectedColor)
                        .cornerRadius(10)
                }
                .disabled(isNextDisabled)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - LOGIC (UNCHANGED)
    var isNextDisabled: Bool {
        switch currentStep {
        case .name: return name.isEmpty
        case .strength: return amount.isEmpty
        case .inventory: return boxQuantity.isEmpty || doseQuantity.isEmpty
        case .schedule: return reminders.isEmpty
        default: return false
        }
    }
    
    func calculateDuration() -> Int? {
        let total = Double(boxQuantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let dose = Double(doseQuantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let dailyConsumption = dose * Double(dailyFrequency)
        
        guard total > 0, dailyConsumption > 0 else { return nil }
        let days = Int(ceil(total / dailyConsumption))
        return days
    }
    
    func goNext() {
        let impact = UIImpactFeedbackGenerator(style: .light); impact.impactOccurred()
        if currentStep == .inventory {
            generateReminders()
            currentStep = AddStep(rawValue: currentStep.rawValue + 1) ?? .name
        } else if currentStep == .schedule {
            saveMedication()
        } else {
            currentStep = AddStep(rawValue: currentStep.rawValue + 1) ?? .name
        }
    }
    
    func goBack() { currentStep = AddStep(rawValue: currentStep.rawValue - 1) ?? .name }
    
    func generateReminders() {
        reminders.removeAll()
        let calendar = Calendar.current
        let today = Date()
        let startHour = 9
        
        for i in 0..<dailyFrequency {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = startHour + (i * 5)
            components.minute = 0
            if let date = calendar.date(from: components) {
                reminders.append(date)
            } else {
                reminders.append(Date())
            }
        }
    }
    
    var mainTypes: [MedicationType] { [.tablet, .capsule, .liquid, .injection] }
    var moreTypes: [MedicationType] { MedicationType.allCases.filter { !mainTypes.contains($0) } }
    
    private func saveMedication() {
        let totalPills = Double(boxQuantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let singleDose = Double(doseQuantity.replacingOccurrences(of: ",", with: ".")) ?? 1.0
        let calculatedTotalDoses = totalPills / singleDose

        let sharedMedicineID = UUID()
        let colorHexString = selectedColor.toHex() ?? "#0000FF"

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())

        let durationInDays = calculateDuration() ?? 1

        for dayOffset in 0..<durationInDays {
            guard let dateForDay = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            for time in reminders {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                var finalComponents = calendar.dateComponents([.year, .month, .day], from: dateForDay)
                finalComponents.hour = timeComponents.hour
                finalComponents.minute = timeComponents.minute

                guard let finalDate = calendar.date(from: finalComponents) else { continue }

                let newMedication = Medication(context: viewContext)
                newMedication.id = UUID()
                newMedication.medicineID = sharedMedicineID
                newMedication.name = name
                newMedication.dosage = "\(amount) \(unit) - \(selectedType.rawValue)"
                newMedication.reminderTime = finalDate
                newMedication.startDate = startDate
                newMedication.isTaken = false
                newMedication.totalStock = calculatedTotalDoses
                newMedication.remainingStock = calculatedTotalDoses
                newMedication.singleDoseAmount = singleDose
                newMedication.colorHex = colorHexString

                if dayOffset == 0 {
                    NotificationManager.shared.scheduleNotification(for: newMedication.id!, name: name, time: finalDate)
                }
            }
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}

// MARK: - Updated MedicationTypeCard
// A cleaner, flatter selection card
struct MedicationTypeCard: View {
    let type: MedicationType
    @Binding var selectedType: MedicationType
    var color: Color
    
    var isSelected: Bool { selectedType == type }
    
    var body: some View {
        Button(action: {
            withAnimation(.snappy) { selectedType = type }
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? color : .secondary)
                
                Text(type.localizedTitle)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
