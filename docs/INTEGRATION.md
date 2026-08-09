# Integration Guide

## Add The Package

After publication:

```bash
moon add ciqingweiyang/mooncal
```

Then import it from a package:

```moonbit
import {
  "ciqingweiyang/mooncal" @mooncal,
}
```

## Parse And Expand

```moonbit
match @mooncal.parse(text) {
  Ok(calendar) => {
    let from = @mooncal.DateTime(2026, 8, 1)
    let until = @mooncal.DateTime(2026, 8, 31)
    ignore(@mooncal.occurrences_between(calendar, from, until, limit=64))
  }
  Err(err) => println(@mooncal.error_to_text(err))
}
```

## Target Notes

MoonCal does not depend on native file APIs. The core library is suitable for wasm-gc-oriented packages and small command-line tools.

## Validation Strategy

Use `parse` for structural validation, `validate_calendar` for diagnostics, and `analyze` for a compact summary. Treat unsupported RRULE parts as explicit errors, not silent skips.
