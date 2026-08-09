# MoonCal 项目申报书

## 基本信息

- 项目名称：MoonCal：MoonBit 原生 iCalendar / RRULE 日程解析与重复事件展开库
- 参赛者：刘瑞彤
- 联系方式：15613701896
- GitHub 仓库链接：https://github.com/ciqingweiyang/MoonCal
- Mooncakes 包名：ciqingweiyang/mooncal
- 项目方向：MoonBit 日历数据基础库 / 开发工具
- 是否为移植项目：否，原创项目
- 许可证：Apache-2.0

## 项目简介

MoonCal 是一个用 MoonBit 编写的 iCalendar 工具库，聚焦 `.ics` 日历文本解析、VEVENT 事件建模、常见 RRULE 重复规则展开，以及面向应用集成的查询、验证和导出能力。它适合提醒工具、排期工具、静态站点、测试数据处理、自动化脚本和 agent 工作流中对日历数据的轻量解析需求。

项目 v0.1.0 的边界非常明确：先做好 MoonBit 生态缺少的可复用日历基础库，不做 CalDAV 网络同步、完整时区数据库、会议邀请协作、提醒闹钟等重型日历客户端功能。

## 主要功能

- 解析 `VCALENDAR` / `VEVENT` 结构；
- 支持 iCalendar 折行展开和属性参数，例如 `DTSTART;VALUE=DATE`；
- 支持 `UID`、`DTSTART`、`DTEND`、`DURATION`、`SUMMARY`、`DESCRIPTION`、`LOCATION`；
- 支持 `STATUS`、`URL`、`CATEGORIES`、`CREATED`、`LAST-MODIFIED`、`SEQUENCE` 等常用元数据；
- 支持 `RRULE` 中 `FREQ`、`INTERVAL`、`COUNT`、`UNTIL`、`BYDAY`、`BYMONTHDAY`、`BYMONTH`；
- 支持 `DAILY`、`WEEKLY`、`MONTHLY`、`YEARLY` 四类常见重复频率；
- 支持 `RDATE` 追加日期和 `EXDATE` 排除日期；
- 提供 occurrence 展开 API、按日期查询 API、后续事件查询 API、验证诊断 API；
- 提供 JSON 导出、基础 ICS 导出、CLI 示例和可运行 example。

## 使用方法

发布后可通过 Mooncakes 安装：

```bash
moon add ciqingweiyang/mooncal
```

本地开发和验收可运行：

```bash
moon check
moon build
moon test
moon run cmd/main
moon run cmd/main -- --json
moon run examples/basic
```

最小使用示例：

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

## 验收准备情况

- MoonBit 为主要实现语言；
- README 已说明项目用途、功能范围、安装方法、CLI 和 API；
- 提供 `examples/basic` 可运行示例；
- 配置 GitHub Actions CI；
- 提供 44 个可运行测试；
- 本地 `moon check`、`moon build`、`moon test` 已通过；
- 当前测试结果为 `Total tests: 44, passed: 44, failed: 0`；
- 仓库提交记录可追踪，已保留多次有意义提交；
- 功能边界和非目标已在 README 中说明；
- 项目许可证为 Apache-2.0；
- 未复制第三方代码或素材，测试 fixture 自行构造。

## 原创性与撞车检查

MoonCal 是原创 MoonBit 项目，不是对其他语言库的移植。项目参考公开 iCalendar 标准 RFC 5545 的格式和概念说明，但没有复制其他项目代码。

截至 2026-08-05，已检索 Mooncakes 与 GitHub 公开结果，未发现明显重复的 MoonBit 原生 iCalendar / ICS / RRULE 项目。其他生态中存在类似能力的库，但 MoonCal 的价值在于为 MoonBit 生态提供原生、轻量、可测试、可发布的日历数据基础能力。

## 后续维护计划

- 补充 `VTIMEZONE` 与更完整的时区处理；
- 增加更多高级 RRULE 组合，例如 `BYSETPOS`、`WKST` 和序数星期；
- 增加从文件读取的 CLI 能力；
- 增加更丰富的错误定位信息；
- 持续扩充真实世界 `.ics` 样例测试；
- 在 Mooncakes 发布后维护版本发布记录和 changelog。

## 开源合规说明

本项目使用 Apache-2.0 许可证。代码、测试数据和文档均为原创编写；项目没有引入需要额外声明的第三方代码或素材。
