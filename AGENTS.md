---
name: xfskill-allegro-skill-workflow
description: XFSKILL（Cadence Allegro SKILL 工具集）的完整开发工作流。当需要新增/修改 SKILL 模块、执行三层闭环测试、递增版本、打包安装、升级回滚或排查加载问题时使用本文件。覆盖项目目标、项目管理、技术栈、开发工具、开发规范、阶段输入输出检查点、质量闸门与交付清单。
version: 0.1.0
status: active
owner: XFSKILL Maintainers
repo: XFSKILL-Skill-Toolbox
targets:
  - Cadence Allegro 16.6
  - Cadence Allegro 17.4
  - Cadence Allegro 24.1
tags: [allegro, skill, xfskill, workflow, quality-gate, release, rollback]
triggers:
  - XFSKILL 开发新模块
  - XFSKILL 修改核心层
  - XFSKILL 测试与质量闸门
  - XFSKILL 打包发布
  - XFSKILL 升级回滚
  - allegro.ilinit 配置
---

# XFSKILL 工作流 (AGENTS.md)

本文件是 XFSKILL 的唯一工作流真源。执行任何 XFSKILL 任务前先读本文件，
阶段产物与检查点必须逐项留痕；本文件与 `references/coding-standard.md` 冲突时，
以 `references/coding-standard.md` 的格式条款为准，其余以本文件为准。

- 不要修改AGENTS.md的工作流规范


---

## 1. 项目目标

| 编号 | 目标 | 验收方式 |
| --- | --- | --- |
| G1 | 一键安装：双击或一条命令完成部署 | `install.ps1` 单命令成功，`allegro.ilinit` 出现标记块 |
| G2 | 自动更新：新版本覆盖旧版本且不丢配置 | 升级后 `VERSION` 变化，旧版进入 `_backup/` |
| G3 | 版本回滚：一条命令回到任意备份 | `-Rollback <name>` 后 `VERSION` 回到目标版本 |
| G4 | 全程可追溯：代码、版本、变更、提交一一对应 | `VERSION` ↔ 文件头版本 ↔ `CHANGELOG.md` ↔ `git tag` 四者一致 |
| G5 | 接入官方设计规范 | `references/coding-standard.md` 引用 sklangref/skdevref/skuiref/Allegro SKILL 手册 |
| G6 | 开发阶段闭环测试 | 三层闭环全绿才允许打包 |

核心原则：**先跑通最小闭环，再扩功能；任何改动都必须重新走完三层闭环。**

---

## 2. 项目管理

### 2.1 角色分工

| 角色 | 职责 | 产出 |
| --- | --- | --- |
| 模块开发者 | 编写 `modules/*.il`、单元测试 | 模块代码 + `XFSKILL_Test_*` |
| 核心维护者 | 维护 `main.il` / `core/*.il` | 核心变更 + 影响面说明 |
| 发布工程师 | 版本递增、打包、发布、回滚演练 | `XFSKILL_Setup.exe` + tag + 发布记录 |
| 评审人 | 规范与质量闸门复核 | 评审结论（放行/驳回） |

### 2.2 分支与提交

- `main`：随时可发布，只接受通过三层闭环的变更。
- `feat/<模块名>`：功能分支，完成后合回 `main`。
- `fix/<问题>`：缺陷修复分支。
- 提交信息格式：`<模块路径>: <摘要> (v<版本>)`，例：`modules/hello: 问候语补充版本号 (v0.1.1)`。
- 一次提交只做一件事；提交前必须本地跑通层 1 静态检查。
- 发布打标签：`git tag -a v<版本> -m "<版本> 发布说明"`，标签与 `VERSION` 必须一致。

### 2.3 节奏与里程碑

| 里程碑 | 进入条件 | 退出条件 |
| --- | --- | --- |
| M1 骨架可用 | 目录结构与核心层就位 | 层 1 全绿 + Allegro 内层 2/3 全绿 |
| M2 功能完备 | 所有需求模块合入 | 三层全绿 + 评审通过 |
| M3 可发布 | 版本与 CHANGELOG 更新 | 8 项质量闸门全过 + 兼容矩阵验证 |
| M4 可回滚 | 已生成备份 | 演练回滚成功并留记录 |

