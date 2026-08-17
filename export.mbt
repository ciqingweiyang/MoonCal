///|
pub fn summary_to_text(summary : CalendarSummary) -> String {
  let b = StringBuilder()
  b.write_string("MoonCal summary\n")
  b.write_string("events: \{summary.event_count}\n")
  b.write_string("recurring: \{summary.recurring_event_count}\n")
  b.write_string("all_day: \{summary.all_day_event_count}\n")
  b.write_string("tasks: \{summary.task_count}\n")
  b.write_string("open_tasks: \{summary.open_task_count}\n")
  b.write_string("completed_tasks: \{summary.completed_task_count}\n")
  b.write_string("freebusy: \{summary.blocked_time_count}\n")
  b.write_string("freebusy_periods: \{summary.blocked_period_count}\n")
  b.write_string("earliest: \{option_datetime_to_text(summary.earliest)}\n")
  b.write_string("latest: \{option_datetime_to_text(summary.latest)}\n")
  if summary.diagnostics.is_empty() {
    b.write_string("diagnostics: none\n")
  } else {
    b.write_string("diagnostics:\n")
    for diag in summary.diagnostics {
      b.write_string("- [\{diag.severity}] \{diag.code}: \{diag.message}\n")
    }
  }
  b.to_string()
}

///|
pub fn error_to_text(err : MoonCalError) -> String {
  match err {
    InvalidLine(line~, message~) => "line \{line}: \{message}"
    InvalidProperty(line~, name~, message~) =>
      "property \{name} at line \{line}: \{message}"
    InvalidDateTime(value~) => "invalid date-time value: \{value}"
    InvalidRRule(value~, message~) => "invalid RRULE '\{value}': \{message}"
    InvalidCalendar(message~) => "invalid calendar: \{message}"
    MissingEventField(field~) => "missing required VEVENT field: \{field}"
    MissingTaskField(field~) => "missing required VTODO field: \{field}"
    UnsupportedFeature(feature~) => "unsupported feature: \{feature}"
    LimitExceeded(limit~) => "expansion limit exceeded: \{limit}"
  }
}

///|
pub fn summary_to_json(summary : CalendarSummary) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"event_count\":\{summary.event_count},")
  b.write_string("\"recurring_event_count\":\{summary.recurring_event_count},")
  b.write_string("\"all_day_event_count\":\{summary.all_day_event_count},")
  b.write_string("\"task_count\":\{summary.task_count},")
  b.write_string("\"open_task_count\":\{summary.open_task_count},")
  b.write_string("\"completed_task_count\":\{summary.completed_task_count},")
  b.write_string("\"freebusy_count\":\{summary.blocked_time_count},")
  b.write_string("\"freebusy_period_count\":\{summary.blocked_period_count},")
  b.write_string("\"earliest\":\{option_datetime_to_json(summary.earliest)},")
  b.write_string("\"latest\":\{option_datetime_to_json(summary.latest)},")
  b.write_string("\"diagnostics\":[")
  for i, diag in summary.diagnostics {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string("{\"code\":\"\{escape_json(diag.code)}\",")
    b.write_string("\"message\":\"\{escape_json(diag.message)}\",")
    b.write_string("\"severity\":\"\{escape_json(diag.severity)}\"}")
  }
  b.write_string("]}")
  b.to_string()
}

///|
pub fn calendar_to_json(calendar : Calendar) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"version\":\{option_string_to_json(calendar.version)},")
  b.write_string("\"prodid\":\{option_string_to_json(calendar.prodid)},")
  b.write_string("\"events\":[")
  for i, event in calendar.events {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string(event_to_json(event))
  }
  b.write_string("],")
  b.write_string("\"tasks\":[")
  for i, task in calendar.tasks {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string(task_to_json(task))
  }
  b.write_string("],")
  b.write_string("\"freebusy\":[")
  for i, item in calendar.freebusy {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string(freebusy_to_json(item))
  }
  b.write_string("]}")
  b.to_string()
}

