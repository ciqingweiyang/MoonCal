///|
pub fn event_effective_end(event : Event) -> DateTime? {
  match event.end {
    Some(value) => Some(value)
    None =>
      match event.duration {
        Some(duration) => Some(duration.apply(event.start))
        None =>
          if event.start.is_date {
            Some(event.start.add_days(1))
          } else {
            None
          }
      }
  }
}

///|
pub fn event_is_recurring(event : Event) -> Bool {
  event.rrule is Some(_) || !event.rdate.is_empty()
}

///|
pub fn event_overlaps(event : Event, from : DateTime, until : DateTime) -> Bool {
  let finish = match event_effective_end(event) {
    Some(value) => value
    None => event.start
  }
  !finish.before(from) && !event.start.after(until)
}

///|
pub fn events_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
) -> Array[Event] {
  let result : Array[Event] = []
  for event in calendar.events {
    if event_overlaps(event, from, until) {
      result.push(event)
    }
  }
  result
}

///|
pub fn occurrences_on_date(
  calendar : Calendar,
  date : DateTime,
  limit? : Int = 128,
) -> Result[Array[Occurrence], MoonCalError] {
  let from = DateTime(date.year, date.month, date.day)
  let until = DateTime(
    date.year,
    date.month,
    date.day,
    hour=23,
    minute=59,
    second=59,
  )
  occurrences_between(calendar, from, until, limit~)
}

///|
pub fn next_occurrences(
  calendar : Calendar,
  after : DateTime,
  limit? : Int = 10,
) -> Result[Array[Occurrence], MoonCalError] {
  let horizon = after.add_days(366)
  match occurrences_between(calendar, after, horizon, limit=limit * 4) {
    Ok(items) => {
      let result : Array[Occurrence] = []
      for item in items {
        if !item.start.before(after) && result.length() < limit {
          result.push(item)
        }
      }
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

///|
pub fn expand_calendar_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
  limit? : Int = 256,
) -> Result[Array[Occurrence], MoonCalError] {
  if until.before(from) {
    return Err(
      InvalidCalendar(message="occurrence window end must not be before start"),
    )
  }
  let all : Array[Occurrence] = []
  for event in calendar.events {
    match expand_event_between(event, from, until, limit~) {
      Ok(items) => all.append(items)
      Err(err) => return Err(err)
    }
    if all.length() > limit {
      return Err(LimitExceeded(limit~))
    }
  }
  sort_occurrences(all)
  Ok(all)
}

///|
pub fn expand_event_between(
  event : Event,
  from : DateTime,
  until : DateTime,
  limit? : Int = 256,
) -> Result[Array[Occurrence], MoonCalError] {
  let out : Array[Occurrence] = []
  match event.rrule {
    Some(rule) => {
      let stop = match rule.until {
        Some(rule_until) =>
          if rule_until.before(until) {
            rule_until
          } else {
            until
          }
        None => until
      }
      let mut candidate = event.start
      let mut generated = 0
      let mut steps = 0
      while !candidate.after(stop) && steps < 50000 {
        if rrule_matches_start(rule, event.start, candidate) {
          generated = generated + 1
          if rule.count is Some(max_count) {
            if generated > max_count {
              break
            }
          }
          if !candidate.before(from) &&
            !candidate.after(until) &&
            !contains_datetime(event.exdate, candidate) {
            push_occurrence_once(out, make_occurrence(event, candidate))
          }
        }
        candidate = candidate.add_days(1)
        steps = steps + 1
      }
      if steps >= 50000 {
        return Err(LimitExceeded(limit=50000))
      }
    }
    None =>
      if event_overlaps(event, from, until) &&
        !contains_datetime(event.exdate, event.start) {
        push_occurrence_once(out, make_occurrence(event, event.start))
      }
  }
  for extra in event.rdate {
    if !extra.before(from) &&
      !extra.after(until) &&
      !contains_datetime(event.exdate, extra) {
      push_occurrence_once(out, make_occurrence(event, extra))
    }
  }
  sort_occurrences(out)
  if out.length() > limit {
    Err(LimitExceeded(limit~))
  } else {
    Ok(out)
  }
}

///|
fn make_occurrence(event : Event, start : DateTime) -> Occurrence {
  let end = match event_effective_end(event) {
    Some(finish) => {
      let diff = event.start.seconds_until(finish)
      Some(start.add_seconds(diff))
    }
    None => None
  }
  Occurrence::{ uid: event.uid, start, end, summary: event.summary }
}

///|
fn contains_datetime(values : Array[DateTime], needle : DateTime) -> Bool {
  for value in values {
    if value == needle {
      return true
    }
  }
  false
}

///|
fn push_occurrence_once(values : Array[Occurrence], item : Occurrence) -> Unit {
  for existing in values {
    if existing.uid == item.uid && existing.start == item.start {
      return
    }
  }
  values.push(item)
}

///|
fn sort_occurrences(values : Array[Occurrence]) -> Unit {
  for i in 1..<values.length() {
    let current = values[i]
    let mut j = i
    while j > 0 && current.start.before(values[j - 1].start) {
      values[j] = values[j - 1]
      j = j - 1
    }
    values[j] = current
  }
}

///|
pub fn summarize(calendar : Calendar) -> CalendarSummary {
  let diagnostics = validate_calendar(calendar)
  let mut recurring_event_count = 0
  let mut all_day_event_count = 0
  let mut earliest : DateTime? = None
  let mut latest : DateTime? = None
  for event in calendar.events {
    if event_is_recurring(event) {
      recurring_event_count = recurring_event_count + 1
    }
    if event.start.is_date {
      all_day_event_count = all_day_event_count + 1
    }
    earliest = match earliest {
      Some(value) =>
        if event.start.before(value) {
          Some(event.start)
        } else {
          Some(value)
        }
      None => Some(event.start)
    }
    latest = match latest {
      Some(value) =>
        if event.start.after(value) {
          Some(event.start)
        } else {
          Some(value)
        }
      None => Some(event.start)
    }
  }
  CalendarSummary::{
    event_count: calendar.events.length(),
    recurring_event_count,
    all_day_event_count,
    earliest,
    latest,
    diagnostics,
  }
}

///|
pub fn find_event(calendar : Calendar, uid : String) -> Event? {
  for event in calendar.events {
    if event.uid == uid {
      return Some(event)
    }
  }
  None
}
