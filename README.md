# MoonCal

MoonCal 是一个 MoonBit 原生 iCalendar 工具库，用于解析 `.ics` 日历文本、校验日历数据、展开常见 `RRULE` 重复事件，并处理 `VTODO` 待办任务和 `VFREEBUSY` 空闲忙碌时间段。

## 项目状态

黑客松版本：`0.1.2`。

当前版本包含命令行示例、可运行基础示例和 82 个测试用例。本地统计约 4,189 行有效 MoonBit 代码，已经达到活动说明中 4,000 到 10,000 行参考规模的下限区间。代码规模来自事件解析、重复规则展开、任务处理、空闲忙碌时间段处理、验证诊断、导出和测试，不包含无意义占位代码。

## 功能范围

- 支持 iCalendar 折行展开；
- 支持 `VCALENDAR`、`VEVENT`、`VTODO`、`VFREEBUSY` 结构解析；
- 支持属性参数，例如 `DTSTART;VALUE=DATE` 和 `FREEBUSY;FBTYPE=BUSY-TENTATIVE`；
- 支持事件字段：`UID`、`DTSTART`、`DTEND`、`DURATION`、`SUMMARY`、`DESCRIPTION`、`LOCATION`、`STATUS`、`URL`、`CATEGORIES`、`CREATED`、`LAST-MODIFIED`、`SEQUENCE`；
- 支持重复规则：`FREQ`、`INTERVAL`、`COUNT`、`UNTIL`、`BYDAY`、`BYMONTHDAY`、`BYMONTH`；
- 支持 `DAILY`、`WEEKLY`、`MONTHLY`、`YEARLY` 四类常见重复频率；
- 支持 `RDATE` 追加日期和 `EXDATE` 排除日期；
- 支持待办任务字段：`DUE`、`COMPLETED`、`STATUS`、`PRIORITY`、`PERCENT-COMPLETE`、`RELATED-TO`、`CATEGORIES`；
- 支持任务查询：打开任务、已完成任务、逾期任务、指定日期到期任务、高优先级任务；
- 支持空闲忙碌时间段解析：`BUSY`、`BUSY-TENTATIVE`、`BUSY-UNAVAILABLE`、`FREE`；
- 支持忙碌窗口查询、指定时刻忙碌判断、后续忙碌时间段查询；
- 提供日历摘要、任务摘要、空闲忙碌摘要、JSON 输出和基础 ICS 导出能力。

## 非目标范围

- 不做 CalDAV 网络同步；
- 不内置完整时区数据库和 `VTIMEZONE` 解析；
- 不实现会议邀请回复、参会人状态同步等完整协作流程；
- 不覆盖 `BYSETPOS`、`WKST`、`1MO` 这类高级 `RRULE` 组合；
- 不面向超大 `.ics` 文件的流式解析。

## 安装

通过 Mooncakes 安装：

```bash
moon add ciqingweiyang/mooncal
```

本地开发和验收命令：

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/main -- --json
moon run examples/basic
```

## 最小示例

```moonbit
match @mooncal.parse(@mooncal.sample_ics) {
  Ok(calendar) => {
    let from = @mooncal.DateTime(2026, 8, 1)
    let until = @mooncal.DateTime(2026, 8, 31)
    match @mooncal.occurrences_between(calendar, from, until, limit=32) {
      Ok(items) => println(@mooncal.occurrences_to_json(items))
      Err(err) => println(@mooncal.error_to_text(err))
    }
    let due = @mooncal.tasks_due_on_date(calendar, @mooncal.DateTime(2026, 8, 18))
    println(@mooncal.task_to_json(due[0]))
  }
  Err(err) => println(@mooncal.error_to_text(err))
}
```

## 命令行示例

```bash
moon run cmd/main
moon run cmd/main -- --json
```

命令行示例会分析内置日历样例，并输出文本摘要或 JSON 摘要。文件输入不属于 `0.1.2` 范围，以保持核心库在不同 MoonBit 目标上的可移植性。

## 接口概览

| 接口 | 用途 |
| --- | --- |
| `parse(input)` | 解析 `VCALENDAR` 文档 |
| `parse_rule(input)` | 解析单条 `RRULE` 值 |
| `occurrences_between(calendar, from, until, limit=...)` | 展开指定时间窗口内的事件 |
| `occurrences_on_date(calendar, date)` | 展开指定日期的事件 |
| `next_occurrences(calendar, after)` | 查询后续即将发生的事件 |
| `open_tasks(calendar)` | 查询未完成、未取消的任务 |
| `completed_tasks(calendar)` | 查询已完成任务 |
| `overdue_tasks(calendar, as_of)` | 按调用方给定日期查询逾期任务 |
| `tasks_due_on_date(calendar, date)` | 查询指定日期到期任务 |
| `high_priority_tasks(calendar)` | 查询高优先级任务 |
| `busy_periods_between(calendar, from, until)` | 查询时间窗口内的忙碌时间段 |
| `free_periods_between(calendar, from, until)` | 查询显式空闲时间段 |
| `time_is_busy(calendar, moment)` | 判断某个时刻是否忙碌 |
| `analyze(input)` | 解析日历并生成摘要 |
| `validate_calendar(calendar)` | 返回日历验证诊断 |
| `calendar_to_json(calendar)` | 输出解析后的日历 JSON |
| `calendar_to_ics(calendar)` | 导出基础 `VCALENDAR` 文本 |
| `summary_to_text(summary)` | 输出适合命令行展示的文本摘要 |
| `error_to_text(err)` | 将类型化错误转换为可读文本 |

## 项目定位

MoonCal 补足 MoonBit 生态中日历数据处理能力的空白。它适用于排期工具、提醒工具、静态站点生成器、测试数据处理器，以及需要稳定解析日历数据的自动化流程。

项目选择用 MoonBit 原生实现，不依赖 JavaScript、C 或其他语言库封装，便于在 MoonBit 生态中直接复用、测试、发布和维护。

## 验收材料

验收自查、撞车检查和本地验证记录见 `docs/ACCEPTANCE_SELF_CHECK.md`。

## 原创性与参考

MoonCal 是原创 MoonBit 实现。项目参考公开 iCalendar 标准 RFC 5545 的格式和概念说明，但没有复制其他项目代码。测试样例由项目自行构造。

## 许可证

Apache-2.0。
