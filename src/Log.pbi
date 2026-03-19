; Log.pbi — Leveled logger with optional file output.
;
; Log levels (lowest to highest):
;   Log::#LevelDebug = 0
;   Log::#LevelInfo  = 1
;   Log::#LevelWarn  = 2
;   Log::#LevelError = 3
;
; Default level: LevelInfo (Debug messages suppressed in production).
; Default output: stdout (PrintN).
;
; Usage:
;   Log::SetLevel(Log::#LevelWarn)
;   Log::SetOutput("logs/app.log")   ; "" = stdout
;   Log::Dbg("Verbose debug info")
;   Log::Info("Server starting on :8080")
;   Log::Error("Database connection failed")
;
; Log line format:
;   [2026-03-20 14:32:01] [INFO] message

EnableExplicit

DeclareModule Log
  #LevelDebug = 0
  #LevelInfo  = 1
  #LevelWarn  = 2
  #LevelError = 3

  Declare   SetLevel(Level.i)
  Declare   SetOutput(Filename.s)
  Declare   Dbg(Msg.s)
  Declare   Info(Msg.s)
  Declare   Warn(Msg.s)
  Declare   Error(Msg.s)
EndDeclareModule

Module Log
  UseModule Types

  Global _Level.i  = #LevelInfo
  Global _Output.s = ""       ; "" = stdout

  ; ------------------------------------------------------------------
  ; Internal write helper — format and emit one log line.
  ; Appends to _Output file (creates if needed); or PrintN to stdout.
  ; ------------------------------------------------------------------
  Procedure _Write(LevelStr.s, Msg.s)
    Protected ts.s   = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
    Protected line.s = "[" + ts + "] [" + LevelStr + "] " + Msg
    Protected fh.i

    If _Output = ""
      PrintN(line)
    Else
      If FileSize(_Output) >= 0
        fh = OpenFile(#PB_Any, _Output)
        If fh : FileSeek(fh, Lof(fh)) : EndIf
      Else
        fh = CreateFile(#PB_Any, _Output)
      EndIf
      If fh
        WriteStringN(fh, line)
        CloseFile(fh)
      EndIf
    EndIf
  EndProcedure

  ; ------------------------------------------------------------------
  ; SetLevel — suppress messages below Level.
  ; ------------------------------------------------------------------
  Procedure SetLevel(Level.i)
    _Level = Level
  EndProcedure

  ; ------------------------------------------------------------------
  ; SetOutput — "" = stdout; any other string = file path.
  ; ------------------------------------------------------------------
  Procedure SetOutput(Filename.s)
    _Output = Filename
  EndProcedure

  ; ------------------------------------------------------------------
  ; Log procedures — each checks the current level before writing.
  ; ------------------------------------------------------------------

  Procedure Dbg(Msg.s)
    If _Level <= #LevelDebug : _Write("DEBUG", Msg) : EndIf
  EndProcedure

  Procedure Info(Msg.s)
    If _Level <= #LevelInfo : _Write("INFO", Msg) : EndIf
  EndProcedure

  Procedure Warn(Msg.s)
    If _Level <= #LevelWarn : _Write("WARN", Msg) : EndIf
  EndProcedure

  Procedure Error(Msg.s)
    If _Level <= #LevelError : _Write("ERROR", Msg) : EndIf
  EndProcedure

EndModule
