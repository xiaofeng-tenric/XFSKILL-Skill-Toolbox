; XFSKILL_Setup.exe - NSIS packaging script
; Build:  "C:\Program Files (x86)\NSIS\makensis.exe" tools\xfskill_setup.nsi
; Output: dist\XFSKILL_Setup.exe
;
; Design: NSIS is a thin shell. It extracts the payload to a temp directory and
;         hands off to tools\install.ps1, which owns backup / copy / allegro.ilinit
;         logic. install.ps1 derives its source root from its own location, so the
;         payload MUST be extracted somewhere other than $INSTDIR.
; Paths:  makensis resolves relative paths against the script directory (tools\),
;         hence the ..\ prefix on every source path.
; Silent: XFSKILL_Setup.exe /S   (NSIS built-in, forwarded to install.ps1 -Silent)

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

!define PRODUCT_NAME "XFSKILL"
!define PRODUCT_PUBLISHER "XFSKILL Maintainers"
!define /file PRODUCT_VERSION "..\VERSION"
!define PAYLOAD_DIR "$LOCALAPPDATA\xfskill_payload"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\dist\XFSKILL_Setup.exe"
InstallDir "$LOCALAPPDATA\${PRODUCT_NAME}"
InstallDirRegKey HKCU "Software\${PRODUCT_NAME}" "InstallDir"
RequestExecutionLevel user
Unicode True
BrandingText "${PRODUCT_NAME} ${PRODUCT_VERSION}"

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE.md"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "Install" SecInstall
  ; Each directory is walked inside itself (dir\*.* form). The plain /r "..\dir"
  ; form would resolve the directory part to the repo root and recurse the whole
  ; tree, picking up strays such as .git\config for the "config" pattern.
  SetOutPath "${PAYLOAD_DIR}"
  File "..\main.il"
  File "..\VERSION"
  File "..\CHANGELOG.md"

  SetOutPath "${PAYLOAD_DIR}\core"
  File /r "..\core\*.*"

  SetOutPath "${PAYLOAD_DIR}\modules"
  File /r "..\modules\*.*"

  SetOutPath "${PAYLOAD_DIR}\forms"
  File /r "..\forms\*.*"

  SetOutPath "${PAYLOAD_DIR}\config"
  File /r "..\config\*.*"

  SetOutPath "${PAYLOAD_DIR}\tools"
  File /r /x __pycache__ /x "*.pyc" "..\tools\*.*"

  SetOutPath "${PAYLOAD_DIR}\references"
  File /r "..\references\*.*"
  SetOutPath "${PAYLOAD_DIR}"

  DetailPrint "Running install.ps1 ..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$\"${PAYLOAD_DIR}\tools\install.ps1$\" -Target "$\"$INSTDIR$\" -Silent'
  Pop $R0
  ${If} $R0 != "0"
    ${If} $R0 != "error"
      MessageBox MB_ICONEXCLAMATION|MB_OK \
        "install.ps1 returned exit code $R0.$\r$\nCheck the console output for details." /SD IDOK
    ${EndIf}
  ${EndIf}

  RMDir /r "${PAYLOAD_DIR}"

  WriteRegStr HKCU "Software\${PRODUCT_NAME}" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
    "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
    "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
    "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
    "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
    "EstimatedSize" "$0"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR\core"
  RMDir /r "$INSTDIR\modules"
  RMDir /r "$INSTDIR\forms"
  RMDir /r "$INSTDIR\config"
  RMDir /r "$INSTDIR\tools"
  RMDir /r "$INSTDIR\references"
  Delete "$INSTDIR\main.il"
  Delete "$INSTDIR\VERSION"
  Delete "$INSTDIR\CHANGELOG.md"
  RMDir "$INSTDIR"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
  DeleteRegKey HKCU "Software\${PRODUCT_NAME}"
SectionEnd
