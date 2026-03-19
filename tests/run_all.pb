; run_all.pb — PureSimple test suite entry point
; Compile as console binary: pbcompiler tests/run_all.pb -cl -o run_all
; Run: ./run_all

EnableExplicit

; Pull in the framework so test files can reference Engine:: etc.
XIncludeFile "../src/PureSimple.pb"

; Test harness (macros + counters)
XIncludeFile "TestHarness.pbi"

; ------------------------------------------------------------------
; Phase test files — add each new phase's test file here
; ------------------------------------------------------------------
PrintN("PureSimple Test Suite")
PrintN("=====================")
PrintN("")

XIncludeFile "P0_Harness_Test.pbi"
XIncludeFile "P1_Router_Test.pbi"
XIncludeFile "P2_Middleware_Test.pbi"
XIncludeFile "P3_Binding_Test.pbi"
XIncludeFile "P4_Rendering_Test.pbi"
;   XIncludeFile "P5_Groups_Test.pbi"
;   XIncludeFile "P6_SQLite_Test.pbi"
;   XIncludeFile "P7_Auth_Test.pbi"
;   XIncludeFile "P8_Config_Test.pbi"

; ------------------------------------------------------------------
; Print summary and exit with non-zero code on failure
; ------------------------------------------------------------------
If PrintResults()
  End 0
Else
  End 1
EndIf
