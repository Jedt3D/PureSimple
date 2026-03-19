# บทที่ 23: รองรับหลายฐานข้อมูล

![Chapter 23 opening illustration](../../illustrations/ch23-cover.svg)

*Interface เดียว สามไดรเวอร์ โค้ดไม่เปลี่ยนแม้แต่บรรทัดเดียว*

---

**หลังจากอ่านบทนี้จบ คุณจะสามารถ:**

- อธิบายว่า DSN-based connection factory ทำให้ทำงานกับฐานข้อมูลหลายตัวได้อย่างไร
- ใช้ `DBConnect::Open` เพื่อเชื่อมต่อ SQLite, PostgreSQL และ MySQL จาก code path เดียว
- แยกวิเคราะห์ DSN string แบบ URL เป็น key-value connection format ของ PureBasic
- สลับฐานข้อมูลผ่านไฟล์ `.env` โดยไม่ต้องเปลี่ยนโค้ดแอปพลิเคชัน

---

## 23.1 ทำไมต้องมี Abstraction?

ตลอดยี่สิบสองบทที่ผ่านมา ทุกตัวอย่างฐานข้อมูลในหนังสือเล่มนี้ใช้ SQLite SQLite ยอดเยี่ยมมาก: compile รวมเข้ากับ binary ไม่ต้องใช้ server process เก็บทุกอย่างในไฟล์เดียว และมีประสิทธิภาพเพียงพอสำหรับแอปพลิเคชันส่วนใหญ่ blog Wild & Still (บทที่ 22) รันบน SQLite ใน production รับ traffic ได้โดยไม่มีปัญหา

แต่มีกรณีที่ SQLite ไม่ใช่ตัวเลือกที่เหมาะสม คุณต้องการ concurrent write จากหลาย process คุณต้องการ full-text search ที่รู้จักภาษา คุณต้องการฐานข้อมูลที่อยู่บน server แยกจากแอปพลิเคชัน หรือคุณต้องการ integrate กับ PostgreSQL หรือ MySQL ที่มีอยู่แล้ว ความต้องการเหล่านี้ล้วนสมเหตุสมผล และไม่ควรจำเป็นต้องเขียน `DB::Exec` และ `DB::Query` ทุกครั้งที่เรียกใหม่หมด

module `DBConnect` แก้ปัญหานี้ มันนั่งอยู่ระหว่าง application code กับ database API ของ PureBasic โดยมี procedure `Open` ตัวเดียวที่รับ DSN (Data Source Name) string และคืนค่า database handle handle นั้นทำงานกับทุก `DB::*` procedure ที่คุณรู้จักอยู่แล้ว ไม่มี query API ใหม่ ไม่มี result-set API ใหม่ แค่วิธีต่างกันในการเปิด connection

เรื่องตลกเกี่ยวกับ database abstraction layer คือพวกมันสัญญาว่า "สลับฐานข้อมูลด้วยการเปลี่ยน config ครั้งเดียว" และไม่เคยทำได้จริงเพราะ query ของคุณใช้ feature เฉพาะของฐานข้อมูลนั้น เรื่องตลกนั้นสมเหตุสมผล ถ้า query ของคุณใช้ syntax `INSERT OR IGNORE` ของ SQLite การสลับไปยัง PostgreSQL หมายถึงต้องเขียนใหม่เป็น `INSERT ... ON CONFLICT DO NOTHING` module `DBConnect` ไม่ได้ซ่อนเรื่องนี้ มัน abstract การ *เชื่อมต่อ* ไม่ใช่ *dialect* นี่คือ abstraction ที่ซื่อสัตย์: มันแก้ปัญหาที่บอกว่าจะแก้และไม่แกล้งทำเป็นว่าแก้ปัญหาที่ทำไม่ได้

> **เปรียบเทียบ:** ใน Go package `database/sql` ให้ pattern เดียวกัน: ฟังก์ชัน `sql.Open(driver, dsn)` ที่คืนค่า handle `*sql.DB` ไดรเวอร์ลงทะเบียนแยกต่างหาก (เช่น `_ "github.com/lib/pq"` สำหรับ PostgreSQL) `OpenDatabase()` ของ PureBasic รับค่า constant plugin (`#PB_Database_SQLite`, `#PB_Database_PostgreSQL`, `#PB_Database_MySQL`) แทน `DBConnect::Open` map จาก DSN prefix ไปยัง constant ที่ถูกต้อง

