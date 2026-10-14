; 文件名: modules/align/align.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-13
; 版本: 0.3.0
; 功能描述: 对齐分布模块入口，提供 xfskill_align 交互命令、参数表单、快捷键与设置持久化
; 修改记录: 2026-10-13 由 template/align/align.il 按编码规范移植，表单改用 forms/align.form，命令重命名为 xfskill_ 前缀

unless(boundp('XFSKILL_ALIGN_FINISH)
  XFSKILL_ALIGN_FINISH = nil
)

unless(boundp('XFSKILL_ALIGN_FORM_PTR)
  XFSKILL_ALIGN_FORM_PTR = nil
)

unless(boundp('XFSKILL_ALIGN_HANDLER)
  XFSKILL_ALIGN_HANDLER = nil
)

unless(boundp('XFSKILL_ALIGN_SELECTED)
  XFSKILL_ALIGN_SELECTED = nil
)

unless(boundp('XFSKILL_ALIGN_CHECKED_FILTER)
  XFSKILL_ALIGN_CHECKED_FILTER = nil
)

unless(boundp('XFSKILL_ALIGN_TXN_MARK)
  XFSKILL_ALIGN_TXN_MARK = nil
)

unless(boundp('XFSKILL_ALIGN_OOPS_KEY)
  XFSKILL_ALIGN_OOPS_KEY = nil
)

defun(XFSKILL_AlignFormFile ()
  let((formFile)
    formFile = XFSKILL_JoinPath(XFSKILL_ROOT "forms/align.form")
    unless(isFile(formFile)
      formFile = "align.form"
    )
    formFile
  )
)

defun(XFSKILL_Align ()
  let((popupMark)
    if(!axlOKToProceed()
      then nil
      else
        axlDebug(nil)
        axlClearSelSet()
        XFSKILL_AlignInitGlobals()
        XFSKILL_AlignInitForm()
        XFSKILL_AlignInitHotKeys()
        popupMark = axlUIPopupDefine(nil
          list(
            list("Done" 'XFSKILL_AlignDone)
            list("Oops" 'XFSKILL_AlignOops)
            list("Cancel" 'XFSKILL_AlignCancel)
          )
        )
        axlUIPopupSet(popupMark)
        axlSetFindFilter(
          ?enabled '(GROUPS SYMBOLS PINS VIAS TEXT NAMEFORM)
          ?onButtons XFSKILL_ALIGN_CHECKED_FILTER
        )
        axlMsgPut("Select object(s)")
        XFSKILL_ALIGN_TXN_MARK = axlDBTransactionStart()
        while(XFSKILL_ALIGN_FINISH == nil
          XFSKILL_ALIGN_SELECTED = axlGetSelSet()
          when(XFSKILL_ALIGN_SELECTED
            axlMsgPut("Choose action")
          )
          XFSKILL_ALIGN_SELECTED = XFSKILL_AlignFilterFixed(XFSKILL_ALIGN_SELECTED)
          axlSelect(?groupMode nil ?prompt nil)
          when(XFSKILL_ALIGN_HANDLER
            if(XFSKILL_ALIGN_SELECTED
              then
                axlDBTransactionMark(XFSKILL_ALIGN_TXN_MARK)
                funcall(XFSKILL_ALIGN_HANDLER)
                axlDBRefreshId(axlGetSelSet())
                XFSKILL_ALIGN_SELECTED = XFSKILL_AlignRefreshIDs(XFSKILL_ALIGN_SELECTED)
                axlSingleSelectObject(XFSKILL_ALIGN_SELECTED)
              else axlMsgPut("No object(s) found")
            )
            XFSKILL_ALIGN_HANDLER = nil
          )
        )
    )
  )
)

defun(XFSKILL_AlignDone ()
  axlDBTransactionCommit(XFSKILL_ALIGN_TXN_MARK)
  XFSKILL_AlignExit()
)

defun(XFSKILL_AlignOops ()
  when(XFSKILL_ALIGN_HANDLER
    axlFinishEnterFun()
  )
  axlDBTransactionOops(XFSKILL_ALIGN_TXN_MARK)
  XFSKILL_ALIGN_SELECTED = XFSKILL_AlignRefreshIDs(XFSKILL_ALIGN_SELECTED)
  axlAddSelectObject(XFSKILL_ALIGN_SELECTED)
)

defun(XFSKILL_AlignCancel ()
  axlDBControl('drcEnable nil)
  axlDBTransactionRollback(XFSKILL_ALIGN_TXN_MARK)
  XFSKILL_AlignExit()
)

defun(XFSKILL_AlignExit ()
  XFSKILL_ALIGN_FINISH = t
  errset(axlFormClose(XFSKILL_ALIGN_FORM_PTR) t)
  XFSKILL_ALIGN_FORM_PTR = nil
  axlDehighlightObject(XFSKILL_ALIGN_SELECTED)
  axlCancelEnterFun()
  axlClearSelSet()
  axlUIPopupSet(nil)
  XFSKILL_ALIGN_CHECKED_FILTER = axlGetFindFilter(t)
  XFSKILL_AlignStoreFilter(XFSKILL_ALIGN_CHECKED_FILTER)
  XFSKILL_ALIGN_TXN_MARK = nil
  XFSKILL_AlignRestoreHotKeys()
  axlDBControl('drcEnable t)
  XFSKILL_AlignStoreFormData()
  t
)

defun(XFSKILL_AlignInitGlobals ()
  XFSKILL_ALIGN_FINISH = nil
  XFSKILL_ALIGN_FORM_PTR = nil
  XFSKILL_ALIGN_HANDLER = nil
  XFSKILL_ALIGN_SELECTED = nil
  unless(boundp('XFSKILL_ALIGN_FORM_DATA)
    XFSKILL_ALIGN_FORM_DATA = nil
  )
  unless(boundp('XFSKILL_ALIGN_CHECKED_FILTER)
    XFSKILL_ALIGN_CHECKED_FILTER = nil
  )
  when(!XFSKILL_ALIGN_CHECKED_FILTER
    XFSKILL_ALIGN_CHECKED_FILTER = XFSKILL_AlignRestoreFilter()
    unless(XFSKILL_ALIGN_CHECKED_FILTER
      XFSKILL_ALIGN_CHECKED_FILTER = '(SYMBOLS VIAS TEXT)
    )
  )
  t
)

defun(XFSKILL_AlignInitForm ()
  let((units multiplier formFile)
    formFile = XFSKILL_AlignFormFile()
    XFSKILL_ALIGN_FORM_PTR = axlFormCreate((gensym) formFile nil 'XFSKILL_AlignFormCallback t nil)
    unless(XFSKILL_ALIGN_FORM_PTR
      when(!equal(formFile "align.form")
        XFSKILL_ALIGN_FORM_PTR = axlFormCreate((gensym) "align.form" nil 'XFSKILL_AlignFormCallback t nil)
      )
    )
    if(XFSKILL_ALIGN_FORM_PTR
      then axlFormTitle(XFSKILL_ALIGN_FORM_PTR "XFSKILL - Align")
      else XFSKILL_Alert(strcat("align form create failed " formFile))
    )
    units = axlDBGetDesignUnits()
    case(car(units)
      ("mils" multiplier = 1)
      ("inches" multiplier = 0.001)
      ("microns" multiplier = 25.4)
      ("millimeters" multiplier = 0.0254)
      ("centimeters" multiplier = 0.00254)
    )
    if(XFSKILL_ALIGN_FORM_DATA == nil
      then
        XFSKILL_ALIGN_FORM_DATA = ncons(t)
        XFSKILL_ALIGN_FORM_DATA->units = units
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxPickH" nil)
        XFSKILL_ALIGN_FORM_DATA->usePickH = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStepH" nil)
        XFSKILL_ALIGN_FORM_DATA->useStepH = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxPickV" nil)
        XFSKILL_ALIGN_FORM_DATA->usePickV = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStepV" nil)
        XFSKILL_ALIGN_FORM_DATA->useStepV = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickH" 0.0)
        XFSKILL_ALIGN_FORM_DATA->pickH = 0.0
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepH" (100.0 * multiplier))
        XFSKILL_ALIGN_FORM_DATA->stepH = 100.0 * multiplier
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickV" 0.0)
        XFSKILL_ALIGN_FORM_DATA->pickV = 0.0
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepV" (100.0 * multiplier))
        XFSKILL_ALIGN_FORM_DATA->stepV = 100.0 * multiplier
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxGap" nil)
        XFSKILL_ALIGN_FORM_DATA->useGap = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStretch" t)
        XFSKILL_ALIGN_FORM_DATA->useStretch = t
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxRipup" nil)
        XFSKILL_ALIGN_FORM_DATA->useRipup = nil
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxSnapToGrid" t)
        XFSKILL_ALIGN_FORM_DATA->snapToGrid = t
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "cmbSnapPoint" "center")
        XFSKILL_ALIGN_FORM_DATA->snapPoint = "center"
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "sPinNumber" "1")
        XFSKILL_ALIGN_FORM_DATA->snapPinNumber = "1"
      else
        when(car(XFSKILL_ALIGN_FORM_DATA->units) != car(units)
          case(car(XFSKILL_ALIGN_FORM_DATA->units)
            ("inches" multiplier = multiplier / 0.001)
            ("microns" multiplier = multiplier / 25.4)
            ("millimeters" multiplier = multiplier / 0.0254)
            ("centimeters" multiplier = multiplier / 0.00254)
          )
          XFSKILL_ALIGN_FORM_DATA->pickH = XFSKILL_ALIGN_FORM_DATA->pickH * multiplier
          XFSKILL_ALIGN_FORM_DATA->stepH = XFSKILL_ALIGN_FORM_DATA->stepH * multiplier
          XFSKILL_ALIGN_FORM_DATA->pickV = XFSKILL_ALIGN_FORM_DATA->pickV * multiplier
          XFSKILL_ALIGN_FORM_DATA->stepV = XFSKILL_ALIGN_FORM_DATA->stepV * multiplier
          XFSKILL_ALIGN_FORM_DATA->units = units
        )
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxPickH" XFSKILL_ALIGN_FORM_DATA->usePickH)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStepH" XFSKILL_ALIGN_FORM_DATA->useStepH)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxPickV" XFSKILL_ALIGN_FORM_DATA->usePickV)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStepV" XFSKILL_ALIGN_FORM_DATA->useStepV)
        axlFormSetDecimal(XFSKILL_ALIGN_FORM_PTR "fPickH" cadr(units))
        axlFormSetDecimal(XFSKILL_ALIGN_FORM_PTR "fStepH" cadr(units))
        axlFormSetDecimal(XFSKILL_ALIGN_FORM_PTR "fPickV" cadr(units))
        axlFormSetDecimal(XFSKILL_ALIGN_FORM_PTR "fStepV" cadr(units))
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickH" XFSKILL_ALIGN_FORM_DATA->pickH)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepH" XFSKILL_ALIGN_FORM_DATA->stepH)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickV" XFSKILL_ALIGN_FORM_DATA->pickV)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepV" XFSKILL_ALIGN_FORM_DATA->stepV)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxGap" XFSKILL_ALIGN_FORM_DATA->useGap)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStretch" XFSKILL_ALIGN_FORM_DATA->useStretch)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxRipup" XFSKILL_ALIGN_FORM_DATA->useRipup)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxSnapToGrid" XFSKILL_ALIGN_FORM_DATA->snapToGrid)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "cmbSnapPoint" XFSKILL_ALIGN_FORM_DATA->snapPoint)
        axlFormSetField(XFSKILL_ALIGN_FORM_PTR "sPinNumber" XFSKILL_ALIGN_FORM_DATA->snapPinNumber)
    )
    axlFormSetFieldEditable(XFSKILL_ALIGN_FORM_PTR "fPickH" XFSKILL_ALIGN_FORM_DATA->usePickH)
    axlFormSetFieldEditable(XFSKILL_ALIGN_FORM_PTR "fPickV" XFSKILL_ALIGN_FORM_DATA->usePickV)
    axlFormSetFieldEditable(XFSKILL_ALIGN_FORM_PTR "fStepH" XFSKILL_ALIGN_FORM_DATA->useStepH)
    axlFormSetFieldEditable(XFSKILL_ALIGN_FORM_PTR "fStepV" XFSKILL_ALIGN_FORM_DATA->useStepV)
    when(XFSKILL_ALIGN_FORM_DATA->useStretch
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxRipup" nil)
      XFSKILL_ALIGN_FORM_DATA->useRipup = nil
    )
    when(XFSKILL_ALIGN_FORM_DATA->useRipup
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "bxStretch" nil)
      XFSKILL_ALIGN_FORM_DATA->useStretch = nil
    )
    if(equal(XFSKILL_ALIGN_FORM_DATA->snapPoint "pin")
      then axlFormSetFieldVisible(XFSKILL_ALIGN_FORM_PTR "sPinNumber" 1)
      else axlFormSetFieldVisible(XFSKILL_ALIGN_FORM_PTR "sPinNumber" 0)
    )
    when(axlVersion('version) < 15.7
      axlFormSetFieldEditable(XFSKILL_ALIGN_FORM_PTR "bxSnapToGrid" nil)
    )
    when(XFSKILL_ALIGN_FORM_PTR
      axlFormDisplay(XFSKILL_ALIGN_FORM_PTR)
    )
  )
)

defun(XFSKILL_AlignFormCallback (form)
  case(get(form 'curField)
    ("bnTop" XFSKILL_AlignOnTop())
    ("bnCenterH" XFSKILL_AlignOnCenterH())
    ("bnBottom" XFSKILL_AlignOnBottom())
    ("bnLeft" XFSKILL_AlignOnLeft())
    ("bnCenterV" XFSKILL_AlignOnCenterV())
    ("bnRight" XFSKILL_AlignOnRight())
    ("bxPickH"
      XFSKILL_ALIGN_FORM_DATA->usePickH = form->curValue
      axlFormSetFieldEditable(form "fPickH" XFSKILL_ALIGN_FORM_DATA->usePickH)
    )
    ("fPickH" XFSKILL_ALIGN_FORM_DATA->pickH = form->curValue)
    ("bnPickH" XFSKILL_AlignOnPickH())
    ("bxPickV"
      XFSKILL_ALIGN_FORM_DATA->usePickV = form->curValue
      axlFormSetFieldEditable(form "fPickV" XFSKILL_ALIGN_FORM_DATA->usePickV)
    )
    ("fPickV" XFSKILL_ALIGN_FORM_DATA->pickV = form->curValue)
    ("bnPickV" XFSKILL_AlignOnPickV())
    ("bxStepH"
      XFSKILL_ALIGN_FORM_DATA->useStepH = form->curValue
      axlFormSetFieldEditable(form "fStepH" XFSKILL_ALIGN_FORM_DATA->useStepH)
    )
    ("fStepH" XFSKILL_ALIGN_FORM_DATA->stepH = form->curValue)
    ("bnDistributeH" XFSKILL_AlignOnDistributeH())
    ("bxStepV"
      XFSKILL_ALIGN_FORM_DATA->useStepV = form->curValue
      axlFormSetFieldEditable(form "fStepV" XFSKILL_ALIGN_FORM_DATA->useStepV)
    )
    ("fStepV" XFSKILL_ALIGN_FORM_DATA->stepV = form->curValue)
    ("bnDistributeV" XFSKILL_AlignOnDistributeV())
    ("bxGap" XFSKILL_ALIGN_FORM_DATA->useGap = form->curValue)
    ("bxStretch"
      XFSKILL_ALIGN_FORM_DATA->useStretch = form->curValue
      when(XFSKILL_ALIGN_FORM_DATA->useStretch
        axlFormSetField(form "bxRipup" nil)
        XFSKILL_ALIGN_FORM_DATA->useRipup = nil
      )
    )
    ("bxRipup"
      XFSKILL_ALIGN_FORM_DATA->useRipup = form->curValue
      when(XFSKILL_ALIGN_FORM_DATA->useRipup
        axlFormSetField(form "bxStretch" nil)
        XFSKILL_ALIGN_FORM_DATA->useStretch = nil
      )
    )
    ("bxSnapToGrid" XFSKILL_ALIGN_FORM_DATA->snapToGrid = form->curValue)
    ("cmbSnapPoint"
      XFSKILL_ALIGN_FORM_DATA->snapPoint = form->curValue
      axlFormSetFieldVisible(form "sPinNumber" if(equal(XFSKILL_ALIGN_FORM_DATA->snapPoint "pin") then 1 else 0))
    )
    ("sPinNumber" XFSKILL_ALIGN_FORM_DATA->snapPinNumber = form->curValue)
  )
)

defun(XFSKILL_AlignInitHotKeys ()
  let((aliases alias aliasFunc funckeys funckey funckeyFunc)
    when(axlVersion('version) >= 16.3
      funckeys = axlGetFunckey(nil)
      XFSKILL_ALIGN_FUNCKEYS_SAVED = nil
      foreach(funckey funckeys
        funckeyFunc = axlGetFunckey(funckey)
        XFSKILL_ALIGN_FUNCKEYS_SAVED = cons(list(funckey funckeyFunc) XFSKILL_ALIGN_FUNCKEYS_SAVED)
        when(funckeyFunc == "oops"
          XFSKILL_ALIGN_OOPS_KEY = funckey
        )
      )
    )
    aliases = axlGetAlias(nil)
    XFSKILL_ALIGN_ALIASES_SAVED = nil
    foreach(alias aliases
      aliasFunc = axlGetAlias(alias)
      XFSKILL_ALIGN_ALIASES_SAVED = cons(list(alias aliasFunc) XFSKILL_ALIGN_ALIASES_SAVED)
      when(aliasFunc == "oops"
        XFSKILL_ALIGN_OOPS_KEY = alias
      )
    )
    errset(axlCmdRegister("xfskill_align_oops" 'XFSKILL_AlignOops ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_top" 'XFSKILL_AlignOnTop ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_bottom" 'XFSKILL_AlignOnBottom ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_left" 'XFSKILL_AlignOnLeft ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_right" 'XFSKILL_AlignOnRight ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_center_h" 'XFSKILL_AlignOnCenterH ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_center_v" 'XFSKILL_AlignOnCenterV ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_dist_h" 'XFSKILL_AlignOnDistributeH ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_dist_v" 'XFSKILL_AlignOnDistributeV ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_pick_h" 'XFSKILL_AlignOnPickH ?cmdType "sub_cmd") t)
    errset(axlCmdRegister("xfskill_align_pick_v" 'XFSKILL_AlignOnPickV ?cmdType "sub_cmd") t)
    if(XFSKILL_ALIGN_OOPS_KEY
      then axlSetAlias(XFSKILL_ALIGN_OOPS_KEY "xfskill_align_oops")
      else axlSetAlias("F3" "xfskill_align_oops")
    )
    when(axlVersion('version) >= 16.3
      axlSetFunckey("a" "xfskill_align_left")
      axlSetFunckey("s" "xfskill_align_bottom")
      axlSetFunckey("w" "xfskill_align_top")
      axlSetFunckey("d" "xfskill_align_right")
      axlSetFunckey("q" "xfskill_align_center_h")
      axlSetFunckey("z" "xfskill_align_center_v")
      axlSetFunckey("e" "xfskill_align_dist_h")
      axlSetFunckey("c" "xfskill_align_dist_v")
      axlSetFunckey("r" "xfskill_align_pick_h")
      axlSetFunckey("v" "xfskill_align_pick_v")
    )
  )
)

defun(XFSKILL_AlignRestoreHotKeys ()
  let((funckey alias)
    errset(axlCmdUnregister("xfskill_align_oops") t)
    errset(axlCmdUnregister("xfskill_align_top") t)
    errset(axlCmdUnregister("xfskill_align_bottom") t)
    errset(axlCmdUnregister("xfskill_align_left") t)
    errset(axlCmdUnregister("xfskill_align_right") t)
    errset(axlCmdUnregister("xfskill_align_center_h") t)
    errset(axlCmdUnregister("xfskill_align_center_v") t)
    errset(axlCmdUnregister("xfskill_align_dist_h") t)
    errset(axlCmdUnregister("xfskill_align_dist_v") t)
    errset(axlCmdUnregister("xfskill_align_pick_h") t)
    errset(axlCmdUnregister("xfskill_align_pick_v") t)
    when(!XFSKILL_ALIGN_OOPS_KEY
      axlSetAlias("F3" nil)
    )
    when(boundp('XFSKILL_ALIGN_FUNCKEYS_SAVED) && axlVersion('version) >= 16.3
      axlSetFunckey("a" nil)
      axlSetFunckey("s" nil)
      axlSetFunckey("w" nil)
      axlSetFunckey("d" nil)
      axlSetFunckey("q" nil)
      axlSetFunckey("z" nil)
      axlSetFunckey("e" nil)
      axlSetFunckey("c" nil)
      axlSetFunckey("r" nil)
      axlSetFunckey("v" nil)
      foreach(funckey XFSKILL_ALIGN_FUNCKEYS_SAVED
        unless(axlIsProtectAlias(car(funckey))
          axlSetFunckey(car(funckey) cadr(funckey))
        )
      )
      XFSKILL_ALIGN_FUNCKEYS_SAVED = nil
    )
    when(boundp('XFSKILL_ALIGN_ALIASES_SAVED)
      foreach(alias XFSKILL_ALIGN_ALIASES_SAVED
        unless(axlIsProtectAlias(car(alias))
          axlSetAlias(car(alias) cadr(alias))
        )
      )
      XFSKILL_ALIGN_ALIASES_SAVED = nil
    )
  )
)

defun(XFSKILL_AlignStoreFormData ()
  let((sFormData attachment)
    sFormData = sprintf(nil "%L" XFSKILL_ALIGN_FORM_DATA)
    attachment = axlGetAttachment("XFSKILLAlignFormData" 'string)
    if(attachment
      then
        attachment->data = sFormData
        axlSetAttachment(attachment "XFSKILL")
      else
        errset(axlCreateAttachment("XFSKILLAlignFormData" "XFSKILL" 0 'string sFormData) t)
    )
  )
)

defun(XFSKILL_AlignRestoreFormData ()
  prog((formData attachment sFormData)
    formData = nil
    attachment = axlGetAttachment("XFSKILLAlignFormData" 'string)
    when(attachment
      sFormData = attachment->data
      when(sFormData
        formData = car(errsetstring(strcat("'" sFormData)))
      )
    )
    return(formData)
  )
)

defun(XFSKILL_AlignStoreFilter (checked)
  let((attachment sChecked)
    sChecked = sprintf(nil "%L" checked)
    attachment = axlGetAttachment("XFSKILLAlignSelectFilter" 'string)
    if(attachment
      then
        attachment->data = sChecked
        axlSetAttachment(attachment "XFSKILL")
      else
        errset(axlCreateAttachment("XFSKILLAlignSelectFilter" "XFSKILL" 0 'string sChecked) t)
    )
  )
)

defun(XFSKILL_AlignRestoreFilter ()
  prog((checked attachment sChecked)
    checked = nil
    attachment = axlGetAttachment("XFSKILLAlignSelectFilter" 'string)
    when(attachment
      sChecked = attachment->data
      when(sChecked
        checked = car(errsetstring(strcat("'" sChecked)))
      )
    )
    return(checked)
  )
)

defun(XFSKILL_Test_Align ()
  let((formFile)
    XFSKILL_Assert(if(getd('XFSKILL_Align) then t else nil) "align entry function must exist")
    XFSKILL_Assert(if(getd('XFSKILL_AlignMoveObject) then t else nil) "align move helper must exist")
    XFSKILL_Assert(if(getd('XFSKILL_AlignDoDistributeH) then t else nil) "align distribute handler must exist")
    XFSKILL_Assert(if(getd('XFSKILL_AlignFormCallback) then t else nil) "align form callback must exist")
    formFile = XFSKILL_AlignFormFile()
    XFSKILL_Assert(isFile(formFile) strcat("align form must be found at " formFile))
  )
)

XFSKILL_RegisterTest('XFSKILL_Test_Align)

errset(axlCmdRegister("xfskill_align" 'XFSKILL_Align
  ?cmdType "interactive"
  ?doneCmd 'XFSKILL_AlignDone
  ?cancelCmd 'XFSKILL_AlignCancel
) t)
XFSKILL_Log("command registered xfskill_align")

when(axlVersion('version) >= 16.3
  unless(errset(axlUIMenuFind(nil "xfskill_align") t)
    errset(axlUIMenuRegister("move" '(("&Align" "xfskill_align"))) t)
  )
)
