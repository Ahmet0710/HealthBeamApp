// MARK: - SettingsView.swift
import SwiftUI
import PhotosUI
import HealthKit
import UIKit
import Combine
import UserNotifications
import AuthenticationServices
import FirebaseCore
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CryptoKit
struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var measurementSystemManager: MeasurementSystemManager
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var accountManager: AccountManager
    
    @StateObject private var privacyViewModel = PrivacySecurityViewModel()
    
    @State private var showingEditProfile = false
    @State private var showEmailSignInSheet = false
    @State private var showingRecoveryCodes = false
    @State private var codesToView: [String]? = nil
    @State private var showingRevokeAlert = false
    @State private var showingAboutDeveloperSheet = false
    @State private var needsReload = false
    @State private var showDeleteAccountAlert = false
    @State private var deletionError: String? = nil
    @State private var deletionSuccess: Bool = false
    @State private var showingAccountRecovery = false
    @State private var showLoginSheet = false

    private var isEmailPasswordUser: Bool {
        return Auth.auth().currentUser?.providerData.contains {
            $0.providerID == "password" || $0.providerID == "email"
        } ?? false
    }

    private var passwordButtonTitle: String {
        if isEmailPasswordUser {
            return String(localized: "Change Password")
        } else {
            return privacyViewModel.isPasswordSetServer
                ? String(localized: "Change Password")
                : String(localized: "Create Password")
        }
    }
    
    private var isUserSignedIn: Bool {
        appleSignInManager.isSignedIn || (Auth.auth().currentUser != nil)
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var allHealthPermissionsGranted: Bool {
        let store = healthKitManager.healthStore

        var types: [HKObjectType] = []

        if let afib = HKObjectType.quantityType(forIdentifier: .atrialFibrillationBurden) {
            types.append(afib)
        }
        // ECG (non-optional)
        types.append(HKObjectType.electrocardiogramType())

        if let highHR = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent) {
            types.append(highHR)
        }
        if let lowHR = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent) {
            types.append(lowHR)
        }
        if let irregular = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent) {
            types.append(irregular)
        }
        if let lowCardio = HKObjectType.categoryType(forIdentifier: .lowCardioFitnessEvent) {
            types.append(lowCardio)
        }
        // Sleep apnea notifications: prefer canonical identifier if available, otherwise leave out
        if let sleepApnea = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: "HKCategoryTypeIdentifierSleepApneaEvent")) {
            types.append(sleepApnea)
        }

        // If no specific types are available on this device, consider not granted
        if types.isEmpty { return false }

        // Require every type to be explicitly authorized
        for type in types {
            let status = store.authorizationStatus(for: type)
            if type.identifier.contains("Event") || type is HKElectrocardiogramType {
                if status == .notDetermined { return false }
            } else {
                if status != .sharingAuthorized { return false }
            }
            
            if status != .sharingAuthorized {
                return false
            }
        }
        return true
    }
    
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 44) {
                    if AppReviewManager.shared.isDemoMode {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Reviewer Access Active")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Demo data is being shown for app evaluation.")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.8))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                            )
                                            .padding(.bottom, -20) // Altındaki profileCard ile arasını daraltır
                                        }
                    profileCard
                    healthDataCard
                    privacyCard
                    notificationCard
                    preferencesCard
                    helpCard
                    deleteAccountCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .id(needsReload)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView()
                    .environmentObject(appleSignInManager)
            }
            .sheet(isPresented: $showEmailSignInSheet) {
                EmailSignInView()
                    .environmentObject(accountManager)
            }
            .sheet(isPresented: $privacyViewModel.showingChangePasswordSheet, onDismiss: {
                privacyViewModel.refreshServerPasswordState(using: appleSignInManager)
            }) {
                ChangePasswordView(viewModel: privacyViewModel)
                    .environmentObject(appleSignInManager)
            }
            .sheet(isPresented: $privacyViewModel.showingRecoveryCodeSetup) {
                RecoveryCodeSetupView(viewModel: privacyViewModel)
            }
            .sheet(isPresented: $showingRecoveryCodes) {
                if let codes = codesToView {
                    ViewRecoveryCodesView(codes: codes)
                }
            }
            .sheet(isPresented: $showingAboutDeveloperSheet) {
                AboutDeveloperSheet()
            }
            .sheet(isPresented: $showingAccountRecovery, onDismiss: {
                privacyViewModel.refreshServerPasswordState(using: appleSignInManager)
            }) {
                AccountRecoveryFlowView()
                    .environmentObject(appleSignInManager)
            }
            .sheet(isPresented: $showLoginSheet) {
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Text("Log in to Healthbeam")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    SwiftUISignInWithAppleButton()
                        .environmentObject(appleSignInManager)
                        .frame(maxWidth: 450, minHeight: 44)
                        .padding(.horizontal, 20)
                    Button(action: {
                        showLoginSheet = false
                        showEmailSignInSheet = true
                    }) {
                        Text("Log in with Email")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: 300, minHeight: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .presentationDetents([.fraction(0.35)])
                .presentationBackground(.thinMaterial)
                .presentationDragIndicator(.visible)
            }
            
            .alert("To remove Apple Health permissions", isPresented: $showingRevokeAlert, actions: {
                Button("Go to Settings", action: openAppSettings)
                Button("Dismiss", role: .cancel) {}
            }, message: {
                Text("To disable Apple Health permissions, you need to use the Settings app.")
            })
            .alert("Success", isPresented: .constant(privacyViewModel.successMessage != nil), actions: {
                Button("Awesome!", role: .cancel) { privacyViewModel.clearMessages() }
            }, message: { Text(privacyViewModel.successMessage ?? "") })
            .alert("Error", isPresented: .constant(privacyViewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { privacyViewModel.clearMessages() }
            }, message: { Text(privacyViewModel.errorMessage ?? "") })
            
            .alert("Are you sure you want to request account deletion?", isPresented: $showDeleteAccountAlert, actions: {
                Button("Request Deletion", role: .destructive) {
                    Task {
                        do {
                            try await appleSignInManager.requestAccountDeletion()
                            deletionSuccess = true
                        } catch {
                            deletionError = error.localizedDescription
                        }
                    }
                }
                Button("Dismiss", role: .cancel) { }
            })
            .alert("Account deletion error", isPresented: Binding(get: { deletionError != nil }, set: { _ in deletionError = nil }), actions: {
                Button("OK", role: .cancel) { deletionError = nil }
            }, message: { Text(deletionError ?? "") })
            .alert("Deletion Request Received", isPresented: $deletionSuccess, actions: {
                Button("OK", role: .cancel) { deletionSuccess = false }
            },message: {
                Text("Your account deletion request has been successfully submitted. Your account and data will be permanently deleted by our team shortly. You have been logged out.")
            })
            .onAppear {
                healthKitManager.checkAuthorizationStatus()
                appleSignInManager.fetchUserNameFromFirestore()
                if let user = Auth.auth().currentUser, appleSignInManager.userProfileImage == nil {
                    if let loadedImage = appleSignInManager.loadProfileImageLocally(for: user.uid) {
                        appleSignInManager.userProfileImage = loadedImage
                    }
                }
                privacyViewModel.refreshServerPasswordState(using: appleSignInManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                healthKitManager.checkAuthorizationStatus()
            }
            .onChange(of: appleSignInManager.isSignedIn) { _, newValue in
                if newValue {
                    appleSignInManager.fetchUserNameFromFirestore()
                    if let user = Auth.auth().currentUser {
                        if let loadedImage = appleSignInManager.loadProfileImageLocally(for: user.uid) {
                            appleSignInManager.userProfileImage = loadedImage
                        }
                    }
                }
            }
        }
    }

    private var profileCard: some View {
        PremiumCard(title: "Profile", systemImage: "person.fill") {
            let signedIn = appleSignInManager.isSignedIn || (Auth.auth().currentUser != nil)
            let displayName = appleSignInManager.userFullName ?? Auth.auth().currentUser?.displayName ?? String(localized: "Guest")
            let displayEmail = appleSignInManager.userEmail ?? Auth.auth().currentUser?.email ?? String(localized: "Sign in HealthBeam")
            ProfilePlatinumCard(
                name: displayName,
                email: displayEmail,
                measurementSystem: measurementSystemManager.measurementSystem,
                image: appleSignInManager.userProfileImage,
                isSignedIn: signedIn,
                onSignIn: { showLoginSheet = true },
                onEdit: { showingEditProfile = true }
            )
        }
    }
    
    private var healthDataCard: some View {
            PremiumCard(title: String(localized: "Health Permissions"), systemImage: "heart.rectangle.fill") {
                HStack(spacing: 12) {
                    PremiumRow(title: String(localized: "Manage Permissions"), icon: "lock.shield") { openAppSettings() }

              //       Image(systemName: allHealthPermissionsGranted ? "checkmark.shield.fill" : "shield.slash.fill")
              //          .resizable().scaledToFit().frame(width: 22, height: 22).foregroundStyle(.white.opacity(0.9))
              //      Text("Sync with Apple Health").font(.headline).foregroundStyle(.white)
              //      Spacer()
              //      NavigationLink(destination: HealthPermissionsView()) {
              //          Image(systemName: "chevron.right").font(.headline.weight(.semibold)).foregroundStyle(.white.opacity(0.5))
              //      }
              //       .buttonStyle(.plain)
                }
              //  .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                
              //  Divider().background(Palette.divider)
            }

         }
    private var privacyCard: some View {
            PremiumCard(title: String(localized: "Privacy & Security"), systemImage: "shield.lefthalf.fill") {
                if isUserSignedIn {
                    if privacyViewModel.twoFAOn {
                        PremiumToggleRow(title: String(localized: "Two Factor Authentication (2FA)"), isOn: Binding(
                            get: { privacyViewModel.twoFAOn },
                            set: { newValue in Task { await privacyViewModel.handle2FAToggle(isOn: newValue) } }
                        ))
                        PremiumRow(title: String(localized: "Show Recovery Codes"), icon: "text.book.closed.fill") {
                            Task {
                                if let fetchedCodes = await privacyViewModel.fetchAndVerifyRecoveryCodes() {
                                    self.codesToView = fetchedCodes
                                    self.showingRecoveryCodes = true
                                }
                            }
                        }
                    } else {
                        PremiumRow(title: String(localized: "Enable Two Factor Authentication"), icon: "lock.shield.fill") {
                            Task { await privacyViewModel.handle2FAToggle(isOn: true) }
                        }
                    }
                    
                    Divider().background(Palette.divider)
                    if let _ = Auth.auth().currentUser {
                        PremiumRow(title: passwordButtonTitle, icon: "key.fill") {
                            privacyViewModel.refreshServerPasswordState(using: appleSignInManager)
                            privacyViewModel.showingChangePasswordSheet = true
                        }
                        Divider().background(Palette.divider)
                    }
                }
                if !isUserSignedIn {
                    PremiumRow(title: String(localized: "Account Recovery"), icon: "key.icloud") {
                        showingAccountRecovery = true
                    }
                }
            }
        }
        private var notificationCard: some View {
            PremiumCard(title: String(localized: "Notifications") , systemImage: "bell.badge.fill") {
                PremiumRow(title: String(localized: "Go to Notification Settings") , icon: "bell.badge.fill") { openAppSettings() }
            }
        }
        private var preferencesCard: some View {
            PremiumCard(title: String(localized: "App Preferences") , systemImage: "gearshape.2.fill") {
                PremiumPickerRow<MeasurementSystem>(
                    title: String(localized: "Units"),
                    selection: Binding(
                        get: { measurementSystemManager.measurementSystem },
                        set: { newSelectedSystem in
                            measurementSystemManager.setSystem(newSelectedSystem)
                        }
                    )
                )
                Divider().background(Palette.divider)
                PremiumRow(title: String(localized: "Languages") , icon: "globe") { openAppSettings() }
            }
        }
        private var helpCard: some View {
            PremiumCard(title: String(localized: "Help & About"), systemImage: "questionmark.circle.fill") {
                VersionRow(appName: String(localized: "HealthBeam"), version: "v.\(currentAppVersion)")
                Divider().background(Palette.divider)
                PremiumRow(title: String(localized: "About Developer"), icon: "person.crop.circle.badge.checkmark") {
                    showingAboutDeveloperSheet = true
                }
            }
        }
        private var deleteAccountCard: some View {
                if Auth.auth().currentUser == nil { return AnyView(EmptyView()) }
                return AnyView(
                    PremiumCardBase {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.gray.opacity(0.7))
                                Text("Delete Account")
                                    .font(.headline)
                                    .foregroundColor(.gray.opacity(0.75))
                            }
                            Text("Touch this card to delete all your account and data. This action cannot be undone.")
                                .font(.callout)
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 2)
                            Button(action: { showDeleteAccountAlert = true }) {
                                Text("Delete my account permanently")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.gray.opacity(0.78))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.gray.opacity(0.09))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        }
                        .padding(.vertical, 4)
                    }
                )
            }
        }