---

## 23.2 รูปแบบ DSN

DSN string เข้ารหัสทุกอย่างที่ไดรเวอร์ฐานข้อมูลต้องการสำหรับการเชื่อมต่อ: ประเภทไดรเวอร์, host, port, credentials และชื่อฐานข้อมูล module `DBConnect` รองรับรูปแบบ DSN สามแบบ:

```
sqlite::memory:                         SQLite ในหน่วยความจำ
sqlite:path/to/db.sqlite                SQLite แบบไฟล์
postgres://user:pass@host:5432/dbname   PostgreSQL
postgresql://user:pass@host:5432/db     PostgreSQL (alias)
mysql://user:pass@host:3306/dbname      MySQL / MariaDB
```

รูปแบบนี้ตาม URL conventions scheme (ทุกอย่างก่อน colon แรก) ระบุไดรเวอร์ สำหรับ SQLite ส่วนที่เหลือคือ file path หรือ `:memory:` สำหรับ PostgreSQL และ MySQL ส่วนที่เหลือคือ URL มาตรฐานพร้อม userinfo, host, port และ path

นี่ไม่ใช่สิ่งที่ PureSimple คิดขึ้นเอง `libpq` ของ PostgreSQL ใช้ connection URI ในรูปแบบเดียวกัน `mysqlclient` ของ MySQL รับ string คล้ายกัน SQLite ไม่ได้ใช้ DSN string ตามธรรมชาติ แต่ prefix `sqlite:` เป็น convention ทั่วไปในเครื่องมือ multi-database การใช้รูปแบบสากลหมายความว่าคุณสามารถก็อปปี้ DSN จากเอกสาร PostgreSQL แล้ว paste ลงในไฟล์ `.env` ของคุณได้เลย

---

## 23.3 การตรวจจับไดรเวอร์

ขั้นตอนแรกในการเปิด connection คือการหาว่าต้องใช้ไดรเวอร์ใด procedure `DBConnect::Driver` ดึง scheme จาก DSN และ map ไปยัง constant:

```purebasic
; ตัวอย่างที่ 23.1 -- จาก src/DB/Connect.pbi: การตรวจจับไดรเวอร์
DeclareModule DBConnect
  #Driver_Unknown  = -1
  #Driver_SQLite   =  0
  #Driver_Postgres =  1
  #Driver_MySQL    =  2

  Declare.i Driver(DSN.s)
  Declare.i Open(DSN.s)
  Declare.i OpenFromConfig()
  Declare.s ConnStr(DSN.s)
EndDeclareModule

Module DBConnect
  UseModule Types

  Procedure.s _Scheme(DSN.s)
    Protected p.i = FindString(DSN, ":")
    If p > 0
      ProcedureReturn LCase(Left(DSN, p - 1))
    EndIf
    ProcedureReturn ""
  EndProcedure

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
```

helper `_Scheme` หา colon แรกและคืนค่าทุกอย่างก่อนหน้ามันเป็น lowercase procedure `Driver` เปรียบเทียบ scheme กับค่าที่รู้จัก ทั้ง `postgres` และ `postgresql` map ไปยังไดรเวอร์เดียวกัน — ผู้ใช้ PostgreSQL แบ่งออกเป็นสองค่ายในคำถามการตั้งชื่อนี้ และการรองรับทั้งสองช่วยหลีกเลี่ยง support ticket

statement `Select` คือ switch-case ของ PureBasic แต่ละ `Case` branch เป็นการเปรียบเทียบ string ถ้าไม่มี case ตรงกัน procedure คืนค่า `#Driver_Unknown` และ procedure `Open` จะคืนค่า 0 (ล้มเหลว)

