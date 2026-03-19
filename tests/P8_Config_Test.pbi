; P8_Config_Test.pbi — Tests for Config, Log, and Engine mode (P8)
;
; Tests:
;   Config::Load — parses .env file, skips comments and blanks
;   Config::Get  — returns value or default
;   Config::GetInt — numeric conversion
;   Config::Set  — runtime override
;   Config::Has  — key presence
;   Config::Reset — clears all
;   Engine::SetMode / Engine::Mode — run mode getter/setter
;   Log — compile + call check (output suppressed in test)

Procedure P8_Config_Tests()
  Protected result.i, val.s, ival.i

  ; ---------------------------------------------------------------
  ; Config::Load
  ; ---------------------------------------------------------------
  Config::Reset()
  result = Config::Load("tests/test.env")
  Check(result)   ; file loaded successfully

  ; Verify known keys from test.env
  CheckStr(Config::Get("PORT"),     "9090")
  CheckStr(Config::Get("MODE"),     "release")
  CheckStr(Config::Get("APP_NAME"), "PureSimple")
  CheckStr(Config::Get("DB_PATH"),  "data/test.db")

  ; EMPTY_VAL= should be stored as empty string
  Check(Config::Has("EMPTY_VAL"))
  CheckStr(Config::Get("EMPTY_VAL"), "")

  ; Comment lines must NOT be loaded as keys
  Check(Not Config::Has("# This line is a comment and should be ignored"))

  ; ---------------------------------------------------------------
  ; Config::Get default
  ; ---------------------------------------------------------------
  CheckStr(Config::Get("NONEXISTENT_KEY", "fallback"), "fallback")
  CheckStr(Config::Get("NONEXISTENT_KEY"), "")   ; empty default

  ; ---------------------------------------------------------------
  ; Config::GetInt
  ; ---------------------------------------------------------------
  CheckEqual(Config::GetInt("PORT"),        9090)
  CheckEqual(Config::GetInt("MAX_CONN"),    25)
  CheckEqual(Config::GetInt("MISSING_INT", 42), 42)

  ; ---------------------------------------------------------------
  ; Config::Set — runtime override
  ; ---------------------------------------------------------------
  Config::Set("RUNTIME_KEY", "hello")
  CheckStr(Config::Get("RUNTIME_KEY"), "hello")
  Config::Set("PORT", "1234")
  CheckEqual(Config::GetInt("PORT"), 1234)

  ; ---------------------------------------------------------------
  ; Config::Has
  ; ---------------------------------------------------------------
  Check(Config::Has("MODE"))
  Check(Not Config::Has("DEFINITELY_MISSING"))

  ; ---------------------------------------------------------------
  ; Config::Reset
  ; ---------------------------------------------------------------
  Config::Reset()
  Check(Not Config::Has("PORT"))
  Check(Not Config::Has("MODE"))

  ; ---------------------------------------------------------------
  ; Config::Load returns #False for missing file
  ; ---------------------------------------------------------------
  result = Config::Load("tests/nonexistent.env")
  Check(Not result)

  ; ---------------------------------------------------------------
  ; Engine::SetMode / Engine::Mode
  ; ---------------------------------------------------------------
  CheckStr(Engine::Mode(), "debug")   ; default is "debug"
  Engine::SetMode("release")
  CheckStr(Engine::Mode(), "release")
  Engine::SetMode("test")
  CheckStr(Engine::Mode(), "test")
  Engine::SetMode("debug")            ; restore default for other tests

  ; ---------------------------------------------------------------
  ; Log — compile check: call each level, output suppressed
  ; Log defaults to stdout (#LevelInfo); set to file /dev/null equivalent
  ; We redirect to a temp file path that won't interfere with test output.
  ; ---------------------------------------------------------------
  Log::SetOutput("tests/p8_log_test_tmp.txt")
  Log::SetLevel(Log::#LevelDebug)
  Log::Dbg("debug message")
  Log::Info("info message")
  Log::Warn("warn message")
  Log::Error("error message")
  ; Reset log back to stdout for any subsequent output
  Log::SetOutput("")
  Log::SetLevel(Log::#LevelInfo)

  ; Verify the log file was created and has content
  Check(FileSize("tests/p8_log_test_tmp.txt") > 0)

  ; Clean up temp log file
  DeleteFile("tests/p8_log_test_tmp.txt")

EndProcedure

P8_Config_Tests()
