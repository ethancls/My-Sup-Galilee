import SwiftUI
import Foundation
import PhotosUI
import Charts
import PDFKit
import WebKit
import UserNotifications
import AuthenticationServices
import EventKit
import AVFoundation
import Photos

// MARK: - Data Models
import Foundation

struct UserData: Codable {
    var firstName: String
    var lastName: String
    var student_number: String
    var formation: String
    var username: String    // Nouveau champ
    var password: String    // Nouveau champ pour le mot de passe
    var profileImageData: Data?
    var studentIDCardImageData: Data?
    var notificationsEnabled: Bool
    var icsLink: String?    // Nouveau champ pour le lien ICS
    
    func save() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(student_number, forKey: "student_number")
        UserDefaults.standard.set(formation, forKey: "formation")
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(password, forKey: "password")
        UserDefaults.standard
            .set(icsLink, forKey: "icsLink")    // Enregistrement du lien ICS
        UserDefaults.standard
            .set(notificationsEnabled, forKey: "notificationsEnabled")
        if let imageData = profileImageData {
            UserDefaults.standard.set(imageData, forKey: "profileImageData")
        }
        if let profileImageData = studentIDCardImageData {
            UserDefaults.standard
                .set(profileImageData, forKey: "studentIDCardImageData")
        }
    }
    
    static func load() -> UserData? {
        guard let firstName = UserDefaults.standard.string(forKey: "firstName"),
              let lastName = UserDefaults.standard.string(forKey: "lastName"),
              let student_number = UserDefaults.standard.string(
                forKey: "student_number"
              ),
              let formation = UserDefaults.standard.string(forKey: "formation"),
              let username = UserDefaults.standard.string(forKey: "username"),
              let password = UserDefaults.standard.string(forKey: "password") else {
            return nil
        }
        let profileImageData = UserDefaults.standard.data(
            forKey: "profileImageData"
        )
        let studentIDCardImageData = UserDefaults.standard.data(
            forKey: "studentIDCardImageData"
        )
        let notificationsEnabled = UserDefaults.standard.bool(
            forKey: "notificationsEnabled"
        )
        let icsLink = UserDefaults.standard.string(
            forKey: "icsLink"
        ) // Chargement du lien ICS
        
        return UserData(
            firstName: firstName,
            lastName: lastName,
            student_number: student_number,
            formation: formation,
            username: username,
            password: password,
            profileImageData: profileImageData,
            studentIDCardImageData: studentIDCardImageData,
            notificationsEnabled: notificationsEnabled,
            icsLink: icsLink
        )
    }
}

// MARK: - SubjectData Model

struct SubjectData: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var coefficient: Double
    var iconColorData: Data?
    
    var iconColor: Color {
        get {
            if let colorData = iconColorData,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self,
                from: colorData
               ) {
                return Color(uiColor)
            }
            return .blue
        }
        set {
            if let uiColor = UIColor(newValue) {
                iconColorData = try? NSKeyedArchiver
                    .archivedData(
                        withRootObject: uiColor,
                        requiringSecureCoding: false
                    )
            }
        }
    }
    
    init(name: String, coefficient: Double, iconColor: Color) {
        self.name = name
        self.coefficient = coefficient
        self.iconColor = iconColor
    }
    
    func save() {
        var subjects = SubjectData.loadAll()
        if let index = subjects.firstIndex(where: { $0.id == self.id }) {
            subjects[index] = self
        } else {
            subjects.append(self)
        }
        if let encodedData = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(encodedData, forKey: "subjects")
        }
    }
    
    func delete() {
        var subjects = SubjectData.loadAll()
        if let index = subjects.firstIndex(where: { $0.id == self.id }) {
            subjects.remove(at: index)
        }
        if let encodedData = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(encodedData, forKey: "subjects")
        }
    }
    
    static func loadAll() -> [SubjectData] {
        guard let savedData = UserDefaults.standard.data(forKey: "subjects"),
              let subjects = try? JSONDecoder().decode([SubjectData].self, from: savedData) else {
            return []
        }
        return subjects
    }
}

struct Note: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: NoteType
    var coefficient: Double
    var score: Double
    var subjectId: UUID
    var iconColorData: Data? // Store color data here
    var date: Date = Date() // Automatically set to current date
    
    // Computed property for retrieving the icon color
    var iconColor: Color {
        get {
            if let colorData = iconColorData,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self,
                from: colorData
               ) {
                return Color(uiColor)
            }
            return type.defaultColor // Fallback to the default color if not set
        }
        set {
            if let uiColor = UIColor(newValue) {
                iconColorData = try? NSKeyedArchiver
                    .archivedData(
                        withRootObject: uiColor,
                        requiringSecureCoding: false
                    )
            }
        }
    }
    
    func save() {
        var notes = Note.loadAll()
        if let index = notes.firstIndex(where: { $0.id == self.id }) {
            notes[index] = self
        } else {
            notes.append(self)
        }
        if let encodedData = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encodedData, forKey: "notes")
        }
    }
    
    func delete() {
        var notes = Note.loadAll()
        if let index = notes.firstIndex(where: { $0.id == self.id }) {
            notes.remove(at: index)
        }
        if let encodedData = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encodedData, forKey: "notes")
            UserDefaults.standard.synchronize()
        }
    }
    
    static func loadAll() -> [Note] {
        guard let savedData = UserDefaults.standard.data(forKey: "notes"),
              let notes = try? JSONDecoder().decode([Note].self, from: savedData) else {
            return []
        }
        return notes
    }
}

enum NoteType: String, CaseIterable, Identifiable, Codable {
    case partiel, devoir, projet, tp
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .partiel: return "doc.text"
        case .devoir: return "house"
        case .projet: return "hammer"
        case .tp: return "desktopcomputer"
        }
    }
    
    var displayName: String {
        switch self {
        case .partiel: return "Partiel"
        case .devoir: return "Devoir"
        case .projet: return "Projet"
        case .tp: return "TP"
        }
    }
    
    // Adding color property to be set dynamically
    var defaultColor: Color {
        switch self {
        case .partiel: return .blue
        case .devoir: return .green
        case .projet: return .orange
        case .tp: return .purple
        }
    }
}

// MARK: - Deadline Data Model
struct Deadline: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var subjectId: UUID
    var isCompleted: Bool = false
    
    func save() {
        var deadlines = Deadline.loadAll()
        if let index = deadlines.firstIndex(where: { $0.id == self.id }) {
            deadlines[index] = self
        } else {
            deadlines.append(self)
        }
        if let encodedData = try? JSONEncoder().encode(deadlines) {
            UserDefaults.standard.set(encodedData, forKey: "deadlines")
        }
    }
    
    func delete() {
        var deadlines = Deadline.loadAll()
        if let index = deadlines.firstIndex(where: { $0.id == self.id }) {
            deadlines.remove(at: index)
        }
        if let encodedData = try? JSONEncoder().encode(deadlines) {
            UserDefaults.standard.set(encodedData, forKey: "deadlines")
        }
    }
    
    static func loadAll() -> [Deadline] {
        guard let savedData = UserDefaults.standard.data(forKey: "deadlines"),
              let deadlines = try? JSONDecoder().decode([Deadline].self, from: savedData) else {
            print("Aucune deadline enregistrée dans UserDefaults.")
            return []
        }
        return deadlines
    }
}

struct ICSEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
}

// MARK: - Functions

