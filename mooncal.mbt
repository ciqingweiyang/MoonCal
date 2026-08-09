///|
/// MoonCal is a small MoonBit-native iCalendar toolkit.
///
/// The v1 surface intentionally focuses on reusable library behavior:
/// parsing unfolded ICS properties, extracting VEVENT records, expanding
/// common RRULE patterns, validating calendar shape, and exporting summaries.
pub let package_name : String = "placeholder/mooncal"

///|
/// A compact fixture used by the CLI, examples, and smoke tests.
pub let sample_ics : String =
  #|BEGIN:VCALENDAR
  #|VERSION:2.0
  #|PRODID:-//MoonCal//Hackathon Fixture//EN
  #|BEGIN:VEVENT
  #|UID:demo-standup
  #|DTSTART:20260803T090000Z
  #|DTEND:20260803T093000Z
  #|SUMMARY:MoonCal standup
  #|LOCATION:Online
  #|RRULE:FREQ=WEEKLY;COUNT=4;BYDAY=MO,WE
  #|EXDATE:20260810T090000Z
  #|END:VEVENT
  #|BEGIN:VEVENT
  #|UID:demo-release
  #|DTSTART;VALUE=DATE:20260820
  #|SUMMARY:MoonBit package release day
  #|END:VEVENT
  #|END:VCALENDAR

///|
/// Parse an iCalendar document, returning structured data or a typed error.
pub fn parse(input : String) -> Result[Calendar, MoonCalError] {
  parse_calendar(input)
}

///|
/// Parse a single recurrence rule value, for example
/// `FREQ=WEEKLY;COUNT=3;BYDAY=MO,WE`.
pub fn parse_rule(input : String) -> Result[RRule, MoonCalError] {
  parse_rrule(input)
}

///|
/// Expand every event in a calendar inside an inclusive time window.
pub fn occurrences_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
  limit? : Int = 256,
) -> Result[Array[Occurrence], MoonCalError] {
  expand_calendar_between(calendar, from, until, limit~)
}

///|
/// Parse a document and immediately return an analysis summary.
pub fn analyze(input : String) -> Result[CalendarSummary, MoonCalError] {
  match parse_calendar(input) {
    Ok(calendar) => Ok(summarize(calendar))
    Err(err) => Err(err)
  }
}
