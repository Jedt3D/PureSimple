# ภาคผนวก ข: API Reference ของ PureSimple

ภาคผนวกนี้บันทึก procedure สาธารณะทุกตัวใน framework PureSimple โดยจัดกลุ่มตาม module เนื้อหาสอดคล้องกับไดเรกทอรี `docs/api/` ในคลังโค้ด แต่รวบรวมไว้ในไฟล์เดียวเพื่อความสะดวก ใช้ภาคผนวกนี้เมื่อต้องการค้น signature ของ procedure, ค่า default ของ parameter หรือชื่อ field ที่แน่นอนบน `RequestContext`

---

## ข.1 Handler Signature

ทั้ง route handler และ middleware ทุกตัวใน PureSimple ใช้ signature เดียวกัน:

```purebasic
Prototype.i PS_HandlerFunc(*C.RequestContext)
```

ประกาศ handler เป็น procedure ธรรมดาแล้วส่งที่อยู่ด้วย `@`:

```purebasic
Procedure MyHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  Rendering::JSON(*C, ~"{\"id\":\"" + id + ~"\"}")
EndProcedure

Engine::GET("/users/:id", @MyHandler())
```

---

## ข.2 Engine Module

**ไฟล์:** `src/Engine.pbi`

Engine module คือ API ระดับบนสุดของแอปพลิเคชัน ทำหน้าที่ลงทะเบียน route, จัดการ middleware ระดับ global, กำหนด error handler และควบคุม lifecycle ของแอปพลิเคชัน

### การลงทะเบียน Route

| Procedure | คำอธิบาย |
|---|---|
| `Engine::GET(Pattern.s, Handler.i)` | ลงทะเบียน GET route |
| `Engine::POST(Pattern.s, Handler.i)` | ลงทะเบียน POST route |
| `Engine::PUT(Pattern.s, Handler.i)` | ลงทะเบียน PUT route |
| `Engine::PATCH(Pattern.s, Handler.i)` | ลงทะเบียน PATCH route |
| `Engine::DELETE(Pattern.s, Handler.i)` | ลงทะเบียน DELETE route |
| `Engine::Any(Pattern.s, Handler.i)` | ลงทะเบียน route สำหรับทั้งห้า method |

Pattern รองรับ literal segment (`/users/profile`), named parameter (`/users/:id`) และ wildcard (`/static/*path`)

### Middleware

| Procedure | คำอธิบาย |
|---|---|
| `Engine::Use(Handler.i)` | ลงทะเบียน global middleware (เพิ่มต้น chain ของทุก request) |
| `Engine::ResetMiddleware()` | ล้าง middleware และ error handler ทั้งหมด (สำหรับการแยก test ออกจากกัน) |

Global middleware ทำงานตามลำดับที่ลงทะเบียน เรียก `Use` ก่อนลงทะเบียน route เสมอ

### Error Handler

| Procedure | คำอธิบาย |
|---|---|
| `Engine::SetNotFoundHandler(Handler.i)` | กำหนด 404 handler แบบกำหนดเอง |
| `Engine::HandleNotFound(*C.RequestContext)` | เรียกใช้ 404 handler (ใช้ภายใน) |
| `Engine::SetMethodNotAllowedHandler(Handler.i)` | กำหนด 405 handler แบบกำหนดเอง |
| `Engine::HandleMethodNotAllowed(*C.RequestContext)` | เรียกใช้ 405 handler (ใช้ภายใน) |

ค่า default เมื่อไม่ได้กำหนด handler เอง:
- **404:** `"404 Not Found"` พร้อม `text/plain`
- **405:** `"405 Method Not Allowed"` พร้อม `text/plain`

### Run Mode

| Procedure | คำอธิบาย |
|---|---|
| `Engine::SetMode(mode.s)` | กำหนด mode: `"debug"` (ค่าเริ่มต้น), `"release"` หรือ `"test"` |
| `Engine::Mode()` | คืนค่า mode string ปัจจุบัน |

### App Lifecycle

| Procedure | คำอธิบาย |
|---|---|
| `Engine::NewApp()` | สร้างแอปพลิเคชัน (stub, คืน 0) |
| `Engine::Run(Port.i)` | เริ่ม listening (stub, คืน `#False`) |

### Procedure ภายใน

