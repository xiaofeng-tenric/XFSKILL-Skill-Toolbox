; 文件名: modules/template.il
; 作者: 你的名字
; 创建日期: 2026-10-14
; 版本: 0.1.0
; 功能描述: XXX 功能模块
; 修改记录: 2026-10-14 新增 XXX 功能

defun(XFSKILL_template ()
  let((result)
    result = ...你的逻辑...
    XFSKILL_Log(result)
    result
  )
)

XFSKILL_RegisterCommand("xfskill_template" 'XFSKILL_template)

defun(XFSKILL_Test_template ()
  let((...)
    XFSKILL_Assert(... "描述")
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_template)