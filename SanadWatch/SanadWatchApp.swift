//
//  SanadWatchApp.swift
//  SanadWatch
//
//  Apple Watch companion app entry point
//  Add this as a new WatchKit App target in Xcode:
//  File > New > Target > Watch App
//

import SwiftUI

@main
struct SanadWatchApp: App {

    @StateObject private var connectivityManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environmentObject(connectivityManager)
        }
    }
}