struct AboutDeveloperSheet: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Image("Ahmet.jpeg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(radius: 10, y: 3)
                    Spacer()
                }
                Text("Ahmet Furkan Yıldırım")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Text("Healthbeam aims to help people lead a more conscious, balanced, and healthy life by bringing together technology and health.")
                    .foregroundColor(.white.opacity(0.98))
                    .multilineTextAlignment(.leading)
                Text("The application was designed and developed by Ahmet Furkan Yıldırım. It offers artificial intelligence-supported analyses that make it easy to interpret health data, as well as personal recommendations and a modern user experience.")
                    .foregroundColor(.white.opacity(0.98))
                    .multilineTextAlignment(.leading)
                Text("The main goal of Healthbeam is not just a tracking application, but also to be an intelligent health assistant that guides the user's daily life. Ahmet Furkan has put in a great deal of effort in creating this amazing application and is waiting for your help.")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
        .background(Palette.background.ignoresSafeArea())
    }
}
struct ProfilePlatinumCard: View {
    var name: String
    var email: String
    var measurementSystem: MeasurementSystem
    var image: UIImage?
    var isSignedIn: Bool
    var onSignIn: () -> Void
    var onEdit: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.avatarGlowGradient)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle()
                            .stroke(Palette.platinumStroke, lineWidth: 1)
                            .blendMode(.plusLighter)
                    )
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Palette.platinumStroke, lineWidth: 1)
                                .blendMode(.plusLighter)
                        )
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(email)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .layoutPriority(1)
                if !isSignedIn {
                    Button(action: onSignIn) {
                        Text(" Log in ")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.92))
                            .padding(.horizontal, 60)
                            .padding(.vertical,4)
                    }
                    .buttonStyle(PlatinumPremiumButtonStyle())
                } else {
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.92))
                            .padding(.horizontal, 58)
                            .padding(.vertical,4)
                    }
                    .buttonStyle(PlatinumPremiumButtonStyle())
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}
struct PremiumCard<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: Content
    var body: some View {
        PremiumCardBase {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(Palette.accent)
                        .frame(minWidth: 22)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }
                content
            }
        }
    }
}
struct PremiumCardBase<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.cardGradient)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Palette.cardStroke, lineWidth: 1)
                .blendMode(.plusLighter)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.12), .clear],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5)
                .blendMode(.screen)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .shadow(color: Palette.cardShadow1, radius: 14, x: 0, y: 8)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .opacity(0)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .shadow(color: Palette.cardShadow2, radius: 14, x: 0, y: 8)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .opacity(0)
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(20)
        }
        .clipped()
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
struct PremiumRow: View {
    var title: String
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.white.opacity(0.9))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
struct PremiumToggleRow: View {
    var title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOn ? "checkmark.shield.fill" : "shield.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(.white.opacity(0.9))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 205/255, green: 206/255, blue: 210/255)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}
protocol PremiumPickable {
    var title: String { get }
}
struct PremiumPickerRow<T: PremiumPickable>: View where T: CaseIterable & Hashable {
    var title: String
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dial.low.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(.white.opacity(0.9))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}
struct RingMetric: View {
    var title: String
    var valueText: String
    var progress: Double
    var icon: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Palette.ringBackground, lineWidth: 10)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: progress.clamped)
                    .stroke(Palette.ringGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                    .animation(.easeOut(duration: 0.8), value: progress)
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Text(valueText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
struct PremiumBadge: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .foregroundStyle(Palette.badgeText)
            .background(
                Capsule()
                    .fill(Palette.badgeGradient)
                    .overlay(
                        Capsule()
                            .stroke(Palette.badgeStroke, lineWidth: 0.8)
                            .blendMode(.plusLighter)
                    )
            )
    }
}
struct PremiumCapsuleButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .foregroundStyle(.white)
                .background(
                    Capsule().fill(Palette.capsuleGradient)
                        .contentShape(Capsule())
                )
        }
        .buttonStyle(.plain)
    }
}
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.black.opacity(0.95))
            .background(Palette.buttonGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Palette.buttonStroke, lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
struct PremiumButtonStyleOutline: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(Palette.accent.opacity(0.9), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
struct PremiumButtonStyleGhost: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.white.opacity(0.9))
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.06)))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
struct VersionRow: View {
    var appName: String
    var version: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 0) {
                Text(appName)
                Text(" Version")
            }
            .font(.headline)
            .foregroundStyle(.white)
            Spacer()
            Text(version)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