func scheduleDeadlineNotification(for deadline: Deadline) {
    let content = UNMutableNotificationContent()
    content.title = "Deadline urgente !"
    content.body = "\(deadline.name) est à venir."
    content.sound = .default
    
    let triggerDate = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: deadline.date
    )
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: triggerDate,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: deadline.id.uuidString,
        content: content,
        trigger: trigger
    )
    UNUserNotificationCenter.current().add(request)
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var themeColor: Color {
        didSet { saveColor(color: themeColor) }
    }
    
    init() {
        let defaultColor = UserDefaults.standard.data(
            forKey: "themeColor"
        ).flatMap { data -> Color? in
            if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self,
                from: data
            ) {
                return Color(uiColor)
            }
            return nil
        } ?? Color(red: 185 / 255, green: 161 / 255, blue: 221 / 255)
        
        self.themeColor = defaultColor
    }
    
    private func saveColor(color: Color) {
        guard let uiColor = UIColor(color) else { return }
        if let encodedColor = try? NSKeyedArchiver.archivedData(
            withRootObject: uiColor,
            requiringSecureCoding: false
        ) {
            UserDefaults.standard.set(encodedColor, forKey: "themeColor")
        }
    }
}

extension UIColor {
    // Safely initialize a UIColor from a SwiftUI Color
    convenience init?(_ color: Color) {
        guard let cgColor = color.cgColor else { return nil }
        self.init(cgColor: cgColor)
    }
}

// Rest of the code follows, including the `ContentView`, `SubjectView`, `WelcomeView`, `HomeView`, and `SettingsView`...
// MARK: - Views
struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "house.fill") }
            
            SubjectsAndNotesView()
                .tabItem { Label("Notes", systemImage: "doc.text") }
            
            ENTView()
                .edgesIgnoringSafeArea(.all)
                .tabItem { Label("ENT", systemImage: "network") }
            
            MoodleView()
                .edgesIgnoringSafeArea(.all)
                .tabItem {
                    Label("Moodle", systemImage: "graduationcap")
                }
            
            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gear") }
        }
        .accentColor(themeManager.themeColor)
    }
}

struct WelcomeView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var student_number: String = ""
    @State private var formation: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showHomeView: Bool = false
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme // Détecte le thème actuel
    
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack {
                    Text("Bienvenue dans")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(
                            colorScheme == .dark ? Color.black
                                .opacity(0.6) : Color.white
                                .opacity(0.6)
                        )
                        .multilineTextAlignment(.center)
                        .scaleEffect(animate ? 1 : 0.8)
                        .animation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.6,
                                blendDuration: 0
                            )
                            .delay(0.1),
                            value: animate
                        )
                    Text("My Sup Galilée")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(
                            colorScheme == .dark ? Color.black
                                .opacity(0.8) : Color.white
                                .opacity(0.8)
                        )
                        .multilineTextAlignment(.center)
                        .scaleEffect(animate ? 1 : 0.8)
                        .animation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.6,
                                blendDuration: 0
                            )
                            .delay(0.1),
                            value: animate
                        )
                    Spacer()
                    
                    Image("Galilee") // Utilise l'icône de l'application
                        .resizable()
                        .frame(width: 150, height: 150)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 20)
                        ) // Pour un aspect arrondi
                        .scaleEffect(animate ? 1 : 0.8)
                        .animation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.6,
                                blendDuration: 0
                            )
                            .delay(0.2),
                            value: animate
                        )
                    
                    Spacer()
                    
                    Text("Veuillez renseigner vos informations")
                        .font(.headline)
                        .foregroundColor(
                            colorScheme == .dark ? Color.black
                                .opacity(0.6) : Color.white
                                .opacity(0.6)
                        )
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 0.5).delay(0.2),
                            value: animate
                        )
                }
                .padding(.top, 50)
                
                formFields
                
                Button(action: saveUserData) {
                    Text("Valider")
                        .font(.headline)
                        .foregroundColor(
                            colorScheme == .dark ? Color.white
                                .opacity(1) : Color.black
                                .opacity(1)
                        )
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            colorScheme == .dark ? Color.black
                                .opacity(0.6) : Color.white
                                .opacity(0.6)
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                .padding(.top, 10)
                .scaleEffect(animate ? 1 : 0.8)
                .animation(
                    .spring(
                        response: 0.4,
                        dampingFraction: 0.6,
                        blendDuration: 0
                    ),
                    value: animate
                )
                Spacer()
            }
            .padding(.horizontal, 20)
            .onAppear {
                withAnimation {
                    animate = true
                }
            }
            .fullScreenCover(isPresented: $showHomeView) {
                ContentView()
            }
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 20) {
            CustomTextField(placeholder:"Prénom", text: $firstName)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            CustomTextField(placeholder:"Nom", text: $lastName)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            CustomTextField(
                placeholder:"Numéro étudiant",
                text: $student_number
            )
            .foregroundColor(colorScheme == .dark ? .white : .black)
            CustomTextField(placeholder:"Formation", text: $formation)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            CustomSecureField(placeholder: "Mot de passe", text: $password)
        }
        .padding()
        .background(
            colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.4)
        )
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private func saveUserData() {
        let userData = UserData(
            firstName: firstName,
            lastName: lastName,
            student_number: student_number,
            formation: formation,
            username: student_number,
            password: password,
            notificationsEnabled: false
        )
        userData.save()
        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
        showHomeView = true
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var showPassword: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if showPassword {
                TextField(placeholder, text: $text)
                    .padding(12)
                    .background(
                        colorScheme == .dark ? Color.white
                            .opacity(0.1) : Color.black
                            .opacity(0.05)
                    )
                    .cornerRadius(8)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                SecureField(placeholder, text: $text)
                    .padding(12)
                    .background(
                        colorScheme == .dark ? Color.white
                            .opacity(0.1) : Color.black
                            .opacity(0.05)
                    )
                    .cornerRadius(8)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            colorScheme == .dark ? Color.white
                .opacity(0.1) : Color.black
                .opacity(0.05)
        )
        .cornerRadius(8)
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme // Détecte le thème actuel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField(placeholder, text: $text)
                .padding(12)
                .background(
                    colorScheme == .dark ? Color.white
                        .opacity(0.1) : Color.black
                        .opacity(0.05)
                )
                .cornerRadius(8)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

struct LaunchScreenView: View {
    @State private var animate = false
    @Binding var showContentView: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Conception du fond (dégradé ou couleur unie)
            LinearGradient(
                gradient: Gradient(colors: [.purple, .blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack() {
                Text("Bienvenue dans")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(
                        colorScheme == .dark ? .black
                            .opacity(0.6): .white
                            .opacity(0.6)
                    )
                    .multilineTextAlignment(.center)
                    .scaleEffect(animate ? 1 : 0.8)
                    .animation(
                        .spring(
                            response: 0.5,
                            dampingFraction: 0.6,
                            blendDuration: 0
                        )
                        .delay(0.1),
                        value: animate
                    )
                    .padding(.top, 10)
                
                Text("My Sup Galilée")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .multilineTextAlignment(.center)
                    .scaleEffect(animate ? 1 : 0.8)
                    .animation(
                        .spring(
                            response: 0.5,
                            dampingFraction: 0.6,
                            blendDuration: 0
                        )
                        .delay(0.3),
                        value: animate
                    )
                    .padding(.bottom, 30)
                Image("Galilee") // Utilise l'icône de l'application
                    .resizable()
                    .frame(width: 150, height: 150)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    ) // Pour un aspect arrondi
                    .scaleEffect(animate ? 1 : 0.8)
                    .animation(
                        .spring(
                            response: 0.5,
                            dampingFraction: 0.6,
                            blendDuration: 0
                        )
                        .delay(0.6),
                        value: animate
                    )
            }
            .onAppear {
                withAnimation {
                    animate = true
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1).delay(1.5)) {
                    showContentView = true
                }
            }
        }
    }
}

