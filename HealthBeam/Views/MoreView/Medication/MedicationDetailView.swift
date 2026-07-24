import SwiftUI
import CoreData
struct MedicationDetailView: View {
    @ObservedObject var medication: Medication
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var totalStock = ""
    @State private var remainingStock = ""
    @State private var reminderTime = Date()
    @State private var doseInfo = ""
    @State private var selectedColor: Color = .blue
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 25) {
                        // Hero
                        VStack(spacing: 15) {
                            ZStack {
                                Circle().fill(selectedColor.opacity(0.15)).frame(width: 100, height: 100).overlay(Circle().stroke(selectedColor.opacity(0.3), lineWidth: 2))
                                Image(systemName: getIcon(for: medication.dosage)).font(.system(size: 45)).foregroundColor(selectedColor).shadow(color: selectedColor.opacity(0.5), radius: 10)
                            }
                            Text("Edit Medication").font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary).textCase(.uppercase)
                        }.padding(.top, 20)
                        
                        // Inventory
                        VStack(spacing: 15) {
                            HStack { Image(systemName: "cube.box.fill").foregroundColor(selectedColor); Text("Inventory Status").font(.headline).foregroundColor(.primary); Spacer() }
                            VStack(spacing: 8) {
                                let current = Double(remainingStock) ?? 0; let total = Double(totalStock) ?? 1
                                let percent = min(max(current / total, 0), 1)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.gray.opacity(0.2))
                                        Capsule().fill(LinearGradient(colors: [percent < 0.2 ? .red : selectedColor, selectedColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * percent)
                                    }
                                }.frame(height: 12)
                                HStack { Text(String(localized: "\(Int(current)) doses left")).font(.caption).bold().foregroundColor(current < 5 ? .red : .primary); Spacer(); Text(String(localized: "Capacity: \(Int(total))")).font(.caption).foregroundColor(.secondary) }
                            }
                            Divider()
                            HStack {
                                VStack(alignment: .leading) { Text("Remaining").font(.caption).foregroundColor(.secondary); TextField("0", text: $remainingStock).font(.title3.bold()).keyboardType(.decimalPad) }
                                Divider().frame(height: 30)
                                VStack(alignment: .leading) { Text("Total Capacity").font(.caption).foregroundColor(.secondary); TextField("0", text: $totalStock).font(.title3.bold()).keyboardType(.decimalPad) }
                            }
                        }.padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(20).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5).padding(.horizontal)
                        
                        // Edit & Color
                        VStack(spacing: 0) {
                            CustomEditRow(icon: "pencil", title: "Name", text: $name, color: selectedColor)
                            Divider().padding(.leading, 50)
                            CustomEditRow(icon: "doc.text", title: "Dosage Info", text: $doseInfo, color: selectedColor)
                            Divider().padding(.leading, 50)
                            HStack { Image(systemName: "paintpalette.fill").foregroundColor(selectedColor).frame(width: 30); Text("Theme Color").fontWeight(.medium).foregroundColor(.primary); Spacer(); ColorPicker("", selection: $selectedColor, supportsOpacity: false).labelsHidden() }.padding()
                            Divider().padding(.leading, 50)
                            HStack { Image(systemName: "clock.fill").foregroundColor(selectedColor).frame(width: 30); Text("Time").fontWeight(.medium).foregroundColor(.primary); Spacer(); DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute).labelsHidden() }.padding()
                        }.background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(20).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5).padding(.horizontal)
                        
                        Button(action: saveChanges) {
                            Text("Update Medication").fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(selectedColor).cornerRadius(15).shadow(color: selectedColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        }.padding(.horizontal).padding(.top, 10)
                        
                        Button(action: { showDeleteAlert = true }) { Text("Delete Medication").font(.footnote).fontWeight(.semibold).foregroundColor(.red) }
                            .padding(.top, 10).padding(.bottom, 30)
                            .alert("Delete Medication", isPresented: $showDeleteAlert) {
                                Button("Delete All Doses", role: .destructive) { deleteMedicationGroup() }
                                Button("Cancel", role: .cancel) { }
                            } message: { Text("This will delete this medication and all its scheduled reminders from your list.") }
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                name = medication.name ?? ""; doseInfo = medication.dosage ?? ""; totalStock = String(format: "%.0f", medication.totalStock); remainingStock = String(format: "%.0f", medication.remainingStock); reminderTime = medication.reminderTime ?? Date(); selectedColor = medication.themeColor
            }
        }
    }
    
    private func saveChanges() {
        let newName = name; let newDosage = doseInfo; let newRemaining = Double(remainingStock) ?? 0; let newTotal = Double(totalStock) ?? 0; let newColorHex = selectedColor.toHex()
        
        medication.name = newName; medication.dosage = newDosage; medication.reminderTime = reminderTime; medication.remainingStock = newRemaining; medication.totalStock = newTotal; medication.colorHex = newColorHex
        
        if let id = medication.id { NotificationManager.shared.cancelNotification(id: id); NotificationManager.shared.scheduleNotification(for: id, name: newName, time: reminderTime) }
        
        if let groupID = medication.medicineID {
            let request: NSFetchRequest<Medication> = Medication.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", groupID as CVarArg)
            do {
                let siblings = try viewContext.fetch(request)
                for med in siblings {
                    med.name = newName; med.dosage = newDosage; med.remainingStock = newRemaining; med.totalStock = newTotal; med.colorHex = newColorHex
                }
            } catch { print("Error: \(error)") }
        }
        try? viewContext.save(); dismiss()
    }
    
    private func deleteMedicationGroup() {
        if let groupID = medication.medicineID {
            let request: NSFetchRequest<Medication> = Medication.fetchRequest(); request.predicate = NSPredicate(format: "medicineID == %@", groupID as CVarArg)
            do {
                let siblings = try viewContext.fetch(request)
                for med in siblings { if let id = med.id { NotificationManager.shared.cancelNotification(id: id) }; viewContext.delete(med) }
                try viewContext.save()
            } catch { print("Error: \(error)") }
        } else { viewContext.delete(medication); try? viewContext.save() }
        dismiss()
    }
    
    private func getIcon(for dosage: String?) -> String {
        guard let text = dosage else { return "pills.fill" }
        for type in MedicationType.allCases { if text.contains(type.rawValue) { return type.icon } }
        return "pills.fill"
    }
}
struct CustomEditRow: View {
    var icon: String; var title: String; @Binding var text: String; var color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) { if !text.isEmpty { Text(title).font(.caption2).foregroundColor(.secondary) }; TextField(title, text: $text).font(.body).foregroundColor(.primary) }
        }.padding()
    }
}
