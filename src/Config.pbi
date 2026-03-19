; Config.pbi — .env file loader + in-memory key/value configuration store
;
; Load from a .env file:
;   Config::Load(".env")
;   port = Config::GetInt("PORT", 8080)
;   mode = Config::Get("MODE", "debug")
;
; .env format:
;   # comment lines are ignored
;   KEY=value
;   DB_PORT=5432
;   EMPTY=
;
; Keys are case-sensitive. Values are stored as strings; Config::GetInt
; converts with Val(). Config::Set / Config::Has / Config::Reset are also
; available for test fixtures and runtime overrides.

EnableExplicit

DeclareModule Config
  Declare.i Load(Path.s)
  Declare.s Get(Key.s, Fallback.s = "")
  Declare.i GetInt(Key.s, Fallback.i = 0)
  Declare   Set(Key.s, Val.s)
  Declare.i Has(Key.s)
  Declare   Reset()
EndDeclareModule

Module Config
  UseModule Types

  Global NewMap _C.s()   ; key → value

  ; ------------------------------------------------------------------
  ; Load — parse a .env file into the config store.
  ; Lines starting with # are comments; blank lines are skipped.
  ; Existing keys are overwritten if they appear again.
  ; Returns #True on success, #False if the file cannot be opened.
  ; ------------------------------------------------------------------
  Procedure.i Load(Path.s)
    Protected fh.i, line.s, eq.i, key.s, val.s
    If FileSize(Path) < 0
      ProcedureReturn #False
    EndIf
    fh = ReadFile(#PB_Any, Path)
    If fh = 0
      ProcedureReturn #False
    EndIf
    While Not Eof(fh)
      line = Trim(ReadString(fh))
      If Len(line) = 0 Or Left(line, 1) = "#"
        Continue
      EndIf
      eq = FindString(line, "=")
      If eq > 0
        key = Trim(Left(line, eq - 1))
        val = Trim(Mid(line, eq + 1))
        If key <> ""
          _C(key) = val
        EndIf
      EndIf
    Wend
    CloseFile(fh)
    ProcedureReturn #True
  EndProcedure

  ; ------------------------------------------------------------------
  ; Get — return the string value for Key, or Fallback if not set.
  ; ------------------------------------------------------------------
  Procedure.s Get(Key.s, Fallback.s = "")
    If FindMapElement(_C(), Key)
      ProcedureReturn _C()
    EndIf
    ProcedureReturn Fallback
  EndProcedure

  ; ------------------------------------------------------------------
  ; GetInt — return the integer value for Key, or Fallback if not set.
  ; ------------------------------------------------------------------
  Procedure.i GetInt(Key.s, Fallback.i = 0)
    If FindMapElement(_C(), Key)
      ProcedureReturn Val(_C())
    EndIf
    ProcedureReturn Fallback
  EndProcedure

  ; ------------------------------------------------------------------
  ; Set — set (or overwrite) a config value at runtime.
  ; ------------------------------------------------------------------
  Procedure Set(Key.s, Val.s)
    _C(Key) = Val
  EndProcedure

  ; ------------------------------------------------------------------
  ; Has — returns #True if Key is present in the config store.
  ; ------------------------------------------------------------------
  Procedure.i Has(Key.s)
    ProcedureReturn Bool(FindMapElement(_C(), Key) <> 0)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Reset — clear all config values (used between tests).
  ; ------------------------------------------------------------------
  Procedure Reset()
    ClearMap(_C())
  EndProcedure

EndModule
