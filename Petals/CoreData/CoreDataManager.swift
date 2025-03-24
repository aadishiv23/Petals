//
//  CoreDataManager.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import CoreData
import Foundation

/// CoreDataManager class provides a singleton instance to manage Core Data operations.
class CoreDataManager {

    /// Singleton instance of CoreDataManager.
    static let shared = CoreDataManager()

    /// Lazy property to create and load the NSPersistentContainer.
    lazy var persistenceController: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatModel")

        // Load the persistent stores and handle any errors.
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Error loading Core Data store: \(error)")
            }
        }
        return container
    }()

    /// Access the NSManagedObjectContext associated with the persistence controller.
    var context: NSManagedObjectContext {
        persistenceController.viewContext
    }

    /// Save the changes in the NSManagedObjectContext if there are any.
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
