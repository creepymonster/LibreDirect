//
//  SensorErrorList.swift
//  GlucoseDirectApp
//

import SwiftUI

struct SensorErrorList: View {
    // MARK: Internal

    @EnvironmentObject var store: DirectStore

    var body: some View {
        Group {
            CollapsableSection(teaser: Text(getTeaser(sensorErrorValues.count)), header: Label("Errors", systemImage: "exclamationmark.triangle"), collapsed: true, collapsible: !sensorErrorValues.isEmpty) {
                if sensorErrorValues.isEmpty {
                    Text(getTeaser(sensorErrorValues.count))
                } else {
                    ForEach(sensorErrorValues) { error in
                        HStack {
                            Text(error.timestamp.toLocalDateTime())
                            Spacer()
                            Text(":'(")
                        }
                    }.onDelete { offsets in
                        DirectLog.info("onDelete: \(offsets)")

                        let deletables = offsets.map { i in
                            (index: i, error: sensorErrorValues[i])
                        }

                        deletables.forEach { delete in
                            sensorErrorValues.remove(at: delete.index)
                            store.dispatch(.deleteSensorError(error: delete.error))
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .onAppear {
            DirectLog.info("onAppear")
            self.sensorErrorValues = store.state.sensorErrorValues.reversed()
        }
        .onChange(of: store.state.sensorErrorValues) { errorValues in
            DirectLog.info("onChange")
            self.sensorErrorValues = errorValues.reversed()
        }
    }

    // MARK: Private

    @State private var sensorErrorValues: [SensorError] = []

    private func getTeaser(_ count: Int) -> String {
        if count == 1 {
            return "\(count) Entry..."
        }

        return "\(count) Entries"
    }

    private func isPrecise(glucose: SensorGlucose) -> Bool {
        if store.state.glucoseUnit == .mgdL {
            return false
        }

        return glucose.glucoseValue.isAlmost(store.state.alarmLow, store.state.alarmHigh)
    }
}