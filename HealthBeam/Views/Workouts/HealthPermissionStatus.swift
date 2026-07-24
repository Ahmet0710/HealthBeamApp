import SwiftUI
import HealthKit
struct HealthPermissionsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    private func openHealthAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        List {
            // MARK: - İzin Listesi
            Section {
                ForEach(healthKitManager.permissionStatuses) { status in
                    PermissionRow(status: status)
                }
                
                // Eğer liste boşsa gösterilecek uyarı
                if healthKitManager.permissionStatuses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HealthKit is not available or permissions have not been requested yet.")
                            .foregroundColor(.secondary)
                        Button("Request Health Permissions") {
                            Task {
                                try? await healthKitManager.requestAuthorization()
                                await healthKitManager.checkAllPermissionStatuses()
                            }
                        }
                    }
                }
            } header: {
                Text("Health Data Access Status")
            }
            
            // MARK: - Ayarlar Butonu
            Section {
                Button(action: openHealthAppSettings) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.red)
                        Text("Manage Permissions in Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("You can change the access permissions of this application under the Health section in the main iOS Settings application.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Apple Health Sync")
        .task {
            await healthKitManager.checkAllPermissionStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await healthKitManager.checkAllPermissionStatuses()
            }
        }
    }
}
struct PermissionRow: View {
    let status: HealthPermissionStatus
    
    // Sadece "Read" (Okuma) izni olanlar için mantıksal düzeltme
    var isVisuallyAuthorized: Bool {
        // Eğer veritabanından gelen durum zaten Authorized ise true dön
        if status.isAuthorized { return true }
        
        // EĞER: Yetki verilmedi görünüyorsa AMA izin tipi sadece "Read" içeriyorsa
        // Apple "Read" durumunu gizlediği için (privacy), ve bu sadece okuma amaçlı bir veri ise
        // bunu kullanıcıya "Authorized" (Yeşil) gösteriyoruz.
        if status.permissionType.contains("Read") && !status.permissionType.contains("Write") {
            return true
        }
        
        return false
    }
    
    var body: some View {
        HStack {
            // İkon (Tik veya Çarpı)
            Image(systemName: isVisuallyAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isVisuallyAuthorized ? .green : .red)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                // İsim (Düzeltilmiş fonksiyon kullanılıyor)
                Text(getCleanHealthTitle(status.name))
                    .font(.headline)
                
                // Erişim Tipi (Read/Write)
                Text("\(status.permissionType) Access")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Durum Yazısı
            Text(isVisuallyAuthorized ? "Authorized" : "Denied")
                .font(.subheadline.bold())
                .foregroundColor(isVisuallyAuthorized ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    /// HealthKit ham verilerini düzgün isimlere çeviren fonksiyon
    private func getCleanHealthTitle(_ raw: String) -> String {
        switch raw {
        // Tansiyon
        case "Hkbloodpressurediastolic": return "Diastolic Blood Pressure"
        case "Hkbloodpressuresystolic": return "Systolic Blood Pressure"
        
        // Kalp Bildirimleri (Sorunlu olanlar)
        case "Hkhighheartrateevent": return "High Heart Rate Events"
        case "Hkirregularheartrhythmevent": return "Irregular Rhythm Events"
        case "Hklowheartrateevent": return "Low Heart Rate Events"
        case "Hklowcardiofitnessevent": return "Low Cardio Fitness"
        case "Hksleepapneaevent": return "Sleep Apnea Notifications"
        
        // Diğer
        case "A-fib Burden": return "Afib Burden"
        case "Height": return "Height"
        case "Body Mass Index": return "Body Mass Index (BMI)"
        case "Heart Rate": return "Heart Rate"
        case "Step Count": return "Step Count"
        case "Active Energy Burned": return "Active Energy"
        case "Basal Energy Burned": return "Resting Energy"
            
        default:
            return raw.replacingOccurrences(of: "Hk", with: "").capitalized
        }
    }
}
