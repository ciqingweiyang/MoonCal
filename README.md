# MoonCal

MoonCal 是一个 MoonBit 原生 iCalendar 工具库，用于解析 `.ics` 日历文本、校验 `VEVENT` 事件数据，并展开常见 `RRULE` 重复日程规则。

## 项目状态

黑客松版本：v0.1.1。

项目可在本地正常检查、构建和测试，包含命令行示例、可运行基础示例，以及 44 个测试用例，覆盖解析器、重复规则、持续时间、导出、查询辅助、验证诊断和错误路径。

## 功能范围

- 支持 iCalendar 折行展开；
- 支持 `VCALENDAR` 和 `VEVENT` 结构解析；
- 支持属性参数，例如 `DTSTART;VALUE=DATE`；
- 支持 `UID`、`DTSTART`、`DTEND`、`DURATION`、`SUMMARY`、`DESCRIPTION`、`LOCATION`；
- 支持 `STATUS`、`URL`、`CATEGORIES`、`CREATED`、`LAST-MODIFIED`、`SEQUENCE` 等常用事件元数据；
- 支持 `RRULE` 中的 `FREQ`、`INTERVAL`、`COUNT`、`UNTIL`、`BYDAY`、`BYMONTHDAY`、`BYMONTH`；
- 支持 `DAILY`、`WEEKLY`、`MONTHLY`、`YEARLY` 四类常见重复频率；
- 支持 `RDATE` 追加日期和 `EXDATE` 排除日期；
- 提供日历摘要、事件展开、JSON 输出和基础 ICS 导出能力。

## 非目标范围

- 不做 CalDAV 网络同步；
- 不内置完整时区数据库和 `VTIMEZONE` 解析；
- 不实现提醒、待办、日志、参会人、组织者等完整日历协作流程；
- 不覆盖 `BYSETPOS`、`WKST`、`1MO` 这类序数星期等全部高级 `RRULE` 组合；
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
  }
  Err(err) => println(@mooncal.error_to_text(err))
}
```

## 命令行示例

```bash
moon run cmd/main
moon run cmd/main -- --json
```

命令行示例会分析内置日历样例，并输出文本摘要或 JSON 摘要。文件输入不属于 v0.1.1 范围，以保持核心库在不同 MoonBit 目标上的可移植性。

## API 概览

| API | 用途 |
| --- | --- |
| `parse(input)` | 解析 `VCALENDAR` 文档 |
| `parse_rule(input)` | 解析单条 `RRULE` 值 |
| `occurrences_between(calendar, from, until, limit=...)` | 展开指定时间窗口内的事件 |
| `analyze(input)` | 解析日历并生成摘要 |
| `summary_to_text(summary)` | 输出适合命令行展示的文本摘要 |
| `summary_to_json(summary)` | 输出摘要 JSON |
| `calendar_to_json(calendar)` | 输出解析后的日历 JSON |
| `calendar_to_ics(calendar)` | 导出基础 `VCALENDAR` 文本 |
| `error_to_text(err)` | 将类型化错误转换为可读文本 |
| `validate_calendar(calendar)` | 返回日历验证诊断 |
| `events_between(calendar, from, until)` | 按时间窗口筛选事件 |
| `occurrences_on_date(calendar, date)` | 展开指定日期的事件 |
| `next_occurrences(calendar, after)` | 查询后续即将发生的事件 |

## 项目定位

MoonCal 补足 MoonBit 生态中日历数据处理能力的空白。它适用于排期工具、提醒工具、静态站点生成器、测试数据处理器，以及需要稳定解析日历数据的自动化或 agent 工作流。

项目选择用 MoonBit 原生实现，不依赖 JavaScript、C 或其他语言库封装，便于在 MoonBit 生态中直接复用、测试、发布和维护。

## 验收材料

验收自查、撞车检查和本地验证记录见 `docs/ACCEPTANCE_SELF_CHECK.md`。

## 原创性与参考

MoonCal 是原创 MoonBit 实现。项目参考公开 iCalendar 标准 RFC 5545 的格式和概念说明，但没有复制其他项目代码。测试样例由项目自行构造。

## 许可证

Apache-2.0。
