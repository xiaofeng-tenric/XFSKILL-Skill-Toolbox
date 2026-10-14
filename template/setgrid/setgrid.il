;============================================================
; XFSKILL Plugin: SetGrid
; Quick Grid Setting for Allegro PCB Editor
;
; 参考官方文档:
;   DOC/FUNCS/axlDBGridGet.txt   读当前格点
;   DOC/FUNCS/axlDBGridSet.txt   设置格点（不需要 replay script）
;   DOC/FUNCS/axlFormCreate.txt  form 文件名解析规则
;   23utils.html                 axlMKSConvert 单位换算
;============================================================

; 直接 load 本文件（而非经加载器）时的兜底
unless( boundp('xfskillPluginDir) xfskillPluginDir = nil)

; 记住本插件自己的目录：loader 会为每个插件重设 xfskillPluginDir，
; 多个插件共用这一个全局时，后加载的会覆盖先加载的，导致找不到自己的 .form
xfskill_setgrid_dir = xfskillPluginDir

; 表单句柄。用固定的全局符号而不是 (gensym)，
; 这样才能判断表单是否已经打开、避免开出多个实例。
xfskill_setgrid_form = nil

; 单位选项 -> axlMKSConvert 需要的单位名
; 注意是【大写】——axlDBGetDesignUnits() 返回的是小写，两者不一致（官方如此）
xfskill_grid_units = '(("unit_mm"  "MILLIMETERS")
                       ("unit_mil" "MILS")
                       ("unit_um"  "MICRONS"))

; 格点选项 -> 数值
xfskill_grid_values = '(("grid_0_1"   0.1)
                        ("grid_0_5"   0.5)
                        ("grid_1"     1.0)
                        ("grid_3"     3.0)
                        ("grid_5"     5.0)
                        ("grid_10"   10.0)
                        ("grid_20"   20.0)
                        ("grid_50"   50.0)
                        ("grid_75"   75.0)
                        ("grid_100" 100.0))

;============================================================
; 对外入口
;============================================================

procedure( xfskill_setgrid()
  prog((gridForm formFile)
    ; 已打开则前置，避免开出多个实例
    when( xfskill_setgrid_form
      axlUIWExpose(xfskill_setgrid_form)
      return(t)
    )

    unless( xfskill_setgrid_dir
      axlMsgPut("XFSKILL: plugin directory unknown, cannot locate setgrid.form")
      return(nil)
    )

    ; axlFormCreate 的 form 文件名若不是完整路径，只会去 FORMPATH 里找，
    ; 而插件目录未必在 FORMPATH 中 —— 所以传完整路径。
    formFile = strcat(axlOSSlash(xfskill_setgrid_dir) "/setgrid.form")
    unless( isFile(formFile)
      axlMsgPut("XFSKILL: form file not found - %s" formFile)
      return(nil)
    )

    gridForm = axlFormCreate('xfskill_setgrid_form formFile nil
                             'xfskill_setgrid_action t nil)
    unless( gridForm
      axlMsgPut("XFSKILL: failed to create SetGrid form")
      return(nil)
    )

    axlFormTitle(gridForm "XFSKILL - Set Grid")
    xfskill_setgrid_init(gridForm)
    axlFormDisplay(gridForm)
    t
  )
)

;============================================================
; 表单初始化
;============================================================

procedure( xfskill_setgrid_init(gridForm)
  let((units current)
    ; 单位默认按当前设计单位预选
    units = car(axlDBGetDesignUnits())
    cond(
      ((equal units "millimeters") (xfskill_select_unit gridForm "unit_mm"))
      ((equal units "microns")     (xfskill_select_unit gridForm "unit_um"))
      (t                           (xfskill_select_unit gridForm "unit_mil"))
    )

    ; 把当前格点值报到消息区，方便确认状态
    current = xfskill_get_current_grid()
    when( current
      axlMsgPut("XFSKILL: current grid is %L" current)
    )
  )
)

procedure( xfskill_select_unit(gridForm selected)
  let((item)
    foreach(item xfskill_grid_units
      axlFormSetField(gridForm car(item) (equal car(item) selected))
    )
  )
)

;============================================================
; 表单回调
;============================================================

procedure( xfskill_setgrid_action(gridForm)
  let((gridValue)
    case( gridForm->curField
      ("ok_button"
        gridValue = xfskill_get_selected_grid(gridForm)
        when( gridValue
          xfskill_apply_grid(gridForm gridValue)
          xfskill_setgrid_close(gridForm)
        )
      )
      ("cancel_button"
        xfskill_setgrid_close(gridForm)
      )
      ("apply_button"
        gridValue = xfskill_get_selected_grid(gridForm)
        when( gridValue
          xfskill_apply_grid(gridForm gridValue)
        )
      )
    )
  )
)

procedure( xfskill_setgrid_close(gridForm)
  axlFormClose(gridForm)
  ; 句柄已失效，清掉以免下次误 expose 一个已关闭的表单
  xfskill_setgrid_form = nil
)

;============================================================
; 取值
;============================================================

procedure( xfskill_get_selected_grid(gridForm)
  let((gridValue item)
    gridValue = nil
    foreach(item xfskill_grid_values
      when( axlFormGetField(gridForm car(item))
        gridValue = cadr(item)
      )
    )
    unless( gridValue
      axlMsgPut("XFSKILL: please select a grid value")
    )
    gridValue
  )
)

procedure( xfskill_get_selected_unit(gridForm)
  let((unitName item)
    unitName = nil
    foreach(item xfskill_grid_units
      when( axlFormGetField(gridForm car(item))
        unitName = cadr(item)
      )
    )
    unless( unitName
      axlMsgPut("XFSKILL: please select a unit")
    )
    unitName
  )
)

; 读当前格点值（设计单位）。xGrids 恒为列表，取第一个。
procedure( xfskill_get_current_grid()
  let((o_grid)
    o_grid = axlDBGridGet("TOP")
    when( o_grid
      car(o_grid->xGrids)
    )
  )
)

;============================================================
; 应用
;============================================================

procedure( xfskill_apply_grid(gridForm gridValue)
  let((unitName designValue)
    unitName = xfskill_get_selected_unit(gridForm)
    unless( unitName
      return(nil)
    )

    ; 换算到【当前设计单位】——axlDBGridSet 要的是 dbrep。
    ; 注意第三参必须【省略】：显式传 nil 会换算到 MKS（米），差 1000 倍。
    designValue = axlMKSConvert(gridValue unitName)
    when( designValue
      xfskill_set_grid(designValue gridValue unitName)
    )
  )
)

procedure( xfskill_set_grid(designValue gridValue unitName)
  let((o_grid)
    o_grid = axlDBGridGet("TOP")
    unless( o_grid
      axlMsgPut("XFSKILL: cannot read grid settings")
      return(nil)
    )
    o_grid->name   = 'all
    o_grid->xGrids = designValue
    o_grid->yGrids = designValue
    if( axlDBGridSet(o_grid) then
      axlMsgPut("XFSKILL: grid set to %g %s" gridValue unitName)
      t
    else
      axlMsgPut("XFSKILL: failed to set grid")
      nil
    )
  )
)

; Register AFTER all function definitions
axlCmdRegister("setgrid" `xfskill_setgrid ?cmdType "general")