///|
pub fn event_to_json(event : Event) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"uid\":\"\{escape_json(event.uid)}\",")
  b.write_string("\"start\":\"\{escape_json(event.start.format())}\",")
  b.write_string("\"end\":\{option_datetime_to_json(event.end)},")
  b.write_string("\"summary\":\"\{escape_json(event.summary)}\",")
  b.write_string("\"description\":\{option_string_to_json(event.description)},")
  b.write_string("\"location\":\{option_string_to_json(event.location)},")
  b.write_string("\"status\":\{option_string_to_json(event.status)},")
  b.write_string("\"url\":\{option_string_to_json(event.url)},")
  b.write_string("\"categories\":\{string_array_to_json(event.categories)},")
  b.write_string(
    "\"recurring\":\{if event_is_recurring(event) { "true" } else { "false" }}",
  )
  b.write_string("}")
  b.to_string()
}

///|
pub fn task_to_json(task : Task) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"uid\":\"\{escape_json(task.uid)}\",")
  b.write_string("\"start\":\{option_datetime_to_json(task.start)},")
  b.write_string("\"due\":\{option_datetime_to_json(task.due)},")
  b.write_string("\"completed\":\{option_datetime_to_json(task.completed)},")
  b.write_string("\"created\":\{option_datetime_to_json(task.created)},")
  b.write_string(
    "\"last_modified\":\{option_datetime_to_json(task.last_modified)},",
  )
  b.write_string("\"summary\":\"\{escape_json(task.summary)}\",")
  b.write_string("\"description\":\{option_string_to_json(task.description)},")
  b.write_string("\"status\":\{option_string_to_json(task.status)},")
  b.write_string("\"priority\":\{option_int_to_json(task.priority)},")
  b.write_string(
    "\"percent_complete\":\{option_int_to_json(task.percent_complete)},",
  )
  b.write_string("\"categories\":\{string_array_to_json(task.categories)},")
  b.write_string("\"url\":\{option_string_to_json(task.url)},")
  b.write_string("\"related_to\":\{string_array_to_json(task.related_to)},")
  b.write_string(
    "\"open\":\{if task_is_open(task) { "true" } else { "false" }},",
  )
  b.write_string(
    "\"completed_state\":\{if task_is_completed(task) { "true" } else { "false" }}",
  )
  b.write_string("}")
  b.to_string()
}

///|
pub fn freebusy_to_json(item : FreeBusy) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"uid\":\{option_string_to_json(item.uid)},")
  b.write_string("\"start\":\{option_datetime_to_json(item.start)},")
  b.write_string("\"end\":\{option_datetime_to_json(item.end)},")
  b.write_string("\"dtstamp\":\{option_datetime_to_json(item.dtstamp)},")
  b.write_string("\"organizer\":\{option_string_to_json(item.organizer)},")
  b.write_string("\"attendees\":\{string_array_to_json(item.attendees)},")
  b.write_string("\"comments\":\{string_array_to_json(item.comments)},")
  b.write_string("\"url\":\{option_string_to_json(item.url)},")
  b.write_string("\"periods\":[")
  for i, period in item.periods {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string(freebusy_period_to_json(period))
  }
  b.write_string("]}")
  b.to_string()
}

///|
pub fn freebusy_period_to_json(period : FreeBusyPeriod) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"start\":\"\{escape_json(period.start.format())}\",")
  b.write_string("\"end\":\"\{escape_json(period.end.format())}\",")
  b.write_string("\"busy_type\":\"\{escape_json(period.busy_type)}\",")
  b.write_string(
    "\"busy\":\{if freebusy_is_busy_type(period) { "true" } else { "false" }}",
  )
  b.write_string("}")
  b.to_string()
}