enum Palette {
    static let background = LinearGradient(colors: [Color(red: 14/255, green: 16/255, blue: 21/255),
                                                    Color(red: 9/255, green: 10/255, blue: 14/255)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGradient = LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardStroke = LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.12)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardShadow1 = Color.black.opacity(0.35)
    static let cardShadow2 = Color.black.opacity(0.25)
    static let accent = LinearGradient(colors: [Color(red: 205/255, green: 206/255, blue: 210/255),
                                                Color(red: 160/255, green: 161/255, blue: 166/255)],
                                       startPoint: .top, endPoint: .bottom)
    static let divider = Color.white.opacity(0.08)
    static let ringBackground = Color.white.opacity(0.12)
    static let ringGradient = AngularGradient(gradient: Gradient(colors: [Color(red: 220/255, green: 221/255, blue: 224/255),
                                                                          Color(red: 180/255, green: 181/255, blue: 186/255),
                                                                          Color(red: 220/255, green: 221/255, blue: 224/255)]),
                                              center: .center)
    static let avatarGlowGradient = LinearGradient(colors: [Color(red: 180/255, green: 181/255, blue: 186/255).opacity(0.35),
                                                            Color(red: 120/255, green: 121/255, blue: 128/255).opacity(0.25)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
    static let platinumStroke = LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.1)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
    static let platinumShadow = Color.white.opacity(0.15)
    static let badgeGradient = LinearGradient(colors: [Color.white.opacity(0.95),
                                                       Color(red: 215/255, green: 216/255, blue: 220/255)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing)
    static let badgeStroke = Color.white.opacity(0.3)
    static let badgeText = Color.black.opacity(0.85)
    static let capsuleGradient = LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing)
    static let buttonGradient = LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                               startPoint: .top, endPoint: .bottom)
    static let buttonStroke = Color.white.opacity(0.2)
    static let platinumButtonGradient = LinearGradient(
        colors: [
            Color(red: 150/255, green: 150/255, blue: 150/255, opacity: 0.9),
            Color(red: 200/255, green: 200/255, blue: 200/255, opacity: 0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
enum WeightUnit: String, CaseIterable, PremiumPickable {
    case kg, lb
    var title: String { rawValue.uppercased() }
}
extension Double {
    var clamped: Double { min(max(self, 0), 1) }
}
struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
struct ProfileEditView: View {
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Erkek", female = "Kadın", other = "Diğer"
        var id: String { rawValue }
        var title: String { rawValue }
    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var gender: Gender? = nil
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var healthWeightUnit: WeightUnit = .kg
    @State private var selectedImage: UIImage? = nil
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showSaveError: Bool = false
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    Text("Edit Profile")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    PremiumCardBase {
                        VStack(spacing: 22) {
                            ZStack {
                                Circle()
                                    .fill(Palette.avatarGlowGradient)
                                    .frame(width: 86, height: 86)
                                    .overlay(
                                        Circle()
                                            .stroke(Palette.platinumStroke, lineWidth: 1)
                                            .blendMode(.plusLighter)
                                    )
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Palette.platinumStroke, lineWidth: 1)
                                                .blendMode(.plusLighter)
                                        )
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                }
                            }
                            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                                Text("Select Photo")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.white.opacity(0.09))
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                                    .padding(.top, 3)
                            }
                            .onChange(of: photoItem) { _, newItem in
                                guard let item = newItem else { return }
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) {
                                        selectedImage = img
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Name Surname")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("Enter your name", text: $name)
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Palette.cardStroke, lineWidth: 1)
                                    )
                                Text("Email")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("Enter your email address", text: $email)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Palette.cardStroke, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(8)
                    }

