//
//  CarajasFieldGuideApp.swift
//  CarajasFieldGuide
//
//  Created by Andrew Kerr on 2026-03-20.
//

import SwiftUI
import CoreData

@main
struct CarajasFieldGuideApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
