; Router.pbi — Segment-level trie router
; Provides Insert(method, pattern, handler) and Match(method, path, *ctx).
; Match priority: exact segment > :param > *wildcard (backtracking on failure).
;
; Trie nodes are stored in four parallel arrays of basic types (PureBasic
; modules cannot reference external Structure types in Global Dim or procedure
; parameters; basic types always work).

EnableExplicit

DeclareModule Router
  ; Register a route handler.
  ; Pattern segments: "literal", ":paramname", "*wildcardname"
  Declare Insert(Method.s, Pattern.s, Handler.i)

  ; Match a request path against registered routes.
  ; On match: populates *Ctx\ParamKeys and *Ctx\ParamVals (Chr(9)-delimited).
  ; Returns handler address, or 0 if no route matches.
  Declare.i Match(Method.s, Path.s, *Ctx.RequestContext)
EndDeclareModule

Module Router
  UseModule Types   ; import RequestContext, PS_HandlerFunc, etc. into module scope

  ; ------------------------------------------------------------------
  ; Trie storage — parallel arrays (index 0 = null sentinel)
  ; ------------------------------------------------------------------
  #_MAX = 512

  Global Dim _Seg.s(#_MAX)       ; node segment string
  Global Dim _Handler.i(#_MAX)   ; terminal handler address (0 = not terminal)
  Global Dim _Child.i(#_MAX)     ; first child index  (0 = none)
  Global Dim _Sibling.i(#_MAX)   ; next sibling index (0 = none)
  Global _Cnt.i = 1              ; next free slot; 0 = null sentinel
  Global NewMap _Root.i()        ; method → root node index

  ; ------------------------------------------------------------------
  ; Internal helpers
  ; ------------------------------------------------------------------

  Procedure.i _Alloc(Seg.s)
    Protected idx.i = _Cnt
    If idx > #_MAX : ProcedureReturn 0 : EndIf
    _Seg(idx)     = Seg
    _Handler(idx) = 0
    _Child(idx)   = 0
    _Sibling(idx) = 0
    _Cnt + 1
    ProcedureReturn idx
  EndProcedure

  Procedure _Link(Parent.i, Child.i)
    Protected n.i
    If _Child(Parent) = 0
      _Child(Parent) = Child
    Else
      n = _Child(Parent)
      While _Sibling(n) <> 0
        n = _Sibling(n)
      Wend
      _Sibling(n) = Child
    EndIf
  EndProcedure

  ; Split "/a/b/c" → Out = ["a","b","c"]; returns segment count.
  ; Returns 0 for root path "/" or "".
  Procedure.i _Split(Path.s, Array Out.s(1))
    Protected p.s, n.i, i.i
    p = Path
    If Left(p, 1) = "/" : p = Mid(p, 2) : EndIf
    If Len(p) > 0 And Right(p, 1) = "/" : p = Left(p, Len(p) - 1) : EndIf
    If p = ""
      ReDim Out(0)
      ProcedureReturn 0
    EndIf
    n = CountString(p, "/") + 1
    ReDim Out(n - 1)
    For i = 1 To n
      Out(i - 1) = StringField(p, i, "/")
    Next
    ProcedureReturn n
  EndProcedure

  ; ------------------------------------------------------------------
  ; Recursive match helper.
  ; Context is passed as .i (plain address) to avoid struct-type issues
  ; in Module body; cast to RequestContext pointer inside.
  ; Priority: exact > :param > *wildcard.
  ; ------------------------------------------------------------------
  Procedure.i _Match(NodeIdx.i, Array Segs.s(1), Depth.i, Total.i, CtxPtr.i)
    Protected *C.RequestContext
    Protected seg.s, child.i, cseg.s
    Protected paramChild.i, wildChild.i, result.i
    Protected pname.s, wname.s, wval.s, j.i
    Protected pKeyLen.i, pValLen.i

    *C = CtxPtr

    If Depth = Total
      ProcedureReturn _Handler(NodeIdx)
    EndIf

    seg        = Segs(Depth)
    child      = _Child(NodeIdx)
    paramChild = 0
    wildChild  = 0

    ; First pass: exact segment matches (highest priority)
    While child <> 0
      cseg = _Seg(child)
      If Left(cseg, 1) = ":"
        If paramChild = 0 : paramChild = child : EndIf
      ElseIf Left(cseg, 1) = "*"
        If wildChild = 0 : wildChild = child : EndIf
      ElseIf cseg = seg
        result = _Match(child, Segs(), Depth + 1, Total, CtxPtr)
        If result <> 0 : ProcedureReturn result : EndIf
      EndIf
      child = _Sibling(child)
    Wend

    ; Second pass: :param match with backtrack on failure
    If paramChild
      pname   = Mid(_Seg(paramChild), 2)    ; strip leading ":"
      pKeyLen = Len(*C\ParamKeys)
      pValLen = Len(*C\ParamVals)
      *C\ParamKeys + pname + Chr(9)
      *C\ParamVals + seg   + Chr(9)
      result = _Match(paramChild, Segs(), Depth + 1, Total, CtxPtr)
      If result <> 0 : ProcedureReturn result : EndIf
      *C\ParamKeys = Left(*C\ParamKeys, pKeyLen)
      *C\ParamVals = Left(*C\ParamVals, pValLen)
    EndIf

    ; Third pass: *wildcard consumes all remaining segments
    If wildChild
      wname = Mid(_Seg(wildChild), 2)       ; strip leading "*"
      wval  = ""
      For j = Depth To Total - 1
        If j > Depth : wval + "/" : EndIf
        wval + Segs(j)
      Next
      *C\ParamKeys + wname + Chr(9)
      *C\ParamVals + wval  + Chr(9)
      ProcedureReturn _Handler(wildChild)
    EndIf

    ProcedureReturn 0
  EndProcedure

  ; ------------------------------------------------------------------
  ; Public API
  ; ------------------------------------------------------------------

  Procedure Insert(Method.s, Pattern.s, Handler.i)
    Dim Segs.s(0)
    Protected cnt.i, root.i, node.i, i.i
    Protected seg.s, child.i, found.i, newNode.i

    If Not FindMapElement(_Root(), Method)
      root = _Alloc("")
      _Root(Method) = root
    EndIf
    root = _Root(Method)

    cnt = _Split(Pattern, Segs())
    If cnt = 0      ; root route "/"
      _Handler(root) = Handler
      ProcedureReturn
    EndIf

    node = root
    For i = 0 To cnt - 1
      seg   = Segs(i)
      child = _Child(node)
      found = 0
      While child <> 0
        If _Seg(child) = seg
          found = child
          Break
        EndIf
        child = _Sibling(child)
      Wend
      If found
        node = found
      Else
        newNode = _Alloc(seg)
        _Link(node, newNode)
        node = newNode
      EndIf
    Next
    _Handler(node) = Handler
  EndProcedure

  Procedure.i Match(Method.s, Path.s, *Ctx.RequestContext)
    Dim Segs.s(0)
    Protected root.i, cnt.i

    *Ctx\ParamKeys = ""
    *Ctx\ParamVals = ""

    If Not FindMapElement(_Root(), Method)
      ProcedureReturn 0
    EndIf
    root = _Root(Method)
    cnt  = _Split(Path, Segs())

    If cnt = 0
      ProcedureReturn _Handler(root)
    EndIf
    ProcedureReturn _Match(root, Segs(), 0, cnt, *Ctx)
  EndProcedure

EndModule
