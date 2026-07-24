import CoreData
struct PersistenceController {
    static let shared = PersistenceController()

    // Preview (Önizleme) modunda çökmemesi için sahte veri
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Önizleme için örnek bir veri ekleyelim
        let newMedication = Medication(context: viewContext)
        newMedication.id = UUID()
        newMedication.name = "Örnek İlaç"
        newMedication.dosage = "1 Tablet"
        newMedication.reminderTime = Date()
        newMedication.isTaken = false
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // BURASI ÇOK ÖNEMLİ: Parantez içindeki isim .xcdatamodeld dosyanla AYNI olmalı
        container = NSPersistentContainer(name: "HealthBeam") 
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