| Procedure | คำอธิบาย |
|---|---|
| `Engine::CombineHandlers(*C.RequestContext, RouteHandler.i)` | สร้าง handler chain สำหรับ route ระดับบนสุด |
| `Engine::AppendGlobalMiddleware(*C.RequestContext)` | คัดลอก global middleware เข้า handler array ของ context |

---

## ข.3 Router Module

**ไฟล์:** `src/Router.pbi`

Router module ใช้ radix trie สำหรับ URL pattern matching แอปพลิเคชันส่วนใหญ่โต้ตอบกับ router ผ่าน `Engine::GET`, `Engine::POST` ฯลฯ โดยอ้อม จำเป็นต้องเข้าถึงตรงเฉพาะเมื่อต้องการสร้าง dispatch callback แบบกำหนดเอง

### Procedure

| Procedure | คำอธิบาย |
|---|---|
| `Router::Insert(Method.s, Pattern.s, Handler.i)` | ลงทะเบียน handler สำหรับ method และ pattern ที่กำหนด |
| `Router::Match(Method.s, Path.s, *C.RequestContext)` | เดินใน trie และเติม params คืน handler address หรือ 0 |

### ลำดับความสำคัญของ Segment

1. **Exact match** (เร็วที่สุด) -- เช่น `/users`
2. **Named parameter** -- เช่น `/users/:id`
3. **Wildcard** -- เช่น `/files/*path`

### ตัวอย่าง Pattern

```purebasic
Router::Insert("GET",    "/",               @HomeHandler())
Router::Insert("GET",    "/users",          @ListUsers())
Router::Insert("GET",    "/users/:id",      @GetUser())
Router::Insert("POST",   "/users",          @CreateUser())
Router::Insert("DELETE", "/users/:id",      @DeleteUser())
Router::Insert("GET",    "/files/*path",    @ServeFile())
```

ผลลัพธ์การ match:

| Request | Handler | Params |
|---|---|---|
| `GET /users/42` | `GetUser` | `id="42"` |
| `GET /files/a/b` | `ServeFile` | `path="a/b"` |
| `GET /users` | `ListUsers` | (exact match ชนะ) |

---

## ข.4 Context Module

**ไฟล์:** `src/Context.pbi`

Context module จัดการ lifecycle ของแต่ละ request เริ่มต้น `RequestContext`, ส่งต่อ handler chain และให้บริการ KV store สำหรับการสื่อสารระหว่าง middleware กับ handler

### Lifecycle

| Procedure | คำอธิบาย |
|---|---|
| `Ctx::Init(*C.RequestContext, ContextID.i)` | รีเซ็ตทุก field และกำหนด context ID |
| `Ctx::AddHandler(*C.RequestContext, Handler.i)` | เพิ่ม handler เข้า chain |
| `Ctx::Dispatch(*C.RequestContext)` | เรียก handler ตัวแรกใน chain |
| `Ctx::Advance(*C.RequestContext)` | เรียก handler ตัวถัดไป (เทียบเท่า `Next` ใน Gin) |

`Advance` เพิ่มค่า `HandlerIndex` แล้วเรียก `handlers[HandlerIndex]` middleware แต่ละตัวควรเรียก `Advance` เพื่อส่งต่อการควบคุมลงไปใน chain

### Abort

| Procedure | คำอธิบาย |
|---|---|
| `Ctx::Abort(*C.RequestContext)` | หยุด chain (การเรียก `Advance` ถัดไปจะไม่มีผล) |
| `Ctx::IsAborted(*C.RequestContext)` | คืน `#True` ถ้าเคยเรียก `Abort` แล้ว |
| `Ctx::AbortWithStatus(*C.RequestContext, StatusCode.i)` | Abort และกำหนด HTTP status code |
| `Ctx::AbortWithError(*C.RequestContext, StatusCode.i, Message.s)` | Abort พร้อม status และ error message ใน body |

### Route Parameter

| Procedure | คำอธิบาย |
|---|---|
| `Ctx::Param(*C.RequestContext, Name.s)` | ดึงค่า named route parameter คืน `""` ถ้าไม่พบ |

### KV Store

| Procedure | คำอธิบาย |
|---|---|
| `Ctx::Set(*C.RequestContext, Key.s, Val.s)` | เก็บค่าสตริงสำหรับ request นี้ |
| `Ctx::Get(*C.RequestContext, Key.s)` | ดึงค่าสตริง คืน `""` ถ้าไม่พบ |

