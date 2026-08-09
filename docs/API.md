# MoonCal API

## Data Types

- `DateTime`: date or date-time with UTC/all-day flags.
- `IcsProperty`: unfolded property name, parameters, value, and source line.
- `RRule`: parsed recurrence rule with supported filters.
- `Duration`: parsed VEVENT `DURATION` value.
- `Event`: parsed VEVENT fields and selected metadata.
- `Calendar`: parsed VCALENDAR plus event list.
- `Occurrence`: one expanded event occurrence.
- `CalendarSummary`: counts, date bounds, and diagnostics.
- `MoonCalError`: typed parser, validation, and expansion errors.

## Parsing

```moonbit
let result = @mooncal.parse(text)
```

`parse` returns `Result[Calendar, MoonCalError]`. It requires one `VCALENDAR` wrapper and closed `VEVENT` blocks. Every VEVENT requires `UID` and `DTSTART`.

## RRULE

```moonbit
let rule = @mooncal.parse_rule("FREQ=WEEKLY;COUNT=3;BYDAY=MO,WE")
```

Supported parts are `FREQ`, `INTERVAL`, `COUNT`, `UNTIL`, `BYDAY`, `BYMONTHDAY`, and `BYMONTH`. Unsupported parts return `InvalidRRule`.

## Duration

```moonbit
let duration = @mooncal.parse_duration("PT45M")
```

MoonCal supports week durations such as `P2W` and day/time durations such as `P1DT2H30M`. If a VEVENT contains `DURATION`, occurrence expansion uses it to compute end times. A VEVENT containing both `DTEND` and `DURATION` is rejected.

## Expansion

```moonbit
let from = @mooncal.DateTime(2026, 8, 1)
let until = @mooncal.DateTime(2026, 8, 31, hour=23, minute=59, second=59)
let items = @mooncal.occurrences_between(calendar, from, until, limit=128)
```

Expansion is deterministic and guarded by a limit. `EXDATE` removes matching generated dates. `RDATE` adds explicit occurrences.

## Validation And Query Helpers

- `validate_calendar(calendar)` returns diagnostics.
- `validate_event(event)` validates one event.
- `events_between(calendar, from, until)` filters raw events.
- `occurrences_on_date(calendar, date, limit=...)` expands one day.
- `next_occurrences(calendar, after, limit=...)` returns upcoming occurrences.

## Export

- `summary_to_text`
- `summary_to_json`
- `calendar_to_json`
- `occurrences_to_json`
- `calendar_to_ics`

The JSON writers are small deterministic serializers for CLI and examples, not a full JSON schema contract.
