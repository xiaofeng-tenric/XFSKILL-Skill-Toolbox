# XFSKILL Changelog

本文件记录 XFSKILL 每个版本的可见变更，格式遵循 Keep a Changelog，版本号遵循语义化版本。
每次发布前必须新增小节，否则质量闸门不放行。

## [0.1.0] - 2026-10-10

### Added
- 最小可运行框架：`main.il` 与 `core/{utils,config,loader,menu,test_framework}.il`
- 示例模块 `modules/hello.il`：`XFSKILL_HelloWorld`、命令 `xfskill_hello`、用例 `XFSKILL_Test_HelloWorld`
- 静态检查工具 `tools/xfskill_smoke.py`：括号平衡、残留 CR、GBK 可逆性、文件头六字段、重复命令、命名前缀、行宽
- 配置文件 `config/xfskill.cfg`，编码与发布规范 `references/coding-standard.md`
- 部署脚本 `tools/install.ps1`：备份旧版、复制文件、写入 `allegro.ilinit` 标记块、支持静默模式
- 编码转换脚本 `tools/convert_encoding.ps1`：UTF-8 与 GBK 双向转换，服务编辑与发布闭环

### Known limitations
- 运行时单元测试与冒烟测试需在 Allegro 内执行，CI 环境只能覆盖静态检查层
- 安装包 `XFSKILL_Setup.exe` 属于发布阶段产物，MVP 阶段以 `tools/install.ps1` 交付
