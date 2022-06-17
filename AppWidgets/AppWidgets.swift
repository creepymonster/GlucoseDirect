//
//  AppWidgets.swift
//  AppWidgets
//

import SwiftUI
import WidgetKit

@main
struct AppWidgets: WidgetBundle {
    var body: some Widget {
        GlucoseWidget()
        SensorWidget()
        TransmitterWidget()
    }
}