> **ข้อควรระวังใน PureBasic:** `Select...Case` ของ PureBasic กับ string นั้น case-sensitive การเรียก `LCase()` ใน `_Scheme` ทำให้ input เป็น normalized ทำให้ `POSTGRES://`, `Postgres://` และ `postgres://` ทำงานได้ทั้งหมด หากไม่มีมัน DSN string ตัวพิมพ์ใหญ่จะล้มเหลวแบบเงียบๆ นี่คือ bug ที่คุณมักพบใน production เมื่อมีคนก็อปปี้ DSN จาก environment variable ที่ export ด้วยตัวพิมพ์ใหญ่ทั้งหมด

---

## 23.4 การแยกวิเคราะห์ URL

DSN ของ PostgreSQL และ MySQL บรรจุรายละเอียดการ authentication และการเชื่อมต่อในรูปแบบ URL module `DBConnect` มีชุดของ internal parsing procedure ที่แยก URL ออกเป็นส่วนประกอบ

```purebasic
; ตัวอย่างที่ 23.2 -- URL-parsing helpers (จาก Connect.pbi)
Procedure.s _AfterScheme(DSN.s)
  Protected p.i = FindString(DSN, "://")
  If p > 0
    ProcedureReturn Mid(DSN, p + 3)
  EndIf
  ; sqlite ใช้ "sqlite:<path>" โดยไม่มี "//"
  p = FindString(DSN, ":")
  If p > 0
    ProcedureReturn Mid(DSN, p + 1)
  EndIf
  ProcedureReturn DSN
EndProcedure

Procedure.s _UserInfo(Rest.s)
  Protected atPos.i = FindString(Rest, "@")
  If atPos > 0
    ProcedureReturn Left(Rest, atPos - 1)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s _User(UserInfo.s)
  Protected p.i = FindString(UserInfo, ":")
  If p > 0
    ProcedureReturn Left(UserInfo, p - 1)
  EndIf
  ProcedureReturn UserInfo
EndProcedure

Procedure.s _Pass(UserInfo.s)
  Protected p.i = FindString(UserInfo, ":")
  If p > 0
    ProcedureReturn Mid(UserInfo, p + 1)
  EndIf
  ProcedureReturn ""
EndProcedure

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

Procedure.s _DBName(HostPath.s)
  Protected slashPos.i = FindString(HostPath, "/")
  If slashPos > 0
    ProcedureReturn Mid(HostPath, slashPos + 1)
  EndIf
  ProcedureReturn ""
EndProcedure
```

procedure ทั้งเจ็ดนี้ parse URL แบบที่คุณจะทำด้วยมือ: หา `://` หา `@` หา `/` หา `:` ไม่มี regular expression ไม่มี URI library มีแค่ `FindString`, `Left` และ `Mid` string function ของ PureBasic เพียงพอสำหรับ URL ที่มีรูปแบบถูกต้อง และ DSN string มักถูกต้องเสมอเพราะ developer เป็นคนเขียน ไม่ใช่ผู้ใช้

คุณอาจ parse URL ด้วยมือโดยใช้ `Mid()` และ `FindString()` ใน procedure เดียว ก็ทำได้ เหมือนสร้างบ้านด้วยช้อน ทั้งสองทำได้ในทางเทคนิค helper procedure ทำให้แต่ละขั้นตอนการ parse ทดสอบได้และใช้ซ้ำได้

parsing pipeline สำหรับ `postgres://admin:secret@db.example.com:5432/blogdb` ได้ผลลัพธ์ดังนี้:

| Helper | Input | Output |
|--------|-------|--------|
| `_Scheme` | DSN เต็ม | `"postgres"` |
| `_AfterScheme` | DSN เต็ม | `"admin:secret@db.example.com:5432/blogdb"` |
| `_UserInfo` | หลัง scheme | `"admin:secret"` |
| `_User` | userinfo | `"admin"` |
| `_Pass` | userinfo | `"secret"` |
| `_HostPath` | หลัง scheme | `"db.example.com:5432/blogdb"` |
| `_Host` | hostpath | `"db.example.com"` |
| `_Port` | hostpath | `"5432"` |
| `_DBName` | hostpath | `"blogdb"` |

แต่ละ helper จัดการ component ที่หายไปได้อย่าง graceful DSN ที่ไม่มี port จะคืนค่า empty string สำหรับ `_Port` DSN ที่ไม่มี credentials จะคืนค่า empty string สำหรับ `_User` และ `_Pass` procedure `Open` ส่งค่าเหล่านี้ไปยัง `OpenDatabase` ของ PureBasic ซึ่งใช้ค่า default เฉพาะไดรเวอร์สำหรับทุกอย่างที่ไม่ได้ระบุ

