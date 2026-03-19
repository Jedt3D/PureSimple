; Engine.pbi — Application lifecycle stubs (NewApp / Run)
; Full implementation arrives in P1 (Router) and beyond.

EnableExplicit

DeclareModule Engine
  Declare.i NewApp()
  Declare.i Run(Port.i)
EndDeclareModule

Module Engine
  ; NewApp() — allocate and return a RouterEngine handle.
  ; Returns #PB_Any handle (stub returns 0 until P1 wires the allocator).
  Procedure.i NewApp()
    ProcedureReturn 0   ; stub — P1 will allocate RouterEngine here
  EndProcedure

  ; Run(Port) — start the HTTP listener on the given port.
  ; Returns #False until PureSimpleHTTPServer integration lands in P1.
  Procedure.i Run(Port.i)
    ProcedureReturn #False  ; stub — P1 wires PureSimpleHTTPServer
  EndProcedure
EndModule