struct ContentViewWrapper: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showContentView: Bool
    
    var body: some View {
        ZStack {
            if showContentView {
                ContentView()
                    .environmentObject(themeManager)
                    .transition(.opacity)
            } else {
                LaunchScreenView(showContentView: $showContentView)
                    .transition(.opacity)
            }
        }
    }
}

struct HomeView: View {
    @State private var subjects: [SubjectData] = SubjectData.loadAll()
    @State private var notes: [Note] = Note.loadAll()
    @State private var isShowingSettings = false
    @State private var isShowingStudentID = false
    @State private var profileImageData: Data? = UserDefaults.standard.data(
        forKey: "profileImageData"
    )
    @State private var studentIDCardImageData: Data? = UserDefaults.standard.data(
        forKey: "studentIDCardImageData"
    )
    @State private var calendarEvents: [ICSEvent] = []
    @State private var icsLink: String = UserData.load()?.icsLink ?? ""
    @State private var loadErrorMessage: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var hasLoadedEvents = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    calendarSection
                    upcomingDeadlinesSection
                    notesSection
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(
                "Bonjour, \(UserDefaults.standard.string(forKey: "firstName") ?? "")"
            )
            .onAppear {
                reloadData()
                loadCalendarEvents()
                profileImageData = UserDefaults.standard
                    .data(forKey: "profileImageData")
                studentIDCardImageData = UserDefaults.standard
                    .data(forKey: "studentIDCardImageData")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingSettings = true }) {
                        if let imageData = profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isShowingStudentID = true }) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.title2)
                            .foregroundColor(themeManager.themeColor)
                    }
                }
                ToolbarItem(placement: .principal) { // Placement au centre de la Toolbar
                    Image("institut") // Utilise l'icône de l'application
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.5)
                        .animation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.6,
                                blendDuration: 0
                            )
                            .delay(0.6),
                            value: true
                        )
                }
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingStudentID) {
                StudentIDCardView()
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Événements à venir")
                    .font(.headline)
                    .foregroundStyle(themeManager.themeColor)
                Spacer()
                
                // Bouton pour accéder à la vue du calendrier complet
                NavigationLink(destination: CalendarView(calendarEvents: calendarEvents)) {
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.themeColor)
                        .font(.title3)
                }
                
                Button(action: {
                    promptForICSLink()
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(themeManager.themeColor)
                        .font(.title3)
                }
            }
            
            if let errorMessage = loadErrorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else if calendarEvents.isEmpty {
                Text("Aucun événement à venir.")
                    .foregroundColor(.gray)
            } else {
                ForEach(calendarEvents.prefix(2)) { event in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(themeManager.themeColor)
                                
                                Text(event.description
                                    .replacingOccurrences(of: "Matière.*?\\n", with: "", options: .regularExpression)
                                    .replacingOccurrences(of: "\\n", with: "\n"))
                                .font(.subheadline)
                                .opacity(0.8)
                                
                                Text("\(formatDateToFrenchString(event.startDate)) - \(formatDateToFrenchString(event.endDate))")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Section for Upcoming Deadlines
    private var upcomingDeadlinesSection: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: UpcomingView(calendarEvents: calendarEvents)) {
                HStack {
                    Text("Voir les échéances à venir")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.themeColor)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Encadré pour la Moyenne Générale
            VStack {
                Text("Moyenne Générale")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(generalAverage(), specifier: "%.2f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors(for: generalAverage())),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(15)
            .padding(.horizontal)
            
            // Sections pour chaque matière et leurs notes
            ForEach(subjects) { subject in
                let subjectNotes = notes.filter { $0.subjectId == subject.id }
                if !subjectNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(subject.name)
                                .font(.headline)
                                .foregroundColor(subject.iconColor)
                            
                            Spacer()
                            
                            Text("Moyenne : \(subjectAverage(for: subjectNotes),specifier: "%.2f")"
                            )
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(subjectNotes) { note in
                                HStack {
                                    Image(systemName: note.type.iconName)
                                        .foregroundColor(note.type.defaultColor)
                                        .frame(width: 20)
                                    
                                    Text(note.name)
                                    Spacer()
                                    
                                    Text("\(note.score, specifier: "%.1f")")
                                    Text("Coeff. \(note.coefficient,specifier: "%.1f")"
                                    )
                                    .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                
                            }
                        }
                    }
                    .padding()
                    .background(Color.clear)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func reloadData() {
        subjects = []
        notes = []
        subjects = SubjectData.loadAll()
        notes = Note.loadAll()
    }
    
    // Fonction pour déterminer le gradient en fonction de la moyenne
    private func gradientColors(for average: Double) -> [Color] {
        switch average {
        case ..<8:
            return [Color.red.opacity(0.8), Color.orange.opacity(0.7)]
        case 8..<11:
            return [Color.orange.opacity(0.7), Color.yellow.opacity(0.3)]
        case 11..<13:
            return [Color.purple.opacity(0.6), Color.blue.opacity(0.5)]
        case 13..<15:
            return [Color.blue.opacity(0.5), Color.cyan.opacity(0.6)]
        case 15..<18:
            return [Color.green.opacity(0.5), Color.black.opacity(0.6)]
        default:
            return [Color.cyan.opacity(0.6), Color.green.opacity(0.5)]
        }
    }
    
    private func generalAverage() -> Double {
        var subjectAverages: [(average: Double, coefficient: Double)] = []
        
        for subject in subjects {
            let subjectNotes = notes.filter { $0.subjectId == subject.id }
            let weightedSum = subjectNotes.reduce(0.0) {
                $0 + ($1.score * $1.coefficient)
            }
            let totalNoteCoefficient = subjectNotes.reduce(0.0) {
                $0 + $1.coefficient
            }
            
            if totalNoteCoefficient > 0 {
                let subjectAverage = weightedSum / totalNoteCoefficient
                subjectAverages
                    .append(
                        (
                            average: subjectAverage,
                            coefficient: subject.coefficient
                        )
                    )
            }
        }
        
        let overallWeightedSum = subjectAverages.reduce(0.0) {
            $0 + ($1.average * $1.coefficient)
        }
        let totalSubjectCoefficient = subjectAverages.reduce(0.0) {
            $0 + $1.coefficient
        }
        
        return totalSubjectCoefficient > 0 ? overallWeightedSum / totalSubjectCoefficient : 0.0
    }
    
    private func subjectAverage(for subjectNotes: [Note]) -> Double {
        let weightedSum = subjectNotes.reduce(0.0) {
            $0 + ($1.score * $1.coefficient)
        }
        let totalCoefficient = subjectNotes.reduce(0.0) { $0 + $1.coefficient }
        return totalCoefficient > 0 ? weightedSum / totalCoefficient : 0.0
    }
    
    // MARK: - Chargement des événements ICS
    private func loadCalendarEvents() {
        guard !hasLoadedEvents, let url = URL(string: icsLink), !icsLink.isEmpty else {
            return
        }
        
        hasLoadedEvents = true
        loadErrorMessage = nil // Réinitialise le message d'erreur
        
        let task = URLSession.shared.dataTask(
            with: url
        ) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    loadErrorMessage = "Erreur de chargement du fichier ICS : \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    loadErrorMessage = "Le fichier ICS est vide ou inaccessible."
                }
                return
            }
            
            let events = parseICSEvents(from: data)
            DispatchQueue.main.async {
                if events.isEmpty {
                    loadErrorMessage = "Aucun événement trouvé dans le fichier ICS."
                } else {
                    calendarEvents = events
                }
            }
        }
        task.resume()
    }
    
    private func parseICSEvents(from data: Data) -> [ICSEvent] {
        var parsedEvents: [ICSEvent] = []
        
        guard let icsString = String(data: data, encoding: .utf8) else {
            loadErrorMessage = "Impossible de lire les données du fichier ICS."
            return []
        }
        
        // Diviser le contenu en sections d'événements
        let eventComponents = icsString.components(separatedBy: "BEGIN:VEVENT")
        
        for component in eventComponents {
            guard component.contains("END:VEVENT") else { continue }
            
            var title = "Sans titre"
            var description = ""
            var startDate = Date()
            var endDate = Date()
            
            // Diviser chaque événement en lignes pour extraire les champs spécifiques
            let lines = component.components(separatedBy: "\n")
            
            for line in lines {
                if line.starts(with: "SUMMARY;LANGUAGE=fr:") {
                    // Extraction du titre entre le premier et le deuxième tiret
                    let summaryContent = line.replacingOccurrences(of: "SUMMARY;LANGUAGE=fr:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Diviser le texte en sous-parties basées sur le tiret
                    let components = summaryContent.components(separatedBy: " - ")
                    
                    // Vérifier qu'il y a bien au moins deux composants pour éviter les erreurs
                    if components.count >= 2 {
                        title = components[1]  // Récupère le texte entre le premier et deuxième tiret
                    } else {
                        title = summaryContent // Cas où il n'y a pas de tiret
                    }
                } else if line.starts(with: "DTSTART:") {
                    // Extraction de la date de début (DTSTART)
                    let dtStartString = line.replacingOccurrences(of: "DTSTART:", with: "").trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    if let parsedStartDate = parseICSEventDate(
                        from: dtStartString
                    ) {
                        startDate = parsedStartDate
                    }
                } else if line.starts(with: "DTEND:") {
                    // Extraction de la date de fin (DTEND)
                    let dtEndString = line.replacingOccurrences(of: "DTEND:", with: "").trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    if let parsedEndDate = parseICSEventDate(
                        from: dtEndString
                    ) {
                        endDate = parsedEndDate
                    }
                } else if line.starts(with: "DESCRIPTION;LANGUAGE=fr:") {
                    
                    description = line .replacingOccurrences(of: "DESCRIPTION;LANGUAGE=fr:", with: "").trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
            }
            
            
            if startDate >= Date() {
                parsedEvents.append(
                    ICSEvent(
                        title: title,
                        description: description,
                        startDate: startDate,
                        endDate: endDate
                    )
                )
            }
        }
        parsedEvents.sort { $0.startDate < $1.startDate }
        return parsedEvents
    }
    
    // Helper pour parser les dates d'événement au format YYYYMMDD
    private func parseICSEventDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(
            identifier: "fr_FR"
        ) // Utilisation de la locale française
        return dateFormatter.date(from: dateString)
    }
    
    private func formatDateToFrenchString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM HH:mm" // Format personnalisé : jour, mois abrégé et heure:minute
        dateFormatter.locale = Locale(identifier: "fr_FR")
        return dateFormatter.string(from: date)
    }
    
    private func promptForICSLink() {
        let alert = UIAlertController(
            title: "Lien ICS",
            message: "Entrez votre lien ICS pour les cours",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "https://example.com/calendar.ics"
            textField.text = icsLink
        }
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert
            .addAction(
                UIAlertAction(
                    title: "Enregistrer",
                    style: .default
                ) { _ in
                    if let textField = alert.textFields?.first,
                       let text = textField.text,
                       !text.isEmpty {
                        icsLink = text
                        var updatedUserData = UserData.load() ?? UserData(
                            firstName: "",
                            lastName: "",
                            student_number: "",
                            formation: "",
                            username: "",
                            password: "",
                            profileImageData: nil,
                            notificationsEnabled: false,
                            icsLink: ""
                        )
                        updatedUserData.icsLink = text
                        updatedUserData.save()
                        loadCalendarEvents()
                    }
                })
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

struct CalendarView: View {
    let calendarEvents: [ICSEvent]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentWeekOffset: Int = 0  // Décalage de la semaine sélectionnée par rapport à la semaine actuelle
    
    var body: some View {
        NavigationView {
            VStack {
                // Contrôles pour changer la semaine
                HStack {
                    Button(action: { currentWeekOffset -= 1 }) {
                        Image(systemName: "chevron.left")
                        Text("Semaine précédente")
                    }
                    .font(.subheadline)
                    
                    Spacer()
                    
                    Button(action: { currentWeekOffset += 1 }) {
                        Text("Semaine suivante")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sortedDaysInWeek(), id: \.self) { day in
                            if let events = eventsForDay(day) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(dayHeader(day))
                                        .font(.headline)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal)
                                    
                                    // Affichage des événements pour le jour spécifique
                                    ForEach(events) { event in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(event.title)
                                                .foregroundStyle(themeManager.themeColor)
                                                .fontWeight(.bold)
                                            
                                            Text(event.description
                                                .replacingOccurrences(of: "\\n", with: "\n")
                                                .replacingOccurrences(of: "\\", with: ""))
                                            .font(.subheadline)
                                            .opacity(0.8)
                                            
                                            Text("\(formatDate(event.startDate)) - \(formatDate(event.endDate))")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendrier")
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    // Retourne les jours de la semaine triés de lundi à dimanche pour la semaine active
    private func sortedDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        var weekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: calendar.startOfDay(for: Date()))!
        weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    // Récupère les événements pour un jour spécifique
    private func eventsForDay(_ day: Date) -> [ICSEvent]? {
        let calendar = Calendar.current
        return calendarEvents.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
    
    // Formate le jour pour l'affichage en en-tête avec la première lettre du jour en majuscule et le mois en majuscules
    private func dayHeader(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d"  // Format pour le jour et la date
        dayFormatter.locale = Locale(identifier: "fr_FR")
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"  // Format pour le mois et l'année
        monthFormatter.locale = Locale(identifier: "fr_FR")
        
        let dayString = dayFormatter.string(from: date).prefix(1).uppercased() + dayFormatter.string(from: date).dropFirst()
        let monthString = monthFormatter.string(from: date).prefix(1).uppercased() +  monthFormatter.string(from: date).dropFirst() // Mois en majuscules
        
        return "\(dayString) \(monthString)"
    }
    
    // Formate la date pour l'affichage des heures
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}

// Extension pour obtenir le début de la semaine
extension Date {
    func startOfWeek() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Définit lundi comme premier jour de la semaine
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}
struct StudentIDCardView: View {
    @State private var showPhotoPicker = false
    @Environment(\.colorScheme) var colorScheme
    @State private var userData: UserData = UserData.load() ?? UserData(
        firstName: "",
        lastName: "",
        student_number: "",
        formation: "",
        username: "",
        password: "",
        profileImageData: nil,
        notificationsEnabled: false
    )
    
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationView {
            VStack {
                if let imageData = userData.studentIDCardImageData,
                   let image = UIImage(data: imageData) {
                    // Affiche l'image avec ses proportions d'origine, ajustée pour ne pas être coupée
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit) // Conserve le format d'origine sans découpe
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9) // Limite la largeur pour un bon affichage
                        .cornerRadius(15) // Bords arrondis
                        .shadow(radius: 5) // Optionnel : ajoute une ombre pour un effet de relief
                        .padding()
                } else {
                    Text("Ajouter votre carte étudiante")
                        .font(.title2)
                        .padding()
                }
                
                Button("Choisir une photo") {
                    showPhotoPicker = true
                }
                .padding()
                .foregroundColor(
                    colorScheme == .dark ? Color.white.opacity(1) : Color.black.opacity(1)
                )
                .frame(height: 50)
                .background(
                    colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.6)
                )
                .cornerRadius(15)
            }
            .navigationTitle("Carte étudiante")
            .sheet(isPresented: $showPhotoPicker, onDismiss: saveSelectedImage) {
                PhotoPicker(selectedImageData: $selectedImageData)
            }
        }
    }
    
    private func saveSelectedImage() {
        if let imageData = selectedImageData {
            userData.studentIDCardImageData = imageData
            userData.save()
        }
    }
}

// NOTES
struct SubjectsAndNotesView: View {
    @State private var subjects: [SubjectData] = SubjectData.loadAll()
    @State private var notes: [Note] = Note.loadAll()
    @State private var isShowingAddNoteView = false
    @State private var isShowingAddSubjectView = false
    @State private var isShowingEditNoteSheet = false
    @State private var editingNote: Note?
    @State private var isShowingEditSubjectSheet = false
    @State private var editingSubject: SubjectData?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: HStack {
                    Text("Matières enregistrées")
                    Spacer()
                    Button(action: { isShowingAddSubjectView = true }) {
                        Image(systemName: "plus")
                    }
                }) {
                    ForEach(subjects) { subject in
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(subject.iconColor)
                            VStack(alignment: .leading) {
                                Text(subject.name)
                                Text("Coefficient : \(subject.coefficient,specifier: "%.1f")"
                                )
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteSubject)
                }
                
                Section(header: HStack {
                    Text("Notes enregistrées")
                    Spacer()
                    Button(action: { isShowingAddNoteView = true }) {
                        Image(systemName: "plus")
                    }
                }) {
                    ForEach(notes.indices, id: \.self) { index in
                        let note = notes[index]
                        if let subject = subjects.first(
                            where: { $0.id == note.subjectId
                            }) {
                            HStack {
                                Image(systemName: note.type.iconName)
                                    .foregroundColor(note.type.defaultColor)
                                VStack(alignment: .leading) {
                                    Text("\(note.name) - \(subject.name)")
                                    Text("\(note.type.displayName)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(note.score, specifier: "%.1f")")
                            }
                        }
                    }
                    .onDelete(perform: deleteNote)
                }
            }
            .onAppear {
                reloadSubjects()
                reloadNotes()
            }
            .sheet(isPresented: $isShowingAddNoteView) {
                AddNoteView(subjects: subjects, notes: $notes)
            }
            .sheet(isPresented: $isShowingAddSubjectView) {
                AddSubjectView(subjects: $subjects)
            }
            .navigationTitle("Matières et Notes")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helper Functions
    private func reloadSubjects() {
        subjects = SubjectData.loadAll()
    }
    
    private func reloadNotes() {
        notes = Note.loadAll()
    }
    
    private func deleteSubject(at offsets: IndexSet) {
        offsets.forEach { index in
            subjects[index].delete()
            subjects.remove(at: index)
        }
        reloadSubjects()
    }
    
    private func deleteNote(at offsets: IndexSet) {
        offsets.forEach { index in
            notes[index].delete()
            notes.remove(at: index)
        }
        reloadNotes()
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var noteName: String = ""
    @State private var selectedSubject: SubjectData?
    @State private var coefficient: Double = 1.0
    @State private var scoreText: String = ""
    @State private var selectedType: NoteType = .partiel
    var subjects: [SubjectData]
    @Binding var notes: [Note]  // Utilisez un Binding pour mettre à jour la liste des notes
    @State private var animateForm = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Nouvelle note")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 50)
                    .scaleEffect(animateForm ? 1 : 0.8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6),
                        value: animateForm
                    )
                
                VStack(spacing: 20) {
                    Picker("Matière", selection: $selectedSubject) {
                        Text("Sélectionnez une matière")
                            .tag(nil as SubjectData?)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject as SubjectData?)
                        }
                    }
                    
                    CustomTextField(
                        placeholder: "Nom de la note",
                        text: $noteName
                    )
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    CustomTextField(
                        placeholder: "Entrez la note sur 20",
                        text: $scoreText
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .onChange(of: scoreText) { oldValue, newValue in
                        scoreText = newValue
                            .replacingOccurrences(of: ",", with: ".")
                    }
                    
                    
                    HStack {
                        // Stepper pour le coefficient
                        Stepper(value: $coefficient, in: 0...5, step: 0.5) {
                            Text("Coefficient : \(coefficient, specifier: "%.1f")")
                                .foregroundColor(.primary)
                                .bold()
                        }
                    }
                    .padding(.vertical, 12) // Ajoute du padding vertical pour augmenter la hauteur
                    .padding(.horizontal, 8) // Garde le padding horizontal léger
                    .background(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
                    )
                    .cornerRadius(8)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(NoteType.allCases) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.defaultColor)
                                Text(type.displayName)
                            }.tag(type)
                        }
                    }
                    
                    Button("Ajouter") {
                        guard let selectedSubject = selectedSubject, let score = Double(scoreText) else {
                            return
                        }
                        let newNote = Note(
                            name: noteName,
                            type: selectedType,
                            coefficient: coefficient,
                            score: score,
                            subjectId: selectedSubject.id
                        )
                        notes
                            .append(
                                newNote
                            )  // Ajoutez la note directement à la liste des notes
                        newNote.save()
                        dismiss()
                    }
                    .disabled(
                        noteName.isEmpty || selectedSubject == nil || Double(
                            scoreText
                        ) == nil
                    )
                }
                .padding()
                .background(
                    colorScheme == .dark ? Color.black
                        .opacity(0.6) : Color.white
                        .opacity(0.8)
                )
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear { animateForm = true }
            .onDisappear { animateForm = false }
        }
    }
}

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var subjectName: String = ""
    @State private var coefficient: Double = 1.0
    @State private var selectedColor: Color = .blue
    @Binding var subjects: [SubjectData]  // Utilisez un Binding pour mettre à jour la liste
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                Text("Nouvelle matière")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 50)
                
                VStack(spacing: 20) {
                    // Champ pour entrer le nom de la matière
                    CustomTextField(
                        placeholder: "Nom de la matière",
                        text: $subjectName
                    )
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    // Encadré pour le Stepper et le ColorPicker
                    HStack {
                        // Stepper pour le coefficient
                        Stepper(value: $coefficient, in: 1...20, step: 1) {
                            Text("ECTS : \(coefficient, specifier: "%.0f")")
                                .foregroundColor(.primary)
                                .bold()
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        // ColorPicker sur la même ligne, aligné à droite
                        ColorPicker("", selection: $selectedColor)
                            .labelsHidden() // Cache le label pour gagner de la place
                            .frame(maxWidth: 70) // Fixe la largeur du ColorPicker pour rester compact
                    }
                    .padding(.vertical, 12)
                    .background(
                        colorScheme == .dark ? Color.white
                            .opacity(0.1) : Color.black
                            .opacity(0.05)
                    )
                    .cornerRadius(8)
                    
                    // Bouton pour ajouter la matière
                    Button("Ajouter") {
                        let newSubject = SubjectData(
                            name: subjectName,
                            coefficient: coefficient,
                            iconColor: selectedColor
                        )
                        subjects.append(newSubject)  // Met à jour la liste des matières
                        newSubject.save()
                        dismiss()
                    }
                    .disabled(subjectName.isEmpty)
                    .padding()
                }
                .padding()
                .background(
                    colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.8)
                )
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