### 2.4 风险与回退策略

- 层 2/层 3 失败：立即定位，禁止用"注释掉失败用例"过关。
- 加载失败：用 `xfskill_reload` 复现，检查 `_backup/` 是否有可用旧版。
- 兼容性失败：在该 Allegro 版本上单独记录问题，降级为已知限制并写入 `CHANGELOG.md`。
- 任何发布失败：执行 `install.ps1 -Rollback` 回到上一稳定版，再排查。

---

## 3. 技术栈与开发工具

### 3.1 技术栈

| 层次 | 选型 | 说明 |
| --- | --- | --- |
| 运行时 | Cadence Allegro 16.6 / 17.4 / 24.1 | 至少两个版本验证通过才允许发布 |
| 扩展语言 | Cadence SKILL（`.il`） | GBK 编码，2 空格缩进 |
| 配置 | `config/xfskill.cfg`（key=value） | GBK 编码 |
| 静态检查 | Python 3.8+ | 仅标准库，无第三方依赖 |
| 部署脚本 | PowerShell 5.1 | Windows 自带，支持 `-Silent` |
| 安装包 | NSIS 或 Python + PyInstaller | 产出 `XFSKILL_Setup.exe` |
| 版本管理 | Git | 分支 + 提交规范 + tag |

### 3.2 开发工具

| 工具 | 用途 | 关键配置 |
| --- | --- | --- |
| VS Code / Notepad++ | 编辑源码 | 打开 GBK 文件时显式选 CP936；关闭自动转 BOM |
| `tools/convert_encoding.ps1` | UTF-8 ↔ GBK 转换 | 提交前转回 GBK |
| `python tools/xfskill_smoke.py` | 层 1 静态检查 | 提交前必须执行 |
| Allegro SKILL 控制台 | 层 2/层 3 测试 | 命令行输入 `skill` 进入 |
| `%CDS_SITE%/share/pcb/examples/skill/DOC/FUNCS` | `axl*` 函数速查 | 调用前查签名 |
| `install.ps1` | 安装/升级/回滚 | 支持 `-Silent` 供静默安装 |
| Git | 版本与追溯 | 提交信息按 2.2 节 |

### 3.3 环境变量与路径

- `XFSKILL_ROOT`：只在 `allegro.ilinit` 中赋值一次，指向安装目录，路径用正斜杠。
- `%HOME%/pcbenv/allegro.ilinit`：个人环境入口；站点级用 `%CDS_SITE%/pcb/skill/allegro.ilinit`。
- `_backup/`：升级前自动备份目录，被 `.gitignore` 排除，只保留 `.gitkeep` 进入版本管理。

---

## 4. 开发规范（摘要）

完整规范见 `references/coding-standard.md`，以下是必须记住的硬约束：

1. 文件头六字段：`文件名 / 作者 / 创建日期 / 版本 / 功能描述 / 修改记录`，版本必须等于 `VERSION`。
2. 命名：函数 `XFSKILL_` 前缀、命令 `xfskill_` 前缀、测试 `XFSKILL_Test_` 前缀、全局 `XFSKILL_` 大写。
3. 命名自解释，注释只写"为什么"：禁止行尾注释、禁止注释掉的死代码、禁止复述代码、禁止分节横幅。
4. 格式：2 空格缩进、无 Tab、行宽 ≤ 120、左括号紧跟函数名、右括号与起始行行首对齐、函数之间空一行。
5. 函数定义的函数名与参数表之间必须有空格（`defun(Name (args)`）：SKILL 读取器会把
   `defun(Name(args)` 里的 `Name(args)` 合并成一个调用形式，`defun` 只剩 2 个参数，
   报 `*Error* defun: too few arguments`，整条加载链在此中断（层 1 检查 13）。
6. `let` 绑定对齐，长表达式按参数边界换行，续行缩进 = 起始缩进 + 4。
7. 所有 `axl*` 调用包 `errset`，失败降级为 `XFSKILL_Alert`。
8. 修改数据库必须走事务：`axlDBTransactionStart` → 成功 `Commit` / 失败 `Oops`。
9. 格式调整不得改变功能，格式化后必须重新执行三层闭环并全绿。

---

## 5. 仓库结构

