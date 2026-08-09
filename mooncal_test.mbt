///|
test "public parse and analyze" {
  match @mooncal.analyze(@mooncal.sample_ics) {
    Ok(summary) => {
      @test.assert_eq(summary.event_count, 2)
      @test.assert_eq(summary.recurring_event_count, 1)
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