///|
pub fn task_summary_to_json(summary : TaskSummary) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"task_count\":\{summary.task_count},")
  b.write_string("\"open_task_count\":\{summary.open_task_count},")
  b.write_string("\"completed_task_count\":\{summary.completed_task_count},")
  b.write_string("\"in_process_task_count\":\{summary.in_process_task_count},")
  b.write_string("\"cancelled_task_count\":\{summary.cancelled_task_count},")
  b.write_string(
    "\"high_priority_task_count\":\{summary.high_priority_task_count},",
  )
  b.write_string("\"due_task_count\":\{summary.due_task_count},")
  b.write_string(
    "\"earliest_due\":\{option_datetime_to_json(summary.earliest_due)},",
  )
  b.write_string(
    "\"latest_due\":\{option_datetime_to_json(summary.latest_due)}",
  )
  b.write_string("}")
  b.to_string()
}

///|
pub fn freebusy_summary_to_json(summary : FreeBusySummary) -> String {
  let b = StringBuilder()
  b.write_string("{")
  b.write_string("\"component_count\":\{summary.component_count},")
  b.write_string("\"period_count\":\{summary.period_count},")
  b.write_string("\"busy_period_count\":\{summary.busy_period_count},")
  b.write_string(
    "\"tentative_period_count\":\{summary.tentative_period_count},",
  )
  b.write_string(
    "\"unavailable_period_count\":\{summary.unavailable_period_count},",
  )
  b.write_string("\"free_period_count\":\{summary.free_period_count},")
  b.write_string(
    "\"earliest_start\":\{option_datetime_to_json(summary.earliest_start)},",
  )
  b.write_string(
    "\"latest_end\":\{option_datetime_to_json(summary.latest_end)}",
  )
  b.write_string("}")
  b.to_string()
}

///|
pub fn occurrences_to_json(items : Array[Occurrence]) -> String {
  let b = StringBuilder()
  b.write_string("[")
  for i, item in items {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string("{")
    b.write_string("\"uid\":\"\{escape_json(item.uid)}\",")
    b.write_string("\"start\":\"\{escape_json(item.start.format())}\",")
    b.write_string("\"end\":\{option_datetime_to_json(item.end)},")
    b.write_string("\"summary\":\"\{escape_json(item.summary)}\"")
    b.write_string("}")
  }
  b.write_string("]")
  b.to_string()
}

///|
pub fn calendar_to_ics(calendar : Calendar) -> String {
  let b = StringBuilder()
  b.write_string("BEGIN:VCALENDAR\r\n")
  b.write_string(
    "VERSION:\{match calendar.version { Some(v) => v; None => "2.0" }}\r\n",
  )
  b.write_string(
    "PRODID:\{match calendar.prodid { Some(v) => v; None => "-//MoonCal//Generated//EN" }}\r\n",
  )
  for event in calendar.events {
    b.write_string(event_to_ics(event))
  }
  for task in calendar.tasks {
    b.write_string(task_to_ics(task))
  }
  for item in calendar.freebusy {
    b.write_string(freebusy_to_ics(item))
  }
  b.write_string("END:VCALENDAR\r\n")
  b.to_string()
}

