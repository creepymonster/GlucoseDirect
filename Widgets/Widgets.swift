//
//  Widgets.swift
//  Widgets
//

import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        GlucoseWidget()
        SensorWidget()
        TransmitterWidget()
    }
}
