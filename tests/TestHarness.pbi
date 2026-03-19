; TestHarness.pbi — Assertion library for PureSimple tests
; Include once at the top of run_all.pb before any test files.
;
; NOTE: PureBasic 6.x (C backend) pre-defines Assert() and AssertString()
; as built-in halt-on-fail macros (from pureunit.res). This harness uses
; non-conflicting names to support count-and-continue reporting.
;
; Public API:
;   BeginSuite(name)     — label a group of related checks
;   Check(expr)          — fails if expr is #False
;   CheckEqual(a, b)     — fails if a <> b (numeric)
;   CheckStr(a, b)       — fails if a <> b (string)
;   PrintResults()       — print summary; returns #True if all passed

EnableExplicit

; ------------------------------------------------------------------
; Global counters
; ------------------------------------------------------------------
Global _PS_PassCount.i = 0
Global _PS_FailCount.i = 0

; ------------------------------------------------------------------
; Internal helper procedures — do all the work so macros stay thin
; (PureBasic macros can't safely call Str() on arbitrary expressions
;  inside string concatenation contexts)
; ------------------------------------------------------------------
Procedure _PS_CheckTrue(result.i, file.s, line.i)
  If result
    _PS_PassCount + 1
  Else
    _PS_FailCount + 1
    PrintN("  FAIL  Check @ " + file + ":" + Str(line))
  EndIf
EndProcedure

Procedure _PS_CheckEqual(a.i, b.i, file.s, line.i)
  If a = b
    _PS_PassCount + 1
  Else
    _PS_FailCount + 1
    PrintN("  FAIL  CheckEqual @ " + file + ":" + Str(line) + " => " + Str(a) + " <> " + Str(b))
  EndIf
EndProcedure

Procedure _PS_CheckStr(a.s, b.s, file.s, line.i)
  If a = b
    _PS_PassCount + 1
  Else
    _PS_FailCount + 1
    PrintN("  FAIL  CheckStr @ " + file + ":" + Str(line) + ~" => \"" + a + ~"\" <> \"" + b + ~"\"")
  EndIf
EndProcedure

; ------------------------------------------------------------------
; BeginSuite(name) — label a group of related checks
; ------------------------------------------------------------------
Macro BeginSuite(name)
  PrintN("  [Suite] " + name)
EndMacro

; ------------------------------------------------------------------
; Check(expr) — thin macro: captures file/line, delegates to procedure
; Bool() wraps expr so comparisons (=, <, >=, etc.) are valid as args
; ------------------------------------------------------------------
Macro Check(expr)
  _PS_CheckTrue(Bool(expr), #PB_Compiler_File, #PB_Compiler_Line)
EndMacro

; ------------------------------------------------------------------
; CheckEqual(a, b) — numeric equality
; Bool() wraps comparison for the same reason
; ------------------------------------------------------------------
Macro CheckEqual(a, b)
  _PS_CheckEqual((a), (b), #PB_Compiler_File, #PB_Compiler_Line)
EndMacro

; ------------------------------------------------------------------
; CheckStr(a, b) — string equality
; ------------------------------------------------------------------
Macro CheckStr(a, b)
  _PS_CheckStr((a), (b), #PB_Compiler_File, #PB_Compiler_Line)
EndMacro

; ------------------------------------------------------------------
; PrintResults() — call once at end of run_all.pb
; Returns #True if all tests passed, #False otherwise.
; ------------------------------------------------------------------
Procedure.i PrintResults()
  Protected Total.i = _PS_PassCount + _PS_FailCount
  PrintN("")
  PrintN("======================================")
  If _PS_FailCount = 0
    PrintN("  ALL TESTS PASSED  (" + Str(Total) + " assertions)")
  Else
    PrintN("  FAILURES: " + Str(_PS_FailCount) + " / " + Str(Total))
  EndIf
  PrintN("======================================")
  ProcedureReturn Bool(_PS_FailCount = 0)
EndProcedure