```mermaid
graph LR
    A["postgres://admin:secret@host:5432/blogdb"] --> B[_Scheme]
    A --> C[_AfterScheme]
    C --> D[_UserInfo]
    C --> E[_HostPath]
    D --> F[_User]
    D --> G[_Pass]
    E --> H[_Host]
    E --> I[_Port]
    E --> J[_DBName]
    B --> K{Driver Select}
    F --> L[OpenDatabase]
    G --> L
    H --> M[ConnStr]
    I --> M
    J --> M
    M --> L
    K --> L

    style K fill:#4A90D9,color:#fff
```
*รูปที่ 23.1 — DSN factory: URL-style string ถูก parse ออกเป็น component ประกอบเป็น connection format ของ PureBasic แล้วส่งไปยัง `OpenDatabase` พร้อม driver constant ที่ถูกต้อง*

---

## 23.5 Procedure ConnStr

`OpenDatabase` ของ PureBasic รับ connection string ในรูปแบบ key-value สำหรับฐานข้อมูลแบบ server: `host=localhost port=5432 dbname=mydb` procedure `ConnStr` แปลง URL-style DSN เป็นรูปแบบนี้:

```purebasic
; ตัวอย่างที่ 23.3 -- ConnStr: URL DSN ไปเป็น PureBasic key=value format
Procedure.s ConnStr(DSN.s)
  Protected rest.s     = _AfterScheme(DSN)
  Protected userInfo.s = _UserInfo(rest)
  Protected hostPath.s = _HostPath(rest)
  Protected host.s     = _Host(hostPath)
  Protected port.s     = _Port(hostPath)
  Protected dbname.s   = _DBName(hostPath)
  Protected result.s   = "host=" + host
  If port   <> ""
    result + " port="   + port
  EndIf
  If dbname <> ""
    result + " dbname=" + dbname
  EndIf
  ProcedureReturn result
EndProcedure
```

user และ password ถูกยกเว้นจาก connection string โดยตั้งใจ `OpenDatabase` ของ PureBasic รับเป็น parameter แยก (argument ที่สองและสาม) ซึ่งเป็นการแยกแบบเดียวกับที่ `libpq` ของ PostgreSQL ใช้: connection string อธิบาย *ที่ไหน* ที่จะเชื่อมต่อ credentials อธิบาย *ใคร* ที่กำลังเชื่อมต่อ

สำหรับ `postgres://admin:secret@db.example.com:5432/blogdb` นั้น `ConnStr` คืนค่า `"host=db.example.com port=5432 dbname=blogdb"` user `admin` และ password `secret` ถูกดึงแยกต่างหากโดย `_User` และ `_Pass` แล้วส่งตรงไปยัง `OpenDatabase`

---

## 23.6 การเปิด Connection

procedure `Open` คือ public entry point มันตรวจจับไดรเวอร์ parse DSN และเรียก `OpenDatabase` ด้วย parameter ที่ถูกต้อง:

```purebasic
; ตัวอย่างที่ 23.4 -- DBConnect::Open: connection factory
Procedure.i Open(DSN.s)
  Protected drv.i    = Driver(DSN)
  Protected rest.s   = _AfterScheme(DSN)
  Protected userInfo.s, user.s, pass.s, cs.s

  Select drv
    Case #Driver_SQLite
      ProcedureReturn OpenDatabase(#PB_Any,
        rest, "", "", #PB_Database_SQLite)

    Case #Driver_Postgres
      userInfo = _UserInfo(rest)
      user     = _User(userInfo)
      pass     = _Pass(userInfo)
      cs       = ConnStr(DSN)
      ProcedureReturn OpenDatabase(#PB_Any,
        cs, user, pass, #PB_Database_PostgreSQL)

    Case #Driver_MySQL
      userInfo = _UserInfo(rest)
      user     = _User(userInfo)
      pass     = _Pass(userInfo)
      cs       = ConnStr(DSN)
      ProcedureReturn OpenDatabase(#PB_Any,
        cs, user, pass, #PB_Database_MySQL)

  EndSelect
  ProcedureReturn 0
EndProcedure
```