```text
XFSKILL-Skill-Toolbox/
├── AGENTS.md                     本工作流（真源）
├── VERSION                       当前版本 x.y.z（真源之一）
├── CHANGELOG.md                  变更记录（发布前必须更新）
├── .gitignore                    排除 _backup 内容、构建产物
├── main.il                       总入口：加载核心层、初始化、注册命令、构建菜单
├── core/
│   ├── utils.il                  XFSKILL_Log / XFSKILL_Alert / 字符串与路径工具
│   ├── config.il                 XFSKILL_VersionLoad / XFSKILL_ConfigLoad / XFSKILL_ConfigGet
│   ├── loader.il                 XFSKILL_LoadModules 扫描 modules/**.il
│   ├── menu.il                   XFSKILL_MenuBuild 先查后插，菜单名 XFSKILL
│   └── test_framework.il         XFSKILL_Assert / XFSKILL_AssertEqual /
│                                 XFSKILL_RunUnitTests / XFSKILL_SmokeTest
├── modules/
│   └── hello.il                  示例：XFSKILL_HelloWorld + xfskill_hello + XFSKILL_Test_HelloWorld
├── forms/
│   └── README.md                 表单命名与规则
├── config/
│   └── xfskill.cfg               运行配置（menu_enabled / auto_test / auto_smoke / backup_keep）
├── tools/
│   ├── xfskill_smoke.py          层 1 静态检查
│   ├── convert_encoding.ps1      UTF-8 ↔ GBK 转换
│   └── install.ps1               安装 / 升级 / 回滚
├── references/
│   └── coding-standard.md        编码规范（官方文档映射 + 可机检规则）
└── _backup/
    └── .gitkeep                  升级前备份落盘位置
```

---

## 6. 工作流总览

```text
P0 环境与仓库初始化
      │  输入: 需求 + Allegro 安装路径
      ▼
P1 骨架与加载链      ── 产出 main.il + core/*.il + 最小模块
      ▼
P2 模块开发（编码）  ── 产出 modules/*.il + 单元测试
      ▼
P3 层1 静态检查      python tools/xfskill_smoke.py
      ▼ 失败 → 回到 P2
P4 层2 单元测试      Allegro 内 XFSKILL_RunUnitTests
      ▼ 失败 → 回到 P2
P5 层3 运行时冒烟    Allegro 内 XFSKILL_SmokeTest
      ▼ 失败 → 回到 P1/P2
P6 质量闸门评审（8 项）
      ▼ 未过 → 不得进入 P7
P7 版本递增与变更记录  VERSION + 文件头 + CHANGELOG + git commit/tag
      ▼
P8 打包  XFSKILL_Setup.exe（NSIS / PyInstaller）
      ▼
P9 部署、升级、回滚、追溯
      │
      └── 任何回退都回到 P2，并重新走 P3→P6
```

每阶段都是**可执行、可验证**的；未通过检查点不得进入下一阶段。

---

## 7. 阶段详情

### P0 环境与仓库初始化

- 目标：拿到可用的 Allegro 环境与干净仓库。
- 输入：需求清单、Allegro 安装目录、目标版本矩阵（16.6 / 17.4 / 24.1）。
- 输出：`XFSKILL-Skill-Toolbox/` 仓库、`git init` 完成、参考文档路径确认。
- 检查点：
  1. `%CDS_SITE%/share/pcb/examples/skill/DOC/FUNCS` 可访问。
  2. `%HOME%/pcbenv/` 存在，可写 `allegro.ilinit`。
  3. `python --version` ≥ 3.8，`powershell` 可用，`git` 可用。
- 命令：

```powershell
git init
git add AGENTS.md references/coding-standard.md
git commit -m "docs: XFSKILL 工作流与规范 (v0.1.0)"
```

### P1 骨架与加载链

- 目标：建立最小可运行框架，跑通"加载 → 命令 → 菜单 → 测试"四条链路。
- 输入：本文件第 5 节目录结构、`config/xfskill.cfg`。
- 输出：`main.il`、`core/*.il`、`modules/hello.il`、`VERSION`、`CHANGELOG.md`。
- 检查点：
  1. `allegro.ilinit` 中有标记块，`XFSKILL_ROOT` 指向正确目录。
  2. 重启 Allegro 后命令行出现 `[XFSKILL] ... ready` 日志。
  3. 菜单栏出现 `XFSKILL` 菜单（先查后插，重复加载不重复插入）。
