///|
fn must_datetime(input : String) -> DateTime {
  match parse_datetime(input) {
    Ok(value) => value
    Err(_) => panic()
  }
}

///|
fn must_calendar(input : String) -> Calendar {
  match parse(input) {
    Ok(value) => value
    Err(_) => panic()
  }
}

///|
fn must_rule(input : String) -> RRule {
  match parse_rule(input) {
    Ok(value) => value
    Err(_) => panic()
  }
}

///|
test "leap year rules" {
  @test.assert_eq(is_leap_year(2024), true)
  @test.assert_eq(is_leap_year(2100), false)
  @test.assert_eq(is_leap_year(2000), true)
}

///|
test "days in month" {
  @test.assert_eq(days_in_month(2026, 2), 28)
  @test.assert_eq(days_in_month(2024, 2), 29)
  @test.assert_eq(days_in_month(2026, 11), 30)
  @test.assert_eq(days_in_month(2026, 12), 31)
}

///|
test "parse date value" {
  let dt = must_datetime("20260820")
  @test.assert_eq(dt.is_date, true)
  @test.assert_eq(dt.format(), "2026-08-20")
}

///|
test "parse utc date time" {
  let dt = must_datetime("20260803T090000Z")
  @test.assert_eq(dt.is_utc, true)
  @test.assert_eq(dt.format(), "2026-08-03T09:00:00Z")
}

///|
test "reject invalid date time" {
  assert_true(parse_datetime("20260230") is Err(_))
  assert_true(parse_datetime("20260803T250000Z") is Err(_))
}

///|
test "add days over month boundary" {
  @test.assert_eq(must_datetime("20260831").add_days(1).format(), "2026-09-01")
  @test.assert_eq(must_datetime("20260301").add_days(-1).format(), "2026-02-28")
}

///|
test "add seconds over midnight" {
  let dt = must_datetime("20260803T235900Z").add_seconds(90)
  @test.assert_eq(dt.format(), "2026-08-04T00:00:30Z")
}

///|
test "weekday calculation" {
  @test.assert_eq(must_datetime("20260803").weekday(), MO)
  @test.assert_eq(must_datetime("20260809").weekday(), SU)
}

///|
test "seconds until preserves short durations" {
  let a = must_datetime("20260803T090000Z")
  let b = must_datetime("20260803T093000Z")
  @test.assert_eq(a.seconds_until(b), 1800)
}

///|
test "unfold folded lines" {
  let text = "SUMMARY:hello\r\n world\r\nUID:x\r\n"
  match unfold_lines(text) {
    Ok(lines) => {
      @test.assert_eq(lines.length(), 2)
      @test.assert_eq(lines[0].1, "SUMMARY:helloworld")
    }
    Err(_) => panic()
  }
}

///|
test "reject folded first line" {
  assert_true(unfold_lines(" broken\r\n") is Err(_))
}

///|
test "parse property with params" {
  match parse_property_line("DTSTART;VALUE=DATE:20260820", 7) {
    Ok(prop) => {
      @test.assert_eq(prop.name, "DTSTART")
      @test.assert_eq(prop.value, "20260820")
      @test.assert_eq(Map::get_from_string(prop.params, "VALUE"), Some("DATE"))
    }
    Err(_) => panic()
  }
}

///|
test "reject property without colon" {
  assert_true(parse_property_line("SUMMARY missing colon", 1) is Err(_))
}

///|
test "parse sample calendar" {
  let calendar = must_calendar(sample_ics)
  @test.assert_eq(calendar.events.length(), 2)
  @test.assert_eq(calendar.tasks.length(), 3)
  @test.assert_eq(calendar.freebusy.length(), 1)
  @test.assert_eq(calendar.events[0].uid, "demo-standup")
}

///|
test "parse all-day event date parameter" {
  let calendar = must_calendar(sample_ics)
  @test.assert_eq(calendar.events[1].start.is_date, true)
}

///|
test "missing uid fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VEVENT
    #|DTSTART:20260803T090000Z
    #|END:VEVENT
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "missing calendar wrapper fails" {
  assert_true(parse("BEGIN:VEVENT\r\nUID:x\r\nEND:VEVENT\r\n") is Err(_))
}

///|
test "text unescape" {
  @test.assert_eq(
    unescape_text("hello\\, MoonBit\\nnext"),
    "hello, MoonBit\nnext",
  )
}

