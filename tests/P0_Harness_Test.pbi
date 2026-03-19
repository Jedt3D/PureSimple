; P0_Harness_Test.pbi — Self-tests for the TestHarness macros
; Also verifies that the framework stub (Types.pbi) compiles cleanly.

; Verify the Types stub is includable without errors
XIncludeFile "../src/Types.pbi"

BeginSuite("P0 / Harness self-tests")

; Boolean checks
Check(#True)
Check(Not #False)
Check(1 = 1)

; Numeric equality
CheckEqual(1 + 1, 2)
CheckEqual(10 - 3, 7)
CheckEqual(3 * 4, 12)

; String equality
CheckStr("a" + "b", "ab")
CheckStr(LCase("HELLO"), "hello")
CheckStr(UCase("world"), "WORLD")
CheckStr(Str(42), "42")

; Framework stub: Engine module is accessible and Run() returns #False
CheckEqual(Engine::Run(8080), #False)
CheckEqual(Engine::NewApp(), 0)
