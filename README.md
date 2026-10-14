# XFSKILL-Skill-Toolbox

Cadence Allegro SKILL 工具集，提供一键安装、自动更新、版本回滚、全程可追溯的 Allegro 扩展框架，
内置三个实用模块：**对齐分布**、**快速格点**、**双引脚计算格点**。

- 兼容：Allegro 16.6 / 17.4 / 24.1
- 当前版本：**v0.3.0**
- 编码：`.il` / `.cfg` 为 GBK（Allegro 按 Windows ANSI 代码页读取），文档为 UTF-8

## 功能一览

| 模块 | 命令 | 说明 |
| --- | --- | --- |
| 对齐分布 `modules/align/` | `xfskill_align` | 交互式对齐工具：顶/底/左/右对齐、水平/垂直居中、等距/等间隙分布、拾取对齐；支持 Stretch/Ripup 走线跟随、栅格吸附、按原点/中心/引脚对齐 |
| 快速格点 `modules/setgrid/` | `xfskill_setgrid` | 表单选择单位（mm/mil/um）与格点值（0.1~100），一键写入设计格点；打开时按当前设计单位自动预选 |
| 双引脚格点 `modules/set_symbol_grid/` | `xfskill_set_symbol_grid` | 依次点选两个引脚，按 等分比（2/3/4）计算格点间距，可同步 X/Y、原点对齐到 pin1、应用到全局格点 |
| 示例模块 `modules/hello.il` | `xfskill_hello` | 最小闭环演示，兼作新模块开发模板 |

### 核心命令（加载即注册）

| 命令 | 作用 |
| --- | --- |
| `xfskill_version` | 显示当前版本与安装路径 |
| `xfskill_reload` | 重新加载整条 XFSKILL 链 |
| `xfskill_tests` | 执行层 2 单元测试 |
| `xfskill_smoke` | 执行层 3 运行时冒烟 |

> 提示：`xfskill_*` 是 Allegro **命令**，命令行输入时不加括号；SKILL 控制台里调用对应函数形式，如 `XFSKILL_RunUnitTests()`。

### 菜单

加载成功后菜单栏出现 `XFSKILL` 菜单：

```text
XFSKILL
└── TEST
    ├── Run Smoke Test      xfskill_smoke
    ├── Show Version        xfskill_version
    ├── ────────────
    ├── Reload XFSKILL      xfskill_reload
    ├── Align Objects       xfskill_align
    ├── Set Grid            xfskill_setgrid
    └── Set Grid by Pins    xfskill_set_symbol_grid
```

## 安装

```powershell
# 首次安装 / 升级（自动备份旧版、复制文件、写入 allegro.ilinit 标记块）
powershell -ExecutionPolicy Bypass -File tools\install.ps1

# 静默安装（批量部署）
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Silent

# 指定安装目录与 ilinit 位置
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Target D:/XFSKILL -IlInit C:/home/pcbenv/allegro.ilinit

# 回滚到指定备份
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Rollback 0.2.0_20261014_090000
```

安装后重启 Allegro，命令行应出现：

```text
[XFSKILL] ready version=0.3.0 modules=4
```

也可手工加载（开发期临时验证）：在 `%HOME%/pcbenv/allegro.ilinit` 中写入：

```skill
unless(boundp('XFSKILL_ROOT)
  XFSKILL_ROOT = "D:/XFSKILL"
)
load(strcat(XFSKILL_ROOT "/main.il"))
```

路径必须使用**正斜杠**。

## 使用

### 对齐分布（xfskill_align）

1. 命令行输入 `xfskill_align`（或菜单 Align Objects），弹出 "XFSKILL - Align" 表单
2. 框选对象 → 表单上点 Top / Bottom / Left / Right / Center / Distrib / Pick
3. 表单选项：Gap（按间隙分布）、Stretch etch / Ripup etch（走线跟随）、Grid snap（栅格吸附）、
   对齐基准（Origin / Center / Pin）
4. **Done** 提交事务；**Oops** 回退一步；**Cancel** 撤销退出

会话内快捷键（退出自动恢复原绑定）：

| 键 | 动作 | 键 | 动作 |
| --- | --- | --- | --- |
| w / s | 对齐顶 / 底 | q / z | 水平 / 垂直居中 |
| a / d | 对齐左 / 右 | e / c | 水平 / 垂直分布 |
| r / v | 水平 / 垂直拾取 | F3 | Oops |

### 快速格点（xfskill_setgrid）

命令行输入 `xfskill_setgrid` → 选单位与格点值 → OK（应用并关闭）/ Apply（应用不关闭）/ Cancel。

### 双引脚格点（xfskill_set_symbol_grid）

