; examples/todo/main.pb — PureSimple to-do list API (JSON, in-memory)
;
; Routes:
;   GET    /todos          — list all to-dos
;   POST   /todos          — create a to-do  (JSON body: {"title":"..."})
;   GET    /todos/:id      — get one to-do
;   DELETE /todos/:id      — delete a to-do
;   GET    /health         — health check
;
; Compile:
;   $PUREBASIC_HOME/compilers/pbcompiler examples/todo/main.pb -cl -o todo
; Run:
;   ./todo

EnableExplicit

XIncludeFile "../../src/PureSimple.pb"

; ---- In-memory store -------------------------------------------------------

Structure TodoItem
  id.i
  title.s
  done.i
EndStructure

Global NewList _Todos.TodoItem()
Global _NextID.i = 1

; ---- Helpers ---------------------------------------------------------------

Procedure.s TodoJSON(*T.TodoItem)
  Protected done.s = "false"
  If *T\done : done = "true" : EndIf
  ProcedureReturn "{" +
    ~"\"id\":"    + Str(*T\id)      + "," +
    ~"\"title\":" + Chr(34) + *T\title + Chr(34) + "," +
    ~"\"done\":"  + done +
  "}"
EndProcedure

Procedure.s AllTodosJSON()
  Protected out.s = "["
  Protected first.i = #True
  ForEach _Todos()
    If Not first : out + "," : EndIf
    out + TodoJSON(_Todos())
    first = #False
  Next
  ProcedureReturn out + "]"
EndProcedure

; ---- Handlers --------------------------------------------------------------

Procedure ListTodos(*C.RequestContext)
  Rendering::JSON(*C, AllTodosJSON())
EndProcedure

Procedure CreateTodo(*C.RequestContext)
  Binding::BindJSON(*C)
  Protected title.s = Binding::JSONString(*C, "title")
  Binding::ReleaseJSON(*C)
  If title = ""
    Ctx::AbortWithError(*C, 400, ~"{\"error\":\"title is required\"}")
    ProcedureReturn
  EndIf
  AddElement(_Todos())
  _Todos()\id    = _NextID
  _Todos()\title = title
  _Todos()\done  = #False
  _NextID + 1
  Rendering::JSON(*C, TodoJSON(_Todos()), 201)
EndProcedure

Procedure GetTodo(*C.RequestContext)
  Protected id.i = Val(Binding::Param(*C, "id"))
  ForEach _Todos()
    If _Todos()\id = id
      Rendering::JSON(*C, TodoJSON(_Todos()))
      ProcedureReturn
    EndIf
  Next
  Ctx::AbortWithError(*C, 404, ~"{\"error\":\"not found\"}")
EndProcedure

Procedure DeleteTodo(*C.RequestContext)
  Protected id.i = Val(Binding::Param(*C, "id"))
  ForEach _Todos()
    If _Todos()\id = id
      DeleteElement(_Todos())
      Rendering::Status(*C, 204)
      ProcedureReturn
    EndIf
  Next
  Ctx::AbortWithError(*C, 404, ~"{\"error\":\"not found\"}")
EndProcedure

Procedure HealthCheck(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure

; ---- Bootstrap -------------------------------------------------------------

Config::Load(".env")
Protected port.i = Config::GetInt("PORT", 8080)
Engine::SetMode(Config::Get("MODE", "debug"))

Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

Engine::GET("/todos",        @ListTodos())
Engine::POST("/todos",       @CreateTodo())
Engine::GET("/todos/:id",    @GetTodo())
Engine::DELETE("/todos/:id", @DeleteTodo())
Engine::GET("/health",       @HealthCheck())

Log::Info("Todo API starting on :" + Str(port) + " [" + Engine::Mode() + "]")
Engine::Run(port)
