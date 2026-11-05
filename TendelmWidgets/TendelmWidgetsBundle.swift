//
//  TendelmWidgetsBundle.swift
//  TendelmWidgets
//
//  Created by Sébastien Castiel on 18/04/2026.
//

import SwiftUI
import WidgetKit
import TendelmCore

@main
struct TendelmWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayGridSmallWidget()
        TodayProgressMediumWidget()
        WeeklyGridLargeWidget()
        LockRectangularWidget()
        LockCircularWidget()
        LockInlineWidget()
        LockDayProgressWidget()
    }
}