///|
test "parse weekly rrule" {
  let rule = must_rule("FREQ=WEEKLY;INTERVAL=2;COUNT=5;BYDAY=MO,WE")
  @test.assert_eq(rule.freq, Weekly)
  @test.assert_eq(rule.interval, 2)
  @test.assert_eq(rule.byday.length(), 2)
}

///|
test "parse monthly filters" {
  let rule = must_rule("FREQ=MONTHLY;BYMONTHDAY=1,-1")
  @test.assert_eq(rule.bymonthday.length(), 2)
  @test.assert_eq(rule.bymonthday[1], -1)
}

///|
test "parse yearly month filter" {
  let rule = must_rule("FREQ=YEARLY;BYMONTH=8;BYMONTHDAY=20")
  @test.assert_eq(rule.bymonth[0], 8)
}

///|
test "rrule rejects unsupported part" {
  assert_true(parse_rule("FREQ=DAILY;WKST=MO") is Err(_))
}

///|
test "rrule rejects bad count" {
  assert_true(parse_rule("FREQ=DAILY;COUNT=0") is Err(_))
}

///|
test "weekly expansion honors exdate" {
  let calendar = must_calendar(sample_ics)
  let from = DateTime(2026, 8, 1)
  let until = DateTime(2026, 8, 31, hour=23, minute=59, second=59)
  match occurrences_between(calendar, from, until, limit=32) {
    Ok(items) => {
      @test.assert_eq(items.length(), 4)
      @test.assert_eq(items[0].start.format(), "2026-08-03T09:00:00Z")
      @test.assert_eq(items[1].start.format(), "2026-08-05T09:00:00Z")
      @test.assert_eq(items[2].start.format(), "2026-08-12T09:00:00Z")
    }
    Err(_) => panic()
  }
}

///|
test "daily interval expansion" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VEVENT
    #|UID:daily
    #|DTSTART:20260801T100000Z
    #|RRULE:FREQ=DAILY;INTERVAL=2;COUNT=3
    #|SUMMARY:Daily
    #|END:VEVENT
    #|END:VCALENDAR
  let calendar = must_calendar(text)
  match
    occurrences_between(
      calendar,
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 10),
      limit=10,
    ) {
    Ok(items) => {
      @test.assert_eq(items.length(), 3)
      @test.assert_eq(items[2].start.format(), "2026-08-05T10:00:00Z")
    }
    Err(_) => panic()
  }
}

///|
test "monthly bymonthday expansion" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VEVENT
    #|UID:month
    #|DTSTART:20260801T100000Z
    #|RRULE:FREQ=MONTHLY;COUNT=2;BYMONTHDAY=1
    #|END:VEVENT
    #|END:VCALENDAR
  let calendar = must_calendar(text)
  match
    occurrences_between(
      calendar,
      DateTime(2026, 8, 1),
      DateTime(2026, 10, 1),
      limit=10,
    ) {
    Ok(items) => {
      @test.assert_eq(items.length(), 2)
      @test.assert_eq(items[1].start.format(), "2026-09-01T10:00:00Z")
    }
    Err(_) => panic()
  }
}

///|
test "rdate adds extra occurrence" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VEVENT
    #|UID:rdate
    #|DTSTART:20260801T100000Z
    #|RDATE:20260803T100000Z
    #|END:VEVENT
    #|END:VCALENDAR
  let calendar = must_calendar(text)
  match
    occurrences_between(
      calendar,
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 5),
      limit=10,
    ) {
    Ok(items) => @test.assert_eq(items.length(), 2)
    Err(_) => panic()
  }
}

///|
test "find event by uid" {
  let calendar = must_calendar(sample_ics)
  assert_true(find_event(calendar, "demo-release") is Some(_))
  assert_true(find_event(calendar, "missing") is None)
}

///|
test "summary counts" {
  let summary = summarize(must_calendar(sample_ics))
  @test.assert_eq(summary.event_count, 2)
  @test.assert_eq(summary.recurring_event_count, 1)
  @test.assert_eq(summary.all_day_event_count, 1)
  @test.assert_eq(summary.task_count, 3)
  @test.assert_eq(summary.open_task_count, 2)
  @test.assert_eq(summary.completed_task_count, 1)
  @test.assert_eq(summary.blocked_time_count, 1)
  @test.assert_eq(summary.blocked_period_count, 4)
}