KV store ใช้ส่งข้อมูลระหว่าง middleware กับ handler และยังเป็นแหล่งตัวแปรสำหรับ template ใน `Rendering::Render` ด้วย

---

## ข.5 Binding Module

**ไฟล์:** `src/Binding.pbi`

Binding module ดึงข้อมูลจาก request ที่เข้ามา ไม่ว่าจะเป็น route parameter, query string, form body หรือ JSON payload

### Route Parameter

| Procedure | คำอธิบาย |
|---|---|
| `Binding::Param(*C.RequestContext, Name.s)` | ดึง named route param (เรียกต่อไปยัง `Ctx::Param`) |

### Query String

| Procedure | คำอธิบาย |
|---|---|
| `Binding::Query(*C.RequestContext, Name.s)` | ดึงค่าจาก query string ถอดรหัส `+` และ `%XX` ให้อัตโนมัติ |

Parse แบบ lazy จาก `*C\RawQuery` ครั้งแรกที่เรียก ผลลัพธ์ cache ไว้ใน `*C\QueryKeys` / `*C\QueryVals`

### Form Data

| Procedure | คำอธิบาย |
|---|---|
| `Binding::PostForm(*C.RequestContext, Field.s)` | ดึง form field จาก body แบบ `application/x-www-form-urlencoded` |

Parse `*C\Body` เป็น URL-encoded form data ทุกครั้งที่เรียก ผลลัพธ์เก็บไว้ใน temporary ระดับ module ไม่ cache ไว้ใน `RequestContext`

### JSON Body

| Procedure | คำอธิบาย |
|---|---|
| `Binding::BindJSON(*C.RequestContext)` | Parse `*C\Body` เป็น JSON เก็บ handle ไว้ใน `*C\JSONHandle` |
| `Binding::JSONString(*C.RequestContext, Key.s)` | ดึง string field จาก JSON ที่ parse แล้ว |
| `Binding::JSONInteger(*C.RequestContext, Key.s)` | ดึง integer field จาก JSON ที่ parse แล้ว |
| `Binding::JSONBool(*C.RequestContext, Key.s)` | ดึง boolean field จาก JSON ที่ parse แล้ว |
| `Binding::ReleaseJSON(*C.RequestContext)` | คืน JSON handle เรียกเสมอเมื่อใช้งานเสร็จ |

**สำคัญ:** `ReleaseJSON` ใช้ชื่อนี้เพื่อหลีกเลี่ยงการ shadow `FreeJSON` built-in ของ PureBasic ถ้า JSON ไม่ถูกต้อง จะตั้ง `JSONHandle = 0` และ `StatusCode = 400` ตัวเข้าถึง field คืนค่า default ที่ปลอดภัย (`""` / `0` / `#False`) เมื่อ handle เป็น 0 หรือไม่พบ key

---

## ข.6 Rendering Module

**ไฟล์:** `src/Rendering.pbi`

Rendering module เขียน HTTP response ทุก procedure จะกำหนด `StatusCode`, `ContentType` และ `ResponseBody` บน context

### Procedure

| Procedure | Signature | คำอธิบาย |
|---|---|---|
| `Rendering::JSON` | `(*C, Body.s, Status.i = 200)` | JSON response (`application/json`) |
| `Rendering::HTML` | `(*C, Body.s, Status.i = 200)` | HTML response (`text/html`) |
| `Rendering::Text` | `(*C, Body.s, Status.i = 200)` | Plain text response (`text/plain`) |
| `Rendering::Status` | `(*C, Status.i)` | กำหนด status code เท่านั้น ไม่มี body (สำหรับ 204 No Content) |
| `Rendering::Redirect` | `(*C, URL.s, Status.i = 302)` | Redirect กำหนด `*C\Location` ใช้ 302 สำหรับชั่วคราว, 301 สำหรับถาวร |
| `Rendering::File` | `(*C, Path.s)` | ส่งไฟล์จาก disk คืน 404 ถ้าไม่พบไฟล์ |
| `Rendering::Render` | `(*C, TemplateName.s, TemplatesDir.s = "templates/")` | Render Jinja template ผ่าน PureJinja ตัวแปรมาจาก KV store |

### รายละเอียดการ Render Template

