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
pub fn task_is_completed(task : Task) -> Bool {
  if task.completed is Some(_) {
    return true
  }
  if task.status is Some(status) {
    if status == "COMPLETED" {
      return true
    }
  }
  match task.percent_complete {
    Some(value) => value >= 100
    None => false
  }
}

///|
pub fn task_is_cancelled(task : Task) -> Bool {
  task.status == Some("CANCELLED")
}

///|
pub fn task_is_in_process(task : Task) -> Bool {
  task.status == Some("IN-PROCESS")
}

///|
pub fn task_is_open(task : Task) -> Bool {
  !task_is_completed(task) && !task_is_cancelled(task)
}

///|
pub fn task_is_overdue(task : Task, as_of : DateTime) -> Bool {
  if !task_is_open(task) {
    return false
  }
  match task.due {
    Some(due) => due.before(as_of)
    None => false
  }
}

///|
pub fn task_due_on_date(task : Task, date : DateTime) -> Bool {
  match task.due {
    Some(due) => due.same_day(date)
    None => false
  }
}

///|
pub fn task_due_between(task : Task, from : DateTime, until : DateTime) -> Bool {
  match task.due {
    Some(due) => !due.before(from) && !due.after(until)
    None => false
  }
}

///|
pub fn find_task(calendar : Calendar, uid : String) -> Task? {
  for task in calendar.tasks {
    if task.uid == uid {
      return Some(task)
    }
  }
  None
}

///|
pub fn open_tasks(calendar : Calendar) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_is_open(task) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn completed_tasks(calendar : Calendar) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_is_completed(task) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn cancelled_tasks(calendar : Calendar) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_is_cancelled(task) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn overdue_tasks(calendar : Calendar, as_of : DateTime) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_is_overdue(task, as_of) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn tasks_due_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_due_between(task, from, until) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn tasks_due_on_date(calendar : Calendar, date : DateTime) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task_due_on_date(task, date) {
      result.push(task)
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn high_priority_tasks(calendar : Calendar) -> Array[Task] {
  let result : Array[Task] = []
  for task in calendar.tasks {
    if task.priority is Some(value) {
      if value > 0 && value <= 4 {
        result.push(task)
      }
    }
  }
  sort_tasks_by_due(result)
  result
}

///|
pub fn summarize_tasks(calendar : Calendar) -> TaskSummary {
  let mut open_task_count = 0
  let mut completed_task_count = 0
  let mut in_process_task_count = 0
  let mut cancelled_task_count = 0
  let mut high_priority_task_count = 0
  let mut due_task_count = 0
  let mut earliest_due : DateTime? = None
  let mut latest_due : DateTime? = None
  for task in calendar.tasks {
    if task_is_open(task) {
      open_task_count = open_task_count + 1
    }
    if task_is_completed(task) {
      completed_task_count = completed_task_count + 1
    }
    if task_is_in_process(task) {
      in_process_task_count = in_process_task_count + 1
    }
    if task_is_cancelled(task) {
      cancelled_task_count = cancelled_task_count + 1
    }
    if task.priority is Some(value) {
      if value > 0 && value <= 4 {
        high_priority_task_count = high_priority_task_count + 1
      }
    }
    if task.due is Some(due) {
      due_task_count = due_task_count + 1
      earliest_due = min_datetime(earliest_due, due)
      latest_due = max_datetime(latest_due, due)
    }
  }
  TaskSummary::{
    task_count: calendar.tasks.length(),
    open_task_count,
    completed_task_count,
    in_process_task_count,
    cancelled_task_count,
    high_priority_task_count,
    due_task_count,
    earliest_due,
    latest_due,
  }
}

///|
pub fn freebusy_period_overlaps(
  period : FreeBusyPeriod,
  from : DateTime,
  until : DateTime,
) -> Bool {
  !period.end.before(from) && !period.start.after(until)
}

///|
pub fn freebusy_period_contains(
  period : FreeBusyPeriod,
  moment : DateTime,
) -> Bool {
  !moment.before(period.start) && moment.before(period.end)
}

///|
pub fn freebusy_is_busy_type(period : FreeBusyPeriod) -> Bool {
  period.busy_type == "BUSY" ||
  period.busy_type == "BUSY-TENTATIVE" ||
  period.busy_type == "BUSY-UNAVAILABLE"
}

///|
pub fn freebusy_periods_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
) -> Array[FreeBusyPeriod] {
  let result : Array[FreeBusyPeriod] = []
  for item in calendar.freebusy {
    for period in item.periods {
      if freebusy_period_overlaps(period, from, until) {
        result.push(period)
      }
    }
  }
  sort_freebusy_periods(result)
  result
}

///|
pub fn busy_periods_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
) -> Array[FreeBusyPeriod] {
  let result : Array[FreeBusyPeriod] = []
  for period in freebusy_periods_between(calendar, from, until) {
    if freebusy_is_busy_type(period) {
      result.push(period)
    }
  }
  result
}

