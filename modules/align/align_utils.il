; 文件名: modules/align/align_utils.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-13
; 版本: 0.3.0
; 功能描述: 对齐工具函数库，提供包围盒计算、栅格吸附、对象排序、固定对象过滤与对象移动
; 修改记录: 2026-10-13 由 template/align/align_utils.il 按编码规范移植，函数重命名为 XFSKILL_Align 前缀

unless(boundp('XFSKILL_ALIGN_FORM_DATA)
  XFSKILL_ALIGN_FORM_DATA = nil
)

defun(XFSKILL_AlignGriddedPoint (point grids)
  let((xOrigin yOrigin xMajor yMajor pointX pointY)
    pointX = xCoord(point)
    pointY = yCoord(point)
    when(axlVersion('version) >= 15.7
      when(XFSKILL_ALIGN_FORM_DATA->snapToGrid && grids
        xMajor = grids->xMajor
        yMajor = grids->yMajor
        xOrigin = grids->xOrigin
        yOrigin = grids->yOrigin
        pointX = round(pointX / xMajor) * xMajor + xOrigin
        pointY = round(pointY / yMajor) * yMajor + yOrigin
      )
    )
    list(pointX pointY)
  )
)

defun(XFSKILL_AlignGetCurrentGrid (selectedObjects)
  prog((grids isMirrored)
    when(axlVersion('version) >= 15.7
      case(car(selectedObjects)->objType
        (("group" "symbol" "pin" "via")
          isMirrored = car(selectedObjects)->isMirrored
          foreach(item XFSKILL_ALIGN_SELECTED
            if(isMirrored == item->isMirrored
              then isMirrored = item->isMirrored
              else return(axlDBGridGet(axlConductorTopLayer()))
            )
          )
          if(isMirrored
            then return(axlDBGridGet(axlConductorBottomLayer()))
            else return(axlDBGridGet(axlConductorTopLayer()))
          )
        )
        ("text"
          grids = axlDBGridGet("non-etch")
        )
      )
    )
    return(grids)
  )
)

defun(XFSKILL_AlignMaxX (lObjects)
  let((obj pointX result)
    result = -1000000.0
    foreach(obj lObjects
      pointX = xCoord(XFSKILL_AlignObjectLocation(obj))
      result = max(pointX result)
    )
    result
  )
)

defun(XFSKILL_AlignMinX (lObjects)
  let((obj pointX result)
    result = 1000000.0
    foreach(obj lObjects
      pointX = xCoord(XFSKILL_AlignObjectLocation(obj))
      result = min(pointX result)
    )
    result
  )
)

defun(XFSKILL_AlignMaxY (lObjects)
  let((obj pointY result)
    result = -1000000.0
    foreach(obj lObjects
      pointY = yCoord(XFSKILL_AlignObjectLocation(obj))
      result = max(pointY result)
    )
    result
  )
)

defun(XFSKILL_AlignMinY (lObjects)
  let((obj pointY result)
    result = 1000000.0
    foreach(obj lObjects
      pointY = yCoord(XFSKILL_AlignObjectLocation(obj))
      result = min(pointY result)
    )
    result
  )
)

defun(XFSKILL_AlignOrderByX (objectList)
  sort(objectList 'XFSKILL_AlignComparePositionX)
)

defun(XFSKILL_AlignComparePositionX (obj1 obj2)
  let((pt1 pt2 pt1x pt2x pt1y pt2y result)
    pt1 = XFSKILL_AlignObjectLocation(obj1)
    pt2 = XFSKILL_AlignObjectLocation(obj2)
    pt1x = xCoord(pt1)
    pt2x = xCoord(pt2)
    if(pt1x < pt2x
      then result = t
      else
        if(pt1x == pt2x
          then
            pt1y = yCoord(pt1)
            pt2y = yCoord(pt2)
            if(pt1y < pt2y
              then result = t
              else result = nil
            )
          else result = nil
        )
    )
    result
  )
)

defun(XFSKILL_AlignOrderByY (objectList)
  sort(objectList 'XFSKILL_AlignComparePositionY)
)

defun(XFSKILL_AlignComparePositionY (obj1 obj2)
  let((pt1 pt2 pt1x pt2x pt1y pt2y result)
    pt1 = XFSKILL_AlignObjectLocation(obj1)
    pt2 = XFSKILL_AlignObjectLocation(obj2)
    pt1y = yCoord(pt1)
    pt2y = yCoord(pt2)
    if(pt1y < pt2y
      then result = t
      else
        if(pt1y == pt2y
          then
            pt1x = xCoord(pt1)
            pt2x = xCoord(pt2)
            if(pt1x < pt2x
              then result = t
              else result = nil
            )
          else result = nil
        )
    )
    result
  )
)

defun(XFSKILL_AlignObjectLocation (object)
  let((result message)
    case(XFSKILL_ALIGN_FORM_DATA->snapPoint
      ("origin" result = axlDBAltOrigin('origin object))
      ("center" result = axlDBAltOrigin('center object))
      ("pin"
        result = XFSKILL_AlignPinLocation(object XFSKILL_ALIGN_FORM_DATA->snapPinNumber)
        when(!result
          message = strcat("WARNING: Pin '" XFSKILL_ALIGN_FORM_DATA->snapPinNumber "' not found")
          if(object->refdes
            then message = strcat(message " for symbol '" object->refdes "', got body center.")
            else message = strcat(message ", got body center.")
          )
          axlMsgPut(message)
          result = axlDBAltOrigin('center object)
        )
      )
    )
    result
  )
)

defun(XFSKILL_AlignPinLocation (object pinNumber)
  let((result number pin pinList)
    pinNumber = upperCase(pinNumber)
    pinList = object->pins
    foreach(pin pinList
      number = upperCase(pin->number)
      when(pinNumber == number
        result = pin->xy
      )
    )
    result
  )
)

defun(XFSKILL_AlignObjectBBox (object)
  let((objectChildren child dfaLayer placeLayer result)
    if(object->isMirrored
      then
        dfaLayer = "PACKAGE GEOMETRY/DFA_BOUND_BOTTOM"
        placeLayer = "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM"
      else
        dfaLayer = "PACKAGE GEOMETRY/DFA_BOUND_TOP"
        placeLayer = "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
    )
    objectChildren = object->children
    when(objectChildren
      foreach(child objectChildren
        when(child->objType == "shape" && child->layer == dfaLayer
          result = child->bBox
        )
      )
      unless(result
        foreach(child objectChildren
          when(child->objType == "shape" && child->layer == placeLayer
            result = child->bBox
          )
        )
      )
    )
    unless(result
      result = object->bBox
    )
    result
  )
)

defun(XFSKILL_AlignBBoxes (objectList)
  let((object result)
    foreach(object objectList
      result = tconc(result XFSKILL_AlignObjectBBox(object))
    )
    car(result)
  )
)

defun(XFSKILL_AlignMinBBoxX (boxList)
  let((pointX box result)
    result = 1000000.0
    foreach(box boxList
      pointX = xCoord(car(box))
      result = min(pointX result)
    )
    result
  )
)

defun(XFSKILL_AlignMaxBBoxX (boxList)
  let((pointX box result)
    result = -1000000.0
    foreach(box boxList
      pointX = xCoord(cadr(box))
      result = max(pointX result)
    )
    result
  )
)

defun(XFSKILL_AlignMinBBoxY (boxList)
  let((pointY box result)
    result = 1000000.0
    foreach(box boxList
      pointY = yCoord(car(box))
      result = min(pointY result)
    )
    result
  )
)

defun(XFSKILL_AlignMaxBBoxY (boxList)
  let((pointY box result)
    result = -1000000.0
    foreach(box boxList
      pointY = yCoord(cadr(box))
      result = max(pointY result)
    )
    result
  )
)

defun(XFSKILL_AlignRefreshIDs (objectList)
  let((object resultList)
    foreach(object objectList
      resultList = tconc(resultList axlDBRefreshId(object))
    )
    car(resultList)
  )
)

defun(XFSKILL_AlignFilterFixed (objectList)
  let((object resultList)
    foreach(object objectList
      if(axlDBIsFixed(object nil)
        then axlSubSelectObject(object)
        else resultList = tconc(resultList object)
      )
    )
    car(resultList)
  )
)

defun(XFSKILL_AlignMoveObject (object deltaPoint)
  let((segmentsToCreate segmentsToRemove pinList pin pinXY paths isVia path segments segment startEnd
      newStartEnd segmentToCreate x1 y1 x2 y2 net width layer netname)
    when(car(deltaPoint) != 0.0 || cadr(deltaPoint) != 0.0
      when(XFSKILL_ALIGN_FORM_DATA->useStretch || XFSKILL_ALIGN_FORM_DATA->useRipup
        pinList = object->pins
        when(object->objType == "via"
          isVia = t
          pinList = list(object)
        )
        foreach(pin pinList
          pinXY = pin->xy
          paths = axlDBGetConnect(pin nil)
          foreach(path paths
            segments = path->segments
            foreach(segment segments
              startEnd = segment->startEnd
              newStartEnd = nil
              if(car(startEnd) == pinXY
                then
                  x1 = xCoord(car(startEnd)) + xCoord(deltaPoint)
                  y1 = yCoord(car(startEnd)) + yCoord(deltaPoint)
                  x2 = xCoord(cadr(startEnd))
                  y2 = yCoord(cadr(startEnd))
                  newStartEnd = list(x1:y1 x2:y2)
                else
                  when(cadr(startEnd) == pinXY
                    x1 = xCoord(car(startEnd))
                    y1 = yCoord(car(startEnd))
                    x2 = xCoord(cadr(startEnd)) + xCoord(deltaPoint)
                    y2 = yCoord(cadr(startEnd)) + yCoord(deltaPoint)
                    newStartEnd = list(x1:y1 x2:y2)
                  )
              )
              when(newStartEnd
                segmentsToRemove = cons(segment segmentsToRemove)
                segmentToCreate = ncons(t)
                segmentToCreate->startEnd = newStartEnd
                segmentToCreate->width = segment->width
                segmentToCreate->layer = segment->layer
                segmentToCreate->netname = (segment->net)->name
                segmentsToCreate = cons(segmentToCreate segmentsToCreate)
              )
            )
          )
        )
        when(segmentsToRemove
          foreach(segment segmentsToRemove
            axlDeleteObject(segment)
          )
        )
      )
      axlTransformObject(object ?move deltaPoint)
      when(isVia
        net = car(segmentsToCreate)->netname
        when(net
          axlDBAssignNet(object net)
        )
      )
      when(segmentsToCreate && XFSKILL_ALIGN_FORM_DATA->useStretch
        foreach(segment segmentsToCreate
          startEnd = segment->startEnd
          width = segment->width
          layer = segment->layer
          netname = segment->netname
          axlDBCreateLine(startEnd width layer netname nil)
        )
      )
    )
    t
  )
)
