package com.raghif.app.data

import com.raghif.app.session.Session
import java.time.LocalDate

// ponytail: real spec pre-orders today for tomorrow's bread; demo collapses that to
// "today" so a purchase shows up in the owner's queue immediately during the live demo.
// simulatedDayOffset lets the demo "simulate new day" button fast-forward without waiting
// for real midnight.
fun todayDateString(): String = LocalDate.now().plusDays(Session.simulatedDayOffset.toLong()).toString()
