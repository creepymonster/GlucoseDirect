//
//  GlucoseWatchActivity.swift
//  GlucoseDirect
//
//  Created by Marian Dugaesescu on 21/09/2024.
//

import WidgetKit
import SwiftUI

extension WidgetConfiguration
{
  func extraActivityFamily() -> some WidgetConfiguration
  {
    if #available(iOSApplicationExtension 18.0, *) {
      return self.supplementalActivityFamilies([ActivityFamily.small, ActivityFamily.medium])
    } else {
      return self
    }
  }
}