                    if showSaveError {
                        Text("Name and Email cannot be empty.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                    }

                    PremiumCardBase {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Health Information")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                            Group {
                                Text("Age")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("Enter your age", text: $age)
                                    .keyboardType(.numberPad)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.cardStroke, lineWidth: 1))
                                Text("Gender")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Picker("Gender", selection: $gender) {
                                    ForEach(Gender.allCases) { g in
                                        Text(g.title).tag(g)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.vertical, 2)
                                Text("Height (cm)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                TextField("Enter your height ", text: $height)
                                    .keyboardType(.decimalPad)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.cardStroke, lineWidth: 1))
                                Text("Weight")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                HStack(spacing: 10) {
                                    TextField("Enter your weight", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.cardStroke, lineWidth: 1))
                                    Picker("Unit", selection: $healthWeightUnit) {
                                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                                            Text(unit.title).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 84)
                                    .tint(Palette.accent)
                                }
                            }
                        }
                        .padding(8)
                    }

                    Spacer()

                    Button {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            showSaveError = true
                            return
                        }
                        showSaveError = false
                        appleSignInManager.updateUserProfile(name: name, email: email, image: selectedImage)
                        if let user = Auth.auth().currentUser {
                            appleSignInManager.userProfileImage = appleSignInManager.loadProfileImageLocally(for: user.uid)
                        }
                        self.saveHealthDetailsToDefaults()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .padding(.horizontal, 20)

                    Button {
                        appleSignInManager.signOut()
                        selectedImage = nil
                        dismiss()
                    } label: {
                        Text("Log out")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .onAppear {
            loadProfileFromManager()
            selectedImage = appleSignInManager.userProfileImage
            if selectedImage == nil, let user = Auth.auth().currentUser {
                if let loadedImage = appleSignInManager.loadProfileImageLocally(for: user.uid) {
                    selectedImage = loadedImage
                    appleSignInManager.userProfileImage = loadedImage
                }
            }
        }
    }
}
extension ProfileEditView {
    func loadProfileFromManager() {
        self.name = appleSignInManager.userFullName ?? ""
        self.email = appleSignInManager.userEmail ?? ""
    }

