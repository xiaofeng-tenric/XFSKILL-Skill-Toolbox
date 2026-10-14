# XFSKILL 表单目录 (forms/)

本目录存放 Allegro 表单定义与表单装配代码。

## 命名

| 文件 | 用途 |
| --- | --- |
| `<feature>.form` | Allegro 标准文本表单定义，可直接被表单 API 加载 |
| `<feature>_form.il` | 表单装配代码：创建、显示、回调绑定、释放 |

## 规则

1. 编码遵循 `references/coding-standard.md` 第 2 节：`.form` 与 `.il` 均为 GBK、LF、无 BOM。
2. 文件头必须包含六字段，函数名以 `XFSKILL_Form` 开头。
3. 回调需要从菜单或命令行触发时，用 `XFSKILL_RegisterCommand` 注册为带 `xfskill_` 前缀的命令。
4. 表单加载前先判断是否已存在，关闭时释放句柄，禁止重复创建。
5. 表单 API 的参数以 `skuiref.pdf` 为准，禁止凭记忆编写。
6. 新增表单后必须执行三层闭环测试，并在 `CHANGELOG.md` 登记。
7. Form表单的编码格式为ANSI

## 当前状态

- `align.form`：对齐分布模块表单，由 `modules/align/align.il` 通过 `XFSKILL_AlignFormFile()` 以
  `forms/align.form` 全路径加载，找不到时回退 FORMPATH 上的 `align.form`。
- `setgrid.form`：快速格点表单，由 `modules/setgrid/setgrid.il` 的 `XFSKILL_SetGridFormFile()` 加载。
- `set_symbol_grid.form`：双引脚计算格点表单，由 `modules/set_symbol_grid/set_symbol_grid.il` 的
  `XFSKILL_SymbolGridFormFile()` 加载。
- `icons/`：`align.form` 的 THUMBNAIL 位图（顶/底/左/右/居中/分布/拾取共 10 个 bmp），
  需把本目录加入 Allegro 的 `%bmppath%`（如 env 文件中 `bmppath` 增加一项指向 `forms/icons`），
  否则表单按钮无图标显示，功能不受影响。
- `core/menu.il` 提供的 `XFSKILL` 菜单含 Align Objects 入口，调用 `xfskill_align`。
