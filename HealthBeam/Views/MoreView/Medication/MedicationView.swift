import SwiftUI
import CoreData

struct MedicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate: Date = Date()
    @State private var showCalendarModal = false
    @AppStorage("userName") private var userName: String = ""
    @State private var showingAddSheet = false
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Medication.reminderTime, ascending: true)])
    private var allMedications: FetchedResults<Medication>
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Professional Solid Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 2. Header with Navigation Controls
                    headerSection
                    
                    // 3. Clean Week Calendar
                    WeekCalendarStrip(selectedDate: $selectedDate)
                        .background(Color(UIColor.systemBackground))
                        .padding(.bottom, 1) // Separator line effect
                    
                    // 4. Medication List
                    FilteredMedicationList(
                        filterDate: selectedDate,
                        allMeds: Array(allMedications),
                        demoMedications: AppReviewManager.shared.isDemoMode ? MockMedicationData.shared.getMockMedications(for: selectedDate) : nil
                    )
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) { AddMedicationView() }
            .sheet(isPresented: $showCalendarModal) {
                calendarModalView
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                // Date Display
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Navigation Buttons (Calendar + Today)
                HStack(spacing: 16) {
                    Button(action: { showCalendarModal = true }) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button("Today") {
                        withAnimation { selectedDate = Date() }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Calendar Modal
    private var calendarModalView: some View {
        VStack {
            // Modal Header
            HStack {
                Text("Select Date")
                    .font(.headline)
                Spacer()
                Button("Close") { showCalendarModal = false }
                    .foregroundColor(.blue)
            }
            .padding()
            
            Divider()
            
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
            
            Button("Go to Date") { showCalendarModal = false }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Filtered List Component
struct FilteredMedicationList: View {
    var filterDate: Date
    var allMeds: [Medication]
    var demoMedications: [Medication]?
    
    @State private var selectedMedication: Medication?
    
    @FetchRequest var filteredMedications: FetchedResults<Medication>
    
    init(filterDate: Date, allMeds: [Medication], demoMedications: [Medication]? = nil) {
        self.filterDate = filterDate
        self.allMeds = allMeds
        self.demoMedications = demoMedications
        
        let start = Calendar.current.startOfDay(for: filterDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        _filteredMedications = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Medication.reminderTime, ascending: true)],
            predicate: NSPredicate(format: "reminderTime >= %@ AND reminderTime < %@", start as NSDate, end as NSDate))
    }
    
    var body: some View {
        let medicationsToShow = demoMedications ?? Array(filteredMedications)
        
        ScrollView {
            VStack(spacing: 16) {
                if medicationsToShow.isEmpty {
                    emptyStateView
                } else {
                    ForEach(medicationsToShow, id: \.id) { medication in
                        SolidMedicationCard(medication: medication)
                            .onTapGesture { selectedMedication = medication }
                    }
                }
            }
            .padding()
            .padding(.bottom, 50)
        }
        .sheet(item: $selectedMedication) { MedicationDetailView(medication: $0) }
    }

    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 50)
            Text("No medications for this day")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Solid Medication Card
// The "Clean & Professional" Card Design
struct SolidMedicationCard: View {
    @ObservedObject var medication: Medication
    
    var body: some View {
        let color = medication.themeColor
        
        HStack(spacing: 15) {
            // 1. Color Strip (Visual Identifier)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 12)
            
            // 2. Icon & Time
            VStack(spacing: 5) {
                Image(systemName: getIcon(for: medication.dosage))
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(medication.reminderTime ?? Date(), style: .time)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // 3. Details
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name ?? String(localized: "Unnamed"))
                    .font(.headline)
                    .foregroundColor(medication.isTaken ? .secondary : .primary)
                    .strikethrough(medication.isTaken)
                
                Text(medication.dosage ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if medication.remainingStock < 5 {
                    Text(String(localized: "Low Stock: \(Int(medication.remainingStock))"))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // 4. Large Check Button
            Button(action: toggleMedication) {
                Image(systemName: medication.isTaken ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(medication.isTaken ? color : .gray.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getIcon(for dosage: String?) -> String {
        guard let text = dosage else { return "pills.fill" }
        if text.contains("Tablet") { return "pills.fill" }
        if text.contains("Capsule") { return "pills.circle.fill" }
        if text.contains("Liquid") { return "drop.fill" }
        if text.contains("Injection") { return "syringe.fill" }
        return "pills.fill"
    }

    // Logic: Updates current dose AND synchronizes stock across all future doses
    private func toggleMedication() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.snappy) {
            let isTaking = !medication.isTaken
            var newStock = medication.remainingStock
            
            if isTaking {
                // Taking pill -> Decrease stock
                if newStock > 0 { newStock -= 1 }
            } else {
                // Unticking -> Restore stock
                if newStock < medication.totalStock { newStock += 1 }
            }

            if let context = medication.managedObjectContext, let groupID = medication.medicineID {
                let request: NSFetchRequest<Medication> = Medication.fetchRequest()
                request.predicate = NSPredicate(format: "medicineID == %@", groupID as CVarArg)
                
                do {
                    let siblings = try context.fetch(request)
                    for med in siblings {
                        med.remainingStock = newStock
                        // Only update 'isTaken' for THIS specific instance
                        if med.id == medication.id {
                            med.isTaken = isTaking
                        }
                    }
                    try context.save()
                } catch {
                    print("Error updating stock: \(error)")
                }
            }
        }
    }
}

// MARK: - Week Calendar Strip
struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    @State private var days: [Date] = []
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 10) {
                    ForEach(days, id: \.self) { date in
                        let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
                        let isToday = Calendar.current.isDateInToday(date)
                        
                        VStack(spacing: 8) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .blue : .secondary)
                            
                            Text(date.formatted(.dateTime.day()))
                                .font(.title3)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? .white : .primary)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? Color.blue : Color.clear)
                                .clipShape(Circle())
                            
                            // Dot indicator for Today
                            if isToday && !isSelected {
                                Circle().fill(Color.blue).frame(width: 4, height: 4)
                            } else {
                                Circle().fill(Color.clear).frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 50, height: 80)
                        .background(Color(UIColor.systemBackground))
                        .onTapGesture {
                            withAnimation { selectedDate = date }
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .onAppear {
                    generateDays(around: selectedDate)
                    // Slight delay to ensure scroll happens after layout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
                .onChange(of: selectedDate) { _, newValue in
                    if !days.contains(where: { Calendar.current.isDate($0, inSameDayAs: newValue) }) {
                        generateDays(around: newValue)
                    }
                    withAnimation { proxy.scrollTo(newValue, anchor: .center) }
                }
            }
        }
    }
    
    func generateDays(around date: Date) {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        days = []
        // Generate previous few days and next 30 days
        if let previous = calendar.date(byAdding: .day, value: -3, to: startOfWeek) {
             for i in 0..<35 {
                 if let d = calendar.date(byAdding: .day, value: i, to: previous) {
                     days.append(d)
                 }
             }
        }
    }
}
// MARK: - Enhanced Background
struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            GeometryReader { proxy in
                // Blobs with increased blur for smoother gradient effect
                Circle()
                    .fill(Color.blue.opacity(0.2)) // Slightly reduced opacity
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -50, y: -100)
                
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: proxy.size.width - 120, y: 300)
                
                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 50, y: proxy.size.height / 2 - 50)
                
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 70)
                    .offset(x: -50, y: proxy.size.height - 200)
            }
        }
    }
}

extension Color {
    static let healthPrimary = Color.blue
    static let healthSecondary = Color.mint
    static let backgroundSoft = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}