    func saveHealthDetailsToDefaults() {
    }
}
struct ViewRecoveryCodesView: View {
    let codes: [String]
    var body: some View {
        VStack(spacing: 16) {
            Text("Recovery Codes")
                .font(.title2.bold())
            ForEach(codes, id: \.self) { code in
                Text(code).font(.body.monospaced())
            }
        }
        .padding()
    }
}
struct HealthKitPermissionsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    var body: some View {
        VStack(spacing: 14) {
            Text("HealthKit Permissions")
                .font(.title.bold())
            if healthKitManager.isAuthorized {
                Text("Apple Health permissions are granted.")
            } else {
                Text("Apple Health permissions are missing.")
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Close") { isPresented = false }
        }
        .padding()
    }
}
struct ChangePasswordView: View {
    @ObservedObject var viewModel: PrivacySecurityViewModel
    @EnvironmentObject var appleSignInManager: AppleSignInManager

    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @FocusState private var focusedField: Field?
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var isLoading: Bool = false

    enum Field: Hashable {
        case old, new, confirm
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.isPasswordSetServer ? "Change Password" : "Create Password")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.top, 10)

            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            if let success = successMessage {
                Text(success)
                    .font(.subheadline).foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                if viewModel.isPasswordSetServer {
                    SecureField("Current Password", text: $oldPassword)
                        .focused($focusedField, equals: .old)
                        .textContentType(.password)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.09)))
                }
                
                SecureField("New password", text: $newPassword)
                    .focused($focusedField, equals: .new)
                    .textContentType(.newPassword)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.09)))
                
                SecureField("New Password (Again)", text: $confirmPassword)
                    .focused($focusedField, equals: .confirm)
                    .textContentType(.newPassword)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.09)))
            }
            .padding(.top, 10)

            Button(action: onSave) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(viewModel.isPasswordSetServer ? "Change Password" : "Create Password")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PremiumButtonStyle())
            .padding(.top, 10)
            .disabled(isLoading)

            Button("Dismiss") {
                viewModel.showingChangePasswordSheet = false
                clearMessages()
            }
            .foregroundColor(.secondary)
            .padding(.top, 2)
            Spacer()
        }
        .padding(24)
        .background(Palette.background.ignoresSafeArea())
        .onAppear {
            oldPassword = ""
            newPassword = ""
            confirmPassword = ""
            clearMessages()
            focusedField = viewModel.isPasswordSetServer ? .old : .new
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func onSave() {
        clearMessages()
        
        if viewModel.isPasswordSetServer && oldPassword.isEmpty {
            errorMessage = "Current password cannot be empty."
            return
        }
        
        guard !newPassword.isEmpty, newPassword == confirmPassword else {
            errorMessage = NSLocalizedString("passwords are not matched or empty.", comment:"")
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = NSLocalizedString("Password must be at least 6 characters.", comment:"")
            return
        }
        
        isLoading = true
        Task {
            guard let user = Auth.auth().currentUser else {
                errorMessage = "Could not verify user session."
                isLoading = false
                return
            }
            
            do {
                if viewModel.isPasswordSetServer {
                    guard let email = user.email else {
                        errorMessage = "User email not found for re-authentication."
                        throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email required for re-auth."])
                    }
                    
                    let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
                    try await user.reauthenticate(with: credential)
                    
                    try await user.updatePassword(to: newPassword)
                    successMessage = NSLocalizedString("Password has been successfully changed.", comment:"")
                    
                } else {
                    _ = try await user.getIDTokenResult(forcingRefresh: true)
                    try await user.updatePassword(to: newPassword)
                    successMessage = NSLocalizedString("Password has been successfully created.", comment:"")
                }
                
                viewModel.refreshServerPasswordState(using: appleSignInManager)
                oldPassword = ""
                newPassword = ""
                confirmPassword = ""
                viewModel.clearMessages()
                
            } catch let error as NSError where error.code == AuthErrorCode.wrongPassword.rawValue {
                errorMessage = NSLocalizedString("Current password is incorrect.", comment:"")
            } catch let error as NSError where error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                errorMessage = "This action is sensitive and requires recent login. Please try logging out and signing in again with Apple."
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}
struct PlatinumPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 210/255, green: 212/255, blue: 220/255),
                        Color(red: 170/255, green: 175/255, blue: 182/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                    .blendMode(.plusLighter)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.white.opacity(0.20), radius: 8, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.13), value: configuration.isPressed)
    }
}
extension HKObjectType {
    var displayName: String {
        if let qt = self as? HKQuantityType {
            switch qt.identifier {
            case HKQuantityTypeIdentifier.height.rawValue: return "Height" // Boy
            case HKQuantityTypeIdentifier.bodyMass.rawValue: return "Weight" // Kilo
            case HKQuantityTypeIdentifier.bodyMassIndex.rawValue: return "Body Mass Index (BMI)"
            case HKQuantityTypeIdentifier.bodyFatPercentage.rawValue: return "Body Fat Percentage"
            case HKQuantityTypeIdentifier.leanBodyMass.rawValue: return "Lean Body Mass"
            case HKQuantityTypeIdentifier.height.rawValue: return "Weight"
            case HKQuantityTypeIdentifier.bodyMass.rawValue: return "Weight"
            case HKQuantityTypeIdentifier.bodyFatPercentage.rawValue: return "body Fat Percentage"
            case HKQuantityTypeIdentifier.bodyMassIndex.rawValue: return "Body Mass Index"
            case HKQuantityTypeIdentifier.leanBodyMass.rawValue: return "Yağsız Vücut Kütlesi"
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue: return "Active Energy Burned"
            case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: return "Basal Energy Burned"
            case HKQuantityTypeIdentifier.appleExerciseTime.rawValue: return "Exercise Time"
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: return "Distance of Walking and Running"
            case HKQuantityTypeIdentifier.stepCount.rawValue: return "Steps"
            case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue: return "Energy Consumed"
            case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue: return "Carbohydrates"
            case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue: return "Fat Total"
            case HKQuantityTypeIdentifier.dietaryProtein.rawValue: return "Protein"
            case HKQuantityTypeIdentifier.dietarySugar.rawValue: return "Sugar"
            case HKQuantityTypeIdentifier.dietaryWater.rawValue: return "Water"
            case HKQuantityTypeIdentifier.heartRate.rawValue: return "Heart Rate"
            case HKQuantityTypeIdentifier.restingHeartRate.rawValue: return "Resting Heart Rate"
            case HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue: return "Walking HeartRate Average"
            case HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue: return "Diastolic Blood Pressure"
            case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue: return "Systolic Blood Pressure"
            case HKQuantityTypeIdentifier.heartRate.rawValue: return "Heart Rate"
            case HKQuantityTypeIdentifier.restingHeartRate.rawValue: return "Resting Heart Rate"
            case HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue: return "Walking Heart Rate Avg"
            case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue: return "Heart Rate Variability (HRV)"
            case HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue: return "Afib Burden"
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue: return "Oxygen Saturation"
                
            // Aktivite ve Enerji
            case HKQuantityTypeIdentifier.stepCount.rawValue: return "Step Count"
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: return "Walking/Running Distance"
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue: return "Active Energy"
            case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: return "Resting Energy"
            case HKQuantityTypeIdentifier.appleExerciseTime.rawValue: return "Exercise Time"
            case HKQuantityTypeIdentifier.flightsClimbed.rawValue: return "Flights Climbed"
                
            // Beslenme
            case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue: return "Calories Consumed"
            case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue: return "Carbohydrates"
            case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue: return "Total Fat"
            case HKQuantityTypeIdentifier.dietaryProtein.rawValue: return "Protein"
            case HKQuantityTypeIdentifier.dietarySugar.rawValue: return "Sugar"
            case HKQuantityTypeIdentifier.dietaryWater.rawValue: return "Water"
            case HKQuantityTypeIdentifier.dietaryCaffeine.rawValue: return "Caffeine"
            case HKQuantityTypeIdentifier.bodyTemperature.rawValue: return "Body Temperature"
            case HKQuantityTypeIdentifier.respiratoryRate.rawValue: return "Respiratory Rate"
            default: return qt.identifier
            }
        }
        if self is HKElectrocardiogramType {
            return "ECG"
        }
        if let ct = self as? HKCategoryType {
            switch ct.identifier {
            case HKCategoryTypeIdentifier.sleepAnalysis.rawValue: return "Sleep Analysis"
            case HKCategoryTypeIdentifier.highHeartRateEvent.rawValue: return "High Heart Rate Events"
            case HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue: return "Low Heart Rate Events"
            case HKCategoryTypeIdentifier.irregularHeartRhythmEvent.rawValue: return "Irregular Rhythm Events"
            case HKCategoryTypeIdentifier.lowCardioFitnessEvent.rawValue: return "Low Cardio Fitness"
            case "HKCategoryTypeIdentifierSleepApneaEvent": return "Sleep Apnea Notifications"
            case HKCategoryTypeIdentifier.mindfulSession.rawValue: return "Mindfulness Minutes"
            case HKCategoryTypeIdentifier.sexualActivity.rawValue: return "Sexual Activity"
            default:
                if ct.identifier == "Hksleepapneaevent" || ct.identifier.contains("sleepapnea") {
                    return "Sleep Apnea Notifications"
                }
                return ct.identifier
            }
        }
        if self is HKWorkoutType { return "Workouts" }
        if let ch = self as? HKCharacteristicType {
            switch ch.identifier {
            case HKCharacteristicTypeIdentifier.biologicalSex.rawValue: return "Biological Sex"
            case HKCharacteristicTypeIdentifier.dateOfBirth.rawValue: return "Date of Birth"
            case HKCharacteristicTypeIdentifier.bloodType.rawValue: return "Blood Type"
            case HKCharacteristicTypeIdentifier.fitzpatrickSkinType.rawValue: return "Skin Type"
            case HKCharacteristicTypeIdentifier.biologicalSex.rawValue: return "Gender"
            case HKCharacteristicTypeIdentifier.dateOfBirth.rawValue: return "Date Of Birth"
            default: return ch.identifier
            }
        }
        return "Health Data"
    }
}
