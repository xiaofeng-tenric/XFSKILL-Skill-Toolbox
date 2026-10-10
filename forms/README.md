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

## 当前状态

MVP 版本不含交互表单，`core/menu.il` 提供的 `XFSKILL` 菜单已满足最小闭环演示。
