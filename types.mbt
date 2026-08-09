///|
/// Errors are data, not panics. This makes CLI output and tests predictable.
pub(all) enum MoonCalError {
  InvalidLine(line~ : Int, message~ : String)
  InvalidProperty(line~ : Int, name~ : String, message~ : String)
  InvalidDateTime(value~ : String)
  InvalidRRule(value~ : String, message~ : String)
  InvalidCalendar(message~ : String)
  MissingEventField(field~ : String)
  UnsupportedFeature(feature~ : String)
  LimitExceeded(limit~ : Int)
} derive(Eq, @debug.Debug)

///|
/// Calendar date or date-time. `is_date=true` represents all-day DATE values.
pub(all) struct DateTime {
  year : Int
  month : Int
  day : Int
  hour : Int
  minute : Int
  second : Int
  is_date : Bool
  is_utc : Bool
} derive(Eq, @debug.Debug)

///|
/// A parsed iCalendar property after RFC-style line unfolding.
pub(all) struct IcsProperty {
  name : String
  params : Map[String, String]
  value : String
  line : Int
} derive(@debug.Debug)

///|
/// Supported recurrence frequencies for v1.
pub(all) enum Frequency {
  Daily
  Weekly
  Monthly
  Yearly
} derive(Eq, @debug.Debug)

///|
/// Weekdays use the iCalendar two-letter names.
pub(all) enum Weekday {
  MO
  TU
  WE
  TH
  FR
  SA
  SU
} derive(Eq, @debug.Debug)

///|
/// A v1 recurrence rule. Unsupported RRULE parts are rejected during parsing.
pub(all) struct RRule {
  freq : Frequency
  interval : Int
  count : Int?
  until : DateTime?
  byday : Array[Weekday]
  bymonthday : Array[Int]
  bymonth : Array[Int]
} derive(Eq, @debug.Debug)

///|
/// RFC-style duration subset used by VEVENT DURATION.
pub(all) struct Duration {
  negative : Bool
  weeks : Int
  days : Int
  hours : Int
  minutes : Int
  seconds : Int
} derive(Eq, @debug.Debug)

///|
/// A VEVENT record with the fields MoonCal v1 understands.
pub(all) struct Event {
  uid : String
  start : DateTime
  end : DateTime?
  summary : String
  description : String?
  location : String?
  status : String?
  url : String?
  categories : Array[String]
  created : DateTime?
  last_modified : DateTime?
  sequence : Int?
  rrule : RRule?
  duration : Duration?
  rdate : Array[DateTime]
  exdate : Array[DateTime]
  raw : Array[IcsProperty]
} derive(@debug.Debug)

///|
/// A parsed VCALENDAR document.
pub(all) struct Calendar {
  version : String?
  prodid : String?
  events : Array[Event]
  properties : Array[IcsProperty]
} derive(@debug.Debug)

///|
/// A concrete occurrence of an event after expanding recurrence data.
pub(all) struct Occurrence {
  uid : String
  start : DateTime
  end : DateTime?
  summary : String
} derive(Eq, @debug.Debug)

///|
/// A validation or analysis note.
pub(all) struct Diagnostic {
  code : String
  message : String
  severity : String
} derive(Eq, @debug.Debug)

///|
/// Human-readable summary for CLI output and README examples.
pub(all) struct CalendarSummary {
  event_count : Int
  recurring_event_count : Int
  all_day_event_count : Int
  earliest : DateTime?
  latest : DateTime?
  diagnostics : Array[Diagnostic]
} derive(@debug.Debug)
