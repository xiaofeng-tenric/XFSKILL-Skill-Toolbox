# XFSKILL 编码规范 (coding-standard.md)

本文件是 XFSKILL 的强制规范，来源于 Cadence 官方文档与项目实践。
`tools/xfskill_smoke.py` 负责把其中可机检的条目固化为质量闸门，其余条目在代码评审中人工确认。
任何与本规范冲突的实现，以本规范为准。

## 1. 官方参考文档

| 文档 | 用途 | 查阅时机 |
| --- | --- | --- |
| `sklangref.pdf` (SKILL Language Reference) | 语法、运算符、控制流、字符串与列表函数 | 使用任何内置函数前 |
| `skdevref.pdf` (SKILL Developer Reference) | 函数实现约定、文件 I/O、错误处理 | 编写加载器、配置读写、错误恢复时 |
| `skuiref.pdf` (SKILL UI Reference) | 表单、菜单、对话框、触发器 | 编写 `forms/`、`core/menu.il` 时 |
| Allegro SKILL 手册 (`algroskill.pdf` / Book Ten SKILL Reference) | `axl*` 数据库与命令接口 | 操作 PCB 数据库、注册命令时 |
| `$CDS_SITE/share/pcb/examples/skill/DOC/FUNCS` | 每个 `axl*` 函数的说明与示例 | 调用任何 `axl*` 函数前 |
| `$CDS_SITE/share/pcb/examples/skill/ui/menu.il` | 官方菜单示例 | 调整菜单结构时 |

任何 API 在使用前必须在上述文档中确认签名与返回值，禁止凭记忆编写。

## 2. 编码与文件格式

| 项目 | 规则 | 闸门 |
| --- | --- | --- |
| `.il` / `.cfg` 源文件 | GBK (CP936)，无 BOM | smoke 检查 1、3 |
| `.md` / `.py` / `.ps1` / `.nsi` | UTF-8，无 BOM | 人工 |
| 换行符 | LF，禁止残留 CR | smoke 检查 2 |
| 制表符 | 禁止，一律 2 空格 | smoke 检查 4 |
| 行宽 | 一行不超过 120 字符 | smoke 检查 5 |

编辑流程：GBK 只服务运行时，编辑时先执行 `tools/convert_encoding.ps1 -To utf8`，
用 `python tools/xfskill_smoke.py --encoding utf8` 校验，提交前执行
`tools/convert_encoding.ps1 -To gbk` 并跑完整 smoke。

## 3. 文件头六字段

每个 `.il` 文件的前 10 行内必须包含六字段，且每字段独占一行、以 `;` 开头：

```text
; 文件名: <相对路径>
; 作者: <作者或团队>
; 创建日期: <YYYY-MM-DD>
; 版本: <与 VERSION 文件一致的 x.y.z>
; 功能描述: <一句话说明本文件职责>
; 修改记录: <YYYY-MM-DD> <变更摘要>
```

- `版本` 必须等于 `VERSION` 文件内容，否则 smoke 检查 7 失败。
- `修改记录` 只追加，不覆盖历史行；本次修改必须新增一条记录。
- `功能描述` 描述"文件为什么存在"，不复述函数清单。

## 4. 命名规范

| 对象 | 规则 | 示例 |
| --- | --- | --- |
| 函数 | `XFSKILL_` 前缀 + 自解释驼峰 | `XFSKILL_LoadModules` |
| Allegro 命令 | `xfskill_` 前缀 + 动词/名词 | `xfskill_hello` |
| 全局变量 | `XFSKILL_` 前缀全大写下划线 | `XFSKILL_MODULE_COUNT` |
| 局部变量 | 小驼峰，名字即含义 | `moduleDir`、`separator` |
| 模块文件 | 小写功能名 `.il` | `modules/hello.il` |
| 配置项 | 小写下划线 | `menu_enabled` |
| 测试函数 | `XFSKILL_Test_` + 被测对象 | `XFSKILL_Test_HelloWorld` |

- 命名必须自解释，禁止用注释补充含义（见第 6 节）。
- 一个函数只做一件事，名字里体现输入与输出（如 `XFSKILL_IndexOf` 返回位置或 `nil`）。
- 全局变量只在初始化文件中用 `boundp` 保护后创建，模块内禁止新增全局。

## 5. 结构与加载规范

- 加载顺序固定：`allegro.ilinit` → `main.il` → `core/{utils,config,loader,menu,test_framework}.il` → `modules/**.il`。
- `core/*.il` 之间只允许单向依赖：`utils` → `config` / `loader` / `menu` / `test_framework`。
- 模块之间禁止相互依赖，模块只能依赖 `core` 层，保证可单独加载与卸载。
- 所有可重复执行的顶层语句必须用 `boundp` 保护，支持 `xfskill_reload` 热重载。
- 路径统一使用正斜杠 `/`，由 `XFSKILL_JoinPath` 拼接，禁止硬编码盘符。
- `XFSKILL_ROOT` 只允许在 `allegro.ilinit` 中赋值一次。

## 6. 注释规范

