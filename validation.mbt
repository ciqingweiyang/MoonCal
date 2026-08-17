///|
pub fn validate_calendar(calendar : Calendar) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  if calendar.version is None {
    diagnostics.push(
      warning("missing-version", "VCALENDAR does not declare VERSION"),
    )
  } else if calendar.version != Some("2.0") {
    diagnostics.push(warning("version-not-2", "MoonCal v1 expects VERSION:2.0"))
  }
  if calendar.prodid is None {
    diagnostics.push(
      warning("missing-prodid", "VCALENDAR does not declare PRODID"),
    )
  }
  if calendar.events.is_empty() &&
    calendar.tasks.is_empty() &&
    calendar.freebusy.is_empty() {
    diagnostics.push(info("no-events", "VCALENDAR contains no VEVENT records"))
  }
  collect_duplicate_uid_diagnostics(calendar, diagnostics)
  for event in calendar.events {
    diagnostics.append(validate_event(event))
  }
  for task in calendar.tasks {
    diagnostics.append(validate_task(task))
  }
  for item in calendar.freebusy {
    diagnostics.append(validate_freebusy(item))
  }
  diagnostics
}

///|
pub fn validate_event(event : Event) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  if event.summary.trim().is_empty() {
    diagnostics.push(
      info("empty-summary", "VEVENT \{event.uid} has no SUMMARY"),
    )
  }
  if event.rrule is Some(rule) {
    if rule.count is None && rule.until is None {
      diagnostics.push(
        warning(
          "unbounded-rrule",
          "VEVENT \{event.uid} has RRULE without COUNT or UNTIL",
        ),
      )
    }
  }
  if event.duration is Some(duration) {
    if duration.negative {
      diagnostics.push(
        error("negative-duration", "VEVENT \{event.uid} has negative DURATION"),
      )
    }
    if duration.is_zero() {
      diagnostics.push(
        info("zero-duration", "VEVENT \{event.uid} has zero DURATION"),
      )
    }
  }
  if event.status is Some(status) {
    if !is_known_status(status) {
      diagnostics.push(
        warning("unknown-status", "VEVENT \{event.uid} has non-standard STATUS"),
      )
    }
  }
  if event.sequence is Some(sequence) {
    if sequence < 0 {
      diagnostics.push(
        error("negative-sequence", "VEVENT \{event.uid} has negative SEQUENCE"),
      )
    }
  }
  diagnostics
}

///|
pub fn validate_task(task : Task) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  if task.summary.trim().is_empty() {
    diagnostics.push(
      info("empty-task-summary", "VTODO \{task.uid} has no SUMMARY"),
    )
  }
  if task.status is Some(status) {
    if !is_known_task_status(status) {
      diagnostics.push(
        warning(
          "unknown-task-status",
          "VTODO \{task.uid} has non-standard STATUS",
        ),
      )
    }
    if status == "COMPLETED" && task.completed is None {
      diagnostics.push(
        info(
          "completed-without-timestamp",
          "VTODO \{task.uid} is completed but has no COMPLETED timestamp",
        ),
      )
    }
    if status == "NEEDS-ACTION" && task.completed is Some(_) {
      diagnostics.push(
        warning(
          "open-task-has-completed-time",
          "VTODO \{task.uid} has COMPLETED while STATUS is NEEDS-ACTION",
        ),
      )
    }
  }
  if task.priority is Some(priority) {
    if priority < 0 || priority > 9 {
      diagnostics.push(
        error(
          "priority-out-of-range",
          "VTODO \{task.uid} PRIORITY must be 0..9",
        ),
      )
    }
  }
  if task.percent_complete is Some(percent) {
    if percent < 0 || percent > 100 {
      diagnostics.push(
        error(
          "percent-out-of-range",
          "VTODO \{task.uid} PERCENT-COMPLETE must be 0..100",
        ),
      )
    } else if percent == 100 && !task_is_completed(task) {
      diagnostics.push(
        warning(
          "percent-complete-status-mismatch",
          "VTODO \{task.uid} is 100 percent complete but not marked completed",
        ),
      )
    }
  }
  if task.start is Some(start) {
    if task.due is Some(due) {
      if due.before(start) {
        diagnostics.push(
          error(
            "task-due-before-start",
            "VTODO \{task.uid} DUE is before DTSTART",
          ),
        )
      }
    }
  }
  if task.completed is Some(completed) {
    if task.created is Some(created) {
      if completed.before(created) {
        diagnostics.push(
          warning(
            "completed-before-created",
            "VTODO \{task.uid} COMPLETED is before CREATED",
          ),
        )
      }
    }
  }
  for related in task.related_to {
    if related == task.uid {
      diagnostics.push(
        warning(
          "task-related-to-self",
          "VTODO \{task.uid} RELATED-TO points to itself",
        ),
      )
    }
  }
  diagnostics
}

