# MoonCal 接口说明

## 数据类型

- `DateTime`：日期或日期时间，包含全天和 UTC 标记。
- `IcsProperty`：折行展开后的属性名、参数、值和来源行号。
- `RRule`：已解析的重复规则和受支持过滤条件。
- `Duration`：事件持续时间。
- `Event`：`VEVENT` 事件字段和常用元数据。
- `Task`：`VTODO` 待办任务字段、状态、优先级、完成进度和关联关系。
- `FreeBusyPeriod`：一个 `FREEBUSY` 时间段。
- `FreeBusy`：`VFREEBUSY` 组件及其忙碌/空闲时间段。
- `Calendar`：已解析的 `VCALENDAR`，包含事件、任务、空闲忙碌组件和顶层属性。
- `Occurrence`：重复规则展开后的具体事件实例。
- `CalendarSummary`：日历摘要、日期边界和验证诊断。
- `TaskSummary`：任务数量、打开任务、完成任务、高优先级任务和到期日期摘要。
- `FreeBusySummary`：空闲忙碌组件数量、时间段数量和时间边界摘要。
- `MoonCalError`：解析、验证和展开过程中的类型化错误。

## 解析

```moonbit
let result = @mooncal.parse(text)
```

`parse` 返回 `Result[Calendar, MoonCalError]`。输入必须包含一个完整的 `VCALENDAR` 包装，组件必须正确闭合。`VEVENT` 需要 `UID` 和 `DTSTART`，`VTODO` 需要 `UID`。

## 重复规则

```moonbit
let rule = @mooncal.parse_rule("FREQ=WEEKLY;COUNT=3;BYDAY=MO,WE")
```

当前支持 `FREQ`、`INTERVAL`、`COUNT`、`UNTIL`、`BYDAY`、`BYMONTHDAY` 和 `BYMONTH`。不支持的规则片段会返回 `InvalidRRule`，不会被静默忽略。

## 持续时间

```moonbit
let duration = @mooncal.parse_duration("PT45M")
```

MoonCal 支持 `P2W` 这类周持续时间，也支持 `P1DT2H30M` 这类日期和时间组合。事件包含 `DURATION` 时，事件展开会用它计算结束时间。同一个事件同时包含 `DTEND` 和 `DURATION` 会被拒绝。

## 事件展开

```moonbit
let from = @mooncal.DateTime(2026, 8, 1)
let until = @mooncal.DateTime(2026, 8, 31, hour=23, minute=59, second=59)
let items = @mooncal.occurrences_between(calendar, from, until, limit=128)
```

事件展开是确定性的，并受 `limit` 限制。`EXDATE` 会排除匹配日期，`RDATE` 会加入额外发生时间。

常用事件查询：

- `events_between(calendar, from, until)`：筛选原始事件；
- `occurrences_on_date(calendar, date, limit=...)`：展开指定日期事件；
- `next_occurrences(calendar, after, limit=...)`：查询后续事件。

## 任务处理

`VTODO` 任务会被解析到 `calendar.tasks`。常用字段包括 `DUE`、`COMPLETED`、`STATUS`、`PRIORITY`、`PERCENT-COMPLETE`、`CATEGORIES` 和 `RELATED-TO`。

常用任务接口：

- `find_task(calendar, uid)`：按 `UID` 查找任务；
- `open_tasks(calendar)`：返回未完成、未取消任务；
- `completed_tasks(calendar)`：返回已完成任务；
- `cancelled_tasks(calendar)`：返回已取消任务；
- `overdue_tasks(calendar, as_of)`：按调用方给定日期判断逾期任务；
- `tasks_due_between(calendar, from, until)`：返回时间窗口内到期任务；
- `tasks_due_on_date(calendar, date)`：返回指定日期到期任务；
- `high_priority_tasks(calendar)`：返回优先级 1 到 4 的任务；
- `summarize_tasks(calendar)`：生成任务摘要。

## 空闲忙碌时间段

`VFREEBUSY` 会被解析到 `calendar.freebusy`。`FREEBUSY` 支持 `start/end` 和 `start/duration` 两种形式，并识别 `BUSY`、`BUSY-TENTATIVE`、`BUSY-UNAVAILABLE`、`FREE`。

常用空闲忙碌接口：

- `freebusy_periods_between(calendar, from, until)`：返回窗口内全部时间段；
- `busy_periods_between(calendar, from, until)`：只返回忙碌时间段；
- `free_periods_between(calendar, from, until)`：只返回显式空闲时间段；
- `time_is_busy(calendar, moment)`：判断指定时刻是否处于忙碌时间段；
- `next_busy_periods(calendar, after, limit=...)`：查询后续忙碌时间段；
- `summarize_freebusy(calendar)`：生成空闲忙碌摘要。

## 验证诊断

- `validate_calendar(calendar)`：验证整个日历；
- `validate_event(event)`：验证一个事件；
- `validate_task(task)`：验证一个任务；
- `validate_freebusy(item)`：验证一个空闲忙碌组件。

验证器会检查重复 `UID`、未知状态、任务优先级范围、完成进度范围、任务到期时间、空闲忙碌时间段边界、未知 `FBTYPE` 等问题。诊断分为 `info`、`warning` 和 `error`。

## 导出

- `summary_to_text(summary)`：文本摘要；
- `summary_to_json(summary)`：摘要 JSON；
- `task_summary_to_json(summary)`：任务摘要 JSON；
- `freebusy_summary_to_json(summary)`：空闲忙碌摘要 JSON；
- `calendar_to_json(calendar)`：完整日历 JSON；
- `event_to_json(event)`：单个事件 JSON；
- `task_to_json(task)`：单个任务 JSON；
- `freebusy_to_json(item)`：单个空闲忙碌组件 JSON；
- `occurrences_to_json(items)`：事件实例 JSON；
- `calendar_to_ics(calendar)`：导出 `VCALENDAR`；
- `event_to_ics(event)`：导出 `VEVENT`；
- `task_to_ics(task)`：导出 `VTODO`；
- `freebusy_to_ics(item)`：导出 `VFREEBUSY`。

这些 JSON 输出用于命令行、示例和轻量集成场景，保持字段稳定和结果确定，但不承诺覆盖完整 JSON Schema。