- 关键片段见第 8.1 / 8.2 / 8.3 节。

### P2 模块开发（编码）

- 目标：实现功能模块并配套单元测试。
- 输入：需求、`references/coding-standard.md`、官方 `DOC/FUNCS` 说明。
- 输出：`modules/<feature>.il`、`XFSKILL_Test_<feature>`、菜单项（如需）。
- 检查点：
  1. 文件头六字段齐全，`版本` 与 `VERSION` 一致。
  2. 新命令以 `xfskill_` 注册且无重复。
  3. 每个模块至少一个 `XFSKILL_Test_*` 并调用 `XFSKILL_RegisterTest`。
  4. 无行尾注释、无死代码、无 Tab、行宽 ≤ 120。
- 命令：

```powershell
powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To utf8
python tools\xfskill_smoke.py --encoding utf8
powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To gbk
python tools\xfskill_smoke.py
```

### P3 层 1：静态检查

- 目标：在进入 Allegro 之前拦截结构性错误。
- 输入：GBK 编码的 `.il` / `.cfg` 源文件。
- 输出：`RESULT PASS files=N ...` 或 `[FAIL]` 明细列表。
- 检查点（14 项检查全部通过）：

| # | 检查 | 说明 |
| --- | --- | --- |
| 1 | GBK 可逆 | 解码 GBK 后重新编码字节完全一致 |
| 2 | 无 CR | 不残留 `\r` |
| 3 | 无 BOM | Allegro 不接受 BOM 前缀 |
| 4 | 无 Tab | 2 空格缩进 |
| 5 | 行宽 ≤ 120 | 超长按参数拆行 |
| 6 | 文件头六字段 | 文件名/作者/创建日期/版本/功能描述/修改记录 |
| 7 | 版本一致 | 文件头 `版本` == `VERSION` |
| 8 | 括号平衡 | 去掉注释与字符串后 `(` 与 `)` 配对 |
| 9 | 无行尾注释 | 注释独占整行 |
| 10 | 命名前缀 | 函数 `XFSKILL_`、命令 `xfskill_` |
| 11 | 无重复 | 同一命令、同一函数名不得重复 |
| 12 | CHANGELOG | 存在 `## [<VERSION>]` 小节 |
| 13 | 函数定义写法 | `defun(Name (args)` 的名字与参数表之间必须有空格 |
| 14 | 禁用非标准原语 | `substr` 必须写成 SKILL 标准的 `substring` |

- 命令与退出码：

```powershell
python tools\xfskill_smoke.py
if ($LASTEXITCODE -ne 0) { throw "static gate failed" }
```

### P4 层 2：单元测试

- 目标：验证每个模块的函数级行为。
- 输入：P3 通过的源码、已加载的 Allegro 会话。
- 输出：`UNIT result pass=N fail=0`。
- 检查点：
  1. 注册用例数 > 0，逐个 `RUN` 无 error。
  2. 失败用例会输出 `FAIL <消息>` 并计入 `fail` 计数。
  3. 返回值为 `t` 表示全绿。
- 命令（Allegro 命令行或 SKILL 控制台）：

```text
skill xfskill_reload()
skill xfskill_tests()
```

或在 SKILL 控制台直接调用：

```text
skill> XFSKILL_RunUnitTests()
```

### P5 层 3：运行时冒烟

- 目标：验证整条链路在真实 Allegro 中可用。
- 输入：P4 全绿的会话。
- 输出：`SMOKE result pass=N fail=0`。
- 检查点（8 项冒烟断言）：
  1. `VERSION` 可读且非空。
  2. `config/xfskill.cfg` 已加载。
  3. `modules/` 至少加载 1 个模块。
  4. 单元测试已登记。
  5. `XFSKILL_HelloWorld` 已定义。
  6. 问候语包含当前版本号（真实运行行为）。
  7. `XFSKILL` 菜单已插入菜单栏。
  8. 返回 `t` 表示通过。
- 命令：

