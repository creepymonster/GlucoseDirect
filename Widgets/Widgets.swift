//
//  Widgets.swift
//  Widgets
//

import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
#if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            return WidgetBundleBuilder.buildBlock(
                GlucoseWidget(),
                GlucoseActivityWidget(),
                SensorWidget(),
                TransmitterWidget()
            )
        } else {
            return WidgetBundleBuilder.buildBlock(
                GlucoseWidget(),
                SensorWidget(),
                TransmitterWidget()
            )
        }
#else
        return WidgetBundleBuilder.buildBlock(
            GlucoseWidget(),
            SensorWidget(),
            TransmitterWidget()
        )
#endif
    }
}
