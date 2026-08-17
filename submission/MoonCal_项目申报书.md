# MoonCal 项目申报书

## 基本信息

- 项目名称：MoonCal：MoonBit 原生 iCalendar 日程、任务与空闲忙碌时间处理库
- 参赛者：刘瑞彤；联系方式：15613701896
- GitHub 仓库：https://github.com/ciqingweiyang/MoonCal
- Mooncakes 包名：ciqingweiyang/mooncal；版本：0.1.2
- 项目类型：原创 MoonBit 开源库；许可证：Apache-2.0

## 项目简介

MoonCal 是 MoonBit 原生 iCalendar / ICS 工具库，面向排期工具、提醒工具、静态站点生成器、测试数据处理和自动化流程，提供 `.ics` 解析、重复事件展开、待办任务查询、空闲忙碌时间段查询、验证诊断和 JSON / ICS 导出能力。项目核心功能全部使用 MoonBit 实现，不依赖其他语言库封装。

## 已完成内容

当前版本支持 `VCALENDAR`、`VEVENT`、`VTODO`、`VFREEBUSY` 的实用子集解析，支持 iCalendar 折行展开、属性参数、事件字段、任务字段、`FREEBUSY` 时间段、`RRULE`、`RDATE`、`EXDATE` 和 `DURATION`。本次开发补齐了任务状态与优先级查询、忙碌窗口判断、验证诊断、JSON / ICS 导出、命令行示例、基础示例、CI、中文 README、API 文档和验收自查文档。

## 技术路线

项目按模块分层实现：`types.mbt` 定义领域模型，`parser.mbt` 负责 ICS 折行展开和组件解析，`datetime.mbt` / `duration.mbt` / `rrule.mbt` 提供日期时间、持续时间和重复规则能力，`query.mbt` 提供事件、任务和忙碌时间查询，`validation.mbt` 输出可分级诊断，`export.mbt` 提供 JSON 和 ICS 导出。所有错误使用类型化结果返回，便于命令行工具和上层应用稳定处理。

## 验收证据

本地可运行 `moon add ciqingweiyang/mooncal` 安装；验收命令包括 `moon check`、`moon build`、`moon test`、`moon run cmd/main`、`moon run cmd/main -- --json`、`moon run examples/basic`。当前 `moon check`、`moon build`、`moon test`、`moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check`、`moon info`、命令行示例和基础示例均通过；测试结果为 `Total tests: 82, passed: 82, failed: 0.`；本地统计约 4,189 行有效 MoonBit 代码，达到活动说明参考规模区间。

## 边界与合规

MoonCal 当前不做 CalDAV 网络同步、完整时区数据库、会议邀请回复状态同步和超大文件流式解析，后续计划补充 `VTIMEZONE`、高级 `RRULE`、`VALARM`、文件输入 CLI 和更多真实世界 `.ics` 样例。项目为原创 MoonBit 实现，只参考公开 iCalendar 标准 RFC 5545 的格式和概念说明，没有复制第三方项目代码或素材；测试样例自行构造，许可证为 Apache-2.0。
