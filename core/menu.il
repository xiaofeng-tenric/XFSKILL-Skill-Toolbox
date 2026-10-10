; 文件名: menu.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.1.0
; 功能描述: XFSKILL 菜单层，按先查后插原则把 XFSKILL 菜单挂到 Allegro 菜单栏
; 修改记录: 2026-10-10 创建菜单项声明、菜单定位与菜单插入

unless(boundp('XFSKILL_MENU_BUILT)
  XFSKILL_MENU_BUILT = nil
)

defun(XFSKILL_MenuItems ()
  list(
    list("Hello World" "xfskill_hello")
    list("Run Unit Tests" "xfskill_tests")
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
    probe = errset(axlUIMenuFind(nil -1 'top))
    if(probe && car(probe)
      then car(probe)
      else
        probe = errset(axlUIMenuFind(nil -1))
        if(probe && car(probe)
          then car(probe)
          else nil
        )
    )
  )
)

defun(XFSKILL_MenuFill (subMenu)
  foreach(menuEntry XFSKILL_MenuItems()
    axlUIMenuInsert(subMenu car(menuEntry) cadr(menuEntry))
  )
  t
)

defun(XFSKILL_MenuBuild ()
  let((existing anchor subMenu)
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
            subMenu = axlUIMenuInsert(anchor 'popup "XFSKILL")
            when(subMenu
              when(errset(XFSKILL_MenuFill(subMenu) t)
                XFSKILL_MENU_BUILT = t
                XFSKILL_Log("menu inserted XFSKILL")
              )
            )
            subMenu
        )
    )
  )
)
