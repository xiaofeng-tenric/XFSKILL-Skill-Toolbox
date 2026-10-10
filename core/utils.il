; 文件名: utils.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.1.0
; 功能描述: XFSKILL 基础工具，提供日志、告警、字符串、目录与命令注册的公共能力
; 修改记录: 2026-10-10 创建日志、告警与字符串工具集

unless(boundp('XFSKILL_LOG_PREFIX)
  XFSKILL_LOG_PREFIX = "[XFSKILL]"
)

unless(boundp('XFSKILL_ALERT_COUNT)
  XFSKILL_ALERT_COUNT = 0
)

defun(XFSKILL_Log(message)
  let((line)
    line = sprintf(nil "%s %s" XFSKILL_LOG_PREFIX message)
    printf("%s\n" line)
    line
  )
)

defun(XFSKILL_Alert(message)
  XFSKILL_ALERT_COUNT = XFSKILL_ALERT_COUNT + 1
  XFSKILL_Log(strcat("ALERT " message))
  message
)

defun(XFSKILL_InCharSet(character charSet)
  let((hit)
    hit = nil
    foreach(candidate charSet
      when(equal(candidate character)
        hit = t
      )
    )
    hit
  )
)

defun(XFSKILL_WhiteCharAt(text position)
  let((whiteChars)
    whiteChars = list(" " "\t" "\r" "\n")
    if(position >= 1 && position <= strlen(text)
      then XFSKILL_InCharSet(substr(text position 1) whiteChars)
      else nil
    )
  )
)

defun(XFSKILL_Trim(text)
  let((first last)
    first = 1
    last = strlen(text)
    while(XFSKILL_WhiteCharAt(text first)
      first = first + 1
    )
    while(XFSKILL_WhiteCharAt(text last)
      last = last - 1
    )
    if(last >= first
      then substr(text first last - first + 1)
      else ""
    )
  )
)

defun(XFSKILL_IndexOf(text token start)
  let((textLength tokenLength position hit)
    textLength = strlen(text)
    tokenLength = strlen(token)
    position = start
    hit = nil
    while(!hit && position + tokenLength - 1 <= textLength
      when(equal(substr(text position tokenLength) token)
        hit = position
      )
      position = position + 1
    )
    hit
  )
)

defun(XFSKILL_StartsWith(text prefix)
  if(strlen(text) < strlen(prefix)
    then nil
    else equal(substr(text 1 strlen(prefix)) prefix)
  )
)

defun(XFSKILL_EndsWith(text suffix)
  let((textLength suffixLength)
    textLength = strlen(text)
    suffixLength = strlen(suffix)
    if(textLength < suffixLength
      then nil
      else equal(substr(text textLength - suffixLength + 1 suffixLength) suffix)
    )
  )
)

defun(XFSKILL_ToString(value)
  if(stringp(value)
    then value
    else sprintf(nil "%L" value)
  )
)

defun(XFSKILL_JoinPath(directory name)
  if(XFSKILL_EndsWith(directory "/")
    then strcat(directory name)
    else strcat(directory "/" name)
  )
)

defun(XFSKILL_RegisterCommand(commandName handler)
  let((probe)
    probe = errset(axlCmdRegister(commandName handler))
    if(probe
      then
        XFSKILL_Log(strcat("command registered " commandName))
        t
      else
        XFSKILL_Alert(strcat("command register failed " commandName))
        nil
    )
  )
)