```text
skill> XFSKILL_SmokeTest()
```

### P6 质量闸门评审

8 项全部为真才允许进入 P7：

| # | 闸门 | 验证方式 |
| --- | --- | --- |
| 1 | 静态全绿 | `python tools/xfskill_smoke.py` 退出码 0 |
| 2 | 单元全绿 | `XFSKILL_RunUnitTests()` 返回 `t` |
| 3 | 冒烟通过 | `XFSKILL_SmokeTest()` 返回 `t` |
| 4 | 六字段完整 | 层 1 检查 6 通过 |
| 5 | 版本递增 | 相对上一个 tag 版本号变大 |
| 6 | CHANGELOG 更新 | 层 1 检查 12 通过 |
| 7 | Git 提交规范 | 提交信息符合 `<模块>: <摘要> (v<版本>)` |
| 8 | 兼容性 | 至少两个 Allegro 版本（如 17.4 与 24.1）重复 P4/P5 全绿 |

评审动作：逐项打勾，任何一项为否即驳回，退回对应阶段。

### P7 版本与变更记录

- 目标：让代码、版本、变更、标签四者对齐。
- 输入：P6 全绿的代码。
- 输出：更新后的 `VERSION`、全部 `.il` 文件头 `版本`、`CHANGELOG.md`、`git commit`、`git tag`。
- 检查点：
  1. `VERSION` 已按语义化版本递增。
  2. 每个 `.il` 文件头 `版本` 与 `VERSION` 相同（层 1 检查 7）。
  3. `CHANGELOG.md` 新增 `## [x.y.z] - <日期>` 小节（层 1 检查 12）。
  4. `git tag` 名称与 `VERSION` 一致。
- 命令：

```powershell
Set-Content -Path VERSION -Value "0.2.0" -NoNewline -Encoding Ascii
python tools\xfskill_smoke.py
git add -A
git commit -m "release: v0.2.0 版本递增与变更记录"
git tag -a v0.2.0 -m "v0.2.0 发布说明"
```

### P8 打包

- 目标：产出可分发的 `XFSKILL_Setup.exe`。
- 输入：P7 打过 tag 的源码。
- 输出：`dist/XFSKILL_Setup.exe`、打包日志。
- 检查点：
  1. 安装包内 `VERSION` 与 tag 一致。
  2. 静默安装可用：`XFSKILL_Setup.exe /S`。
  3. 安装后自动备份旧版、复制文件、写入 `allegro.ilinit` 标记块。
- 推荐方案 A（NSIS，片段见 8.6）与方案 B（PyInstaller 包装 Python 安装逻辑）。
- MVP 阶段可先用 `tools/install.ps1` 交付安装能力，发布阶段再生成 exe。

### P9 部署、升级、回滚与追溯

- 目标：在现场机器上可控地装、升、退、查。
- 输入：`XFSKILL_Setup.exe` 或 `tools/install.ps1`。
- 输出：安装记录、`_backup/<版本>_<时间戳>/` 备份、可追溯的版本链。
- 检查点：
  1. 升级前旧版本已进入 `_backup/`。
  2. 升级后 `allegro.ilinit` 标记块仍只有一份。
  3. 回滚演练成功，`VERSION` 回到目标版本。
  4. 现场版本可通过 `xfskill_version` 查询并与 tag 对应。
- 命令：

```powershell
# 首次安装 / 升级
powershell -ExecutionPolicy Bypass -File tools\install.ps1
# 静默安装（供 NSIS 或批量部署转发）
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Silent
# 指定安装目录与 ilinit
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Target D:/XFSKILL -IlInit C:/home/pcbenv/allegro.ilinit
# 回滚到指定备份
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Rollback 0.1.0_20261010_083000
# 查询现场版本
# Allegro 命令行:  xfskill_version
```

---

## 8. 关键代码片段

### 8.1 allegro.ilinit 标记块（由 install.ps1 幂等维护）

```skill
; >>> XFSKILL BEGIN (managed by install.ps1) >>>
unless(boundp('XFSKILL_READY)
  setq(XFSKILL_ROOT "D:/XFSKILL")
  errset(load(strcat(XFSKILL_ROOT "/main.il")) t)
)
; <<< XFSKILL END <<<
```