`Rendering::Render` ดำเนินการตามขั้นตอนเหล่านี้:
1. สร้าง PureJinja environment
2. กำหนด template search path เป็น `TemplatesDir`
3. อ่านตัวแปร template จาก `*C\StoreKeys` / `*C\StoreVals`
4. Render template
5. คืน environment
6. กำหนด `ContentType = "text/html"` และ `StatusCode = 200`

หาก render ล้มเหลว response body จะมี error string จาก PureJinja

---

## ข.7 Group Module

**ไฟล์:** `src/Group.pbi`

Group module สร้าง sub-router ที่มี path prefix และ middleware stack ร่วมกัน

### Structure

```purebasic
Structure PS_RouterGroup
  Prefix.s            ; path prefix สำหรับทุก route ใน group
  MW.i[32]            ; middleware ระดับ group (สูงสุด 32)
  MWCount.i           ; จำนวน middleware ที่ลงทะเบียน
EndStructure
```

### Procedure

| Procedure | คำอธิบาย |
|---|---|
| `Group::Init(*G.PS_RouterGroup, Prefix.s)` | เริ่มต้น group ด้วย path prefix |
| `Group::Use(*G.PS_RouterGroup, Handler.i)` | เพิ่ม middleware เข้า group |
| `Group::GET(*G, Pattern.s, Handler.i)` | ลงทะเบียน GET route ใน group |
| `Group::POST(*G, Pattern.s, Handler.i)` | ลงทะเบียน POST route ใน group |
| `Group::PUT(*G, Pattern.s, Handler.i)` | ลงทะเบียน PUT route ใน group |
| `Group::PATCH(*G, Pattern.s, Handler.i)` | ลงทะเบียน PATCH route ใน group |
| `Group::DELETE(*G, Pattern.s, Handler.i)` | ลงทะเบียน DELETE route ใน group |
| `Group::Any(*G, Pattern.s, Handler.i)` | ลงทะเบียนทุก method ใน group |
| `Group::SubGroup(*Parent, *Child, SubPrefix.s)` | สร้าง sub-group ที่ซ้อนกัน คัดลอก middleware ของ parent ไปยัง child |
| `Group::CombineHandlers(*G, *C, RouteHandler.i)` | สร้าง handler chain: global MW + group MW + route handler |

### ลำดับ Handler Chain

`CombineHandlers` สร้าง handler array แบบ flat ตามลำดับนี้:

1. **Global engine middleware** (ลงทะเบียนด้วย `Engine::Use`)
2. **Group middleware** (ลงทะเบียนด้วย `Group::Use`)
3. **Route handler**

`SubGroup` คัดลอก middleware ของ parent ไปยัง child ณ เวลาสร้าง middleware ที่เพิ่มให้ child ภายหลัง `SubGroup` จะไม่กระทบ parent

---

## ข.8 Middleware Module

**ไฟล์:** `src/Middleware/*.pbi`

PureSimple มี middleware built-in หกตัว ทั้งหมดใช้ handler signature มาตรฐาน

### Logger

**ไฟล์:** `src/Middleware/Logger.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `Logger::Middleware()` | คืนที่อยู่ Logger handler ลงทะเบียนด้วย `Engine::Use(@Logger::Middleware())` |

บันทึกหนึ่งบรรทัดต่อ request หลังจาก downstream chain ทำงานเสร็จ:

```
[LOG] GET /users/42 -> 200 (3ms)
```

ใช้ `ElapsedMilliseconds()` สำหรับจับเวลา ส่ง output ไปยัง stdout ผ่าน `PrintN`

### Recovery

**ไฟล์:** `src/Middleware/Recovery.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `Recovery::Middleware()` | คืนที่อยู่ Recovery handler |

ติดตั้ง `OnErrorGoto` checkpoint รอบ downstream chain เมื่อเกิด PureBasic runtime error จะเขียน response `500 Internal Server Error` แล้ว resume ต่อได้อย่างสะอาด

**หมายเหตุ:** บน macOS arm64, OS signal (SIGSEGV, SIGHUP จาก `RaiseError`) ไม่สามารถ intercept ได้ผ่าน `OnErrorGoto` Recovery ทำงานได้อย่างน่าเชื่อถือบน Linux และ Windows

### Cookie