สามไดรเวอร์ procedure เดียว return type เดียว handle ที่ได้จาก `Open` คือ standard PureBasic database handle ทำงานกับ `DB::Exec`, `DB::Query`, `DB::NextRow`, `DB::GetStr`, `DB::BindStr`, `DB::Migrate` — ทุก procedure จากบทที่ 13 และ 14 ไดรเวอร์มองไม่เห็นจาก application ส่วนที่เหลือของคุณ

flag `#PB_Any` บอก PureBasic ให้จัดสรร handle แบบ dynamic และคืนค่า ID ของมัน นี่คือ pattern เดียวกับที่ใช้ทั่ว PureSimple สำหรับ resource ที่สร้างแบบ dynamic ทั้งหมด (บทที่ 2) หากไม่มี `#PB_Any` คุณจะต้องกำหนด numeric handle ล่วงหน้า ซึ่งไม่ scale เมื่อมี database connection เปิดอยู่หลายตัว

สำหรับ SQLite connection string คือ file path (หรือ `:memory:`) ไม่มี user ไม่มี password ไม่มี host empty string ที่ส่งไปยัง `OpenDatabase` ถูกละเว้นโดย SQLite driver

สำหรับ PostgreSQL และ MySQL URL parsing pipeline ทั้งหมดจะทำงาน: ดึง user และ password จาก userinfo สร้าง key-value connection string จาก host, port และชื่อฐานข้อมูล แล้วส่งทุกอย่างไปยัง `OpenDatabase` พร้อม plugin constant ที่เหมาะสม

> **คำเตือน:** PostgreSQL และ MySQL ต้องการให้ server process ทำงานอยู่ก่อนที่จะเรียก `Open` แต่ SQLite ไม่ต้อง — มันสร้างไฟล์เมื่อ access ครั้งแรก ถ้า `Open` คืนค่า 0 สำหรับ PostgreSQL DSN ให้ตรวจสอบว่า server กำลังทำงานและ credentials ถูกต้อง error อยู่ที่ infrastructure ไม่ใช่ที่โค้ด

---

## 23.7 การเชื่อมต่อด้วย Configuration

procedure `OpenFromConfig` อ่าน DSN จากไฟล์ `.env` ของแอปพลิเคชัน:

```purebasic
; ตัวอย่างที่ 23.5 -- OpenFromConfig: การตั้งค่าฐานข้อมูลในบรรทัดเดียว
Procedure.i OpenFromConfig()
  Protected dsn.s = Config::Get("DB_DSN",
                                "sqlite::memory:")
  ProcedureReturn Open(dsn)
EndProcedure
```

สองบรรทัด อ่าน environment variable `DB_DSN` (พร้อมค่าเริ่มต้น `sqlite::memory:`) แล้วเรียก `Open` ไดรเวอร์ฐานข้อมูลของแอปพลิเคชันถูกควบคุมทั้งหมดโดยไฟล์ `.env`:

```bash
; ตัวอย่างที่ 23.6 -- การสลับฐานข้อมูลผ่าน .env

# Development: SQLite file
DB_DSN=sqlite:data/app.db

# Staging: PostgreSQL
DB_DSN=postgres://appuser:staging_pass@localhost:5432/myapp_staging

# Production: MySQL
DB_DSN=mysql://appuser:prod_pass@db.internal:3306/myapp_production
```

ไม่มีการเปลี่ยนโค้ด ไม่มีการ recompile แค่เปลี่ยน DSN restart แอป และฐานข้อมูลจะสลับ นี่คือหลักการ twelve-factor app จากบทที่ 18 ที่นำมาใช้กับ database layer: configuration อยู่ใน environment ไม่ใช่ใน source code

ค่าเริ่มต้น `sqlite::memory:` มีเหตุผล ถ้าไม่มีไฟล์ `.env` และไม่มีการตั้งค่า `DB_DSN` แอปยังเริ่มต้นได้ — ด้วย in-memory database ที่หายไปเมื่อ process สิ้นสุด มีประโยชน์สำหรับ test (บทที่ 20) และสำหรับ demo ด่วนที่ไม่ต้องการ persistence