命令行输入 `xfskill_set_symbol_grid` → 依次点选第 1、第 2 个引脚 →
表单回显坐标与 dx/dy → 选等分比 → Apply。间距 = 引脚距离 ÷ 等分比。

> 图标显示：`align.form` 的按钮图标位于 `forms/icons/`，需把该目录加入 Allegro 的
> `bmppath` 环境变量；不配置只影响图标显示，功能不受影响。

## 目录结构

```text
XFSKILL-Skill-Toolbox/
├── main.il                       总入口：加载核心层、初始化、注册命令、构建菜单
├── core/
│   ├── utils.il                  日志/告警/字符串/路径工具、命令注册
│   ├── config.il                 版本与配置加载
│   ├── loader.il                 递归扫描加载 modules/**.il
│   ├── menu.il                   XFSKILL 菜单（menu 触发器自动补插）
│   └── test_framework.il         断言、单元测试、运行时冒烟
├── modules/
│   ├── hello.il                  示例模块
│   ├── align/                    对齐分布模块
│   ├── setgrid/                  快速格点模块
│   └── set_symbol_grid/          双引脚计算格点模块
├── forms/                        表单定义 *.form 与 icons/ 图标
├── config/xfskill.cfg            运行配置（menu_enabled / auto_test / auto_smoke / backup_keep）
├── tools/
│   ├── xfskill_smoke.py          层 1 静态检查（14 项）
│   ├── convert_encoding.ps1      UTF-8 ↔ GBK 转换
│   └── install.ps1               安装 / 升级 / 回滚
├── template/                     第三方插件源码暂存区（不进静态闸门、不随加载链执行）
├── references/coding-standard.md 编码规范
└── _backup/                      升级前自动备份
```

## 开发：新增一个模块

1. 复制 `template/module_skeleton.il` 到 `modules/<feature>.il`，按六字段文件头填写
2. 函数名 `XFSKILL_` 前缀、命令名 `xfskill_` 前缀，配套 `XFSKILL_Test_<feature>` 并
   `XFSKILL_RegisterTest` 登记（loader 会自动加载 `modules/` 下所有 `.il`，无需改 main.il）
3. 跑三层闭环（顺序不可调换，任一层失败即停止）：

```powershell
# 层 1 静态检查（本机执行）
powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To utf8
python tools\xfskill_smoke.py --encoding utf8
powershell -ExecutionPolicy Bypass -File tools\convert_encoding.ps1 -To gbk
python tools\xfskill_smoke.py
```

```text
层 2 单元测试（Allegro 内）  skill> XFSKILL_RunUnitTests()
层 3 运行时冒烟（Allegro 内） skill> XFSKILL_SmokeTest()
```

4. 递增 `VERSION`、同步全部 `.il` 文件头版本、`CHANGELOG.md` 新增小节，三者必须一致
5. 提交信息格式：`modules/<feature>: <摘要> (v<版本>)`

硬约束速记：2 空格缩进、无 Tab、行宽 ≤ 120、注释独占整行、`defun(名字 (参数)` 名字后必须有空格、
用 `substring` 不用 `substr`、改数据库走事务。完整规范见 `references/coding-standard.md` 与 `AGENTS.md`。

## 配置（config/xfskill.cfg）

| 键 | 默认 | 说明 |
| --- | --- | --- |
| `menu_enabled` | `t` | 是否构建 XFSKILL 菜单 |
| `auto_test` | `f` | 启动时自动跑单元测试 |
| `auto_smoke` | `f` | 启动时自动跑冒烟测试 |
| `backup_keep` | `5` | 升级备份保留份数 |

## 故障排查

| 症状 | 排查 | 处置 |
| --- | --- | --- |
| 启动无 `[XFSKILL]` 日志 | `allegro.ilinit` 是否有加载语句；`XFSKILL_ROOT` 是否正斜杠 | 手工补写或重跑 `install.ps1` |
| 提示 `undefined function - xfskill_reload` | 命令被当函数调用了 | 命令行不加括号；SKILL 控制台改用 `XFSKILL_Reload()` |
| `*Error* eval: undefined function - substr` | 用了非标准函数 | 全局换成 `substring` |
| 中文乱码 | `.il` / `.cfg` 被存成 UTF-8 | `convert_encoding.ps1 -To gbk` 后重跑层 1 |
| 菜单不出现 | 启动日志有无 `menu trigger registered` | 命令行执行 `xfskill_menu` 后重跑 `xfskill_smoke` |
| 升级后功能异常 | `_backup/` 中有旧版本 | `install.ps1 -Rollback <备份名>` |

## 版本历史

见 [CHANGELOG.md](CHANGELOG.md)。发布链：`VERSION` 文件 == 每个 `.il` 文件头版本 == `CHANGELOG.md` 小节 == `git tag`。

## 许可

内部工具，按需分发。