**ไฟล์:** `src/Middleware/Cookie.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `Cookie::Get(*C.RequestContext, Name.s)` | อ่าน cookie จาก header `Cookie` ที่เข้ามา |
| `Cookie::Set(*C.RequestContext, Name.s, Value.s)` | กำหนด response cookie (แบบพื้นฐาน) |
| `Cookie::Set(*C, Name.s, Value.s, Path.s, MaxAge.i)` | กำหนด response cookie พร้อม path และ Max-Age |

`Get` parse `*C\Cookie` (คู่ `name=value` คั่นด้วยเซมิโคลอน) `Set` เพิ่ม `Set-Cookie` directive เข้า `*C\SetCookies` (คั่นด้วย Chr(10))

### Session

**ไฟล์:** `src/Middleware/Session.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `Session::Middleware()` | คืนที่อยู่ Session middleware handler |
| `Session::Get(*C.RequestContext, Key.s)` | อ่านค่า session (คืนค่าที่เขียนล่าสุดสำหรับ key นั้น) |
| `Session::Set(*C.RequestContext, Key.s, Value.s)` | เขียนค่า session |
| `Session::ID(*C.RequestContext)` | ดึง session ID ปัจจุบัน |
| `Session::Save(*C.RequestContext)` | บันทึก session data (middleware เรียกอัตโนมัติหลัง chain) |
| `Session::ClearStore()` | ล้าง session ทั้งหมด (สำหรับการแยก test ออกจากกัน) |

Session เก็บใน global in-memory map (`sessionID` ไปยัง KV แบบ serialised) Session ID เป็น random hex string 32 ตัวอักษรที่เก็บใน cookie `_psid`

### BasicAuth

**ไฟล์:** `src/Middleware/BasicAuth.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `BasicAuth::SetCredentials(User.s, Pass.s)` | กำหนด username และ password ที่คาดหวัง |
| `BasicAuth::Middleware()` | คืนที่อยู่ BasicAuth handler |

ถอดรหัส header `Authorization: Basic <base64>` หยุดด้วย `401 Unauthorized` ถ้า header หายไป, รูปแบบผิด หรือ credential ไม่ตรง เมื่อสำเร็จ จะเก็บ username ที่ยืนยันแล้วใน KV store ภายใต้ key `_auth_user`

### CSRF

**ไฟล์:** `src/Middleware/CSRF.pbi`

| Procedure | คำอธิบาย |
|---|---|
| `CSRF::GenerateToken()` | สร้าง random hex token แบบ 128-bit |
| `CSRF::SetToken(*C.RequestContext)` | เก็บ token ใน session และ cookie |
| `CSRF::ValidateToken(*C.RequestContext, Token.s)` | ตรวจสอบ token กับที่เก็บใน session คืน `#True` เมื่อตรงกัน |
| `CSRF::Middleware()` | คืนที่อยู่ CSRF middleware handler |

`CSRF::Middleware` ข้าม request แบบ `GET` และ `HEAD` สำหรับ method อื่น จะอ่าน form field `_csrf` ผ่าน `Binding::PostForm` แล้วเปรียบเทียบกับ token ที่เก็บใน session หยุดด้วย `403 Forbidden` หากไม่ตรงกัน

**ต้องการ:** Session middleware ต้องลงทะเบียนก่อน CSRF middleware

---

## ข.9 DB Module (SQLite)

**ไฟล์:** `src/DB/SQLite.pbi`

DB module ห่อ SQLite support built-in ของ PureBasic ด้วย API ที่กระชับกว่าและเพิ่ม migration runner เข้ามา

### การเปิดและปิดฐานข้อมูล

| Procedure | คำอธิบาย |
|---|---|
| `DB::Open(Path.s)` | เปิดหรือสร้าง SQLite database คืน handle (0 เมื่อล้มเหลว) |
| `DB::Close(Handle.i)` | ปิด database handle |

ใช้ `":memory:"` สำหรับ in-memory database (ไม่มีการบันทึกถาวร เหมาะสำหรับ test)

### การรัน SQL

| Procedure | คำอธิบาย |
|---|---|
| `DB::Exec(Handle.i, SQL.s)` | รัน SQL ที่ไม่ใช่ SELECT (DDL, INSERT, UPDATE, DELETE) คืน `#True` เมื่อสำเร็จ |
| `DB::Error()` | คืน error string ล่าสุดของฐานข้อมูล |

### การ Query