ในทางปฏิบัติ แอปพลิเคชัน PureSimple ส่วนใหญ่ใช้ `OpenFromConfig` ใน `main.pb`:

```purebasic
; ตัวอย่างที่ 23.7 -- การใช้ OpenFromConfig ในแอปพลิเคชัน
Config::Load(".env")
Protected _db.i = DBConnect::OpenFromConfig()
If _db = 0
  PrintN("ERROR: Cannot connect to database")
  PrintN("DB_DSN = " +
         Config::Get("DB_DSN", "(not set)"))
  End 1
EndIf
```

ถ้า connection ล้มเหลว error message จะพิมพ์ DSN (โดยไม่มี credentials) เพื่อช่วยวินิจฉัยปัญหา ล้มเร็ว ล้มพร้อมข้อมูลที่มีประโยชน์

---

## 23.8 การเปิดใช้งานไดรเวอร์

ที่ด้านบนของ `Connect.pbi` สามบรรทัดเปิดใช้งาน database driver ทั้งหมดตอน compile time:

```purebasic
; ตัวอย่างที่ 23.8 -- การเปิดใช้งานไดรเวอร์
UseSQLiteDatabase()
UsePostgreSQLDatabase()
UseMySQLDatabase()
```

PureBasic ต้องการการเปิดใช้งานไดรเวอร์อย่างชัดเจน หากไม่มี `UsePostgreSQLDatabase()` การส่ง `#PB_Database_PostgreSQL` ไปยัง `OpenDatabase` จะล้มเหลวแบบเงียบๆ สามบรรทัดนี้ทำให้มั่นใจว่าไดรเวอร์ทั้งหมดพร้อมใช้งานโดยไม่คำนึงว่าแอปพลิเคชันใช้ DSN ใดใน runtime

ค่าใช้จ่ายน้อยมาก: แต่ละไดรเวอร์เพิ่มขนาด binary เล็กน้อย แต่ database client library จะ link เข้ามาเฉพาะเมื่อ compiler พบการเรียก `Use*Database()` ที่สอดคล้อง บน macOS SQLite library เป็นส่วนหนึ่งของระบบ PostgreSQL และ MySQL client library ต้องติดตั้งแยก

> **เคล็ดลับ:** ถ้าคุณรู้ว่าแอปพลิเคชันจะใช้ SQLite เท่านั้น คุณสามารถละเว้นบรรทัด `UsePostgreSQLDatabase()` และ `UseMySQLDatabase()` ในโค้ดของคุณเอง module `DBConnect` รวมทั้งสามเพราะมันเป็น connector ที่ใช้งานทั่วไป การลบไดรเวอร์ที่ไม่ใช้ช่วยลดขนาด binary ลงเล็กน้อย

---

## 23.9 ข้อพิจารณาเชิงปฏิบัติ

### ความแตกต่างของ SQL Dialect

module `DBConnect` abstract การเชื่อมต่อ ไม่ใช่ query language SQLite, PostgreSQL และ MySQL มี SQL dialect ที่แตกต่างกัน ความแตกต่างทั่วไปที่ควรระวัง:

| Feature | SQLite | PostgreSQL | MySQL |
|---------|--------|-----------|-------|
| Auto-increment | `AUTOINCREMENT` | `SERIAL` หรือ `GENERATED ALWAYS AS IDENTITY` | `AUTO_INCREMENT` |
| Upsert | `INSERT OR IGNORE` | `ON CONFLICT DO NOTHING` | `INSERT IGNORE` |
| Boolean type | `INTEGER (0/1)` | `BOOLEAN` | `TINYINT(1)` |
| String concat | `\|\|` | `\|\|` | `CONCAT()` |
| Current timestamp | `datetime('now')` | `NOW()` | `NOW()` |

ถ้าคุณวางแผนรองรับหลายฐานข้อมูล ให้เขียน SQL ตาม lowest common denominator หรือดูแล migration file แยกสำหรับแต่ละไดรเวอร์ blog Wild & Still (บทที่ 22) ใช้ syntax เฉพาะ SQLite (`INSERT OR IGNORE`, `AUTOINCREMENT`) และจะต้องเปลี่ยน migration เพื่อรันบน PostgreSQL

