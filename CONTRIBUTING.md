# Contributing

MoonCal keeps v1 deliberately small. Contributions should preserve deterministic behavior and clear error paths.

Before opening a pull request:

```bash
moon fmt
moon check
moon build
moon test
moon run cmd/main
moon run examples/basic
```

New parser or recurrence behavior should include tests for valid input, invalid input, and boundary cases.
