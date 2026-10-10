; 文件名: modules/hello.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.1.0
; 功能描述: XFSKILL 示例模块，提供问候函数、菜单命令与配套单元测试
; 修改记录: 2026-10-10 创建示例模块，贯通加载、命令、菜单、测试四条链路

defun(XFSKILL_HelloWorld()
  let((greeting)
    greeting = strcat("Hello XFSKILL " XFSKILL_VERSION)
    XFSKILL_Log(greeting)
    greeting
  )
)

XFSKILL_RegisterCommand("xfskill_hello" 'XFSKILL_HelloWorld)

defun(XFSKILL_Test_HelloWorld()
  let((greeting expected)
    greeting = XFSKILL_HelloWorld()
    expected = strcat("Hello XFSKILL " XFSKILL_VERSION)
    XFSKILL_AssertEqual(greeting expected "greeting must embed the active version")
    XFSKILL_Assert(strlen(greeting) > 0 "greeting must never be empty")
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_HelloWorld)
