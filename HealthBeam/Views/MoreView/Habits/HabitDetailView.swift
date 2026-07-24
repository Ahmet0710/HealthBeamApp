import SwiftUI

struct HabitDetailView: View {
    @State private var habit: Habit
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmAlert = false

    var onUpdate: (Habit) -> Void
    var onDelete: (Habit) -> Void

    private var formattedTime: String {
        let calendar = Calendar.current
        if let date = calendar.date(from: habit.time) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return ""
    }
    init(habit: Habit, onUpdate: @escaping (Habit) -> Void, onDelete: @escaping (Habit) -> Void) {
        _habit = State(initialValue: habit)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [habit.colorValue.opacity(0.85), .black.opacity(0.85)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: habit.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .padding()
                    .background(habit.colorValue.opacity(0.2))
                    .clipShape(Circle())
                    .foregroundColor(.white)
                Text(habit.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text(habit.localizedCategory)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(habit.colorValue.opacity(0.8))
                    .clipShape(Capsule())
                    .foregroundColor(.white)

                if !formattedTime.isEmpty {
                    Label(formattedTime, systemImage: "clock")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                Label(String(localized: "Streak: \(habit.streak)"), systemImage: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            AddHabitSheet(habit: habit, onSave: { name, icon, color, time, category in
                habit.name = name
                habit.icon = icon
                habit.color = color
                habit.time = time
                habit.category = category
                onUpdate(habit)
                isEditing = false
            }, onDelete: {
                onDelete(habit)
                isEditing = false
            })
        }
        .alert("Are you sure you want to delete this habit?", isPresented: $showDeleteAlert, actions: {
            Button("Delete", role: .destructive) {
                onDelete(habit)
            }
            Button("Cancel", role: .cancel) {}
        })
    }
}