| Procedure | คำอธิบาย |
|---|---|
| `DB::Query(Handle.i, SQL.s)` | รัน SELECT query คืน `#True` เมื่อสำเร็จ |
| `DB::NextRow(Handle.i)` | เลื่อนไปยังแถวถัดไป คืน `#True` ถ้ามีแถว |
| `DB::Done(Handle.i)` | คืน result set |

`NextRow` ใช้ชื่อนี้เพื่อหลีกเลี่ยง reserved keyword `Next`

### Column Accessor

| Procedure | คำอธิบาย |
|---|---|
| `DB::GetStr(Handle.i, Col.i)` | ดึงค่าสตริง (column index นับจาก 0) คืน `""` ถ้าเป็น NULL |
| `DB::GetInt(Handle.i, Col.i)` | ดึงค่าจำนวนเต็ม คืน 0 ถ้าเป็น NULL |
| `DB::GetFloat(Handle.i, Col.i)` | ดึงค่า float คืน 0.0 ถ้าเป็น NULL |

### Parameter Binding

| Procedure | คำอธิบาย |
|---|---|
| `DB::BindStr(Handle.i, Index.i, Value.s)` | ผูกสตริงกับ placeholder `?` (นับจาก 0) |
| `DB::BindInt(Handle.i, Index.i, Value.i)` | ผูกจำนวนเต็มกับ placeholder `?` (นับจาก 0) |

Binding ต้องทำก่อนการเรียก `Exec` หรือ `Query` ที่ใช้ placeholder นั้น

### Migration

| Procedure | คำอธิบาย |
|---|---|
| `DB::AddMigration(Version.i, SQL.s)` | ลงทะเบียน migration |
| `DB::Migrate(Handle.i)` | ใช้ migration ที่รอดำเนินการทั้งหมด (idempotent) |
| `DB::ResetMigrations()` | ล้าง migration ที่ลงทะเบียน (สำหรับการแยก test ออกจากกัน) |

`Migrate` สร้างตาราง tracking `puresimple_migrations` ในครั้งแรก จากนั้นใช้ migration แต่ละตัวที่ยังไม่เคยบันทึก version number การรัน `Migrate` สองครั้งปลอดภัย Migration รันตามลำดับที่ลงทะเบียน

---

## ข.10 DBConnect Module (Multi-Driver Factory)

**ไฟล์:** `src/DB/Connect.pbi`

DBConnect module ให้ connection factory แบบ DSN-based รองรับ SQLite, PostgreSQL และ MySQL handle ทั้งหมดที่คืนจาก `DBConnect::Open` ใช้ร่วมกับ procedure ใน `DB::*` ได้

### Procedure

| Procedure | คำอธิบาย |
|---|---|
| `DBConnect::Open(DSN.s)` | Parse DSN, เปิดใช้ driver, เปิด connection คืน handle |
| `DBConnect::OpenFromConfig()` | อ่าน `DB_DSN` จาก config (ค่าเริ่มต้น `"sqlite::memory:"`) |
| `DBConnect::Driver(DSN.s)` | ตรวจหา driver จาก DSN prefix คืน driver constant |
| `DBConnect::ConnStr(DSN.s)` | แปลง DSN แบบ URL เป็นรูปแบบ `key=value` (สำหรับ PostgreSQL/MySQL) |

### Driver Constant

| ค่าคงที่ | ค่า | DSN Prefix |
|---|---|---|
| `DBConnect::#Driver_SQLite` | 0 | `sqlite:` |
| `DBConnect::#Driver_Postgres` | 1 | `postgres://` หรือ `postgresql://` |
| `DBConnect::#Driver_MySQL` | 2 | `mysql://` |
| `DBConnect::#Driver_Unknown` | -1 | อื่นๆ |

### ตัวอย่าง DSN

```
sqlite::memory:
sqlite:data/app.db
postgres://user:pass@host:5432/mydb
mysql://user:pass@host:3306/mydb
```

### ConnStr Conversion

```
Input:  postgres://alice:s3cr3t@db.host.io:5432/myapp
Output: host=db.host.io port=5432 dbname=myapp
```

---

## ข.11 Config Module

**ไฟล์:** `src/Config.pbi`

Config module โหลดไฟล์ `.env` และให้บริการ key/value configuration store ขณะ runtime

### Procedure

