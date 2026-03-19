; DB/Connect.pbi — Driver-agnostic DSN-based database connection factory.
;
; Supported DSN formats:
;   sqlite::memory:                        SQLite in-memory database
;   sqlite:path/to/db.sqlite               SQLite file-based database
;   postgres://user:pass@host:5432/dbname  PostgreSQL
;   postgresql://user:pass@host:5432/db    PostgreSQL (alias)
;   mysql://user:pass@host:3306/dbname     MySQL / MariaDB
;
; Usage:
;   db = DBConnect::Open("sqlite::memory:")
;   db = DBConnect::OpenFromConfig()       ; reads DB_DSN from Config::Get
;   DB::Exec(db, "SELECT 1")
;   DB::Close(db)
;
; All handles returned by DBConnect::Open are fully compatible with the
; existing DB::* procedures (Exec, Query, NextRow, GetStr, Migrate, …).
;
; Driver activation at compile time (called once by this module):
;   UseSQLiteDatabase()         always included
;   UsePostgreSQLDatabase()     always included
;   UseMySQLDatabase()          always included
;
; PureBasic selects the correct plugin via the #PB_Database_* constant passed
; as the optional fifth argument to OpenDatabase().

EnableExplicit

UseSQLiteDatabase()
UsePostgreSQLDatabase()
UseMySQLDatabase()

DeclareModule DBConnect
  #Driver_Unknown  = -1
  #Driver_SQLite   =  0
  #Driver_Postgres =  1
  #Driver_MySQL    =  2

  ; Detect which driver is implied by the DSN prefix.
  Declare.i Driver(DSN.s)

  ; Open a database connection from a DSN string.
  ; Returns a PureBasic database handle on success, or 0 on failure.
  Declare.i Open(DSN.s)

  ; Read DB_DSN from the Config store and call Open().
  ; If DB_DSN is not set, defaults to "sqlite::memory:".
  Declare.i OpenFromConfig()

  ; Build a PureBasic-style key=value connection string from a URL-style DSN.
  ; Works for both postgres:// and mysql:// DSNs.
  ; Returns e.g. "host=localhost port=5432 dbname=mydb"
  ; (user and password are returned via the separate Open() parameters)
  Declare.s ConnStr(DSN.s)
EndDeclareModule