นี่คือข้อแลกเปลี่ยนที่ซื่อสัตย์ database portability มีคุณค่าเมื่อคุณต้องการมัน และเป็น overhead ที่ไม่จำเป็นเมื่อคุณไม่ต้องการ แอปพลิเคชันส่วนใหญ่เลือกฐานข้อมูลและอยู่กับมัน module `DBConnect` ให้ตัวเลือกโดยไม่บังคับการตัดสินใจ

### Connection Lifecycle

ความแตกต่างหนึ่งระหว่าง SQLite กับฐานข้อมูลแบบ server: ค่าใช้จ่ายของ connection SQLite เปิดไฟล์ local ในไม่กี่ไมโครวินาที PostgreSQL และ MySQL negotiates TCP connection ตรวจสอบสิทธิ์ และ initialize session — ใช้เวลาหลายมิลลิวินาที สำหรับ web application ที่เปิด connection เดียวตอน startup และถือไว้ตลอด process ความแตกต่างนี้เล็กน้อยมาก ถ้าคุณเปิด connection ใหม่ต่อ request (อย่าทำ) ความแตกต่างจะสำคัญ

แอปพลิเคชัน PureSimple โดยทั่วไปเปิด database connection หนึ่งตัวใน boot sequence และส่ง handle ไปยัง handler ทั้งหมดผ่าน global variable นี่คือ pattern ที่ใช้ใน blog Wild & Still และ to-do API มันทำงานได้สำหรับแอปพลิเคชัน single-threaded สำหรับแอปพลิเคชัน multi-threaded ที่ใช้ flag `-t` คุณจะต้องการ connection pooling ซึ่ง PureBasic ไม่มี native รองรับ ณ จุดนั้น คุณกำลังสร้าง infrastructure มากกว่า web application และ connection pool module จะเป็นส่วนเพิ่มที่คุ้มค่าสำหรับ framework

---

## สรุป

module `DBConnect` มี DSN-based connection factory ที่ abstract เหนือ SQLite, PostgreSQL และ MySQL procedure `Open` ตัวเดียว parse URL-style DSN string ตรวจจับไดรเวอร์ แปลง connection parameter เป็น native format ของ PureBasic และคืนค่า standard database handle procedure convenience `OpenFromConfig` อ่าน DSN จากไฟล์ `.env` ทำให้การเลือกฐานข้อมูลเป็นการตัดสินใจด้าน configuration ไม่ใช่การเปลี่ยนโค้ด abstraction ครอบคลุมการเชื่อมต่อเท่านั้น — ความแตกต่างของ SQL dialect ยังคงเป็นความรับผิดชอบของแอปพลิเคชัน

## สิ่งสำคัญที่ควรจำ

- ใช้ `DBConnect::Open("sqlite:data/app.db")` หรือ `DBConnect::OpenFromConfig()` สำหรับ database connection แบบ driver-agnostic
- DSN prefix (`sqlite:`, `postgres://`, `mysql://`) กำหนดไดรเวอร์ ส่วนที่เหลือของ string ให้รายละเอียดการเชื่อมต่อ
- ความแตกต่างของ SQL dialect (auto-increment syntax, upsert behavior, boolean type) ไม่ถูก abstract — เขียน SQL แบบ portable หรือดูแล migration แยกต่อไดรเวอร์

## คำถามทบทวน

1. จะเกิดอะไรขึ้นถ้าคุณส่ง DSN ที่มี prefix `mongodb://` ไปยัง `DBConnect::Open`? ติดตาม code path ผ่าน `Driver` และ `Open` เพื่ออธิบายผลลัพธ์
2. ทำไม `ConnStr` ถึงยกเว้น user และ password จาก key-value string ที่คืนค่า แม้ว่าทั้งสองจะเป็นส่วนหนึ่งของ DSN?
3. *ลองทำ:* ติดตั้ง PostgreSQL ใน local สร้างฐานข้อมูลทดสอบ และแก้ไข blog Wild & Still ให้ใช้ `DBConnect::OpenFromConfig()` กับ PostgreSQL DSN SQL statement ใดใน migration ที่ต้องเปลี่ยน?
