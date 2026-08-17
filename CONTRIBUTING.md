# 贡献说明

MoonCal 保持功能边界清晰，新增能力应当服务于日历数据解析、查询、验证或导出，不加入无关工具代码。

提交改动前请运行：

```bash
moon fmt
moon check
moon build
moon test
moon run cmd/main
moon run examples/basic
```

新增解析、重复规则、任务或空闲忙碌行为时，应同时补充正常输入、异常输入和边界情况测试。