// MARK: - PhotoPicker for Logo Selection

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider
                .canLoadObject(ofClass: UIImage.self) else { return }
            provider
                .loadObject(ofClass: UIImage.self) {
                    [weak self] image,
                    _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            // Redimensionner et recadrer l'image
                            let resizedImage = self?.resizeAndCropImage(
                                uiImage,
                                targetSize: CGSize(width: 200, height: 200)
                            )
                            self?.parent.selectedImageData = resizedImage?
                                .pngData()
                        }
                    }
                }
        }
        
        // Fonction pour redimensionner et recadrer l'image en carré
        private func resizeAndCropImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
            let widthRatio = targetSize.width / image.size.width
            let heightRatio = targetSize.height / image.size.height
            let scaleFactor = max(widthRatio, heightRatio)
            
            let scaledImageSize = CGSize(
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )
            
            UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
            let xOffset = (targetSize.width - scaledImageSize.width) / 2
            let yOffset = (targetSize.height - scaledImageSize.height) / 2
            image
                .draw(
                    in: CGRect(
                        x: xOffset,
                        y: yOffset,
                        width: scaledImageSize.width,
                        height: scaledImageSize.height
                    )
                )
            
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage
        }
    }
}

// MARK: - ENT
struct ENTView: UIViewRepresentable {
    private let loginURL = URL(
        string: "https://cas.univ-paris13.fr/cas/login?service=https%3A%2F%2Fent.univ-paris13.fr"
    )!
    private let webView = WKWebView()
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // Configurer la WebView, mais la cacher initialement
        webView.isHidden = true
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        containerView.addSubview(webView)
        
