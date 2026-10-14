# XFSKILL Changelog

本文件记录 XFSKILL 每个版本的可见变更，格式遵循 Keep a Changelog，版本号遵循语义化版本。
每次发布前必须新增小节，否则质量闸门不放行。

## [0.3.0] - 2026-10-14

### Added
- 新增快速格点模块 `modules/setgrid/setgrid.il`：由 `template/setgrid` 按编码规范移植，表单选单位（mm/mil/um）与格点值（0.1~100），命令 `xfskill_setgrid`，测试 `XFSKILL_Test_SetGrid`
- 新增多引脚格点模块 `modules/set_symbol_grid/set_symbol_grid.il`：由 `template/set_symbol_grid` 按编码规范移植，点选两个引脚后按 等分比（2/3/4）计算间距并写入格点，命令 `xfskill_set_symbol_grid`（interactive），测试 `XFSKILL_Test_SymbolGrid`
- 表单 `forms/setgrid.form`、`forms/set_symbol_grid.form`，均挂进 XFSKILL 菜单（Set Grid / Set Grid by Pins）
- 函数重命名为 `XFSKILL_SetGrid*` / `XFSKILL_SymbolGrid*` 前缀，全局量 `XFSKILL_SETGRID_*` / `XFSKILL_SYMBOLGRID_*` / `XFSKILL_PIN_*`

### Fixed
- `setgrid.form` 补上原模板缺失的 `unit_um` 字段（.il 引用了但表单里没有，导致 um 单位预选无效）

## [0.2.0] - 2026-10-14

### Added
- 新增对齐分布模块 `modules/align/{align,align_do,align_utils}.il`：由 `template/align` 第三方插件按编码规范完整移植，函数重命名为 `XFSKILL_Align*` 前缀
- 命令 `xfskill_align`（交互式），子命令 `xfskill_align_{oops,top,bottom,left,right,center_h,center_v,dist_h,dist_v,pick_h,pick_v}`，并注册进 XFSKILL 菜单（Align Objects）
- 表单 `forms/align.form` 与图标 `forms/icons/*.bmp`（顶底对齐、居中、分布、拾取共 10 个位图）
- 单元测试 `XFSKILL_Test_Align` 并登记进测试框架
- `xfskill_smoke.py` 排除 `template/` 暂存目录；根目录模块模板草稿移入 `template/module_skeleton.il`

### Known limitations
- 表单设置持久化改用附件名 `XFSKILLAlignFormData` / `XFSKILLAlignSelectFilter`（原插件附件不再兼容，首次运行恢复默认值）
- 快捷键 a/s/w/d/q/z/e/c/r/v 与 F3 oops 仅在交互会话内接管，Done/Cancel 后恢复原绑定

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