`XFSKILL_READY` 由 `main.il` 在加载链末尾置位；站点级 `%CDS_SITE%/pcb/skill/allegro.ilinit`
与用户级 `%HOME%/pcbenv/allegro.ilinit` 两处都可以写这份标记块，先执行的加载，
后执行的因 `XFSKILL_READY` 已绑定而跳过，不会重复加载。`errset(... t)` 保证加载失败时
在命令行打印错误，而不是被静默吞掉。

手写等价形式（开发期临时验证）：

```skill
unless(boundp('XFSKILL_ROOT)
  XFSKILL_ROOT = "E:/cadence_lib_xiaofeng/skill test/XFSKILL-Skill-Toolbox"
)
load(strcat(XFSKILL_ROOT "/main.il"))
```

### 8.2 main.il 加载链

```skill
when(!boundp('XFSKILL_ROOT)
  XFSKILL_ROOT = getShellEnvVar("XFSKILL")
)

when(XFSKILL_ROOT && isDir(strcat(XFSKILL_ROOT "/core"))
  load(strcat(XFSKILL_ROOT "/core/utils.il"))
  load(strcat(XFSKILL_ROOT "/core/config.il"))
  load(strcat(XFSKILL_ROOT "/core/loader.il"))
  load(strcat(XFSKILL_ROOT "/core/menu.il"))
  load(strcat(XFSKILL_ROOT "/core/test_framework.il"))

  XFSKILL_TESTS = list()
  XFSKILL_VersionLoad()
  XFSKILL_ConfigLoad(XFSKILL_JoinPath(XFSKILL_ROOT "config/xfskill.cfg"))
  XFSKILL_LoadModules()

  XFSKILL_RegisterCommand("xfskill_tests" 'XFSKILL_RunUnitTests)
  XFSKILL_RegisterCommand("xfskill_smoke" 'XFSKILL_SmokeTest)

  when(equal(XFSKILL_ConfigGet("menu_enabled" "t") "t")
    XFSKILL_MenuInit()
  )
)

when(!(XFSKILL_ROOT && isDir(strcat(XFSKILL_ROOT "/core"))
  error("XFSKILL_ROOT is not set or invalid; set env var XFSKILL or load main.il through allegro.ilinit")
)
```

根目录未绑定时自动从环境变量 `XFSKILL` 取值；校验失败只报一次错，整条链不启动，
避免 `loadi` 逐行继续执行造成的级联错误。

### 8.3 菜单：触发器内先查后插

官方示例 `share/pcb/examples/skill/ui/menu.il` 规定：菜单项必须在 menu 触发器内创建
（触发器外插入仅限开发期调试）。`xfskill_menu` 命令保留为开发期手动插入通道。

```skill
defun(XFSKILL_MenuTrigger (t_menuName)
  errset(XFSKILL_MenuBuild() t)
  nil
)

defun(XFSKILL_MenuInit ()
  if(!isCallable('axlTriggerSet)
    then
      XFSKILL_Alert("axlTriggerSet unavailable, run xfskill_menu manually")
      nil
    else
      if(XFSKILL_MENU_TRIGGER_SET
        then
          XFSKILL_Log("menu trigger already registered")
          t
        else
          let((probe)
            probe = errset(axlTriggerSet('menu 'XFSKILL_MenuTrigger))
            if(probe && car(probe)
              then
                XFSKILL_MENU_TRIGGER_SET = t
                XFSKILL_Log("menu trigger registered")
                t
              else
                XFSKILL_Alert("menu trigger register failed, run xfskill_menu manually")
                nil
            )
          )
      )
  )
)
```

`XFSKILL_MenuBuild` 保持先查后插：锚点 `axlUIMenuFind(nil -1)` 取菜单栏最右侧菜单（Help），
在其位置插入顶层 `XFSKILL` 弹出菜单；查到 `xfskill_hello` 即视为已存在，跳过重复插入。
触发器在 Allegro 每次装载菜单时回调，因此切换设计重建菜单后 XFSKILL 菜单会自动补回。

### 8.4 断言与测试登记

