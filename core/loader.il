; 文件名: loader.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.3.0
; 功能描述: XFSKILL 加载器，递归扫描 modules 下的 .il 文件并按序加载
; 修改记录: 2026-10-10 创建目录递归扫描与模块加载

unless(boundp('XFSKILL_MODULE_COUNT)
  XFSKILL_MODULE_COUNT = 0
)

defun(XFSKILL_ListDir (directory)
  let((scan)
    scan = errset(getDirFiles(directory))
    if(scan && listp(car(scan))
      then car(scan)
      else nil
    )
  )
)

defun(XFSKILL_IsDirectory (path)
  let((probe)
    probe = errset(isDir(path))
    if(probe
      then car(probe)
      else XFSKILL_ProbeDirectory(path)
    )
  )
)

defun(XFSKILL_ProbeDirectory (path)
  let((probe)
    probe = errset(getDirFiles(path))
    if(probe && car(probe)
      then t
      else nil
    )
  )
)

defun(XFSKILL_CollectIlFiles (directory)
  let((names name fullPath collected)
    collected = nil
    names = XFSKILL_ListDir(directory)
    foreach(name names
      when(!equal(name ".") && !equal(name "..")
        fullPath = XFSKILL_JoinPath(directory name)
        cond(
          (XFSKILL_EndsWith(name ".il")
            collected = cons(fullPath collected)
          )
          (XFSKILL_IsDirectory(fullPath)
            collected = append(XFSKILL_CollectIlFiles(fullPath) collected)
          )
        )
      )
    )
    reverse(collected)
  )
)

defun(XFSKILL_LoadModules ()
  let((moduleDir ilFiles loaded)
    moduleDir = XFSKILL_JoinPath(XFSKILL_ROOT "modules")
    ilFiles = XFSKILL_CollectIlFiles(moduleDir)
    loaded = 0
    foreach(ilFile ilFiles
      if(errset(load(ilFile) t)
        then
          loaded = loaded + 1
          XFSKILL_Log(strcat("module loaded " ilFile))
        else
          XFSKILL_Alert(strcat("module load failed " ilFile))
      )
    )
    XFSKILL_MODULE_COUNT = loaded
    loaded
  )
)
