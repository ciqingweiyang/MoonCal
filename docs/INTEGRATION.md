# MoonCal 集成说明

## 添加依赖

通过 Mooncakes 添加依赖：

```bash
moon add ciqingweiyang/mooncal
```

在包代码中引入：

```moonbit
import {
  "ciqingweiyang/mooncal" @mooncal,
}
```

## 解析并展开事件

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

## 查询任务

```moonbit
match @mooncal.parse(text) {
  Ok(calendar) => {
    let today = @mooncal.DateTime(2026, 8, 18)
    let open = @mooncal.open_tasks(calendar)
    let overdue = @mooncal.overdue_tasks(calendar, today)
    println("open tasks: \{open.length()}")
    println("overdue tasks: \{overdue.length()}")
  }
  Err(err) => println(@mooncal.error_to_text(err))
}
```

## 查询忙碌时间

```moonbit
match @mooncal.parse(text) {
  Ok(calendar) => {
    let from = @mooncal.DateTime(2026, 8, 1)
    let until = @mooncal.DateTime(2026, 8, 31)
    let busy = @mooncal.busy_periods_between(calendar, from, until)
    let occupied = @mooncal.time_is_busy(
      calendar,
      @mooncal.DateTime(2026, 8, 3, hour=9, minute=10),
    )
    println("busy periods: \{busy.length()}")
    println("occupied: \{occupied}")
  }
  Err(err) => println(@mooncal.error_to_text(err))
}
```

## 验证策略

推荐集成流程：

1. 使用 `parse` 做结构解析，解析失败时直接展示 `error_to_text`。
2. 使用 `validate_calendar` 生成诊断，区分 `info`、`warning` 和 `error`。
3. 使用 `occurrences_between`、`open_tasks`、`busy_periods_between` 等查询接口执行业务逻辑。
4. 使用 `calendar_to_json` 或 `calendar_to_ics` 输出处理结果。

MoonCal 对不支持的 `RRULE` 片段返回明确错误，不会静默跳过。对任务状态、任务优先级、任务完成进度和空闲忙碌时间段边界会给出验证诊断，便于上层应用决定是否阻断导入。

## 目标说明

MoonCal 核心库不依赖原生文件接口，适合 `wasm-gc` 方向的库和小型命令行工具。命令行样例用于展示摘要输出；读取外部文件、网络同步和完整时区数据库不属于当前版本范围。
