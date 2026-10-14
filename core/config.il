; 文件名: config.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.3.0
; 功能描述: XFSKILL 配置层，读取 VERSION 与 config/xfskill.cfg 并提供查询接口
; 修改记录: 2026-10-10 创建版本读取与 key=value 配置解析

unless(boundp('XFSKILL_CONFIG)
  XFSKILL_CONFIG = list()
)

unless(boundp('XFSKILL_VERSION)
  XFSKILL_VERSION = "0.0.0"
)

defun(XFSKILL_VersionLoad ()
  let((versionFile port line version)
    version = "0.0.0"
    versionFile = XFSKILL_JoinPath(XFSKILL_ROOT "VERSION")
    when(isFile(versionFile)
      port = infile(versionFile)
      when(port
        when(gets(line port)
          version = XFSKILL_Trim(line)
        )
        close(port)
      )
    )
    XFSKILL_VERSION = version
    XFSKILL_Log(strcat("version file -> " version))
    version
  )
)

defun(XFSKILL_ConfigLoad (configFile)
  let((port line separator key value)
    XFSKILL_CONFIG = list()
    when(isFile(configFile)
      port = infile(configFile)
      when(port
        while(gets(line port)
          line = XFSKILL_Trim(line)
          when(strlen(line) > 0 && !XFSKILL_StartsWith(line "#")
            separator = XFSKILL_IndexOf(line "=" 1)
            when(separator
              key = XFSKILL_Trim(substring(line 1 separator - 1))
              value = XFSKILL_Trim(substring(line separator + 1))
              when(strlen(key) > 0
                XFSKILL_CONFIG = cons(list(key value) XFSKILL_CONFIG)
              )
            )
          )
        )
        close(port)
      )
    )
    XFSKILL_Log(strcat("config entries " XFSKILL_ToString(length(XFSKILL_CONFIG))))
    XFSKILL_CONFIG
  )
)

defun(XFSKILL_ConfigGet (key defaultValue)
  let((result)
    result = defaultValue
    foreach(entry XFSKILL_CONFIG
      when(equal(car(entry) key)
        result = cadr(entry)
      )
    )
    result
  )
)
