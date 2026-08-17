///|
test "public parse and analyze" {
  match @mooncal.analyze(@mooncal.sample_ics) {
    Ok(summary) => {
      @test.assert_eq(summary.event_count, 2)
      @test.assert_eq(summary.recurring_event_count, 1)
      @test.assert_eq(summary.task_count, 3)
      @test.assert_eq(summary.blocked_period_count, 4)
    }
    Err(_) => panic()
  }
}

///|
test "public rrule parser" {
  match @mooncal.parse_rule("FREQ=DAILY;COUNT=2") {
    Ok(rule) => {
      @test.assert_eq(rule.freq, @mooncal.Daily)
      @test.assert_eq(rule.count, Some(2))
    }
    Err(_) => panic()
  }
}

///|
test "public occurrence expansion" {
  match @mooncal.parse(@mooncal.sample_ics) {
    Ok(calendar) => {
      let from = @mooncal.DateTime(2026, 8, 1)
      let until = @mooncal.DateTime(2026, 8, 31)
      match @mooncal.occurrences_between(calendar, from, until, limit=32) {
        Ok(items) => assert_true(items.length() >= 3)
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "public task query helpers" {
  match @mooncal.parse(@mooncal.sample_ics) {
    Ok(calendar) => {
      let open = @mooncal.open_tasks(calendar)
      let due = @mooncal.tasks_due_on_date(
        calendar,
        @mooncal.DateTime(2026, 8, 18),
      )
      @test.assert_eq(open.length(), 2)
      @test.assert_eq(due.length(), 1)
      assert_true(@mooncal.find_task(calendar, "demo-docs") is Some(_))
    }
    Err(_) => panic()
  }
}

///|
test "public freebusy query helpers" {
  match @mooncal.parse(@mooncal.sample_ics) {
    Ok(calendar) => {
      let from = @mooncal.DateTime(2026, 8, 1)
      let until = @mooncal.DateTime(2026, 8, 31)
      let busy = @mooncal.busy_periods_between(calendar, from, until)
      @test.assert_eq(busy.length(), 3)
      assert_true(
        @mooncal.time_is_busy(
          calendar,
          @mooncal.DateTime(2026, 8, 3, hour=9, minute=5),
        ),
      )
    }
    Err(_) => panic()
  }
}

///|
test "public task and freebusy json exports" {
  match @mooncal.parse(@mooncal.sample_ics) {
    Ok(calendar) => {
      let task_json = @mooncal.task_to_json(calendar.tasks[0])
      let freebusy_json = @mooncal.freebusy_to_json(calendar.freebusy[0])
      assert_true(task_json.contains("demo-docs"))
      assert_true(freebusy_json.contains("demo-availability"))
    }
    Err(_) => panic()
  }
}
