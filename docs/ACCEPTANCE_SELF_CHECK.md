# MoonCal Hackathon Acceptance Self-Check

Last checked: 2026-08-09

## Collision Check

Current positioning: MoonCal is a MoonBit-native iCalendar / ICS parser and RRULE occurrence expansion library.

Searches across Mooncakes-oriented results and GitHub did not find an obvious MoonBit package that combines:

- VCALENDAR / VEVENT parsing
- ICS folded-line and property-parameter handling
- RRULE expansion for daily, weekly, monthly, and yearly events
- RDATE / EXDATE handling
- MoonBit-native public APIs, CLI, tests, and examples

Related projects exist in other ecosystems, and general date/time packages exist in MoonBit, but they do not appear to duplicate this project boundary. The project should still avoid claiming complete RFC 5545 coverage, because v0.1.1 intentionally supports a practical subset.

## Acceptance Checklist

| Requirement | Status | Evidence |
| --- | --- | --- |
| MoonBit is the main implementation language | Passed | Core library, tests, CLI, and example are written in `.mbt` files. |
| Public repository is accessible | Ready | Repository URL: `https://github.com/ciqingweiyang/MoonCal`; `moon.mod` points to this URL. |
| Clear and complete README | Passed | `README.md` explains status, features, scope, install, usage, CLI, API, originality, and license. |
| Purpose, features, and usage are documented | Passed | `README.md`, `docs/API.md`, and `docs/INTEGRATION.md`. |
| Runnable example is provided | Passed | `examples/basic` runs with `moon run examples/basic`. |
| CI is configured | Passed | `.github/workflows/ci.yml` runs check, build, test, CLI, JSON CLI, and example. |
| Runnable tests are provided | Passed | `moon test` reports 44 passed, 0 failed. |
| Project builds successfully | Passed | `moon check` and `moon build` pass locally. |
| Published to mooncakes.io | Release target defined | Mooncakes package name: `ciqingweiyang/mooncal`. |
| Development process and commits are traceable | Passed | Repository keeps multiple meaningful commits on `main`. |
| Clear functional boundary and maintenance value | Passed | README documents v0.1.1 support and non-goals; changelog records release scope. |
| Third-party code/assets/dependencies have compatible licenses | Passed | No third-party code or assets are copied; project license is Apache-2.0. |

## Latest Local Verification

The following commands were run successfully on 2026-08-09:

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/main -- --json
moon run examples/basic
```

Test result:

```text
Total tests: 44, passed: 44, failed: 0.
```

## Release Metadata

- GitHub repository: `https://github.com/ciqingweiyang/MoonCal`
- Mooncakes package: `ciqingweiyang/mooncal`
- Version: `0.1.1`
- License: `Apache-2.0`
