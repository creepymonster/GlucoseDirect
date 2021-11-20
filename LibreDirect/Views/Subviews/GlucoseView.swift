//
//  GlucoseView.swift
//  LibreDirect
//

import SwiftUI

// MARK: - GlucoseView

struct GlucoseView: View {
    @EnvironmentObject var store: AppStore

    var minuteChange: String {
        if let minuteChange = store.state.currentGlucose?.minuteChange {
            if store.state.glucoseUnit == .mgdL {
                return GlucoseFormatters.minuteChangeFormatter.string(from: minuteChange as NSNumber)!
            } else {
                return GlucoseFormatters.minuteChangeFormatter.string(from: minuteChange.asMmolL as NSNumber)!
            }
        }

        return "?"
    }

    var isAlarm: Bool {
        if let glucose = store.state.currentGlucose, glucose.glucoseValue < store.state.alarmLow || glucose.glucoseValue > store.state.alarmHigh {
            return true
        }

        return false
    }

    var glucoseForegroundColor: Color {
        if isAlarm {
            return Color.ui.red
        }

        return Color.primary
    }

    var body: some View {
        if !store.state.isPaired {
            VStack(alignment: .center) {
                Text("No Sensor")
                    .foregroundColor(Color.ui.red)
                    .font(.system(size: 32))
                    .padding(.vertical)
                
                /*Text("Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus. Vivamus elementum semper nisi. Aenean vulputate eleifend tellus. Aenean leo ligula, porttitor eu.")
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)*/
            }
        }
        
        if let currentGlucose = store.state.currentGlucose {
            VStack(alignment: .center) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(currentGlucose.glucoseValue.asGlucose(unit: store.state.glucoseUnit))
                            .font(.system(size: 112))

                        VStack(alignment: .leading) {
                            Text(currentGlucose.trend.description).font(.system(size: 48))
                            Text(store.state.glucoseUnit.localizedString)
                        }
                    }.foregroundColor(glucoseForegroundColor)

                    HStack(spacing: 20) {
                        if store.state.connectionState == .connected {
                            Text(String(format: LocalizedString("%1$@ a clock"), currentGlucose.timestamp.localTime))

                            if let _ = store.state.lastGlucose?.minuteChange, currentGlucose.trend != .unknown {
                                Text(String(format: LocalizedString("%1$@/min."), minuteChange))
                            } else {
                                Text(String(format: LocalizedString("%1$@/min."), "?"))
                            }
                        } else {
                            Text(store.state.connectionState.localizedString).foregroundColor(Color.ui.red)
                        }
                    }.padding(.bottom)
                }
                
                SnoozeView().padding(.bottom, 5)
            }
        } else {
            VStack(alignment: .center) {
                Text("???")
                    .font(.system(size: 112))
            }.foregroundColor(Color.ui.red)
        }
    }
}

// MARK: - GlucoseView_Previews

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        let store = AppStore(initialState: PreviewAppState())

        ForEach(ColorScheme.allCases, id: \.self) {
            GlucoseView().environmentObject(store).preferredColorScheme($0)
        }
    }
}