///|
pub fn validate_freebusy(item : FreeBusy) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  let label = match item.uid {
    Some(uid) => uid
    None => "(without UID)"
  }
  if item.uid is None {
    diagnostics.push(warning("freebusy-missing-uid", "VFREEBUSY has no UID"))
  }
  if item.dtstamp is None {
    diagnostics.push(
      warning("freebusy-missing-dtstamp", "VFREEBUSY \{label} has no DTSTAMP"),
    )
  }
  if item.periods.is_empty() {
    diagnostics.push(
      info("freebusy-no-periods", "VFREEBUSY \{label} has no FREEBUSY periods"),
    )
  }
  if item.start is Some(start) {
    if item.end is Some(end) {
      if end.before(start) {
        diagnostics.push(
          error(
            "freebusy-end-before-start",
            "VFREEBUSY \{label} DTEND is before DTSTART",
          ),
        )
      }
    }
  }
  for period in item.periods {
    diagnostics.append(
      validate_freebusy_period(period, label, item.start, item.end),
    )
  }
  collect_overlapping_freebusy_periods(item.periods, label, diagnostics)
  diagnostics
}

///|
fn validate_freebusy_period(
  period : FreeBusyPeriod,
  owner : String,
  window_start : DateTime?,
  window_end : DateTime?,
) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  if !is_known_freebusy_type(period.busy_type) {
    diagnostics.push(
      warning(
        "unknown-freebusy-type",
        "VFREEBUSY \{owner} has non-standard FBTYPE \{period.busy_type}",
      ),
    )
  }
  if period.end.before(period.start) {
    diagnostics.push(
      error(
        "freebusy-period-backwards",
        "VFREEBUSY \{owner} has backwards period",
      ),
    )
  } else if period.end == period.start {
    diagnostics.push(
      info("freebusy-period-zero", "VFREEBUSY \{owner} has zero-length period"),
    )
  }
  if window_start is Some(start) {
    if period.start.before(start) {
      diagnostics.push(
        warning(
          "freebusy-period-before-window",
          "VFREEBUSY \{owner} has a period before DTSTART",
        ),
      )
    }
  }
  if window_end is Some(end) {
    if period.end.after(end) {
      diagnostics.push(
        warning(
          "freebusy-period-after-window",
          "VFREEBUSY \{owner} has a period after DTEND",
        ),
      )
    }
  }
  diagnostics
}

///|
fn collect_duplicate_uid_diagnostics(
  calendar : Calendar,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let ids : Array[(String, String)] = []
  for event in calendar.events {
    ids.push((event.uid, "VEVENT"))
  }
  for task in calendar.tasks {
    ids.push((task.uid, "VTODO"))
  }
  for item in calendar.freebusy {
    if item.uid is Some(uid) {
      ids.push((uid, "VFREEBUSY"))
    }
  }
  for i in 0..<ids.length() {
    for j in (i + 1)..<ids.length() {
      if ids[i].0 == ids[j].0 {
        diagnostics.push(
          error(
            "duplicate-uid",
            "duplicate UID \{ids[i].0} appears in \{ids[i].1} and \{ids[j].1}",
          ),
        )
      }
    }
  }
}

///|
fn collect_overlapping_freebusy_periods(
  periods : Array[FreeBusyPeriod],
  owner : String,
  diagnostics : Array[Diagnostic],
) -> Unit {
  for i in 0..<periods.length() {
    for j in (i + 1)..<periods.length() {
      if periods[i].busy_type == periods[j].busy_type &&
        freebusy_period_overlaps(periods[i], periods[j].start, periods[j].end) {
        diagnostics.push(
          warning(
            "freebusy-period-overlap",
            "VFREEBUSY \{owner} has overlapping \{periods[i].busy_type} periods",
          ),
        )
      }
    }
  }
}

///|
fn is_known_status(status : String) -> Bool {
  status == "TENTATIVE" ||
  status == "CONFIRMED" ||
  status == "CANCELLED" ||
  status == "NEEDS-ACTION" ||
  status == "COMPLETED" ||
  status == "IN-PROCESS" ||
  status == "DRAFT" ||
  status == "FINAL"
}

///|
fn is_known_task_status(status : String) -> Bool {
  status == "NEEDS-ACTION" ||
  status == "COMPLETED" ||
  status == "IN-PROCESS" ||
  status == "CANCELLED"
}

///|
fn is_known_freebusy_type(value : String) -> Bool {
  value == "FREE" ||
  value == "BUSY" ||
  value == "BUSY-UNAVAILABLE" ||
  value == "BUSY-TENTATIVE"
}

///|
fn info(code : String, message : String) -> Diagnostic {
  Diagnostic::{ code, message, severity: "info" }
}

///|
fn warning(code : String, message : String) -> Diagnostic {
  Diagnostic::{ code, message, severity: "warning" }
}

///|
fn error(code : String, message : String) -> Diagnostic {
  Diagnostic::{ code, message, severity: "error" }
}