///|
pub fn free_periods_between(
  calendar : Calendar,
  from : DateTime,
  until : DateTime,
) -> Array[FreeBusyPeriod] {
  let result : Array[FreeBusyPeriod] = []
  for period in freebusy_periods_between(calendar, from, until) {
    if period.busy_type == "FREE" {
      result.push(period)
    }
  }
  result
}

///|
pub fn time_is_busy(calendar : Calendar, moment : DateTime) -> Bool {
  for item in calendar.freebusy {
    for period in item.periods {
      if freebusy_is_busy_type(period) &&
        freebusy_period_contains(period, moment) {
        return true
      }
    }
  }
  false
}

///|
pub fn next_busy_periods(
  calendar : Calendar,
  after : DateTime,
  limit? : Int = 10,
) -> Array[FreeBusyPeriod] {
  let horizon = after.add_days(366)
  let result : Array[FreeBusyPeriod] = []
  for period in busy_periods_between(calendar, after, horizon) {
    if !period.end.before(after) && result.length() < limit {
      result.push(period)
    }
  }
  result
}

///|
pub fn summarize_freebusy(calendar : Calendar) -> FreeBusySummary {
  let mut period_count = 0
  let mut busy_period_count = 0
  let mut tentative_period_count = 0
  let mut unavailable_period_count = 0
  let mut free_period_count = 0
  let mut earliest_start : DateTime? = None
  let mut latest_end : DateTime? = None
  for item in calendar.freebusy {
    for period in item.periods {
      period_count = period_count + 1
      if period.busy_type == "BUSY" {
        busy_period_count = busy_period_count + 1
      } else if period.busy_type == "BUSY-TENTATIVE" {
        tentative_period_count = tentative_period_count + 1
      } else if period.busy_type == "BUSY-UNAVAILABLE" {
        unavailable_period_count = unavailable_period_count + 1
      } else if period.busy_type == "FREE" {
        free_period_count = free_period_count + 1
      }
      earliest_start = min_datetime(earliest_start, period.start)
      latest_end = max_datetime(latest_end, period.end)
    }
  }
  FreeBusySummary::{
    component_count: calendar.freebusy.length(),
    period_count,
    busy_period_count,
    tentative_period_count,
    unavailable_period_count,
    free_period_count,
    earliest_start,
    latest_end,
  }
}

///|
fn sort_tasks_by_due(values : Array[Task]) -> Unit {
  for i in 1..<values.length() {
    let current = values[i]
    let mut j = i
    while j > 0 && task_compare_by_due(current, values[j - 1]) < 0 {
      values[j] = values[j - 1]
      j = j - 1
    }
    values[j] = current
  }
}

///|
fn task_compare_by_due(left : Task, right : Task) -> Int {
  match (left.due, right.due) {
    (Some(a), Some(b)) => a.compare(b)
    (Some(_), None) => -1
    (None, Some(_)) => 1
    (None, None) => left.uid.compare(right.uid)
  }
}

///|
fn sort_freebusy_periods(values : Array[FreeBusyPeriod]) -> Unit {
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
fn min_datetime(current : DateTime?, candidate : DateTime) -> DateTime? {
  match current {
    Some(value) =>
      if candidate.before(value) {
        Some(candidate)
      } else {
        Some(value)
      }
    None => Some(candidate)
  }
}

///|
fn max_datetime(current : DateTime?, candidate : DateTime) -> DateTime? {
  match current {
    Some(value) =>
      if candidate.after(value) {
        Some(candidate)
      } else {
        Some(value)
      }
    None => Some(candidate)
  }
}

///|
pub fn summarize(calendar : Calendar) -> CalendarSummary {
  let diagnostics = validate_calendar(calendar)
  let task_summary = summarize_tasks(calendar)
  let freebusy_summary = summarize_freebusy(calendar)
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
    earliest = min_datetime(earliest, event.start)
    latest = max_datetime(latest, event.start)
  }
  for task in calendar.tasks {
    if task.start is Some(start) {
      earliest = min_datetime(earliest, start)
      latest = max_datetime(latest, start)
    }
    if task.due is Some(due) {
      earliest = min_datetime(earliest, due)
      latest = max_datetime(latest, due)
    }
  }
  for item in calendar.freebusy {
    for period in item.periods {
      earliest = min_datetime(earliest, period.start)
      latest = max_datetime(latest, period.end)
    }
  }
  CalendarSummary::{
    event_count: calendar.events.length(),
    recurring_event_count,
    all_day_event_count,
    task_count: task_summary.task_count,
    open_task_count: task_summary.open_task_count,
    completed_task_count: task_summary.completed_task_count,
    blocked_time_count: freebusy_summary.component_count,
    blocked_period_count: freebusy_summary.period_count,
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