| Procedure | คำอธิบาย |
|---|---|
| `Config::Load(Path.s)` | โหลดไฟล์ `.env` คืน `#True` เมื่อสำเร็จ, `#False` ถ้าไม่พบ |
| `Config::Get(Key.s)` | ดึงค่า config คืน `""` ถ้าไม่ได้ตั้งไว้ |
| `Config::Get(Key.s, Default.s)` | ดึงค่า config พร้อม fallback |
| `Config::GetInt(Key.s, Default.i)` | ดึงค่า config แบบจำนวนเต็ม (ผ่าน `Val()`) |
| `Config::Has(Key.s)` | คืน `#True` ถ้า key มีอยู่ |
| `Config::Set(Key.s, Value.s)` | ตั้งค่าหรือเขียนทับ config ขณะ runtime |
| `Config::Reset()` | ล้างค่า config ทั้งหมด (สำหรับการแยก test ออกจากกัน) |

### รูปแบบไฟล์ `.env`

```
# ความคิดเห็นขึ้นต้นด้วย #
PORT=8080
MODE=release
APP_NAME=MyApp
DB_PATH=data/app.db
EMPTY_VALUE=
```

กฎ:
- แต่ละบรรทัดแบ่งที่ `=` ตัวแรก ตัด whitespace ออก
- บรรทัดที่ขึ้นต้นด้วย `#` และบรรทัดว่างจะถูกข้าม
- Key มีความต่างของตัวพิมพ์ใหญ่-เล็ก (case-sensitive)
- โหลดซ้ำจะเขียนทับ key ที่มีอยู่

---

## ข.12 Log Module

**ไฟล์:** `src/Log.pbi`

Log module ให้บริการบันทึก log แบบมีระดับ (leveled logging) พร้อมตัวเลือกส่ง output ไปยังไฟล์

### ระดับ Log

| ค่าคงที่ | ค่า | การใช้งาน |
|---|---|---|
| `Log::#LevelDebug` | 0 | Output แบบละเอียดสำหรับ development |
| `Log::#LevelInfo` | 1 | ข้อความการทำงานปกติ (ค่าเริ่มต้น) |
| `Log::#LevelWarn` | 2 | ปัญหาที่แก้ไขได้ |
| `Log::#LevelError` | 3 | ความล้มเหลวที่ต้องให้ความสนใจ |

### การตั้งค่า

| Procedure | คำอธิบาย |
|---|---|
| `Log::SetLevel(Level.i)` | กำหนดระดับ log ขั้นต่ำ ข้อความที่ต่ำกว่าระดับนี้จะถูกระงับ |
| `Log::SetOutput(Path.s)` | เขียน log ลงไฟล์ (append mode) ส่ง `""` เพื่อไปยัง stdout |

### การเขียนข้อความ

| Procedure | คำอธิบาย |
|---|---|
| `Log::Dbg(Message.s)` | เขียนข้อความ `[DEBUG]` |
| `Log::Info(Message.s)` | เขียนข้อความ `[INFO]` |
| `Log::Warn(Message.s)` | เขียนข้อความ `[WARN]` |
| `Log::Error(Message.s)` | เขียนข้อความ `[ERROR]` |

**หมายเหตุ:** procedure debug ใช้ชื่อ `Log::Dbg` (ไม่ใช่ `Log::Debug`) เพราะ `Debug` เป็น reserved keyword ของ PureBasic

### รูปแบบ Output

```
[2026-03-20 14:32:01] [INFO]  Server starting on :8080
[2026-03-20 14:32:05] [WARN]  Rate limit approaching
[2026-03-20 14:32:09] [ERROR] Database connection lost
```

เมื่อ `SetOutput` ได้รับ path ที่ไม่ว่าง ไฟล์จะถูกเปิดและปิดทุกครั้งที่เขียน (ปลอดภัยสำหรับการใช้งานแบบ single-thread) ถ้าไฟล์มีอยู่แล้วจะ append, ถ้าไม่มีจะสร้างใหม่

---

## ข.13 RequestContext Field Reference