///|
test "summary diagnostics for sparse calendar" {
  let text =
    #|BEGIN:VCALENDAR
    #|BEGIN:VEVENT
    #|UID:x
    #|DTSTART:20260801
    #|END:VEVENT
    #|END:VCALENDAR
  let summary = summarize(must_calendar(text))
  @test.assert_eq(summary.diagnostics.length(), 3)
}

///|
test "json escaping" {
  @test.assert_eq(escape_json("a\"b\nc"), "a\\\"b\\nc")
}

///|
test "ics text escaping" {
  @test.assert_eq(escape_ics_text("a,b;c"), "a\\,b\\;c")
}

///|
test "calendar exports to json" {
  let json = calendar_to_json(must_calendar(sample_ics))
  assert_true(json.contains("\"events\""))
  assert_true(json.contains("\"tasks\""))
  assert_true(json.contains("\"freebusy\""))
  assert_true(json.contains("demo-standup"))
  assert_true(json.contains("demo-docs"))
  assert_true(json.contains("demo-availability"))
}

///|
test "calendar exports to ics" {
  let ics = calendar_to_ics(must_calendar(sample_ics))
  assert_true(ics.contains("BEGIN:VCALENDAR"))
  assert_true(ics.contains("RRULE:FREQ=WEEKLY"))
  assert_true(ics.contains("BEGIN:VTODO"))
  assert_true(ics.contains("BEGIN:VFREEBUSY"))
}

///|
test "parse duration hours and minutes" {
  match parse_duration("PT1H30M") {
    Ok(duration) => {
      @test.assert_eq(duration.hours, 1)
      @test.assert_eq(duration.minutes, 30)
      @test.assert_eq(duration.total_seconds(), 5400)
    }
    Err(_) => panic()
  }
}

///|
test "duration determines event end" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Test//EN
    #|BEGIN:VEVENT
    #|UID:duration
    #|DTSTART:20260801T100000Z
    #|DURATION:PT45M
    #|SUMMARY:Timed
    #|END:VEVENT
    #|END:VCALENDAR
  let calendar = must_calendar(text)
  match
    occurrences_between(
      calendar,
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      limit=4,
    ) {
    Ok(items) =>
      @test.assert_eq(
        items[0].end.map(x => x.format()),
        Some("2026-08-01T10:45:00Z"),
      )
    Err(_) => panic()
  }
}

///|
test "duration and dtend conflict fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VEVENT
    #|UID:bad-duration
    #|DTSTART:20260801T100000Z
    #|DTEND:20260801T110000Z
    #|DURATION:PT30M
    #|END:VEVENT
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "parse event metadata fields" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Test//EN
    #|BEGIN:VEVENT
    #|UID:meta
    #|DTSTART:20260801T100000Z
    #|SUMMARY:Meta
    #|STATUS:CONFIRMED
    #|URL:https://example.com/event
    #|CATEGORIES:MoonBit,Hackathon
    #|CREATED:20260701T000000Z
    #|LAST-MODIFIED:20260702T000000Z
    #|SEQUENCE:2
    #|END:VEVENT
    #|END:VCALENDAR
  let event = must_calendar(text).events[0]
  @test.assert_eq(event.status, Some("CONFIRMED"))
  @test.assert_eq(event.categories.length(), 2)
  @test.assert_eq(event.sequence, Some(2))
}

///|
test "validate duplicate uid" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Test//EN
    #|BEGIN:VEVENT
    #|UID:same
    #|DTSTART:20260801
    #|SUMMARY:A
    #|END:VEVENT
    #|BEGIN:VEVENT
    #|UID:same
    #|DTSTART:20260802
    #|SUMMARY:B
    #|END:VEVENT
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "duplicate-uid"))
}

///|
test "occurrences on date" {
  let calendar = must_calendar(sample_ics)
  match occurrences_on_date(calendar, DateTime(2026, 8, 5), limit=8) {
    Ok(items) => {
      @test.assert_eq(items.length(), 1)
      @test.assert_eq(items[0].uid, "demo-standup")
    }
    Err(_) => panic()
  }
}