///|
pub fn event_to_ics(event : Event) -> String {
  let b = StringBuilder()
  b.write_string("BEGIN:VEVENT\r\n")
  b.write_string("UID:\{escape_ics_text(event.uid)}\r\n")
  if event.start.is_date {
    b.write_string("DTSTART;VALUE=DATE:\{event.start.to_ics_value()}\r\n")
  } else {
    b.write_string("DTSTART:\{event.start.to_ics_value()}\r\n")
  }
  if event.end is Some(finish) {
    if finish.is_date {
      b.write_string("DTEND;VALUE=DATE:\{finish.to_ics_value()}\r\n")
    } else {
      b.write_string("DTEND:\{finish.to_ics_value()}\r\n")
    }
  }
  if !event.summary.is_empty() {
    b.write_string("SUMMARY:\{escape_ics_text(event.summary)}\r\n")
  }
  if event.location is Some(location) {
    b.write_string("LOCATION:\{escape_ics_text(location)}\r\n")
  }
  if event.description is Some(description) {
    b.write_string("DESCRIPTION:\{escape_ics_text(description)}\r\n")
  }
  if event.status is Some(status) {
    b.write_string("STATUS:\{status}\r\n")
  }
  if event.url is Some(url) {
    b.write_string("URL:\{url}\r\n")
  }
  if !event.categories.is_empty() {
    b.write_string("CATEGORIES:\{string_array_to_ics(event.categories)}\r\n")
  }
  if event.created is Some(created) {
    b.write_string("CREATED:\{created.to_ics_value()}\r\n")
  }
  if event.last_modified is Some(last_modified) {
    b.write_string("LAST-MODIFIED:\{last_modified.to_ics_value()}\r\n")
  }
  if event.sequence is Some(sequence) {
    b.write_string("SEQUENCE:\{sequence}\r\n")
  }
  if event.rrule is Some(rule) {
    b.write_string("RRULE:\{rrule_to_ics(rule)}\r\n")
  }
  if event.duration is Some(duration) {
    b.write_string("DURATION:\{duration.format()}\r\n")
  }
  if !event.rdate.is_empty() {
    b.write_string("RDATE:\{datetime_array_to_ics(event.rdate)}\r\n")
  }
  if !event.exdate.is_empty() {
    b.write_string("EXDATE:\{datetime_array_to_ics(event.exdate)}\r\n")
  }
  b.write_string("END:VEVENT\r\n")
  b.to_string()
}

///|
pub fn task_to_ics(task : Task) -> String {
  let b = StringBuilder()
  b.write_string("BEGIN:VTODO\r\n")
  b.write_string("UID:\{escape_ics_text(task.uid)}\r\n")
  if task.start is Some(start) {
    write_datetime_property(b, "DTSTART", start)
  }
  if task.due is Some(due) {
    write_datetime_property(b, "DUE", due)
  }
  if task.completed is Some(completed) {
    write_datetime_property(b, "COMPLETED", completed)
  }
  if task.created is Some(created) {
    write_datetime_property(b, "CREATED", created)
  }
  if task.last_modified is Some(last_modified) {
    write_datetime_property(b, "LAST-MODIFIED", last_modified)
  }
  if !task.summary.is_empty() {
    b.write_string("SUMMARY:\{escape_ics_text(task.summary)}\r\n")
  }
  if task.description is Some(description) {
    b.write_string("DESCRIPTION:\{escape_ics_text(description)}\r\n")
  }
  if task.status is Some(status) {
    b.write_string("STATUS:\{status}\r\n")
  }
  if task.priority is Some(priority) {
    b.write_string("PRIORITY:\{priority}\r\n")
  }
  if task.percent_complete is Some(percent) {
    b.write_string("PERCENT-COMPLETE:\{percent}\r\n")
  }
  if !task.categories.is_empty() {
    b.write_string("CATEGORIES:\{string_array_to_ics(task.categories)}\r\n")
  }
  if task.url is Some(url) {
    b.write_string("URL:\{url}\r\n")
  }
  for related in task.related_to {
    b.write_string("RELATED-TO:\{escape_ics_text(related)}\r\n")
  }
  b.write_string("END:VTODO\r\n")
  b.to_string()
}

///|
pub fn freebusy_to_ics(item : FreeBusy) -> String {
  let b = StringBuilder()
  b.write_string("BEGIN:VFREEBUSY\r\n")
  if item.uid is Some(uid) {
    b.write_string("UID:\{escape_ics_text(uid)}\r\n")
  }
  if item.dtstamp is Some(dtstamp) {
    write_datetime_property(b, "DTSTAMP", dtstamp)
  }
  if item.start is Some(start) {
    write_datetime_property(b, "DTSTART", start)
  }
  if item.end is Some(end) {
    write_datetime_property(b, "DTEND", end)
  }
  if item.organizer is Some(organizer) {
    b.write_string("ORGANIZER:\{organizer}\r\n")
  }
  for attendee in item.attendees {
    b.write_string("ATTENDEE:\{attendee}\r\n")
  }
  for comment in item.comments {
    b.write_string("COMMENT:\{escape_ics_text(comment)}\r\n")
  }
  if item.url is Some(url) {
    b.write_string("URL:\{url}\r\n")
  }
  for period in item.periods {
    b.write_string(freebusy_period_to_ics(period))
  }
  b.write_string("END:VFREEBUSY\r\n")
  b.to_string()
}

