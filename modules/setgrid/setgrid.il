; 文件名: modules/setgrid/setgrid.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-14
; 版本: 0.3.0
; 功能描述: 快速设置设计格点，通过表单选择单位与格点值并写入 TOP 层格点
; 修改记录: 2026-10-14 由 template/setgrid/setgrid.il 按编码规范移植，函数重命名为 XFSKILL_SetGrid 前缀

unless(boundp('XFSKILL_SETGRID_FORM)
  XFSKILL_SETGRID_FORM = nil
)

XFSKILL_SETGRID_UNITS = list(
  list("unit_mm" "MILLIMETERS")
  list("unit_mil" "MILS")
)

XFSKILL_SETGRID_VALUES = list(
  list("grid_0_1" 0.1)
  list("grid_0_5" 0.5)
  list("grid_1" 1.0)
  list("grid_3" 3.0)
  list("grid_5" 5.0)
  list("grid_10" 10.0)
  list("grid_20" 20.0)
  list("grid_50" 50.0)
  list("grid_75" 75.0)
  list("grid_100" 100.0)
)

defun(XFSKILL_SetGridFormFile ()
  let((formFile)
    formFile = XFSKILL_JoinPath(XFSKILL_ROOT "forms/setgrid.form")
    unless(isFile(formFile)
      formFile = "setgrid.form"
    )
    formFile
  )
)

defun(XFSKILL_SetGrid ()
  prog((gridForm formFile)
    when(XFSKILL_SETGRID_FORM
      errset(axlUIWExpose(XFSKILL_SETGRID_FORM) t)
      return(t)
    )
    formFile = XFSKILL_SetGridFormFile()
    gridForm = axlFormCreate('XFSKILL_SETGRID_FORM formFile nil 'XFSKILL_SetGridAction t nil)
    unless(gridForm
      XFSKILL_Alert(strcat("setgrid form create failed " formFile))
      return(nil)
    )
    axlFormTitle(gridForm "XFSKILL - Set Grid")
    XFSKILL_SetGridInit(gridForm)
    axlFormDisplay(gridForm)
    t
  )
)

defun(XFSKILL_SetGridInit (gridForm)
  let((units current)
    units = car(axlDBGetDesignUnits())
    cond(
      (equal(units "millimeters") XFSKILL_SetGridSelectUnit(gridForm "unit_mm"))
      (equal(units "microns") XFSKILL_SetGridSelectUnit(gridForm "unit_um"))
      (t XFSKILL_SetGridSelectUnit(gridForm "unit_mil"))
    )
    current = XFSKILL_SetGridGetCurrent()
    when(current
      axlMsgPut(sprintf(nil "XFSKILL: current grid is %L" current))
    )
  )
)

defun(XFSKILL_SetGridSelectUnit (gridForm selected)
  let((item)
    foreach(item XFSKILL_SETGRID_UNITS
      axlFormSetField(gridForm car(item) equal(car(item) selected))
    )
  )
)

defun(XFSKILL_SetGridAction (gridForm)
  let((gridValue)
    case(gridForm->curField
      ("ok_button"
        gridValue = XFSKILL_SetGridGetSelectedValue(gridForm)
        when(gridValue
          XFSKILL_SetGridApply(gridForm gridValue)
          XFSKILL_SetGridClose(gridForm)
        )
      )
      ("cancel_button"
        XFSKILL_SetGridClose(gridForm)
      )
      ("apply_button"
        gridValue = XFSKILL_SetGridGetSelectedValue(gridForm)
        when(gridValue
          XFSKILL_SetGridApply(gridForm gridValue)
        )
      )
    )
  )
)

defun(XFSKILL_SetGridClose (gridForm)
  errset(axlFormClose(gridForm) t)
  XFSKILL_SETGRID_FORM = nil
)

defun(XFSKILL_SetGridGetSelectedValue (gridForm)
  let((gridValue item)
    gridValue = nil
    foreach(item XFSKILL_SETGRID_VALUES
      when(axlFormGetField(gridForm car(item))
        gridValue = cadr(item)
      )
    )
    unless(gridValue
      axlMsgPut("XFSKILL: please select a grid value")
    )
    gridValue
  )
)

defun(XFSKILL_SetGridGetSelectedUnit (gridForm)
  let((unitName item)
    unitName = nil
    foreach(item XFSKILL_SETGRID_UNITS
      when(axlFormGetField(gridForm car(item))
        unitName = cadr(item)
      )
    )
    unless(unitName
      axlMsgPut("XFSKILL: please select a unit")
    )
    unitName
  )
)

defun(XFSKILL_SetGridGetCurrent ()
  let((o_grid)
    o_grid = axlDBGridGet("TOP")
    when(o_grid
      car(o_grid->xGrids)
    )
  )
)

defun(XFSKILL_SetGridApply (gridForm gridValue)
  let((unitName designValue)
    unitName = XFSKILL_SetGridGetSelectedUnit(gridForm)
    unless(unitName
      return(nil)
    )
    designValue = axlMKSConvert(gridValue unitName)
    when(designValue
      XFSKILL_SetGridWrite(designValue gridValue unitName)
    )
  )
)

defun(XFSKILL_SetGridWrite (designValue gridValue unitName)
  let((o_grid)
    o_grid = axlDBGridGet("TOP")
    unless(o_grid
      axlMsgPut("XFSKILL: cannot read grid settings")
      return(nil)
    )
    o_grid->name = 'all
    o_grid->xGrids = designValue
    o_grid->yGrids = designValue
    if(axlDBGridSet(o_grid)
      then
        axlMsgPut(sprintf(nil "XFSKILL: grid set to %g %s" gridValue unitName))
        t
      else
        axlMsgPut("XFSKILL: failed to set grid")
        nil
    )
  )
)

defun(XFSKILL_Test_SetGrid ()
  let((formFile)
    XFSKILL_Assert(if(getd('XFSKILL_SetGrid) then t else nil) "setgrid entry function must exist")
    XFSKILL_Assert(if(getd('XFSKILL_SetGridWrite) then t else nil) "setgrid write helper must exist")
    XFSKILL_Assert(length(XFSKILL_SETGRID_VALUES) == 10 "setgrid must offer 10 grid values")
    formFile = XFSKILL_SetGridFormFile()
    XFSKILL_Assert(isFile(formFile) strcat("setgrid form must be found at " formFile))
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_SetGrid)

errset(axlCmdRegister("xfskill_setgrid" 'XFSKILL_SetGrid ?cmdType "general") t)
XFSKILL_Log("command registered xfskill_setgrid")