Structure `RequestContext` นิยามไว้ใน `src/Types.pbi` ทุก handler และ middleware ได้รับ pointer ไปยัง structure นี้ เข้าถึง field ด้วย operator `\`: `*C\Method`, `*C\StatusCode` ฯลฯ

### Request Field (เติมโดย HTTP server dispatch)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `Method` | `.s` | HTTP method: `"GET"`, `"POST"`, `"PUT"`, `"PATCH"`, `"DELETE"` |
| `Path` | `.s` | URL path เช่น `"/api/users/42"` |
| `RawQuery` | `.s` | Query string เช่น `"page=1&limit=10"` |
| `Body` | `.s` | Raw request body (สำหรับ JSON binding และ form parsing) |
| `ClientIP` | `.s` | Remote IP address |
| `Cookie` | `.s` | Raw header `Cookie` เช่น `"session=abc; foo=bar"` |
| `Authorization` | `.s` | Raw header `Authorization` เช่น `"Basic dXNlcjpwYXNz"` |

### Response Field (กำหนดโดย rendering procedure)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `StatusCode` | `.i` | HTTP status code ที่จะส่ง (200, 404, 500 ฯลฯ) |
| `ResponseBody` | `.s` | เนื้อหา response |
| `ContentType` | `.s` | MIME type: `"application/json"`, `"text/html"`, `"text/plain"` |
| `Location` | `.s` | Redirect URL (กำหนดโดย `Rendering::Redirect`, อ่านโดย HTTP server) |
| `SetCookies` | `.s` | `Set-Cookie` directive ที่สะสมไว้ คั่นด้วย Chr(10) |

### Handler Chain Field (จัดการโดย Context module)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `ContextID` | `.i` | Slot index ใน global handler chain array |
| `HandlerIndex` | `.i` | ตำแหน่งปัจจุบันใน handler chain |
| `Aborted` | `.i` | `#True` ถ้าเคยเรียก `Ctx::Abort` |

### Route Parameter Field (เติมโดย Router::Match)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `ParamKeys` | `.s` | รายการชื่อ parameter คั่นด้วย Chr(9) |
| `ParamVals` | `.s` | รายการค่า parameter คั่นด้วย Chr(9) |

### Query String Cache Field (เติมโดย Binding::Query)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `QueryKeys` | `.s` | รายการชื่อ query parameter คั่นด้วย Chr(9) |
| `QueryVals` | `.s` | รายการค่า query parameter คั่นด้วย Chr(9) |

### KV Store Field (ใช้โดย Ctx::Set / Ctx::Get)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `StoreKeys` | `.s` | รายการ store key คั่นด้วย Chr(9) |
| `StoreVals` | `.s` | รายการ store value คั่นด้วย Chr(9) |

### JSON Binding Field

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `JSONHandle` | `.i` | Handle ของ JSON object ที่ parse แล้ว (จาก `Binding::BindJSON`) |

### Session Field (เติมโดย Session middleware)

| Field | ชนิด | คำอธิบาย |
|---|---|---|
| `SessionID` | `.s` | Session ID ปัจจุบัน |
| `SessionKeys` | `.s` | Session KV key คั่นด้วย Chr(9) |
| `SessionVals` | `.s` | Session KV value คั่นด้วย Chr(9) |

---

## ข.14 สรุป Request Lifecycle

```
HTTP request เข้า PureSimpleHTTPServer
  -> เรียก dispatch callback พร้อม method + path + headers + body แบบ raw
  -> Router::Match(method, path) -> route handler + params
  -> Engine::CombineHandlers หรือ Group::CombineHandlers
       สร้าง handler array แบบ flat: [global MW...] [group MW...] [route handler]
  -> Ctx::Init เติม RequestContext
  -> Ctx::Dispatch เรียก handlers[0]
  -> middleware แต่ละตัวเรียก Ctx::Advance เพื่อส่งต่อการควบคุมไปยัง handler ถัดไป
  -> Route handler เขียน response ผ่าน Rendering::*
  -> PureSimpleHTTPServer ส่ง StatusCode + ContentType + ResponseBody
```

---

## ข.15 Structure ที่เกี่ยวข้อง

### RouterEngine

```purebasic
Structure RouterEngine
  Port.i              ; port ที่จะ listen
  Running.i           ; #True เมื่อเรียก Run() แล้ว
EndStructure
```

### PS_RouterGroup

```purebasic
Structure PS_RouterGroup
  Prefix.s            ; path prefix ที่นำหน้าทุก route
  MW.i[32]            ; middleware ระดับ group (สูงสุด 32)
  MWCount.i           ; จำนวน middleware ระดับ group ที่ลงทะเบียน
EndStructure
```
