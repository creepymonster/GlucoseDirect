//
//  TransmitterUpdateProvider.swift
//  GlucoseDirectApp
//
//  Created by Reimar Metzen on 18.01.23.
//

import Foundation
import WidgetKit

let placeholderTransmitter = Transmitter(name: "Bubble", battery: 70, firmware: 2.0, hardware: 2.0)

// MARK: - TransmitterEntry

struct TransmitterEntry: TimelineEntry {
    // MARK: Lifecycle

    init() {
        self.date = Date()
        self.transmitter = nil
    }

    init(date: Date) {
        self.date = date
        self.transmitter = nil
    }

    init(date: Date, transmitter: Transmitter) {
        self.date = date
        self.transmitter = transmitter
    }

    // MARK: Internal

    let date: Date
    let transmitter: Transmitter?
}

// MARK: - TransmitterUpdateProvider

struct TransmitterUpdateProvider: TimelineProvider {
    func placeholder(in context: Context) -> TransmitterEntry {
        return TransmitterEntry(date: Date(), transmitter: placeholderTransmitter)
    }

    func getSnapshot(in context: Context, completion: @escaping (TransmitterEntry) -> ()) {
        let entry = TransmitterEntry(date: Date(), transmitter: placeholderTransmitter)

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransmitterEntry>) -> ()) {
        let entries = [
            TransmitterEntry()
        ]

        let reloadDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}
