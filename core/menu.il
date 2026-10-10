; 文件名: menu.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.1.0
; 功能描述: XFSKILL 菜单层，先查后插，由 menu 触发器在 Allegro 装载菜单时把 XFSKILL 挂上菜单栏
; 修改记录: 2026-10-10 创建菜单层；菜单插入改由 menu 触发器执行；菜单树改为 XFSKILL-TEST1-TEST2 三级嵌套

unless(boundp('XFSKILL_MENU_BUILT)
  XFSKILL_MENU_BUILT = nil
)

unless(boundp('XFSKILL_MENU_TRIGGER_SET)
  XFSKILL_MENU_TRIGGER_SET = nil
)

defun(XFSKILL_MenuTree ()
  list(
    list('popup "XFSKILL")
    list('popup "TEST1")
    list("TEST2-1" "xfskill_hello")
    list("TEST2-2" "xfskill_tests")
    'end
    list('separator)
    list("Run Smoke Test" "xfskill_smoke")
    list("Show Version" "xfskill_version")
    list("Reload XFSKILL" "xfskill_reload")
  )
)

defun(XFSKILL_FindExistingMenu ()
  let((probe)
    probe = errset(axlUIMenuFind(nil "xfskill_hello"))
    if(probe
      then car(probe)
      else nil
    )
  )
)

defun(XFSKILL_MenuAnchor ()
  let((probe)
    probe = errset(axlUIMenuFind(nil -1))
    if(probe && car(probe)
      then car(probe)
      else nil
    )
  )
)

defun(XFSKILL_MenuBuild ()
  let((existing anchor probe)
    existing = XFSKILL_FindExistingMenu()
    if(existing
      then
        XFSKILL_MENU_BUILT = t
        XFSKILL_Log("menu already present, skip insert")
        existing
      else
        anchor = XFSKILL_MenuAnchor()
        if(!anchor
          then
            XFSKILL_Alert("menu bar not ready, run xfskill_menu again later")
            nil
          else
            probe = errset(axlUIMenuInsert(anchor XFSKILL_MenuTree()))
            if(probe && car(probe)
              then
                XFSKILL_MENU_BUILT = t
                XFSKILL_Log("menu inserted XFSKILL")
                t
              else
                XFSKILL_Alert("menu insert failed, run xfskill_menu again later")
                nil
            )
        )
    )
  )
)

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
