; 文件名: main.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.1.0
; 功能描述: XFSKILL 总入口，负责核心层加载、状态初始化、命令注册与菜单构建
; 修改记录: 2026-10-10 创建最小可运行闭环框架

unless(boundp('XFSKILL_ROOT)
  error("XFSKILL_ROOT is not set, load main.il through allegro.ilinit")
)

load(strcat(XFSKILL_ROOT "/core/utils.il"))
load(strcat(XFSKILL_ROOT "/core/config.il"))
load(strcat(XFSKILL_ROOT "/core/loader.il"))
load(strcat(XFSKILL_ROOT "/core/menu.il"))
load(strcat(XFSKILL_ROOT "/core/test_framework.il"))

defun(XFSKILL_ShowVersion()
  XFSKILL_Log(strcat("version " XFSKILL_VERSION " root " XFSKILL_ROOT))
  XFSKILL_VERSION
)

defun(XFSKILL_Reload()
  XFSKILL_Log("reload requested")
  load(strcat(XFSKILL_ROOT "/main.il"))
  t
)

XFSKILL_TESTS = list()
XFSKILL_VersionLoad()
XFSKILL_ConfigLoad(XFSKILL_JoinPath(XFSKILL_ROOT "config/xfskill.cfg"))
XFSKILL_LoadModules()

XFSKILL_RegisterCommand("xfskill_version" 'XFSKILL_ShowVersion)
XFSKILL_RegisterCommand("xfskill_reload" 'XFSKILL_Reload)
XFSKILL_RegisterCommand("xfskill_tests" 'XFSKILL_RunUnitTests)
XFSKILL_RegisterCommand("xfskill_smoke" 'XFSKILL_SmokeTest)
XFSKILL_RegisterCommand("xfskill_menu" 'XFSKILL_MenuBuild)

when(equal(XFSKILL_ConfigGet("menu_enabled" "t") "t")
  XFSKILL_MenuBuild()
)

when(equal(XFSKILL_ConfigGet("auto_test" "f") "t")
  XFSKILL_RunUnitTests()
)

when(equal(XFSKILL_ConfigGet("auto_smoke" "f") "t")
  XFSKILL_SmokeTest()
)

XFSKILL_Log(strcat("ready version=" XFSKILL_VERSION " modules=" XFSKILL_ToString(XFSKILL_MODULE_COUNT)))
