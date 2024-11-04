import SwiftUI
import CoreData

// MARK: - Entités Core Data

@objc(Note)
public class Note: NSManagedObject, Identifiable {
    @NSManaged public var valeur: Double
    @NSManaged public var designation: String?
    @NSManaged public var coefficient: Int16
    @NSManaged public var matiere: Matiere?
}

@objc(Matiere)
public class Matiere: NSManagedObject, Identifiable {
    @NSManaged public var nom: String?
    @NSManaged public var coefficient: Int16
    @NSManaged public var notes: NSSet?

    public var notesArray: [Note] {
        let set = notes as? Set<Note> ?? []
        return set.sorted { $0.designation ?? "" < $1.designation ?? "" }
    }
}

@objc(Utilisateur)
public class Utilisateur: NSManagedObject, Identifiable {
    @NSManaged public var nom: String?
    @NSManaged public var prenom: String?
    @NSManaged public var numeroEtudiant: String?
}

// MARK: - Persistence Controller

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MySupGalilee")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (description, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

// MARK: - Vues

struct AccueilView: View {
    @FetchRequest(entity: Note.entity(), sortDescriptors: []) var notes: FetchedResults<Note>
    @FetchRequest(entity: Matiere.entity(), sortDescriptors: []) var matieres: FetchedResults<Matiere>
    
    private var moyenneGenerale: Double {
        var total = 0.0
        var totalCoefficient = 0
        
        for note in notes {
            total += (note.valeur * Double(note.coefficient))
            totalCoefficient += Int(note.coefficient)
        }
        
        return totalCoefficient > 0 ? total / Double(totalCoefficient) : 0
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Moyenne Générale: \(moyenneGenerale, specifier: "%.2f")")
                    .font(.largeTitle)
                    .padding()
                
                List {
                    ForEach(matieres) { matiere in
                        Section(header: Text(matiere.nom ?? "")) {
                            ForEach(matiere.notesArray, id: \.self) { note in
                                Text("\(note.designation ?? "") : \(note.valeur, specifier: "%.2f") (Coeff \(note.coefficient))")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accueil")
        }
    }
}

struct NotesView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: Matiere.entity(), sortDescriptors: []) var matieres: FetchedResults<Matiere>
    
    @State private var selectedMatiere: Matiere?
    @State private var designation = ""
    @State private var coefficient: Int16 = 1
    @State private var valeur: Double = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Matière", selection: $selectedMatiere) {
                    ForEach(matieres, id: \.self) { matiere in
                        Text(matiere.nom ?? "").tag(matiere as Matiere?)
                    }
                }
                
                TextField("Désignation", text: $designation)
                
                Stepper("Coefficient: \(coefficient)", value: $coefficient, in: 1...10)
                
                Slider(value: $valeur, in: 0...20, step: 0.5) {
                    Text("Valeur: \(valeur, specifier: "%.1f")")
                }
                
                Button("Ajouter la Note") {
                    let newNote = Note(context: context)
                    newNote.designation = designation
                    newNote.valeur = valeur
                    newNote.coefficient = coefficient
                    newNote.matiere = selectedMatiere
                    
                    try? context.save()
                }
            }
            .navigationTitle("Ajouter une Note")
        }
    }
}

struct MatieresView: View {
    @Environment(\.managedObjectContext) var context
    @State private var nom = ""
    @State private var coefficient: Int16 = 1
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nom de la matière", text: $nom)
                
                Stepper("Coefficient: \(coefficient)", value: $coefficient, in: 1...10)
                
                Button("Ajouter la Matière") {
                    let newMatiere = Matiere(context: context)
                    newMatiere.nom = nom
                    newMatiere.coefficient = coefficient
                    
                    try? context.save()
                }
            }
            .navigationTitle("Ajouter une Matière")
        }
    }
}

struct ReglagesView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: Utilisateur.entity(), sortDescriptors: []) var utilisateurs: FetchedResults<Utilisateur>
    
    @State private var nom = ""
    @State private var prenom = ""
    @State private var numeroEtudiant = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nom", text: $nom)
                TextField("Prénom", text: $prenom)
                TextField("Numéro étudiant", text: $numeroEtudiant)
                
                Button("Enregistrer") {
                    let utilisateur: Utilisateur
                    
                    if utilisateurs.isEmpty {
                        utilisateur = Utilisateur(context: context)
                    } else {
                        utilisateur = utilisateurs[0]
                    }
                    
                    utilisateur.nom = nom
                    utilisateur.prenom = prenom
                    utilisateur.numeroEtudiant = numeroEtudiant
                    
                    try? context.save()
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

// MARK: - Application principale

@main
struct MySupGalileeApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                AccueilView()
                    .tabItem {
                        Label("Accueil", systemImage: "house")
                    }
                
                NotesView()
                    .tabItem {
                        Label("Notes", systemImage: "plus.circle")
                    }
                
                MatieresView()
                    .tabItem {
                        Label("Matières", systemImage: "folder")
                    }
                
                ReglagesView()
                    .tabItem {
                        Label("Réglages", systemImage: "gear")
                    }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
