; P10_MultiDB_Test.pbi — Tests for DBConnect multi-driver abstraction (P10)
;
; Tests use SQLite (:memory:) exclusively — PostgreSQL and MySQL
; are not available in the test environment. DSN parsing and driver
; detection are tested for all three drivers.

Procedure P10_MultiDB_Tests()

  ; ---------------------------------------------------------------
  ; DBConnect::Driver — detect driver from DSN prefix
  ; ---------------------------------------------------------------
  CheckEqual(DBConnect::Driver("sqlite::memory:"),                  DBConnect::#Driver_SQLite)
  CheckEqual(DBConnect::Driver("sqlite:data/app.db"),               DBConnect::#Driver_SQLite)
  CheckEqual(DBConnect::Driver("postgres://u:p@host:5432/db"),      DBConnect::#Driver_Postgres)
  CheckEqual(DBConnect::Driver("postgresql://u:p@host:5432/db"),    DBConnect::#Driver_Postgres)
  CheckEqual(DBConnect::Driver("mysql://u:p@host:3306/db"),         DBConnect::#Driver_MySQL)
  CheckEqual(DBConnect::Driver("unknown://foo"),                     DBConnect::#Driver_Unknown)
  CheckEqual(DBConnect::Driver(""),                                  DBConnect::#Driver_Unknown)

  ; ---------------------------------------------------------------
  ; DBConnect::ConnStr — parse URL DSN into key=value conn string
  ; ---------------------------------------------------------------
  ; Full postgres DSN with port and dbname
  CheckStr(DBConnect::ConnStr("postgres://alice:s3cr3t@db.example.com:5432/myapp"),
           "host=db.example.com port=5432 dbname=myapp")

  ; Without port
  CheckStr(DBConnect::ConnStr("postgres://alice:s3cr3t@localhost/testdb"),
           "host=localhost dbname=testdb")

  ; Without dbname
  CheckStr(DBConnect::ConnStr("postgres://alice@db.host.io:5432"),
           "host=db.host.io port=5432")

  ; MySQL DSN — same ConnStr format
  CheckStr(DBConnect::ConnStr("mysql://root:hunter2@127.0.0.1:3306/shop"),
           "host=127.0.0.1 port=3306 dbname=shop")

  ; ---------------------------------------------------------------
  ; DBConnect::Open with SQLite driver
  ; ---------------------------------------------------------------
  Protected db.i = DBConnect::Open("sqlite::memory:")
  Check(db > 0)

  ; Verify the returned handle is a valid, working SQLite database
  Check(DB::Exec(db, "CREATE TABLE p10test (id INTEGER PRIMARY KEY, name TEXT)"))
  Check(DB::Exec(db, "INSERT INTO p10test VALUES (1, 'Alice')"))
  Check(DB::Exec(db, "INSERT INTO p10test VALUES (2, 'Bob')"))

  Check(DB::Query(db, "SELECT id, name FROM p10test ORDER BY id"))
  Check(DB::NextRow(db))
  CheckEqual(DB::GetInt(db, 0), 1)
  CheckStr(DB::GetStr(db, 1), "Alice")
  Check(DB::NextRow(db))
  CheckEqual(DB::GetInt(db, 0), 2)
  CheckStr(DB::GetStr(db, 1), "Bob")
  Check(Not DB::NextRow(db))
  DB::Done(db)
  DB::Close(db)

  ; ---------------------------------------------------------------
  ; DBConnect::Open with SQLite file path via DSN
  ; ---------------------------------------------------------------
  Protected filedb.i = DBConnect::Open("sqlite::memory:")
  Check(filedb > 0)
  Check(DB::Exec(filedb, "CREATE TABLE ft (v TEXT)"))
  Check(DB::Exec(filedb, "INSERT INTO ft VALUES ('hello')"))
  DB::Query(filedb, "SELECT v FROM ft")
  DB::NextRow(filedb)
  CheckStr(DB::GetStr(filedb, 0), "hello")
  DB::Done(filedb)
  DB::Close(filedb)

  ; ---------------------------------------------------------------
  ; DBConnect::Open — migration runner works via Connect handle
  ; ---------------------------------------------------------------
  DB::ResetMigrations()
  DB::AddMigration(1, "CREATE TABLE items (id INTEGER PRIMARY KEY, label TEXT)")
  DB::AddMigration(2, "ALTER TABLE items ADD COLUMN qty INTEGER DEFAULT 0")

  Protected mdb.i = DBConnect::Open("sqlite::memory:")
  Check(mdb > 0)
  Check(DB::Migrate(mdb))

  Check(DB::Exec(mdb, "INSERT INTO items (label, qty) VALUES ('widget', 5)"))
  DB::Query(mdb, "SELECT label, qty FROM items")
  DB::NextRow(mdb)
  CheckStr(DB::GetStr(mdb, 0), "widget")
  CheckEqual(DB::GetInt(mdb, 1), 5)
  DB::Done(mdb)
  DB::Close(mdb)
  DB::ResetMigrations()

  ; ---------------------------------------------------------------
  ; DBConnect::OpenFromConfig — reads DB_DSN from Config store
  ; ---------------------------------------------------------------
  Config::Reset()
  Config::Set("DB_DSN", "sqlite::memory:")
  Protected cfgdb.i = DBConnect::OpenFromConfig()
  Check(cfgdb > 0)
  Check(DB::Exec(cfgdb, "CREATE TABLE cfg (k TEXT)"))
  DB::Close(cfgdb)
  Config::Reset()

  ; ---------------------------------------------------------------
  ; DBConnect::OpenFromConfig — default when DB_DSN not set
  ; ---------------------------------------------------------------
  Config::Reset()
  Protected defdb.i = DBConnect::OpenFromConfig()
  Check(defdb > 0)   ; defaults to "sqlite::memory:"
  DB::Close(defdb)
  Config::Reset()

EndProcedure

P10_MultiDB_Tests()
