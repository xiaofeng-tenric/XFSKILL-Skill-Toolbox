; 文件名: modules/set_symbol_grid/set_symbol_grid.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-14
; 版本: 0.3.0
; 功能描述: 按两个引脚自动设置设计格点，间距 = 两引脚距离 / 等分比，可同步原点与全局格点
; 修改记录: 2026-10-14 由 template/set_symbol_grid/set_symbol_grid.il 按编码规范移植，
;           函数重命名为 XFSKILL_SymbolGrid 前缀，表单改用 forms/set_symbol_grid.form

unless(boundp('XFSKILL_SYMBOLGRID_FORM)
  XFSKILL_SYMBOLGRID_FORM = nil
)

unless(boundp('XFSKILL_PIN_DX)
  XFSKILL_PIN_DX = 0.0
)

unless(boundp('XFSKILL_PIN_DY)
  XFSKILL_PIN_DY = 0.0
)

unless(boundp('XFSKILL_PIN_X1)
  XFSKILL_PIN_X1 = 0.0
)

unless(boundp('XFSKILL_PIN_Y1)
  XFSKILL_PIN_Y1 = 0.0
)

defun(XFSKILL_SymbolGridFormFile ()
  let((formFile)
    formFile = XFSKILL_JoinPath(XFSKILL_ROOT "forms/set_symbol_grid.form")
    unless(isFile(formFile)
      formFile = "set_symbol_grid.form"
    )
    formFile
  )
)

defun(XFSKILL_SymbolGrid ()
  prog((gridForm formFile)
    when(XFSKILL_SYMBOLGRID_FORM
      errset(axlUIWExpose(XFSKILL_SYMBOLGRID_FORM) t)
      return(t)
    )
    formFile = XFSKILL_SymbolGridFormFile()
    gridForm = axlFormCreate('XFSKILL_SYMBOLGRID_FORM formFile nil 'XFSKILL_SymbolGridAction t nil)
    unless(gridForm
      XFSKILL_Alert(strcat("set_symbol_grid form create failed " formFile))
      return(nil)
    )
    axlFormTitle(gridForm "XFSKILL - Set Grid by symbol")
    XFSKILL_SymbolGridInit(gridForm)
    axlFormDisplay(gridForm)
    XFSKILL_SymbolGridPickTwoPins(gridForm)
    t
  )
)

defun(XFSKILL_SymbolGridInit (gridForm)
  axlFormSetField(gridForm "chk_syncxy" t)
  axlFormSetField(gridForm "chk_origin" t)
  axlFormSetField(gridForm "chk_all" t)
  axlFormSetField(gridForm "ratio_2" t)
  axlFormSetField(gridForm "pin1" "等待选择...")
  axlFormSetField(gridForm "pin2" "等待选择...")
)

defun(XFSKILL_SymbolGridPickTwoPins (gridForm)
  prog((p1 p2)
    axlSetFindFilter(?enabled list("NOALL" "PINS") ?onButtons list("PINS"))
    axlClearSelSet()
    axlMsgPut("XFSKILL: 请点选第 1 个引脚")
    axlSingleSelectPoint()
    p1 = car(axlGetSelSet())
    unless(p1
      axlUIConfirm("未选择第一个引脚，取消操作。")
      XFSKILL_SymbolGridClose(gridForm)
      return(nil)
    )
    axlClearSelSet()
    axlMsgPut("XFSKILL: 请点选第 2 个引脚")
    axlSingleSelectPoint()
    p2 = car(axlGetSelSet())
    unless(p2
      axlUIConfirm("未选择第二个引脚，取消操作。")
      XFSKILL_SymbolGridClose(gridForm)
      return(nil)
    )
    XFSKILL_PIN_X1 = 0.0
    XFSKILL_PIN_Y1 = 0.0
    when(p1->xy
      XFSKILL_PIN_X1 = xCoord(p1->xy)
      XFSKILL_PIN_Y1 = yCoord(p1->xy)
    )
    XFSKILL_PIN_DX = 0.0
    XFSKILL_PIN_DY = 0.0
    when(p2->xy
      XFSKILL_PIN_DX = abs(xCoord(p2->xy) - XFSKILL_PIN_X1)
      XFSKILL_PIN_DY = abs(yCoord(p2->xy) - XFSKILL_PIN_Y1)
    )
    axlFormSetField(gridForm "pin1" sprintf(nil "(%g, %g)" XFSKILL_PIN_X1 XFSKILL_PIN_Y1))
    axlFormSetField(gridForm "pin2" sprintf(nil "dx=%.4f  dy=%.4f" XFSKILL_PIN_DX XFSKILL_PIN_DY))
  )
)

defun(XFSKILL_SymbolGridApply (gridForm)
  let((factor spacing grid hasDx hasDy)
    factor = XFSKILL_SymbolGridRatioFactor(gridForm)
    hasDx = XFSKILL_PIN_DX > 0.0001
    hasDy = XFSKILL_PIN_DY > 0.0001
    spacing = nil
    cond(
      (hasDx spacing = XFSKILL_PIN_DX * factor)
      (hasDy spacing = XFSKILL_PIN_DY * factor)
    )
    unless(spacing
      axlUIConfirm("两脚间距为 0，无法设置格点。")
      return(nil)
    )
    grid = axlDBGridGet("TOP")
    unless(grid
      axlMsgPut("XFSKILL: 无法读取当前格点")
      return(nil)
    )
    if(axlFormGetField(gridForm "chk_all")
      then grid->name = 'all
      else grid->name = 'etch
    )
    grid->xGrids = spacing
    when(axlFormGetField(gridForm "chk_syncxy")
      grid->yGrids = spacing
    )
    when(axlFormGetField(gridForm "chk_origin")
      grid->xOrigin = XFSKILL_PIN_X1
      grid->yOrigin = XFSKILL_PIN_Y1
    )
    if(axlDBGridSet(grid)
      then
        axlUIConfirm(sprintf(nil "格点已设置  间距 %g  原点 (%g, %g)"
          spacing XFSKILL_PIN_X1 XFSKILL_PIN_Y1))
      else axlUIConfirm("设置格点失败。")
    )
  )
)

defun(XFSKILL_SymbolGridRatioFactor (gridForm)
  let((factor)
    factor = 0.5
    when(axlFormGetField(gridForm "ratio_3")
      factor = 0.333333
    )
    when(axlFormGetField(gridForm "ratio_4")
      factor = 0.25
    )
    factor
  )
)

defun(XFSKILL_SymbolGridClose (gridForm)
  errset(axlFormClose(gridForm) t)
  XFSKILL_SYMBOLGRID_FORM = nil
)

defun(XFSKILL_SymbolGridAction (gridForm)
  case(gridForm->curField
    ("btn_ok"
      XFSKILL_SymbolGridApply(gridForm)
      XFSKILL_SymbolGridClose(gridForm)
    )
    ("btn_apply"
      XFSKILL_SymbolGridApply(gridForm)
    )
    ("btn_cancel"
      XFSKILL_SymbolGridClose(gridForm)
    )
  )
)

defun(XFSKILL_Test_SymbolGrid ()
  let((formFile)
    XFSKILL_Assert(
      if(getd('XFSKILL_SymbolGrid) then t else nil)
      "symbol grid entry function must exist"
    )
    XFSKILL_Assert(
      if(getd('XFSKILL_SymbolGridRatioFactor) then t else nil)
      "symbol grid ratio helper must exist"
    )
    formFile = XFSKILL_SymbolGridFormFile()
    XFSKILL_Assert(isFile(formFile) strcat("set_symbol_grid form must be found at " formFile))
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_SymbolGrid)

errset(axlCmdRegister("xfskill_set_symbol_grid" 'XFSKILL_SymbolGrid ?cmdType "interactive") t)
XFSKILL_Log("command registered xfskill_set_symbol_grid")
