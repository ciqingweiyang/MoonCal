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
  if calendar.events.is_empty() {
    diagnostics.push(info("no-events", "VCALENDAR contains no VEVENT records"))
  }
  collect_duplicate_uid_diagnostics(calendar.events, diagnostics)
  for event in calendar.events {
    diagnostics.append(validate_event(event))
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
fn collect_duplicate_uid_diagnostics(
  events : Array[Event],
  diagnostics : Array[Diagnostic],
) -> Unit {
  for i in 0..<events.length() {
    for j in (i + 1)..<events.length() {
      if events[i].uid == events[j].uid {
        diagnostics.push(
          error("duplicate-uid", "duplicate VEVENT UID: \{events[i].uid}"),
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