///|
test "next occurrences" {
  let calendar = must_calendar(sample_ics)
  match next_occurrences(calendar, DateTime(2026, 8, 4), limit=2) {
    Ok(items) => {
      @test.assert_eq(items.length(), 2)
      @test.assert_eq(items[0].start.format(), "2026-08-05T09:00:00Z")
    }
    Err(_) => panic()
  }
}

///|
test "parse todo metadata fields" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VTODO
    #|UID:task-meta
    #|DTSTART;VALUE=DATE:20260801
    #|DUE;VALUE=DATE:20260810
    #|SUMMARY:Write docs
    #|DESCRIPTION:Cover task APIs
    #|STATUS:IN-PROCESS
    #|PRIORITY:3
    #|PERCENT-COMPLETE:40
    #|CATEGORIES:Docs,Release
    #|URL:https://mooncal.invalid/tasks/task-meta
    #|RELATED-TO:demo-release
    #|END:VTODO
    #|END:VCALENDAR
  let task = must_calendar(text).tasks[0]
  @test.assert_eq(task.uid, "task-meta")
  @test.assert_eq(task.start.map(x => x.format()), Some("2026-08-01"))
  @test.assert_eq(task.due.map(x => x.format()), Some("2026-08-10"))
  @test.assert_eq(task.summary, "Write docs")
  @test.assert_eq(task.description, Some("Cover task APIs"))
  @test.assert_eq(task.status, Some("IN-PROCESS"))
  @test.assert_eq(task.priority, Some(3))
  @test.assert_eq(task.percent_complete, Some(40))
  @test.assert_eq(task.categories.length(), 2)
  @test.assert_eq(task.related_to[0], "demo-release")
}

///|
test "parse completed todo" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VTODO
    #|UID:task-done
    #|COMPLETED:20260804T100000Z
    #|SUMMARY:Done
    #|STATUS:COMPLETED
    #|PERCENT-COMPLETE:100
    #|END:VTODO
    #|END:VCALENDAR
  let task = must_calendar(text).tasks[0]
  assert_true(task_is_completed(task))
  @test.assert_eq(
    task.completed.map(x => x.format()),
    Some("2026-08-04T10:00:00Z"),
  )
}

///|
test "missing todo uid fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VTODO
    #|SUMMARY:No UID
    #|END:VTODO
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "todo due before start fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VTODO
    #|UID:bad-task
    #|DTSTART:20260810T090000Z
    #|DUE:20260809T090000Z
    #|END:VTODO
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "find task by uid" {
  let calendar = must_calendar(sample_ics)
  assert_true(find_task(calendar, "demo-docs") is Some(_))
  assert_true(find_task(calendar, "missing-task") is None)
}

///|
test "open and completed task queries" {
  let calendar = must_calendar(sample_ics)
  let open = open_tasks(calendar)
  let done = completed_tasks(calendar)
  @test.assert_eq(open.length(), 2)
  @test.assert_eq(done.length(), 1)
  @test.assert_eq(open[0].uid, "demo-docs")
  @test.assert_eq(done[0].uid, "demo-tests")
}

///|
test "overdue task query uses caller supplied date" {
  let calendar = must_calendar(sample_ics)
  let overdue = overdue_tasks(calendar, DateTime(2026, 8, 19))
  @test.assert_eq(overdue.length(), 1)
  @test.assert_eq(overdue[0].uid, "demo-docs")
}

///|
test "tasks due between query sorts by due date" {
  let calendar = must_calendar(sample_ics)
  let due = tasks_due_between(
    calendar,
    DateTime(2026, 8, 1),
    DateTime(2026, 8, 20, hour=23, minute=59, second=59),
  )
  @test.assert_eq(due.length(), 2)
  @test.assert_eq(due[0].uid, "demo-docs")
  @test.assert_eq(due[1].uid, "demo-publish")
}

///|
test "tasks due on date query" {
  let calendar = must_calendar(sample_ics)
  let due = tasks_due_on_date(calendar, DateTime(2026, 8, 18))
  @test.assert_eq(due.length(), 1)
  @test.assert_eq(due[0].uid, "demo-docs")
}

///|
test "high priority task query" {
  let calendar = must_calendar(sample_ics)
  let items = high_priority_tasks(calendar)
  @test.assert_eq(items.length(), 2)
  @test.assert_eq(items[0].uid, "demo-docs")
}