```skill
defun(XFSKILL_Test_HelloWorld ()
  let((greeting expected)
    greeting = XFSKILL_HelloWorld()
    expected = strcat("Hello XFSKILL " XFSKILL_VERSION)
    XFSKILL_AssertEqual(greeting expected "greeting must embed the active version")
    XFSKILL_Assert(strlen(greeting) > 0 "greeting must never be empty")
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_HelloWorld)
```

### 8.5 数据库事务保护模板

```skill
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
)
```

### 8.6 NSIS 打包骨架（发布阶段）

```nsis
Name "XFSKILL Setup"
OutFile "dist\XFSKILL_Setup.exe"
InstallDir "$LOCALAPPDATA\XFSKILL"
RequestExecutionLevel user

Section "Install"
  SetOutPath "$INSTDIR"
  File /r main.il core modules forms config tools references VERSION CHANGELOG.md
  ExecWait 'powershell -ExecutionPolicy Bypass -File "$INSTDIR\tools\install.ps1" -Target "$INSTDIR" -Silent'
SectionEnd
```

静默安装：`XFSKILL_Setup.exe /S`（NSIS 内置），内部转发 `install.ps1 -Silent`。

### 8.7 三层闭环命令速查

```powershell
# 层1 静态
python tools\xfskill_smoke.py
# 层2 / 层3（Allegro 内）
#   skill> XFSKILL_RunUnitTests()
#   skill> XFSKILL_SmokeTest()
# 等价命令行
#   xfskill_tests
#   xfskill_smoke
```

---

## 9. 三层闭环测试

```text
层1 静态检查   python tools/xfskill_smoke.py        机器执行，CI 可跑
层2 单元测试   Allegro 内 XFSKILL_RunUnitTests()    函数级断言
层3 运行时冒烟 Allegro 内 XFSKILL_SmokeTest()        链路级断言
```

- 顺序不可调换：层 1 失败不进 Allegro；层 2 失败不跑冒烟。
- 三层全绿才允许打包（P8）。
- 任何格式化、重构、编码转换之后，必须从层 1 重新跑一遍三层。
- 失败留痕：把 `[FAIL]` 明细或 `fail` 计数贴进提交说明或问题单。

---

## 10. 版本管理、发布、升级与回滚

### 10.1 四点一致性

```text
VERSION 文件  ==  每个 .il 文件头"版本"  ==  CHANGELOG.md 小节  ==  git tag
```

层 1 检查 7 与 12 自动强制前三点，第四点由 P7 检查点人工确认。

### 10.2 升级流程

1. 新版本安装包或源码就位。
2. `install.ps1` 读取现场 `VERSION`。
3. 现场 `VERSION` 与新版本不同 → 自动备份到 `_backup/<旧版本>_<时间戳>/`。
4. 复制载荷（`main.il`、`core/`、`modules/`、`forms/`、`config/`、`tools/`、`references/`、`VERSION`、`CHANGELOG.md`）。
5. 幂等重写 `allegro.ilinit` 标记块（只保留一份）。
6. 重启 Allegro，执行 `xfskill_version` 确认，跑 `xfskill_tests` + `xfskill_smoke`。

### 10.3 回滚流程

1. `install.ps1 -Rollback <备份目录名>`。
2. 脚本先把当前版本再备份一次（防止回滚不可逆）。
3. 把备份内容覆盖回安装目录（`_backup/` 自身不参与覆盖）。
4. 重写 `allegro.ilinit` 标记块。
5. 重启 Allegro，`xfskill_version` 确认回到目标版本，重跑三层闭环。

### 10.4 追溯

| 想知道 | 去哪里查 |
| --- | --- |
| 现场跑的是什么版本 | `xfskill_version` / 安装目录 `VERSION` |
| 这个版本改了什么 | `CHANGELOG.md` 的 `## [x.y.z]` 小节 |
| 谁改的、为什么改 | `git log --oneline -- <文件>` + 文件头 `修改记录` |
| 某次升级前的旧代码 | `_backup/<旧版本>_<时间戳>/` |
| 某个版本的源码快照 | `git show v<x.y.z>` |
| 某个函数的规范依据 | `references/coding-standard.md` 对应章节 |

---

## 11. 交付清单

### 11.1 MVP（最小可运行框架，本次交付）