Module DBConnect
  UseModule Types

  ; ------------------------------------------------------------------
  ; Internal URL-parsing helpers
  ; ------------------------------------------------------------------

  ; Return the scheme portion of a DSN ("sqlite", "postgres", "mysql", …).
  Procedure.s _Scheme(DSN.s)
    Protected p.i = FindString(DSN, ":")
    If p > 0
      ProcedureReturn LCase(Left(DSN, p - 1))
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; Return everything after "scheme://" (or "scheme:" for sqlite).
  Procedure.s _AfterScheme(DSN.s)
    Protected p.i = FindString(DSN, "://")
    If p > 0
      ProcedureReturn Mid(DSN, p + 3)
    EndIf
    ; sqlite uses "sqlite:<path>" without "//"
    p = FindString(DSN, ":")
    If p > 0
      ProcedureReturn Mid(DSN, p + 1)
    EndIf
    ProcedureReturn DSN
  EndProcedure

  ; Return the userinfo portion ("user:pass") from "user:pass@host/db".
  Procedure.s _UserInfo(Rest.s)
    Protected atPos.i = FindString(Rest, "@")
    If atPos > 0
      ProcedureReturn Left(Rest, atPos - 1)
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; Return the hostpath portion ("host:port/dbname") from "user:pass@host:port/db".
  Procedure.s _HostPath(Rest.s)
    Protected atPos.i = FindString(Rest, "@")
    If atPos > 0
      ProcedureReturn Mid(Rest, atPos + 1)
    EndIf
    ProcedureReturn Rest
  EndProcedure

  ; Extract user from userinfo string "user:pass" or "user".
  Procedure.s _User(UserInfo.s)
    Protected p.i = FindString(UserInfo, ":")
    If p > 0
      ProcedureReturn Left(UserInfo, p - 1)
    EndIf
    ProcedureReturn UserInfo
  EndProcedure

  ; Extract password from userinfo string "user:pass" (returns "" if absent).
  Procedure.s _Pass(UserInfo.s)
    Protected p.i = FindString(UserInfo, ":")
    If p > 0
      ProcedureReturn Mid(UserInfo, p + 1)
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; Extract host from "host:port/dbname" or "host/dbname".
  Procedure.s _Host(HostPath.s)
    Protected slashPos.i = FindString(HostPath, "/")
    Protected hostPort.s
    If slashPos > 0
      hostPort = Left(HostPath, slashPos - 1)
    Else
      hostPort = HostPath
    EndIf
    Protected colonPos.i = FindString(hostPort, ":")
    If colonPos > 0
      ProcedureReturn Left(hostPort, colonPos - 1)
    EndIf
    ProcedureReturn hostPort
  EndProcedure

  ; Extract port string from "host:port/dbname" (returns "" if absent).
  Procedure.s _Port(HostPath.s)
    Protected slashPos.i = FindString(HostPath, "/")
    Protected hostPort.s
    If slashPos > 0
      hostPort = Left(HostPath, slashPos - 1)
    Else
      hostPort = HostPath
    EndIf
    Protected colonPos.i = FindString(hostPort, ":")
    If colonPos > 0
      ProcedureReturn Mid(hostPort, colonPos + 1)
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; Extract database name from "host:port/dbname" (returns "" if absent).
  Procedure.s _DBName(HostPath.s)
    Protected slashPos.i = FindString(HostPath, "/")
    If slashPos > 0
      ProcedureReturn Mid(HostPath, slashPos + 1)
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; ------------------------------------------------------------------
  ; Public procedures
  ; ------------------------------------------------------------------

  ; Detect which driver is implied by the DSN prefix.
  Procedure.i Driver(DSN.s)
    Protected scheme.s = _Scheme(DSN)
    Select scheme
      Case "sqlite"
        ProcedureReturn #Driver_SQLite
      Case "postgres", "postgresql"
        ProcedureReturn #Driver_Postgres
      Case "mysql"
        ProcedureReturn #Driver_MySQL
    EndSelect
    ProcedureReturn #Driver_Unknown
  EndProcedure

  ; Build the PureBasic key=value connection string for server-based drivers.
  ; Format: "host=H [port=P] [dbname=D]"
  ; User and password are NOT included here — they are passed as separate
  ; parameters to OpenDatabase().
  Procedure.s ConnStr(DSN.s)
    Protected rest.s     = _AfterScheme(DSN)
    Protected userInfo.s = _UserInfo(rest)
    Protected hostPath.s = _HostPath(rest)
    Protected host.s     = _Host(hostPath)
    Protected port.s     = _Port(hostPath)
    Protected dbname.s   = _DBName(hostPath)
    Protected result.s   = "host=" + host
    If port   <> "" : result + " port="   + port   : EndIf
    If dbname <> "" : result + " dbname=" + dbname : EndIf
    ProcedureReturn result
  EndProcedure

  ; Open a database connection from a DSN string.
  ; Returns a PureBasic database handle on success, or 0 on failure.
  Procedure.i Open(DSN.s)
    Protected drv.i    = Driver(DSN)
    Protected rest.s   = _AfterScheme(DSN)
    Protected userInfo.s, user.s, pass.s, cs.s

    Select drv
      Case #Driver_SQLite
        ; sqlite::memory:  →  path = ":memory:"
        ; sqlite:data/app.db  →  path = "data/app.db"
        ProcedureReturn OpenDatabase(#PB_Any, rest, "", "", #PB_Database_SQLite)

      Case #Driver_Postgres
        userInfo = _UserInfo(rest)
        user     = _User(userInfo)
        pass     = _Pass(userInfo)
        cs       = ConnStr(DSN)
        ProcedureReturn OpenDatabase(#PB_Any, cs, user, pass, #PB_Database_PostgreSQL)

      Case #Driver_MySQL
        userInfo = _UserInfo(rest)
        user     = _User(userInfo)
        pass     = _Pass(userInfo)
        cs       = ConnStr(DSN)
        ProcedureReturn OpenDatabase(#PB_Any, cs, user, pass, #PB_Database_MySQL)

    EndSelect
    ProcedureReturn 0
  EndProcedure

  ; Read DB_DSN from the Config store and call Open().
  ; If DB_DSN is not set, defaults to "sqlite::memory:".
  Procedure.i OpenFromConfig()
    Protected dsn.s = Config::Get("DB_DSN", "sqlite::memory:")
    ProcedureReturn Open(dsn)
  EndProcedure

EndModule
