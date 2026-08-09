# 更新日志

## 0.1.1

- 移除非项目交付所需的辅助配置文件。
- 精简模块元数据，发布包只保留验收和使用所需内容。
- 保持公开 API、示例、测试和 CI 行为不变。

## 0.1.0

- 添加 iCalendar 折行展开和属性解析器。
- 添加 `VCALENDAR` / `VEVENT` 解析器和类型化错误。
- 添加 `DateTime` 工具、公历日期运算和星期计算。
- 添加 `DAILY`、`WEEKLY`、`MONTHLY`、`YEARLY` 重复规则解析。
- 添加支持 `COUNT`、`UNTIL`、`BYDAY`、`BYMONTHDAY`、`BYMONTH`、`RDATE`、`EXDATE` 的事件展开能力。
- 添加 `DURATION` 解析和事件元数据字段。
- 添加验证诊断和查询辅助 API。
- 添加命令行工具、基础示例、JSON / ICS 导出、文档和 CI。
