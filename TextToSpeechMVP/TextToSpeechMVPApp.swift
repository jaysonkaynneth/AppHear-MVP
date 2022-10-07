//
//  TextToSpeechMVPApp.swift
//  TextToSpeechMVP
//
//  Created by Ganesh Ekatata Buana on 29/09/22.
//

import SwiftUI

@main
struct TextToSpeechMVPApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
