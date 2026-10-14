; 文件名: modules/align/align_do.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-13
; 版本: 0.3.0
; 功能描述: 对齐操作层，实现顶底左右对齐、水平垂直居中、等距分布与拾取对齐的动作处理器
; 修改记录: 2026-10-13 由 template/align/align_do.il 按编码规范移植，函数重命名为 XFSKILL_Align 前缀

defun(XFSKILL_AlignOnTop ()
  axlMsgPut("Align by TOP boundary")
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoTop
  axlCancelEnterFun()
)

defun(XFSKILL_AlignDoTop ()
  axlDBCloak('XFSKILL_AlignMoveTop() 'shape)
)

defun(XFSKILL_AlignMoveTop ()
  let((lBBoxes maxY i objectItem boxItem boxY objectY griddedY deltaY deltaPoint grids)
    lBBoxes = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
    maxY = XFSKILL_AlignMaxBBoxY(lBBoxes)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    for(i 1 length(XFSKILL_ALIGN_SELECTED)
      objectItem = nthelem(i XFSKILL_ALIGN_SELECTED)
      boxItem = nthelem(i lBBoxes)
      boxY = yCoord(cadr(boxItem))
      deltaY = maxY - boxY
      objectY = yCoord(XFSKILL_AlignObjectLocation(objectItem))
      griddedY = yCoord(XFSKILL_AlignGriddedPoint(list(0 (objectY + deltaY)) grids))
      deltaY = griddedY - objectY
      deltaPoint = list(0 deltaY)
      XFSKILL_AlignMoveObject(objectItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnBottom ()
  axlMsgPut("Align by BOTTOM boundary")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoBottom
)

defun(XFSKILL_AlignDoBottom ()
  axlDBCloak('XFSKILL_AlignMoveBottom() 'shape)
)

defun(XFSKILL_AlignMoveBottom ()
  let((lBBoxes minY i objectItem boxItem boxY objectY griddedY deltaY deltaPoint grids)
    lBBoxes = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
    minY = XFSKILL_AlignMinBBoxY(lBBoxes)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    for(i 1 length(XFSKILL_ALIGN_SELECTED)
      objectItem = nthelem(i XFSKILL_ALIGN_SELECTED)
      boxItem = nthelem(i lBBoxes)
      boxY = yCoord(car(boxItem))
      deltaY = minY - boxY
      objectY = yCoord(XFSKILL_AlignObjectLocation(objectItem))
      griddedY = yCoord(XFSKILL_AlignGriddedPoint(list(0 (objectY + deltaY)) grids))
      deltaY = griddedY - objectY
      deltaPoint = list(0 deltaY)
      XFSKILL_AlignMoveObject(objectItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnLeft ()
  axlMsgPut("Align by LEFT boundary")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoLeft
)

defun(XFSKILL_AlignDoLeft ()
  axlDBCloak('XFSKILL_AlignMoveLeft() 'shape)
)

defun(XFSKILL_AlignMoveLeft ()
  let((lBBoxes minX i objectItem boxItem boxX objectX griddedX deltaX deltaPoint grids)
    lBBoxes = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
    minX = XFSKILL_AlignMinBBoxX(lBBoxes)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    for(i 1 length(XFSKILL_ALIGN_SELECTED)
      objectItem = nthelem(i XFSKILL_ALIGN_SELECTED)
      boxItem = nthelem(i lBBoxes)
      boxX = xCoord(car(boxItem))
      deltaX = minX - boxX
      objectX = xCoord(XFSKILL_AlignObjectLocation(objectItem))
      griddedX = xCoord(XFSKILL_AlignGriddedPoint(list((objectX + deltaX) 0) grids))
      deltaX = griddedX - objectX
      deltaPoint = list(deltaX 0)
      XFSKILL_AlignMoveObject(objectItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnRight ()
  axlMsgPut("Align by RIGHT boundary")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoRight
)

defun(XFSKILL_AlignDoRight ()
  axlDBCloak('XFSKILL_AlignMoveRight() 'shape)
)

defun(XFSKILL_AlignMoveRight ()
  let((lBBoxes maxX i objectItem boxItem boxX objectX griddedX deltaX deltaPoint grids)
    lBBoxes = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
    maxX = XFSKILL_AlignMaxBBoxX(lBBoxes)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    for(i 1 length(XFSKILL_ALIGN_SELECTED)
      objectItem = nthelem(i XFSKILL_ALIGN_SELECTED)
      boxItem = nthelem(i lBBoxes)
      boxX = xCoord(cadr(boxItem))
      deltaX = maxX - boxX
      objectX = xCoord(XFSKILL_AlignObjectLocation(objectItem))
      griddedX = xCoord(XFSKILL_AlignGriddedPoint(list((objectX + deltaX) 0) grids))
      deltaX = griddedX - objectX
      deltaPoint = list(deltaX 0)
      XFSKILL_AlignMoveObject(objectItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnCenterH ()
  axlMsgPut("Align horizontally")
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoCenterH
  axlFinishEnterFun()
)

defun(XFSKILL_AlignDoCenterH ()
  let((maxY minY fixedPointY)
    maxY = XFSKILL_AlignMaxY(XFSKILL_ALIGN_SELECTED)
    minY = XFSKILL_AlignMinY(XFSKILL_ALIGN_SELECTED)
    fixedPointY = (maxY - minY) / 2 + minY
    axlDBCloak('XFSKILL_AlignMoveToHorizontal(fixedPointY) 'shape)
  )
)

defun(XFSKILL_AlignMoveToHorizontal (fixedPointY)
  let((deltaY deltaPoint pointY grids oItem)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    fixedPointY = yCoord(XFSKILL_AlignGriddedPoint(list(0 fixedPointY) grids))
    foreach(oItem XFSKILL_ALIGN_SELECTED
      pointY = yCoord(XFSKILL_AlignObjectLocation(oItem))
      deltaY = fixedPointY - pointY
      deltaPoint = list(0 deltaY)
      XFSKILL_AlignMoveObject(oItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnCenterV ()
  axlMsgPut("Align vertically")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoCenterV
)

defun(XFSKILL_AlignDoCenterV ()
  let((maxX minX fixedPointX)
    maxX = XFSKILL_AlignMaxX(XFSKILL_ALIGN_SELECTED)
    minX = XFSKILL_AlignMinX(XFSKILL_ALIGN_SELECTED)
    fixedPointX = (maxX - minX) / 2 + minX
    axlDBCloak('XFSKILL_AlignMoveToVertical(fixedPointX) 'shape)
  )
)

defun(XFSKILL_AlignMoveToVertical (fixedPointX)
  let((deltaX deltaPoint pointX grids oItem)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    fixedPointX = xCoord(XFSKILL_AlignGriddedPoint(list(fixedPointX 0) grids))
    foreach(oItem XFSKILL_ALIGN_SELECTED
      pointX = xCoord(XFSKILL_AlignObjectLocation(oItem))
      deltaX = fixedPointX - pointX
      deltaPoint = list(deltaX 0)
      XFSKILL_AlignMoveObject(oItem deltaPoint)
    )
  )
)

defun(XFSKILL_AlignOnDistributeH ()
  axlMsgPut("Distribute horizontally")
  XFSKILL_ALIGN_SELECTED = XFSKILL_AlignOrderByX(XFSKILL_ALIGN_SELECTED)
  if(XFSKILL_ALIGN_FORM_DATA->useGap
    then XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignCalcStepBetweenBoundaryH
    else XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignCalcStepH
  )
  axlFinishEnterFun()
)

defun(XFSKILL_AlignCalcStepH ()
  let((leftX rightX step grids)
    unless(XFSKILL_ALIGN_FORM_DATA->useStepH
      leftX = xCoord(XFSKILL_AlignObjectLocation(car(XFSKILL_ALIGN_SELECTED)))
      rightX = xCoord(XFSKILL_AlignObjectLocation(car(last(XFSKILL_ALIGN_SELECTED))))
      step = (rightX - leftX) / (length(XFSKILL_ALIGN_SELECTED) - 1)
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      step = xCoord(XFSKILL_AlignGriddedPoint(list(step 0) grids))
      XFSKILL_ALIGN_FORM_DATA->stepH = step
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepH" step)
    )
    axlDBCloak('XFSKILL_AlignDoDistributeH() 'shape)
  )
)

defun(XFSKILL_AlignDoDistributeH ()
  let((i step pointX deltaX deltaPoint grids oItem)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    i = xCoord(XFSKILL_AlignGriddedPoint(XFSKILL_AlignObjectLocation(car(XFSKILL_ALIGN_SELECTED)) grids))
    step = XFSKILL_ALIGN_FORM_DATA->stepH
    foreach(oItem XFSKILL_ALIGN_SELECTED
      pointX = xCoord(XFSKILL_AlignObjectLocation(oItem))
      deltaX = i - pointX
      deltaPoint = list(deltaX 0)
      XFSKILL_AlignMoveObject(oItem deltaPoint)
      i = i + step
    )
  )
)

defun(XFSKILL_AlignCalcStepBetweenBoundaryH ()
  let((leftX prevX box lBox gap step grids)
    unless(XFSKILL_ALIGN_FORM_DATA->useStepH
      gap = 0.0
      prevX = xCoord(car(XFSKILL_AlignObjectBBox(car(XFSKILL_ALIGN_SELECTED))))
      lBox = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
      foreach(box lBox
        leftX = xCoord(car(box))
        gap = gap + leftX - prevX
        prevX = xCoord(cadr(box))
      )
      step = gap / (length(XFSKILL_ALIGN_SELECTED) - 1)
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      step = xCoord(XFSKILL_AlignGriddedPoint(list(step 0) grids))
      XFSKILL_ALIGN_FORM_DATA->stepH = step
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepH" step)
    )
    axlDBCloak('XFSKILL_AlignDistributeGapBoundaryH() 'shape)
  )
)

defun(XFSKILL_AlignDistributeGapBoundaryH ()
  let((step prevX oItem box leftX rightX deltaX currX destX deltaPoint grids)
    step = XFSKILL_ALIGN_FORM_DATA->stepH
    prevX = xCoord(car(XFSKILL_AlignObjectBBox(car(XFSKILL_ALIGN_SELECTED)))) - step
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    foreach(oItem XFSKILL_ALIGN_SELECTED
      box = XFSKILL_AlignObjectBBox(oItem)
      leftX = xCoord(car(box))
      rightX = xCoord(cadr(box))
      deltaX = leftX - prevX - step
      currX = xCoord(oItem->xy)
      destX = xCoord(XFSKILL_AlignGriddedPoint(list((currX - deltaX) 0) grids))
      deltaPoint = list((destX - currX) 0)
      XFSKILL_AlignMoveObject(oItem deltaPoint)
      prevX = prevX + step + (rightX - leftX)
    )
  )
)

defun(XFSKILL_AlignOnDistributeV ()
  axlMsgPut("Distribute vertically")
  XFSKILL_ALIGN_SELECTED = XFSKILL_AlignOrderByY(XFSKILL_ALIGN_SELECTED)
  if(XFSKILL_ALIGN_FORM_DATA->useGap
    then XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignCalcStepBetweenBoundaryV
    else XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignCalcStepV
  )
  axlFinishEnterFun()
)

defun(XFSKILL_AlignCalcStepV ()
  let((botY topY step grids)
    unless(XFSKILL_ALIGN_FORM_DATA->useStepV
      botY = yCoord(XFSKILL_AlignObjectLocation(car(XFSKILL_ALIGN_SELECTED)))
      topY = yCoord(XFSKILL_AlignObjectLocation(car(last(XFSKILL_ALIGN_SELECTED))))
      step = (topY - botY) / (length(XFSKILL_ALIGN_SELECTED) - 1)
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      step = yCoord(XFSKILL_AlignGriddedPoint(list(0 step) grids))
      XFSKILL_ALIGN_FORM_DATA->stepV = step
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepV" step)
    )
    axlDBCloak('XFSKILL_AlignDoDistributeV() 'shape)
  )
)

defun(XFSKILL_AlignDoDistributeV ()
  let((i step pointY deltaY deltaPoint grids oItem)
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    i = yCoord(XFSKILL_AlignGriddedPoint(XFSKILL_AlignObjectLocation(car(XFSKILL_ALIGN_SELECTED)) grids))
    step = XFSKILL_ALIGN_FORM_DATA->stepV
    foreach(oItem XFSKILL_ALIGN_SELECTED
      pointY = yCoord(XFSKILL_AlignObjectLocation(oItem))
      deltaY = i - pointY
      deltaPoint = list(0 deltaY)
      XFSKILL_AlignMoveObject(oItem deltaPoint)
      i = i + step
    )
  )
)

defun(XFSKILL_AlignCalcStepBetweenBoundaryV ()
  let((bottomY prevY box lBox gap step grids)
    unless(XFSKILL_ALIGN_FORM_DATA->useStepV
      gap = 0.0
      prevY = yCoord(car(XFSKILL_AlignObjectBBox(car(XFSKILL_ALIGN_SELECTED))))
      lBox = XFSKILL_AlignBBoxes(XFSKILL_ALIGN_SELECTED)
      foreach(box lBox
        bottomY = yCoord(car(box))
        gap = gap + bottomY - prevY
        prevY = yCoord(cadr(box))
      )
      step = gap / (length(XFSKILL_ALIGN_SELECTED) - 1)
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      step = yCoord(XFSKILL_AlignGriddedPoint(list(0 step) grids))
      XFSKILL_ALIGN_FORM_DATA->stepV = step
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fStepV" step)
    )
    axlDBCloak('XFSKILL_AlignDistributeGapBoundaryV() 'shape)
  )
)

defun(XFSKILL_AlignDistributeGapBoundaryV ()
  let((step prevY oItem box bottomY topY deltaY currY destY deltaPoint grids)
    step = XFSKILL_ALIGN_FORM_DATA->stepV
    prevY = yCoord(car(XFSKILL_AlignObjectBBox(car(XFSKILL_ALIGN_SELECTED)))) - step
    grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
    foreach(oItem XFSKILL_ALIGN_SELECTED
      box = XFSKILL_AlignObjectBBox(oItem)
      bottomY = yCoord(car(box))
      topY = yCoord(cadr(box))
      deltaY = bottomY - prevY - step
      currY = yCoord(oItem->xy)
      destY = yCoord(XFSKILL_AlignGriddedPoint(list(0 (currY - deltaY)) grids))
      deltaPoint = list(0 (destY - currY))
      XFSKILL_AlignMoveObject(oItem deltaPoint)
      prevY = prevY + step + (topY - bottomY)
    )
  )
)

defun(XFSKILL_AlignOnPickH ()
  axlMsgPut("Pick horizontally")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoPickH
)

defun(XFSKILL_AlignDoPickH ()
  let((fixedObject fixedPoint fixedPointY grids)
    fixedPoint = nil
    if(XFSKILL_ALIGN_FORM_DATA->usePickH
      then fixedPointY = XFSKILL_ALIGN_FORM_DATA->pickH
      else
        fixedPoint = axlEnterPoint(?prompts "Select an object or point")
        when(fixedPoint
          axlSingleSelectPoint(fixedPoint)
          fixedObject = axlGetSelSet()
          if(fixedObject
            then fixedPointY = yCoord(XFSKILL_AlignObjectLocation(car(fixedObject)))
            else fixedPointY = yCoord(fixedPoint)
          )
        )
    )
    when(fixedPointY
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      fixedPointY = yCoord(XFSKILL_AlignGriddedPoint(list(0 fixedPointY) grids))
      XFSKILL_ALIGN_FORM_DATA->pickH = fixedPointY
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickH" fixedPointY)
      axlDBCloak('XFSKILL_AlignMoveToHorizontal(fixedPointY) 'shape)
    )
  )
)

defun(XFSKILL_AlignOnPickV ()
  axlMsgPut("Pick vertically")
  axlFinishEnterFun()
  XFSKILL_ALIGN_HANDLER = 'XFSKILL_AlignDoPickV
)

defun(XFSKILL_AlignDoPickV ()
  let((fixedObject fixedPoint fixedPointX grids)
    fixedPoint = nil
    if(XFSKILL_ALIGN_FORM_DATA->usePickV
      then fixedPointX = XFSKILL_ALIGN_FORM_DATA->pickV
      else
        fixedPoint = axlEnterPoint(?prompts "Select an object or point")
        when(fixedPoint
          axlSingleSelectPoint(fixedPoint)
          fixedObject = axlGetSelSet()
          if(fixedObject
            then fixedPointX = xCoord(XFSKILL_AlignObjectLocation(car(fixedObject)))
            else fixedPointX = xCoord(fixedPoint)
          )
        )
    )
    when(fixedPointX
      grids = XFSKILL_AlignGetCurrentGrid(XFSKILL_ALIGN_SELECTED)
      fixedPointX = xCoord(XFSKILL_AlignGriddedPoint(list(fixedPointX 0) grids))
      XFSKILL_ALIGN_FORM_DATA->pickV = fixedPointX
      axlFormSetField(XFSKILL_ALIGN_FORM_PTR "fPickV" fixedPointX)
      axlDBCloak('XFSKILL_AlignMoveToVertical(fixedPointX) 'shape)
    )
  )
)