- [x] `main.il` 与 `core/{utils,config,loader,menu,test_framework}.il`
- [x] `modules/hello.il`（`XFSKILL_HelloWorld` / `xfskill_hello` / `XFSKILL_Test_HelloWorld`）
- [x] `config/xfskill.cfg`
- [x] `tools/xfskill_smoke.py`（层 1，14 项检查）
- [x] `tools/convert_encoding.ps1`（UTF-8 ↔ GBK）
- [x] `tools/install.ps1`（安装 / 升级 / 回滚 / `-Silent`）
- [x] `references/coding-standard.md`
- [x] `forms/README.md`
- [x] `VERSION`、`CHANGELOG.md`、`_backup/.gitkeep`
- [x] 本文件 `AGENTS.md`

### 11.2 发布阶段（P7–P9 产物）

- [ ] `XFSKILL_Setup.exe`（NSIS 或 PyInstaller 生成，支持 `/S` 静默）
- [ ] `VERSION` 递增 + 全部文件头版本同步
- [ ] `CHANGELOG.md` 新增小节
- [ ] `references/coding-standard.md` 随规范演进更新
- [ ] `tools/xfskill_smoke.py` 随新检查项扩展
- [ ] `_backup/<版本>_<时间戳>/` 升级前备份
- [ ] `git tag v<版本>` 与发布说明
- [ ] 兼容矩阵验证记录（至少两个 Allegro 版本）

---

## 12. 故障排查速查

| 症状 | 排查 | 处置 |
| --- | --- | --- |
| 启动无 `[XFSKILL]` 日志 | `allegro.ilinit` 是否有标记块；`XFSKILL_ROOT` 是否正斜杠 | 重跑 `install.ps1` 或手写标记块 |
| 提示 `XFSKILL_ROOT is not set` | ilinit 未执行或被覆盖 | 检查标记块是否被编辑器删除 |
| `*Error* defun: too few arguments (at least 3 expected, 2 given)` | 函数定义写成了 `defun(Name(args)` | 函数名与参数表之间补空格：`defun(Name (args)`，层 1 检查 13 可静态拦截 |
| `*Error* eval: undefined function - substr` | `substr` 不是 SKILL 标准函数 | 全局换成 `substring`，层 1 检查 14 可静态拦截 |
| 启动日志有 `*Error* load: error while loading file` | 该文件加载时中止，看它报的行号 | 多为上一行的 defun 写法错误，修正后 `xfskill_reload` |
| 菜单不出现 | 层 3 检查 7；`menu_enabled` 是否为 `t`；启动日志有无 `menu trigger registered` | 重启后由 menu 触发器自动插入；或命令行执行 `xfskill_menu` 后重跑冒烟 |
| 中文乱码 | `.il` / `.cfg` 是否被存成 UTF-8 | `convert_encoding.ps1 -To gbk` 后重跑层 1 |
| 层 1 报 GBK round trip | 文件混入 UTF-8 或 CR | 转码脚本处理后复查 |
| 层 1 报括号不平衡 | 换行断在参数中间或漏写右括号 | 按第 4 节格式规则修正 |
| 层 1 报版本不一致 | 只改了 `VERSION` 或只改了文件头 | 两者同步 + 更新 CHANGELOG |
| 单元测试报 `no unit test registered` | 模块未调用 `XFSKILL_RegisterTest` | 补登记后 `xfskill_reload` |
| 升级后功能异常 | `_backup/` 中有旧版本 | `install.ps1 -Rollback <备份名>` |
| 某 Allegro 版本不兼容 | 在该版本单独记录并复现 | 修复或写入 CHANGELOG 已知限制 |

---

## 13. 一句话检查表（提交前）

```text
□ 层1 python tools/xfskill_smoke.py        → RESULT PASS
□ 层2 XFSKILL_RunUnitTests()               → 返回 t
□ 层3 XFSKILL_SmokeTest()                  → 返回 t
□ 六字段完整且版本 == VERSION
□ CHANGELOG 有 [x.y.z] 小节
□ 版本已递增，git tag 已打
□ 提交信息 <模块>: <摘要> (v<版本>)
□ 至少两个 Allegro 版本复测通过
□ 打包前备份已在 _backup/ 生成
□ 升级与回滚各演练一次
```
