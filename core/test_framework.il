; 文件名: test_framework.il
; 作者: XFSKILL Dev Team
; 创建日期: 2026-10-10
; 版本: 0.3.0
; 功能描述: XFSKILL 测试框架，提供用例登记、断言、单元测试执行与运行时冒烟检查
; 修改记录: 2026-10-10 创建断言与单元测试执行器

unless(boundp('XFSKILL_TESTS)
  XFSKILL_TESTS = list()
)

unless(boundp('XFSKILL_TEST_PASS)
  XFSKILL_TEST_PASS = 0
)

unless(boundp('XFSKILL_TEST_FAIL)
  XFSKILL_TEST_FAIL = 0
)

unless(boundp('XFSKILL_TEST_FAILURES)
  XFSKILL_TEST_FAILURES = list()
)

defun(XFSKILL_RegisterTest (testName)
  XFSKILL_TESTS = cons(testName XFSKILL_TESTS)
  testName
)

defun(XFSKILL_RecordFailure (message)
  XFSKILL_TEST_FAIL = XFSKILL_TEST_FAIL + 1
  XFSKILL_TEST_FAILURES = cons(message XFSKILL_TEST_FAILURES)
  XFSKILL_Log(strcat("FAIL " message))
  nil
)

defun(XFSKILL_Assert (condition message)
  if(condition
    then
      XFSKILL_TEST_PASS = XFSKILL_TEST_PASS + 1
      t
    else XFSKILL_RecordFailure(message)
  )
)

defun(XFSKILL_AssertEqual (actual expected message)
  let((detail)
    detail = strcat(message " | expected=" XFSKILL_ToString(expected) " actual=" XFSKILL_ToString(actual))
    XFSKILL_Assert(equal(actual expected) detail)
  )
)

defun(XFSKILL_ResetCounters ()
  XFSKILL_TEST_PASS = 0
  XFSKILL_TEST_FAIL = 0
  XFSKILL_TEST_FAILURES = list()
  t
)

defun(XFSKILL_ReportResult (layerName)
  XFSKILL_Log(sprintf(nil "%s result pass=%d fail=%d" layerName XFSKILL_TEST_PASS XFSKILL_TEST_FAIL))
  foreach(failure reverse(XFSKILL_TEST_FAILURES)
    XFSKILL_Alert(failure)
  )
  XFSKILL_TEST_FAIL == 0
)

defun(XFSKILL_RunUnitTests ()
  let((testFn testName)
    XFSKILL_ResetCounters()
    if(XFSKILL_TESTS == nil
      then XFSKILL_RecordFailure("no unit test registered")
      else
        foreach(testFn reverse(XFSKILL_TESTS)
          testName = sprintf(nil "%L" testFn)
          XFSKILL_Log(strcat("RUN " testName))
          unless(errset(apply(testFn nil) t)
            XFSKILL_RecordFailure(strcat(testName " raised an error"))
          )
        )
    )
    XFSKILL_ReportResult("UNIT")
  )
)

defun(XFSKILL_SmokeTest ()
  let((smokeOk)
    XFSKILL_ResetCounters()
    XFSKILL_Assert(strlen(XFSKILL_VERSION) > 0 "VERSION must be non-empty")
    XFSKILL_Assert(XFSKILL_CONFIG != nil "config must be loaded")
    XFSKILL_Assert(XFSKILL_MODULE_COUNT > 0 "at least one module must load")
    XFSKILL_Assert(XFSKILL_TESTS != nil "unit tests must be registered")
    XFSKILL_Assert(if(getd('XFSKILL_HelloWorld) then t else nil) "hello module must exist")
    XFSKILL_Assert(
        equal(XFSKILL_HelloWorld() strcat("Hello XFSKILL " XFSKILL_VERSION))
        "greeting must embed the active version"
    )
    XFSKILL_Assert(XFSKILL_MENU_BUILT "menu must be inserted")
    smokeOk = XFSKILL_ReportResult("SMOKE")
    if(smokeOk
      then smokeOk
      else reverse(XFSKILL_TEST_FAILURES)
    )
  )
)