///|
test "task summary counts" {
  let summary = summarize_tasks(must_calendar(sample_ics))
  @test.assert_eq(summary.task_count, 3)
  @test.assert_eq(summary.open_task_count, 2)
  @test.assert_eq(summary.completed_task_count, 1)
  @test.assert_eq(summary.in_process_task_count, 1)
  @test.assert_eq(summary.high_priority_task_count, 2)
  @test.assert_eq(summary.due_task_count, 2)
  @test.assert_eq(summary.earliest_due.map(x => x.format()), Some("2026-08-18"))
}

///|
test "task json export" {
  let task = must_calendar(sample_ics).tasks[0]
  let json = task_to_json(task)
  assert_true(json.contains("\"uid\":\"demo-docs\""))
  assert_true(json.contains("\"open\":true"))
  assert_true(json.contains("\"percent_complete\":60"))
}

///|
test "task ics export" {
  let task = must_calendar(sample_ics).tasks[0]
  let ics = task_to_ics(task)
  assert_true(ics.contains("BEGIN:VTODO"))
  assert_true(ics.contains("DUE;VALUE=DATE:20260818"))
  assert_true(ics.contains("RELATED-TO:demo-release"))
}

///|
test "task validation detects invalid status" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VTODO
    #|UID:bad-status
    #|SUMMARY:Bad
    #|STATUS:WAITING
    #|END:VTODO
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "unknown-task-status"))
}

///|
test "task validation detects priority and percent ranges" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VTODO
    #|UID:bad-range
    #|SUMMARY:Bad
    #|PRIORITY:10
    #|PERCENT-COMPLETE:101
    #|END:VTODO
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "priority-out-of-range"))
  assert_true(diagnostics.any(d => d.code == "percent-out-of-range"))
}

///|
test "task validation detects completed task without timestamp" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VTODO
    #|UID:done-without-time
    #|SUMMARY:Done
    #|STATUS:COMPLETED
    #|END:VTODO
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "completed-without-timestamp"))
}

///|
test "duplicate uid across event and task is diagnostic" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//Task Test//EN
    #|BEGIN:VEVENT
    #|UID:shared
    #|DTSTART:20260801T090000Z
    #|SUMMARY:Event
    #|END:VEVENT
    #|BEGIN:VTODO
    #|UID:shared
    #|SUMMARY:Task
    #|END:VTODO
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "duplicate-uid"))
}

///|
test "parse freebusy periods with duration and type" {
  let calendar = must_calendar(sample_ics)
  let item = calendar.freebusy[0]
  @test.assert_eq(item.periods.length(), 4)
  @test.assert_eq(item.periods[1].end.format(), "2026-08-05T09:30:00Z")
  @test.assert_eq(item.periods[2].busy_type, "BUSY-TENTATIVE")
  @test.assert_eq(item.periods[3].busy_type, "FREE")
}

///|
test "freebusy periods between query" {
  let calendar = must_calendar(sample_ics)
  let periods = freebusy_periods_between(
    calendar,
    DateTime(2026, 8, 3),
    DateTime(2026, 8, 6),
  )
  @test.assert_eq(periods.length(), 2)
  @test.assert_eq(periods[0].start.format(), "2026-08-03T09:00:00Z")
}

///|
test "busy periods between excludes free periods" {
  let calendar = must_calendar(sample_ics)
  let periods = busy_periods_between(
    calendar,
    DateTime(2026, 8, 1),
    DateTime(2026, 8, 31),
  )
  @test.assert_eq(periods.length(), 3)
}

///|
test "free periods between returns explicit free windows" {
  let calendar = must_calendar(sample_ics)
  let periods = free_periods_between(
    calendar,
    DateTime(2026, 8, 1),
    DateTime(2026, 8, 31),
  )
  @test.assert_eq(periods.length(), 1)
  @test.assert_eq(periods[0].busy_type, "FREE")
}

///|
test "time is busy checks busy windows" {
  let calendar = must_calendar(sample_ics)
  assert_true(time_is_busy(calendar, DateTime(2026, 8, 3, hour=9, minute=10)))
  assert_true(!time_is_busy(calendar, DateTime(2026, 8, 13, hour=15)))
}

///|
test "next busy periods are sorted and limited" {
  let calendar = must_calendar(sample_ics)
  let periods = next_busy_periods(calendar, DateTime(2026, 8, 4), limit=2)
  @test.assert_eq(periods.length(), 2)
  @test.assert_eq(periods[0].start.format(), "2026-08-05T09:00:00Z")
}