        // Configurer les contraintes pour que WebView occupe tout l'espace
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor
                .constraint(equalTo: containerView.bottomAnchor),
            webView.leadingAnchor
                .constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor
                .constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Charger la page de connexion en arrière-plan
        let request = URLRequest(url: loginURL)
        webView.load(request)
        
        // Afficher la WebView après un délai de 0.5 seconde
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.webView.isHidden = false
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Pas de mise à jour nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ENTView
        
        init(_ parent: ENTView) {
            self.parent = parent
        }
        
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            // Récupérer le nom d'utilisateur et le mot de passe de UserDefaults
            let username = UserDefaults.standard.string(
                forKey: "username"
            ) ?? ""
            let password = UserDefaults.standard.string(
                forKey: "password"
            ) ?? ""
            
            // Injecter JavaScript pour remplir les champs de connexion
            if webView.url == parent.loginURL {
                let javascript = """
                document.getElementById('username').value = '\(username)';
                document.getElementById('password').value = '\(password)';
                document.getElementById('submit').click();
                """
                webView.evaluateJavaScript(javascript) {
                    result,
                    error in
                    if let error = error {
                        print(
                            "Erreur lors de l'injection de JavaScript : \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
        
        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            print(
                "Erreur de chargement de la page : \(error.localizedDescription)"
            )
        }
    }
}

struct MoodleView: UIViewRepresentable {
    private let moodleURL = URL(
        string: "https://cas.univ-paris13.fr/cas/login?service=https%3A%2F%2Fmoodle.univ-spn.fr%2Flogin%2Findex.php%3FauthCAS%3DCAS"
    )!
    private let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        // Configurer la WebView
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Charger la page de connexion Moodle
        let request = URLRequest(url: moodleURL)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Pas de mise à jour spécifique requise
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MoodleView
        
        init(_ parent: MoodleView) {
            self.parent = parent
        }
        
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            // Récupérer le nom d'utilisateur et le mot de passe de UserDefaults
            let username = UserDefaults.standard.string(
                forKey: "username"
            ) ?? ""
            let password = UserDefaults.standard.string(
                forKey: "password"
            ) ?? ""
            
            // Injecter JavaScript pour pré-remplir les champs et soumettre le formulaire
            if webView.url == parent.moodleURL {
                let javascript = """
                document.getElementById('username').value = '\(username)';
                document.getElementById('password').value = '\(password)';
                document.getElementById('submit').click();
                """
                webView.evaluateJavaScript(javascript) {
                    result,
                    error in
                    if let error = error {
                        print(
                            "Erreur lors de l'injection de JavaScript : \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
        
        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            print(
                "Erreur de chargement de la page : \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Upcoming Tab View

struct UpcomingView: View {
    let calendarEvents: [ICSEvent]
    @State private var deadlines: [Deadline] = Deadline.loadAll()
    @State private var subjects: [SubjectData] = SubjectData.loadAll()
    @State private var isShowingAddDeadlineView = false
    
    private func subjectName(for deadline: Deadline) -> String {
        return subjects
            .first(
                where: { $0.id == deadline.subjectId
                })?.name ?? "Matière inconnue"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Urgent")) {
                    ForEach(
                        deadlines
                            .filter { $0.date < Date().addingTimeInterval(24 * 60 * 60) && $0.date >= Date()
                            }) { deadline in
                                deadlineRow(deadline)
                            }
                            .onDelete(perform: deleteDeadline)
                }
                
                Section(header: Text("Plus tard")) {
                    ForEach(
                        deadlines
                            .filter { $0.date >= Date().addingTimeInterval(
                                24 * 60 * 60
                            )
                            }) { deadline in
                                deadlineRow(deadline)
                            }
                            .onDelete(perform: deleteDeadline)
                }
                
                Section(header: Text("Dépassé")) {
                    ForEach(
                        deadlines.filter { $0.date < Date()
                        }) { deadline in
                            deadlineRow(deadline)
                        }
                        .onDelete(perform: deleteDeadline)
                }
            }
            .navigationTitle("À venir")
            .onAppear(perform: {
                reloadDeadlines()
                createExamDeadlinesIfNeeded()
            })
            .navigationBarItems(trailing:
                                    Button(action: {
                isShowingAddDeadlineView = true
            }) {
                Image(systemName: "plus")
            }
            )
            .sheet(
                isPresented: $isShowingAddDeadlineView,
                onDismiss: {
                    reloadDeadlines()
                    subjects = SubjectData
                        .loadAll() // Recharge les matières pour éviter "Matière inconnue"
                }) {
                    AddDeadlineView()
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deadlineRow(_ deadline: Deadline) -> some View {
        VStack(alignment: .leading) {
            Text(deadline.name)
                .font(.headline)
            Text("Matière : \(subjectName(for: deadline))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Échéance : \(dayHeader(deadline.date))"
            )
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = deadlines.firstIndex(
                    where: { $0.id == deadline.id
                    }) {
                    deleteDeadline(at: IndexSet(integer: index))
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
    
    private func dayHeader(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d"  // Format pour le jour et la date
        dayFormatter.locale = Locale(identifier: "fr_FR")
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"  // Format pour le mois et l'année
        monthFormatter.locale = Locale(identifier: "fr_FR")
        
        let dayString = dayFormatter.string(from: date).prefix(1).uppercased() + dayFormatter.string(from: date).dropFirst()
        let monthString = monthFormatter.string(from: date).prefix(1).uppercased() +  monthFormatter.string(from: date).dropFirst() // Mois en majuscules
        
        return "\(dayString) \(monthString)"
    }
    
    private func reloadDeadlines() {
        deadlines = Deadline.loadAll()
    }
    
    private func deleteDeadline(at offsets: IndexSet) {
        offsets.forEach { index in
            guard index < deadlines.count else { return }
            deadlines[index].delete()
            deadlines.remove(at: index)
        }
        reloadDeadlines()
    }
    
    private func createExamDeadlinesIfNeeded() {
        for event in calendarEvents {
            if event.description.contains("Examen") {

                // Vérifie si la matière existe déjà
                var subjectID = subjects.first(where: { $0.name == event.title })?.id

                // Si la matière n'existe pas, on la crée
                if subjectID == nil {
                    let newSubject = SubjectData(name: event.title, coefficient: 1.0, iconColor: .random)
                    newSubject.save()
                    subjects.append(newSubject)  // Ajoute la matière à la liste pour éviter une re-création
                    subjectID = newSubject.id    // Utilise l'ID de la nouvelle matière
                }

                let examDeadline = Deadline(
                    name: "Examen - \(event.title)",
                    date: event.startDate,
                    subjectId: subjectID ?? UUID() // Utilise l'ID de la matière ou un UUID par défaut si nécessaire
                )

                if !deadlines.contains(where: { $0.name == examDeadline.name && $0.date == examDeadline.date }) {
                    examDeadline.save()
                    deadlines.append(examDeadline)
                }
            }
        }
    }
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

struct AddDeadlineView: View {
    @Environment(\.dismiss) var dismiss
    @State private var deadlineName = ""
    @State private var selectedSubject: SubjectData?
    @State private var deadlineDate = Date()
    @State private var subjects: [SubjectData] = SubjectData.loadAll()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nom de l'échéance", text: $deadlineName)
                
                Picker("Matière", selection: $selectedSubject) {
                    Text("Sélectionnez une matière")
                        .tag(nil as SubjectData?)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(subject as SubjectData?)
                    }
                }
                
                DatePicker(
                    "Date",
                    selection: $deadlineDate,
                    displayedComponents: .date
                )
                
                Button("Enregistrer") {
                    saveDeadline()
                    dismiss()
                }
                .disabled(deadlineName.isEmpty || selectedSubject == nil)
            }
            .navigationTitle("Nouvelle échéance")
            .navigationBarItems(leading: Button("Annuler") {
                dismiss()
            })
            .onAppear {
                subjects = SubjectData.loadAll()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveDeadline() {
        guard let selectedSubject = selectedSubject else { return }
        let newDeadline = Deadline(
            name: deadlineName,
            date: deadlineDate,
            subjectId: selectedSubject.id
        )
        newDeadline.save()
        
        // Planifie la notification 2 jours avant la date de l'échéance
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: deadlineDate
        ) ?? deadlineDate
        scheduleDeadlineNotification(for: newDeadline, on: notificationDate)
    }
    
    func scheduleDeadlineNotification(
        for deadline: Deadline,
        on date: Date
    ) {
        // Notification pour 2 jours avant la deadline
        let content = UNMutableNotificationContent()
        content.title = "Rappel : \(deadline.name)"
        content.body = "Votre échéance pour \(deadline.name) est dans 2 jours."
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(deadline.id.uuidString)-2days",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(
                    "Erreur lors de la planification de la notification : \(error)"
                )
            }
        }
        
        // Notification immédiate lors de la création de la deadline
        let immediateContent = UNMutableNotificationContent()
        immediateContent.title = "Nouvelle échéance ajoutée"
        immediateContent.body = "Vous avez ajouté une échéance pour \(deadline.name)."
        immediateContent.sound = .default
        
        let immediateTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        let immediateRequest = UNNotificationRequest(
            identifier: "\(deadline.id.uuidString)-immediate",
            content: immediateContent,
            trigger: immediateTrigger
        )
        
        UNUserNotificationCenter.current().add(immediateRequest) { error in
            if let error = error {
                print(
                    "Erreur lors de l'envoi de la notification immédiate : \(error)"
                )
            }
        }
    }
}

func requestNotificationPermission() {
    UNUserNotificationCenter
        .current()
        .requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("Erreur de demande de permission : \(error)")
            }
            if granted {
                print("Permission accordée pour les notifications")
            } else {
                print("Permission refusée pour les notifications")
            }
        }
}

extension DateFormatter {
    static let long: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(
            identifier: "fr_FR"
        ) // Définit la localisation en français
        return formatter
    }()
}

// MARK: - Settings

struct BackupData: Codable {
    var subjects: [SubjectData]
    var notes: [Note]
    var deadlines: [Deadline]
    var userData: UserData
}

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var userData: UserData = UserData.load() ?? UserData(
        firstName: "",
        lastName: "",
        student_number: "",
        formation: "",
        username: "",
        password: "",
        profileImageData: nil,
        notificationsEnabled: false
    )
    @State private var isShowingProfileEditView = false
    @State private var backupFileURL: URL?
    @State private var isCreatingBackup = false
    @State private var isShowingDocumentPicker = false
    @State private var isShowingProgressSheet = false
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @State private var progressValue: Double = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations personnelles")) {
                    HStack {
                        if let imageData = userData.profileImageData, let uiImage = UIImage(
                            data: imageData
                        ) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .padding(.trailing, 20)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(
                                "\(userData.firstName) \(userData.lastName)"
                            )
                            .font(.title2)
                            .fontWeight(.bold)
                            Text(
                                "Numéro étudiant: \(userData.student_number)"
                            )
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            Text("Formation: \(userData.formation)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        Button(
                            action: { isShowingProfileEditView.toggle()
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(
                                        themeManager.themeColor
                                    )
                            }
                    }
                }
                
                Section(header: Text("Couleur du thème")) {
                    ColorPicker(
                        "Choisir une couleur",
                        selection: $themeManager.themeColor
                    )
                }
                
                Section(header: Text("Notifications")) {
                    Toggle(
                        "Autoriser les notifications",
                        isOn: $userData.notificationsEnabled
                    )
                    .onChange(
                        of: userData.notificationsEnabled
                    ) {old, value in
                        userData.save()
                        if value {
                            requestNotificationPermission()
                        }
                    }
                }
                Section(header: Text("Sauvegarde")) {
                    Button(action: { createBackup() }) {
                        HStack {
                            Text("Créer une sauvegarde")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    Button(action: { isShowingDocumentPicker = true }) {
                        HStack {
                            Text("Restaurer une sauvegarde")
                            Spacer()
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    .fileImporter(
                        isPresented: $isShowingDocumentPicker,
                        allowedContentTypes: [.json]
                    ) { result in
                        handleFileImport(result: result)
                    }
                }
            }
            .navigationTitle("Réglages")
            .onAppear {
                // Reload user data
                userData = UserData.load() ?? userData
            }
            .sheet(isPresented: $isShowingProgressSheet, content: {
                VStack {
                    ProgressView(value: progressValue, total: 1.0) {
                        Text("Restauration en cours...")
                    }
                    .padding()
                    
                    if progressValue >= 1.0 {
                        Button("Fermer") {
                            isShowingProgressSheet = false
                        }
                        .padding(.top)
                    }
                }
            })
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text("Statut de la restauration"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $isShowingProfileEditView) {
                ProfileEditView(userData: $userData)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Backup Functionality
    
    private func createBackup() {
        let subjects = SubjectData.loadAll()
        let notes = Note.loadAll()
        let deadlines = Deadline.loadAll()  // Load deadlines
        let backupData = BackupData(
            subjects: subjects,
            notes: notes,
            deadlines: deadlines,
            userData: userData
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "MySupGalilee_\(dateFormatter.string(from: Date())).json"
        
        do {
            let jsonData = try JSONEncoder().encode(backupData)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                fileName
            )
            try jsonData.write(to: tempURL)
            
            let activityViewController = UIActivityViewController(
                activityItems: [
                    tempURL,
                    UIImage(named: "AppIcon") ?? UIImage()
                ],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController
                    .present(activityViewController, animated: true)
            }
        } catch {
            alertMessage = "Échec lors de la création du fichier de sauvegarde : \(error.localizedDescription)"
            isShowingAlert = true
        }
    }
    
    // MARK: - Restore Functionality
    private func handleFileImport(result: Result<URL, Error>) {
        progressValue = 0.0
        isShowingProgressSheet = true
        
        switch result {
        case .success(let fileURL):
            guard fileURL.startAccessingSecurityScopedResource() else {
                alertMessage = "Impossible d'accéder au fichier."
                isShowingAlert = true
                return
            }
            
            defer { fileURL.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedBackup = try JSONDecoder().decode(
                    BackupData.self,
                    from: data
                )
                
                // Efface les données actuelles dans UserDefaults
                UserDefaults.standard.removeObject(forKey: "subjects")
                UserDefaults.standard.removeObject(forKey: "notes")
                UserDefaults.standard.removeObject(forKey: "deadlines")
                UserDefaults.standard.removeObject(forKey: "firstName")
                UserDefaults.standard.removeObject(forKey: "lastName")
                UserDefaults.standard.removeObject(forKey: "student_number")
                UserDefaults.standard.removeObject(forKey: "formation")
                UserDefaults.standard
                    .removeObject(forKey: "profileImageData")
                
                // Supprime les données existantes en mémoire
                let existingSubjects = SubjectData.loadAll()
                let existingNotes = Note.loadAll()
                let existingDeadlines = Deadline.loadAll()
                existingSubjects.forEach { $0.delete() }
                existingNotes.forEach { $0.delete() }
                existingDeadlines.forEach { $0.delete() }
                
                progressValue += 0.5
                
                // Sauvegarde les données restaurées dans UserDefaults
                decodedBackup.subjects.forEach { $0.save() }
                decodedBackup.notes.forEach { $0.save() }
                decodedBackup.deadlines.forEach { $0.save() }
                decodedBackup.userData.save()
                
                // Met à jour les données en mémoire
                self.userData = decodedBackup.userData
                progressValue = 1.0
                alertMessage = "Sauvegarde restaurée avec succès !"
                
            } catch {
                alertMessage = "Erreur lors de la restauration : \(error.localizedDescription)"
            }
        case .failure(let error):
            alertMessage = "Importation du fichier échouée : \(error.localizedDescription)"
        }
        
        isShowingAlert = true
        isShowingProgressSheet = false
    }
}

struct ProfileEditView: View {
    @Binding var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var studentNumber = ""
    @State private var formation = ""
    @State private var password = ""
    @State private var isShowingPhotoPicker = false
    @State private var selectedImageData: Data?
    @State private var showPassword: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image
                if let imageData = selectedImageData ?? userData.profileImageData, let uiImage = UIImage(
                    data: imageData
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.trailing, 20)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.trailing, 20)
                        .foregroundColor(.gray)
                }
                
                // Button to change profile picture
                Button(action: {
                    isShowingPhotoPicker.toggle()
                }) {
                    Text("Changer la photo de profil")
                }
                .sheet(isPresented: $isShowingPhotoPicker) {
                    PhotoPicker(selectedImageData: $selectedImageData)
                }
                
                // Profile details
                TextField("Prénom", text: $firstName)
                TextField("Nom", text: $lastName)
                TextField("Numéro étudiant", text: $studentNumber)
                TextField("Formation", text: $formation)
                HStack {
                    if showPassword {
                        TextField("Mot de passe", text: $password)
                    } else {
                        SecureField("Mot de passe", text: $password)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(
                            systemName: showPassword ? "eye.slash" : "eye"
                        )
                        .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Modifier le Profil")
            .navigationBarItems(leading: Button("Annuler") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Sauvegarder") {
                saveProfile()
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                firstName = userData.firstName
                lastName = userData.lastName
                studentNumber = userData.student_number
                formation = userData.formation
                selectedImageData = userData.profileImageData
                password = userData.password
            }
            .onChange(of: selectedImageData) {oldImageData, newImageData in
                if let newImageData = newImageData {
                    userData.profileImageData = newImageData
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveProfile() {
        userData.firstName = firstName
        userData.lastName = lastName
        userData.student_number = studentNumber
        userData.formation = formation
        userData.profileImageData = selectedImageData // Save the new profile image
        userData.username = studentNumber
        userData.password = password
        userData.save()
    }
}

// MARK: - Helper Structs

// Helper struct to enable heterogeneous dictionary encoding/decoding
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        self.encodeClosure = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

struct AnyCodable: Codable {
    var value: Any
    
    init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decoded = try? container.decode([SubjectData].self) {
            self.value = decoded
        } else if let decoded = try? container.decode([Note].self) {
            self.value = decoded
        } else if let decoded = try? container.decode(UserData.self) {
            self.value = decoded
        } else {
            throw DecodingError
                .typeMismatch(
                    AnyCodable.self,
                    DecodingError
                        .Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Unknown type"
                        )
                )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        _ = encoder.singleValueContainer()
        if let encodableValue = value as? Encodable {
            try encodableValue.encode(to: encoder)
        } else {
            throw EncodingError
                .invalidValue(
                    value,
                    EncodingError
                        .Context(
                            codingPath: encoder.codingPath,
                            debugDescription: "Unknown type"
                        )
                )
        }
    }
}

// MARK: - Main App
@main
struct MySupGalileeApp: App {
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn: Bool = false
    @State private var showContentView = false
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreenView(showContentView: $showContentView)
                        .transition(.opacity) // Smooth fade transition
                        .onAppear {
                            // Temporarily show LaunchScreen for a smoother transition
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(
                                        .easeInOut(duration: 0.5)
                                    ) { // Animation duration
                                        showLaunchScreen = false
                                    }
                                }
                        }
                } else {
                    if isUserLoggedIn {
                        ContentViewWrapper(
                            showContentView: $showContentView
                        )
                        .environmentObject(themeManager)
                        .transition(.opacity) // Smooth fade transition
                    } else {
                        WelcomeView()
                            .environmentObject(themeManager)
                            .transition(.opacity) // Smooth fade transition
                    }
                }
            }
            .animation(
                .easeInOut(duration: 0.5),
                value: showLaunchScreen
            ) // Apply fade animation
        }
    }
}