///|
pub fn freebusy_period_to_ics(period : FreeBusyPeriod) -> String {
  let param = if period.busy_type == "BUSY" {
    ""
  } else {
    ";FBTYPE=\{period.busy_type}"
  }
  "FREEBUSY\{param}:\{period.start.to_ics_value()}/\{period.end.to_ics_value()}\r\n"
}

///|
pub fn rrule_to_ics(rule : RRule) -> String {
  let parts : Array[String] = ["FREQ=\{frequency_to_string(rule.freq)}"]
  if rule.interval != 1 {
    parts.push("INTERVAL=\{rule.interval}")
  }
  if rule.count is Some(count) {
    parts.push("COUNT=\{count}")
  }
  if rule.until is Some(until) {
    parts.push("UNTIL=\{until.to_ics_value()}")
  }
  if !rule.byday.is_empty() {
    parts.push("BYDAY=\{weekday_array_to_ics(rule.byday)}")
  }
  if !rule.bymonthday.is_empty() {
    parts.push("BYMONTHDAY=\{int_array_to_text(rule.bymonthday)}")
  }
  if !rule.bymonth.is_empty() {
    parts.push("BYMONTH=\{int_array_to_text(rule.bymonth)}")
  }
  parts.join(";")
}

///|
fn write_datetime_property(
  b : StringBuilder,
  name : String,
  value : DateTime,
) -> Unit {
  if value.is_date {
    b.write_string("\{name};VALUE=DATE:\{value.to_ics_value()}\r\n")
  } else {
    b.write_string("\{name}:\{value.to_ics_value()}\r\n")
  }
}

///|
fn weekday_array_to_ics(days : Array[Weekday]) -> String {
  let parts : Array[String] = []
  for day in days {
    parts.push(weekday_to_string(day))
  }
  parts.join(",")
}

///|
fn datetime_array_to_ics(values : Array[DateTime]) -> String {
  let parts : Array[String] = []
  for value in values {
    parts.push(value.to_ics_value())
  }
  parts.join(",")
}

///|
fn int_array_to_text(values : Array[Int]) -> String {
  let parts : Array[String] = []
  for value in values {
    parts.push("\{value}")
  }
  parts.join(",")
}

///|
fn string_array_to_json(values : Array[String]) -> String {
  let b = StringBuilder()
  b.write_string("[")
  for i, value in values {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string("\"\{escape_json(value)}\"")
  }
  b.write_string("]")
  b.to_string()
}

///|
fn string_array_to_ics(values : Array[String]) -> String {
  let parts : Array[String] = []
  for value in values {
    parts.push(escape_ics_text(value))
  }
  parts.join(",")
}

///|
fn option_datetime_to_text(value : DateTime?) -> String {
  match value {
    Some(dt) => dt.format()
    None => "none"
  }
}

///|
fn option_datetime_to_json(value : DateTime?) -> String {
  match value {
    Some(dt) => "\"\{escape_json(dt.format())}\""
    None => "null"
  }
}

///|
fn option_string_to_json(value : String?) -> String {
  match value {
    Some(text) => "\"\{escape_json(text)}\""
    None => "null"
  }
}

///|
fn option_int_to_json(value : Int?) -> String {
  match value {
    Some(n) => "\{n}"
    None => "null"
  }
}

///|
pub fn escape_json(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
  .replace_all(old="\r", new="\\r")
  .replace_all(old="\t", new="\\t")
}

///|
pub fn escape_ics_text(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\n", new="\\n")
  .replace_all(old=",", new="\\,")
  .replace_all(old=";", new="\\;")
}