///|
test "freebusy summary counts" {
  let summary = summarize_freebusy(must_calendar(sample_ics))
  @test.assert_eq(summary.component_count, 1)
  @test.assert_eq(summary.period_count, 4)
  @test.assert_eq(summary.busy_period_count, 2)
  @test.assert_eq(summary.tentative_period_count, 1)
  @test.assert_eq(summary.free_period_count, 1)
  @test.assert_eq(
    summary.earliest_start.map(x => x.format()),
    Some("2026-08-03T09:00:00Z"),
  )
}

///|
test "freebusy json export" {
  let json = freebusy_to_json(must_calendar(sample_ics).freebusy[0])
  assert_true(json.contains("\"uid\":\"demo-availability\""))
  assert_true(json.contains("\"busy_type\":\"BUSY-TENTATIVE\""))
  assert_true(json.contains("\"busy\":false"))
}

///|
test "freebusy ics export" {
  let ics = freebusy_to_ics(must_calendar(sample_ics).freebusy[0])
  assert_true(ics.contains("BEGIN:VFREEBUSY"))
  assert_true(ics.contains("FREEBUSY:20260803T090000Z/20260803T093000Z"))
  assert_true(ics.contains("FREEBUSY;FBTYPE=FREE"))
}

///|
test "freebusy missing uid and dtstamp are diagnostics" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//FreeBusy Test//EN
    #|BEGIN:VFREEBUSY
    #|FREEBUSY:20260801T100000Z/20260801T110000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "freebusy-missing-uid"))
  assert_true(diagnostics.any(d => d.code == "freebusy-missing-dtstamp"))
}

///|
test "freebusy empty component is diagnostic" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//FreeBusy Test//EN
    #|BEGIN:VFREEBUSY
    #|UID:empty-freebusy
    #|DTSTAMP:20260801T000000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "freebusy-no-periods"))
}

///|
test "freebusy backwards period fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VFREEBUSY
    #|UID:bad-freebusy
    #|DTSTAMP:20260801T000000Z
    #|FREEBUSY:20260801T110000Z/20260801T100000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "freebusy period outside declared window is diagnostic" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//FreeBusy Test//EN
    #|BEGIN:VFREEBUSY
    #|UID:window
    #|DTSTAMP:20260801T000000Z
    #|DTSTART:20260810T000000Z
    #|DTEND:20260811T000000Z
    #|FREEBUSY:20260809T230000Z/20260810T010000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "freebusy-period-before-window"))
}

///|
test "freebusy unknown type is diagnostic" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|PRODID:-//MoonCal//FreeBusy Test//EN
    #|BEGIN:VFREEBUSY
    #|UID:unknown-type
    #|DTSTAMP:20260801T000000Z
    #|FREEBUSY;FBTYPE=BUSY-MAYBE:20260801T100000Z/20260801T110000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  let diagnostics = validate_calendar(must_calendar(text))
  assert_true(diagnostics.any(d => d.code == "unknown-freebusy-type"))
}

///|
test "freebusy malformed period fails" {
  let text =
    #|BEGIN:VCALENDAR
    #|VERSION:2.0
    #|BEGIN:VFREEBUSY
    #|UID:bad-period
    #|DTSTAMP:20260801T000000Z
    #|FREEBUSY:20260801T100000Z
    #|END:VFREEBUSY
    #|END:VCALENDAR
  assert_true(parse(text) is Err(_))
}

///|
test "summary json includes task and freebusy counts" {
  let json = summary_to_json(summarize(must_calendar(sample_ics)))
  assert_true(json.contains("\"task_count\":3"))
  assert_true(json.contains("\"freebusy_period_count\":4"))
}

///|
test "task summary json export" {
  let json = task_summary_to_json(summarize_tasks(must_calendar(sample_ics)))
  assert_true(json.contains("\"open_task_count\":2"))
  assert_true(json.contains("\"due_task_count\":2"))
}

///|
test "freebusy summary json export" {
  let json = freebusy_summary_to_json(
    summarize_freebusy(must_calendar(sample_ics)),
  )
  assert_true(json.contains("\"period_count\":4"))
  assert_true(json.contains("\"free_period_count\":1"))
}