- 注释只写"为什么"：设计取舍、外部约束、易错点。
- 禁止复述代码（"加 1"、"打开文件"这类注释一律删除）。
- 禁止行尾注释，注释必须独占整行并以 `;` 开头（smoke 检查 9）。
- 禁止注释掉的死代码，废弃逻辑直接删除，由 Git 负责留痕。
- 禁止无意义分节横幅（`;;;; ---- SECTION ----`）。
- 文件头六字段是唯一要求的"结构性注释"。

## 7. 格式规范

1. 缩进 2 空格，禁止 Tab。
2. 左括号紧跟函数名或操作符，不单独占行：
   `defun(XFSKILL_Log(message)`、`if(last >= first`。
3. 右括号与包含该左括号的**起始行行首缩进**对齐，单独成行：

   ```text
   defun(XFSKILL_Trim(text)
     let((first last)
       ...
     )
   )
   ```

4. 需要换行时在参数边界断行，续行缩进 = 语句起始缩进 + 4；整条语句的右括号回到语句起始缩进：

   ```skill
       XFSKILL_Assert(
           equal(XFSKILL_HelloWorld() strcat("Hello XFSKILL " XFSKILL_VERSION))
           "greeting must embed the active version"
       )
   ```

5. 优先保持单行（≤120 字符），只有超长才换行。
6. 函数之间空一行；文件头与代码之间空一行。
7. `let` 绑定的变量名在同一列声明，连续赋值语句的 `=` 对齐：

   ```skill
   let((moduleDir ilFiles loaded)
     moduleDir = XFSKILL_JoinPath(XFSKILL_ROOT "modules")
     ilFiles   = XFSKILL_CollectIlFiles(moduleDir)
     loaded    = 0
   )
   ```

8. 格式调整不得改变功能；格式化后必须重新执行三层闭环测试并全绿。

## 8. API 与命令规范

- 命令一律通过 `axlCmdRegister` 注册，项目内统一封装为 `XFSKILL_RegisterCommand`，命令名必须以 `xfskill_` 开头（smoke 检查 10、11）。
- 菜单一律"先查后插"：先 `axlUIMenuFind` 判断是否已存在，再 `axlUIMenuInsert` 插入，菜单名固定为 `XFSKILL`，保证重复加载不产生重复菜单。
- 所有 `axl*` 调用必须包在 `errset` 中，失败降级为 `XFSKILL_Alert`，禁止让加载链整体崩溃。
- 外部输入（文件、配置、用户输入）必须校验后再使用；`strlen`/`substr` 前确认字符串非 `nil`。
- 字符串比较用 `equal` / `==` / `!=`，禁止用 `equalp` 之类的宽松比较。

## 9. 事务保护规范

任何修改 PCB 数据库的操作必须成对提交或回滚：

```skill
defun(XFSKILL_DangerousEdit()
  let((transactionMark changesOk)
    transactionMark = axlDBTransactionStart()
    changesOk       = nil
    when(transactionMark
      changesOk = errset(applyDatabaseChanges() t)
      if(changesOk
        then axlDBTransactionCommit(transactionMark)
        else axlDBTransactionOops(transactionMark)
      )
    )
    if(changesOk then t else nil)
  )
)
```

（`applyDatabaseChanges` 代表实际的数据库修改函数，仅示意结构。）

- 事务标记由 `axlDBTransactionStart` 返回，必须保存到局部变量。
- 失败路径先 `axlDBTransactionOops` 再返回，禁止只打印日志不回滚。
- 交互式命令用 `?cmdType "interactive"` 并提供 `?doneCmd` / `?cancelCmd`，保证用户取消时回滚。

## 10. 表单规范

- 表单定义文件放在 `forms/`，命名与功能一致，编码遵循第 2 节。
- 表单加载 API 以 `skuiref.pdf` 为准（`axlFormCreate` / `axlFormDisplay` 系列），禁止凭记忆写参数。
- 表单回调函数必须命名为 `XFSKILL_Form*`，需要从菜单或命令行触发的回调先用 `XFSKILL_RegisterCommand` 注册。
- 表单中所有用户可见文本使用中文时，必须保证文件为 GBK，否则界面乱码。
- 表单打开前检查是否已存在，关闭时释放句柄，禁止重复创建。

## 11. 测试规范

- 每个模块必须至少提供一个 `XFSKILL_Test_*`，并在文件末尾用 `XFSKILL_RegisterTest` 登记。
- 断言使用 `XFSKILL_Assert` / `XFSKILL_AssertEqual`，消息写清"期望什么"。
- 测试必须无副作用：不得修改 PCB 数据库、不得弹出阻塞对话框。
- 三层闭环缺一不可：静态检查 → 单元测试 → 运行时冒烟；任一层失败即中止发布。

## 12. 版本与变更规范

- 版本号遵循语义化版本：破坏性变更升主版本，新增功能升次版本，修复升修订号。
- 递增 `VERSION` 时必须同步：所有 `.il` 文件头 `版本` 字段、`CHANGELOG.md` 新增小节（smoke 检查 7、12）。
- 提交信息格式：`<模块>: <摘要> (v<版本>)`，例如 `modules/hello: 修复问候语版本拼接 (v0.1.1)`。
- 打标签：`git tag -a v<版本> -m "<版本> 发布说明"`。
- 更新前自动备份到 `_backup/<版本>_<时间戳>/`，备份目录不进入 Git。
