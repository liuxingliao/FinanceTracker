//
//  FinanceTrackerApp.swift
//  FinanceTracker
//
//  Created by liuxl on 2025/11/23.
//

import SwiftUI
import CoreData

@main
struct FinanceTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
