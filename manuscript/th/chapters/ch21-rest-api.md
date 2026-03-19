# บทที่ 21: สร้าง REST API — รายการสิ่งที่ต้องทำ

*API แรกของคุณ ตั้งแต่ scaffold จนถึง curl ในบทเดียว*

---

**หลังจากอ่านบทนี้จบ คุณจะสามารถ:**

- สร้างโครงสร้างโปรเจกต์ PureSimple ใหม่ด้วย `scripts/new-project.sh`
- พัฒนา JSON CRUD API แบบครบวงจรโดยใช้การจัดเก็บข้อมูลในหน่วยความจำ
- ตรวจสอบความถูกต้องของข้อมูลที่รับเข้ามา และส่งคืนการตอบกลับข้อผิดพลาดในรูปแบบที่มีโครงสร้างชัดเจน
- ทดสอบทุก endpoint ด้วย `curl` จาก command line
- เพิ่ม authentication middleware เพื่อป้องกัน write operation

---

## 21.1 การสร้างโครงสร้างโปรเจกต์

ทุกโปรเจกต์ก่อสร้างต้องเริ่มจากรากฐาน เช่นเดียวกับทุกโปรเจกต์ PureSimple ที่ต้องเริ่มจาก scaffold framework มาพร้อม shell script ที่สร้างโปรเจกต์พร้อม compile ได้ในคำสั่งเดียว ไม่มี generator ที่ต้องดึง dependency ครึ่งอินเทอร์เน็ต ไม่มีไฟล์ YAML configuration เป็นแค่ bash script ที่เขียน `main.pb`, `.env`, `.gitignore` และ starter template ให้คุณ

ตัวอย่างที่ 21.1 — สร้างโครงสร้างโปรเจกต์ใหม่

```bash
./scripts/new-project.sh todo
```

คำสั่งนั้นสร้างโครงสร้างต่อไปนี้:

```
todo/
  main.pb            -- entry point พร้อม routes, config, และ logging
  .env               -- environment variables สำหรับ local (ไม่ commit)
  .env.example       -- ตัวอย่างที่มีคำอธิบาย สำหรับ version control
  .gitignore         -- ยกเว้นไฟล์ที่ compile แล้วและ .env
  templates/
    index.html       -- starter Jinja HTML template
  static/            -- placeholder สำหรับ static assets
```

`main.pb` ที่ถูกสร้างขึ้นนั้น include PureSimple ไว้แล้ว โหลดไฟล์ `.env` ลงทะเบียน Logger และ Recovery middleware และเชื่อมต่อ health check endpoint ให้เรียบร้อย คุณได้ web app ที่ compile และรันได้ก่อนที่จะเขียนโค้ดแอปพลิเคชันแม้แต่บรรทัดเดียว

```purebasic
; ตัวอย่างที่ 21.2 -- main.pb ที่ถูกสร้างขึ้น (จาก new-project.sh)
EnableExplicit

XIncludeFile "../../src/PureSimple.pb"

; โหลด .env configuration
If Config::Load(".env")
  Log::Info(".env loaded")
Else
  Log::Warn("No .env file found -- using built-in defaults")
EndIf

Protected port.i = Config::GetInt("PORT", 8080)
Protected mode.s = Config::Get("MODE", "debug")
Engine::SetMode(mode)

; ---- Global middleware ----
Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

; ---- Routes ----
Engine::GET("/", @IndexHandler())
Engine::GET("/health", @HealthHandler())

Log::Info("Starting todo on :" + Str(port) +
          " [" + Engine::Mode() + "]")
Engine::Run(port)
```

script เขียน path ของ `XIncludeFile` แบบ relative ตามตำแหน่งที่วางโปรเจกต์ใหม่ ถ้าไดเรกทอรี `todo/` อยู่ใน PureSimple repo ภายใต้ `examples/` path จะเป็น `../../src/PureSimple.pb` ถ้าคุณวางไว้เป็นไดเรกทอรีคู่กัน script จะคำนวณ relative path ด้วย Python's `os.path.relpath` ให้อัตโนมัติ นี่คือสิ่งที่คุณไม่ต้องเสียเวลาจัดการเอง

> **เคล็ดลับ:** ไฟล์ `.env.example` มีไว้เพื่อ commit ลง version control ส่วน `.env` ไม่ควร commit ลงไป แนวทางนี้เป็นไปตามหลักการ twelve-factor app ที่อธิบายไว้ในบทที่ 18 ตัวคุณเองในอนาคตจะขอบคุณตัวเองเมื่อ deploy ขึ้น server แล้วจำไม่ได้ว่าแอปต้องการ environment variable อะไรบ้าง

---

## 21.2 Data Model: การจัดเก็บข้อมูลในหน่วยความจำ

REST API ต้องการข้อมูล สำหรับรายการสิ่งที่ต้องทำ data model นั้นเรียบง่ายจนน่าขำ: แต่ละรายการมี ID, title และ done flag ในบทนี้ยังไม่มีฐานข้อมูล — เราเก็บทุกอย่างไว้ใน linked list ของ PureBasic ซึ่งเป็นการตั้งใจ เป้าหมายคือเรียนรู้เรื่อง routing, binding และ rendering โดยไม่ต้องสนใจ SQL บทที่ 13 จะพูดถึงฐานข้อมูล และบทที่ 22 จะรวมทั้งสองอย่างเข้าด้วยกัน

```purebasic
; ตัวอย่างที่ 21.3 -- In-memory to-do store
Structure TodoItem
  id.i
  title.s
  done.i
EndStructure

Global NewList _Todos.TodoItem()
Global _NextID.i = 1
```

ตัวนับ `_NextID` จะเพิ่มขึ้นทุกครั้งที่มีรายการใหม่ นี่ไม่ใช่วิธีสร้าง ID ในระบบ production จริง — ฐานข้อมูลจะจัดการเรื่องนี้ด้วย `AUTOINCREMENT` แต่สำหรับ demo ที่เก็บข้อมูลในหน่วยความจำ มันใช้ได้ผล และต่างจาก UUID ตรงที่คุณสามารถพิมพ์ `curl localhost:8080/todos/3` ได้เลยโดยไม่ต้องก็อป-เพสต์ string ยาว 36 ตัวอักษร

ถ้า restart แอป ข้อมูลทั้งหมดจะหายไป การจัดเก็บในหน่วยความจำมีอายุเท่ากับ process นั้น ถือเป็นข้อดีสำหรับการเรียนรู้ แต่เป็นข้อเสียสำหรับ production ยอมรับข้อแลกเปลี่ยนนี้แล้วก้าวต่อไป

> **เปรียบเทียบ:** ใน Go's Gin framework คุณมักจะเก็บข้อมูลในหน่วยความจำใน `sync.Map` เพื่อความปลอดภัยของ thread HTTP server ของ PureSimple เป็น single-threaded ตามค่าเริ่มต้น ดังนั้น `NewList` ธรรมดาก็ใช้ได้ ถ้าคุณเปิดใช้งาน threading ด้วย `-t` คุณจะต้องเพิ่มการป้องกันด้วย mutex

---

## 21.3 JSON Helpers

ก่อนที่จะเขียน handler เราต้องมีวิธีแปลง `TodoItem` เป็น JSON PureBasic มี built-in JSON library แต่สำหรับ structure ที่เรียบง่าย การสร้าง string ด้วยตัวเองมักจะชัดเจนและเร็วกว่า แอป to-do ใช้ helper procedure สองตัว: ตัวหนึ่งสำหรับรายการเดียว และอีกตัวสำหรับรายการทั้งหมด

```purebasic
; ตัวอย่างที่ 21.4 -- JSON serialization helpers
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
```

สังเกตว่า syntax `~"\"id\":"` — prefix `~` เปิดใช้งาน escape sequence ทำให้ `\"` กลายเป็น double quote จริงๆ ถ้าไม่ใส่ prefix PureBasic จะตีความ `"` เป็นตัวสิ้นสุด string และ compiler จะแจ้ง error นี่คือสิ่งที่เรียนรู้ครั้งเดียวแล้วจำไปตลอด ส่วนใหญ่เพราะ error message ไม่ค่อยบอกสาเหตุที่แท้จริง

procedure `AllTodosJSON` ใช้ flag `first` เพื่อหลีกเลี่ยง comma ที่นำหน้า คุณอาจสร้าง string แล้วตัด comma ท้ายออก หรือจะ join ด้วย separator ก็ได้ PureBasic ไม่มี `join()` แบบ built-in สำหรับ list ดังนั้น pattern การใช้ flag จึงเป็น idiomatic pattern ที่ใช้กันทั่วไป และมันก็ตรงกับวิธีที่ `json.Marshal` ของ Go จัดการกับ array ภายใน เพียงแต่มี layer of abstraction น้อยกว่า

> **ข้อควรระวังใน PureBasic:** การเรียก `Chr(34)` สร้างตัวอักษร double-quote คุณอาจใช้ `~"\""` ภายใน escape-enabled string ก็ได้ แต่การผสมระหว่าง `~""` string กับ `Chr()` call เป็น pattern ที่พบบ่อยเมื่อ quoting มีความซับซ้อน เลือกแบบที่ทำให้คุณไม่ปวดหัวก็พอ

---

## 21.4 CRUD Handlers

REST API ทำตาม pattern ที่คาดเดาได้: Create, Read, Update, Delete แอป to-do ใช้สี่จากห้า operation มาตรฐาน (ข้าม Update ไปก่อนเพื่อความกระชับ — การเพิ่ม `PUT /todos/:id` handler เป็นแบบฝึกหัดสำหรับทบทวน)

handler แต่ละตัวเป็น procedure ที่รับ pointer `*C.RequestContext` นี่คือ handler signature สากลใน PureSimple ซึ่งเหมือนกับ middleware signature framework ไม่ได้แยกความแตกต่างระหว่างทั้งสอง handler คือแค่ฟังก์ชันสุดท้ายในห่วงโซ่การทำงาน

```purebasic
; ตัวอย่างที่ 21.5 -- แสดงรายการ to-do ทั้งหมด (GET /todos)
Procedure ListTodos(*C.RequestContext)
  Rendering::JSON(*C, AllTodosJSON())
EndProcedure
```

บรรทัดเดียว procedure `Rendering::JSON` ตั้งค่า header `Content-Type` เป็น `application/json` เขียน body และตั้งค่า status code เป็น 200 ถ้าต้องการ status code อื่น ให้ส่งเป็น argument ที่สาม

```purebasic
; ตัวอย่างที่ 21.6 -- สร้าง to-do (POST /todos)
Procedure CreateTodo(*C.RequestContext)
  Binding::BindJSON(*C)
  Protected title.s = Binding::JSONString(*C, "title")
  Binding::ReleaseJSON(*C)
  If title = ""
    Ctx::AbortWithError(*C, 400,
      ~"{\"error\":\"title is required\"}")
    ProcedureReturn
  EndIf
  AddElement(_Todos())
  _Todos()\id    = _NextID
  _Todos()\title = title
  _Todos()\done  = #False
  _NextID + 1
  Rendering::JSON(*C, TodoJSON(_Todos()), 201)
EndProcedure
```

handler นี้แสดงให้เห็น request binding cycle ทั้งหมดจากบทที่ 8: เรียก `Binding::BindJSON` เพื่อ parse body ดึง field ด้วย `Binding::JSONString` แล้ว release JSON ที่ parse แล้วด้วย `Binding::ReleaseJSON` ขั้นตอน release นั้นไม่ใช่ option JSON parser ของ PureBasic จัดสรรหน่วยความจำ และ `ReleaseJSON` จะคืนหน่วยความจำนั้น ถ้าข้ามขั้นตอนนี้จะเกิด memory leak ทุกครั้งที่มี request สำหรับแอป to-do ที่รับ request สิบครั้งต่อวัน คุณอาจไม่สังเกตเห็น แต่สำหรับ production API คุณจะรู้สึกได้แน่นอน

การตรวจสอบความถูกต้องมีน้อยแต่ครบถ้วน: ถ้า title ว่างเปล่า เราจะ abort พร้อม status 400 และ JSON error body `Ctx::AbortWithError` ทั้งตั้งค่า response และหยุด handler chain — ไม่มี middleware ใดจะทำงานหลังจากนั้น

เมื่อสำเร็จ เราส่งคืน 201 Created พร้อม JSON ของรายการใหม่ นี่ตาม REST convention ที่ว่า POST ควรส่งคืน resource ที่ถูกสร้างขึ้น

```purebasic
; ตัวอย่างที่ 21.7 -- ดึงและลบ to-do รายการเดียว
Procedure GetTodo(*C.RequestContext)
  Protected id.i = Val(Binding::Param(*C, "id"))
  ForEach _Todos()
    If _Todos()\id = id
      Rendering::JSON(*C, TodoJSON(_Todos()))
      ProcedureReturn
    EndIf
  Next
  Ctx::AbortWithError(*C, 404,
    ~"{\"error\":\"not found\"}")
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
  Ctx::AbortWithError(*C, 404,
    ~"{\"error\":\"not found\"}")
EndProcedure
```

ทั้งสอง handler ดึง `:id` route parameter ด้วย `Binding::Param` และแปลงเป็น integer ด้วย `Val()` loop `ForEach` ทำการค้นหาแบบ linear scan ผ่าน linked list สำหรับรายการ to-do สามอย่าง ไม่มีปัญหา สำหรับสามพัน คุณต้องการ map สำหรับสามหมื่น คุณต้องการฐานข้อมูล รู้จักปริมาณข้อมูลของคุณ

delete handler ส่งคืน 204 No Content — วิธี HTTP ในการบอกว่า "ทำเสร็จแล้ว และไม่มีอะไรจะบอกเพิ่มเติม" `Rendering::Status` ตั้งค่า status code โดยไม่เขียน body

> **คำเตือน:** `Val()` คืนค่า 0 สำหรับ string ที่ไม่ใช่ตัวเลข ถ้าใครส่ง `GET /todos/abc` ค่า `id` จะเป็น 0 ซึ่งไม่ตรงกับรายการใดเลย และพวกเขาจะได้รับ 404 นี่เป็นพฤติกรรมที่ยอมรับได้ แต่ใน production API คุณอาจต้องการตรวจสอบรูปแบบ parameter และส่งคืน 400 อย่างชัดเจน

---

## 21.5 การลงทะเบียน Route และการเริ่มต้นแอป

เมื่อเขียน handler เสร็จแล้ว การเชื่อมต่อกับ route ใช้แค่ห้าบรรทัด:

```purebasic
; ตัวอย่างที่ 21.8 -- การลงทะเบียน route และการเริ่มต้นแอป
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

Log::Info("Todo API starting on :" + Str(port) +
          " [" + Engine::Mode() + "]")
Engine::Run(port)
```

operator `@` ดึง address ของ procedure PureSimple เก็บ address เหล่านี้ใน route table และเรียกผ่าน function pointer แบบ `Prototype.i` เมื่อ request ตรงกัน นี่คือกลไกเดียวกับที่อธิบายในบทที่ 5 (Routing) และบทที่ 6 (The Request Context)

Logger และ Recovery middleware ทำงานกับทุก request ตามลำดับนั้น Logger บันทึก method, path, status code และ response time Recovery ดักจับ runtime error และส่งคืน response 500 แทนการ crash process middleware ทั้งสองนี้คือ safety net ขั้นต่ำสำหรับแอปพลิเคชัน PureSimple ทุกตัว

---

## 21.6 ทดสอบด้วย curl

API กำลังทำงานอยู่ ถึงเวลาทดสอบ `curl` คือเครื่องมือทดสอบ API สากล — มาพร้อมกับทุกระบบ macOS และ Linux และแสดงผลสิ่งที่ server ส่งมาได้อย่างตรงไปตรงมา

ตัวอย่างที่ 21.9 — ทดสอบ to-do API ด้วย curl

```bash
# Health check
curl http://localhost:8080/health
# {"status":"ok"}

# สร้าง to-do สองรายการ
curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Write Chapter 21"}'
# {"id":1,"title":"Write Chapter 21","done":false}

curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Review Chapter 21"}'
# {"id":2,"title":"Review Chapter 21","done":false}

# แสดงรายการทั้งหมด
curl http://localhost:8080/todos
# [{"id":1,"title":"Write Chapter 21","done":false},
#  {"id":2,"title":"Review Chapter 21","done":false}]

# ดึงรายการเดียว
curl http://localhost:8080/todos/1
# {"id":1,"title":"Write Chapter 21","done":false}

# ลบรายการ
curl -X DELETE http://localhost:8080/todos/1
# (204 No Content -- response ว่างเปล่า)

# ตรวจสอบว่าถูกลบแล้ว
curl http://localhost:8080/todos/1
# {"error":"not found"}
```

การเรียก `curl` แต่ละครั้งคือ HTTP request-response cycle ที่สมบูรณ์ Logger middleware จะพิมพ์บรรทัดสำหรับแต่ละครั้ง ทำให้คุณดู terminal ได้ขณะทดสอบ ถ้ามีข้อผิดพลาด Recovery middleware จะดักจับ error และส่งคืน JSON แทนการปล่อยให้ process crash

นี่คือหน้าตาของ REST API ก่อนที่ framework ต่างๆ จะทำให้ทุกคนคิดว่ามันต้องการ dependency 200 ตัว build step และ Docker container ผ่าน PureBasic เจ็ดสิบบรรทัด compile ได้ในไม่ถึงวินาที serve JSON จากหน่วยความจำด้วยความเร็วที่ Node.js server ของคุณน่าจะอิจฉา

> **เคล็ดลับ:** ถ้าต้องการ format ผลลัพธ์ JSON ให้อ่านง่าย ให้ pipe ผ่าน `jq`: `curl http://localhost:8080/todos | jq .` เครื่องมือ `jq` ไม่ได้ติดตั้งมาให้ในทุกระบบ แต่มีผ่าน package manager ทุกตัว และน่าขำที่มันก็เป็น binary ตัวเดียวเช่นกัน

---

## 21.7 การเพิ่ม Authentication

to-do API ที่เขียนมานั้นเปิดโล่งสมบูรณ์ ใครก็ตามที่เข้าถึง port ได้ก็สร้างและลบรายการได้ สำหรับ demo ในเครื่อง local ไม่มีปัญหา แต่สำหรับสถานการณ์อื่น คุณต้องการ authentication

PureSimple มี BasicAuth middleware พร้อมใช้งาน (บทที่ 16) การเพิ่มเข้าไปใน to-do API ใช้แค่สามบรรทัด แต่แทนที่จะป้องกันทุก route เราจะป้องกันเฉพาะ write operation — POST และ DELETE — โดยการสร้าง route group

```purebasic
; ตัวอย่างที่ 21.10 -- เพิ่ม BasicAuth ให้กับ write operation
BasicAuth::SetCredentials("admin", "secret")

; Public routes (ไม่ต้องการ auth)
Engine::GET("/todos",     @ListTodos())
Engine::GET("/todos/:id", @GetTodo())
Engine::GET("/health",    @HealthCheck())

; Protected routes (ต้องการ BasicAuth)
Define writeGrp.PS_RouterGroup
Group::Init(@writeGrp, "/todos")
Group::Use(@writeGrp, @_BasicAuthMW())
Group::POST(@writeGrp, "",     @CreateTodo())
Group::DELETE(@writeGrp, "/:id", @DeleteTodo())
```

ตอนนี้ `GET /todos` และ `GET /todos/:id` ทำงานได้โดยไม่ต้องมี credentials แต่ `POST /todos` และ `DELETE /todos/:id` ต้องการ header `Authorization` ที่ถูกต้อง นี่คือ route group pattern จากบทที่ 10 ที่นำมาแก้ปัญหาจริง: ความต้องการด้านความปลอดภัยที่แตกต่างกันสำหรับ operation ต่างกัน

ทดสอบ:

```bash
# ยังใช้ได้โดยไม่ต้อง auth
curl http://localhost:8080/todos

# ตอนนี้ต้องการ auth
curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Test auth"}'
# 401 Unauthorized

# ด้วย credentials
curl -X POST http://localhost:8080/todos \
  -u admin:secret \
  -H "Content-Type: application/json" \
  -d '{"title":"Test auth"}'
# {"id":1,"title":"Test auth","done":false}
```

flag `-u` ใน curl ส่ง username และ password เป็น Base64-encoded `Authorization: Basic` header browser ก็ทำแบบเดียวกันเมื่อแสดง login dialog แบบ built-in อันน่าเกลียดนั้น

---

## สรุป

REST API ใน PureSimple คือชุดของ handler procedure ที่ลงทะเบียนกับ HTTP method และ path combination ข้อมูล request เข้ามาผ่าน `Binding::BindJSON` และ `Binding::Param` การตอบกลับออกไปผ่าน `Rendering::JSON` และ `Rendering::Status` script scaffold ลดงาน boilerplate Authentication คือ middleware ที่ใช้กับ route group to-do API ทั้งหมด compile เป็น binary ตัวเดียวขนาดไม่เกิน 2 MB

## สิ่งสำคัญที่ควรจำ

- ใช้ `scripts/new-project.sh` เพื่อสร้างโครงสร้างโปรเจกต์พร้อม config, templates และ middleware ที่เชื่อมต่อไว้แล้ว
- เรียก `Binding::ReleaseJSON` เสมอหลังจากดึง field จาก JSON request body — JSON parser ของ PureBasic จัดสรรหน่วยความจำที่ต้องคืนให้ระบบ
- ส่งคืน HTTP status code ที่เหมาะสม: 200 สำหรับความสำเร็จ, 201 สำหรับการสร้าง, 204 สำหรับการลบ, 400 สำหรับ input ที่ไม่ถูกต้อง, 404 สำหรับ resource ที่ไม่พบ

## คำถามทบทวน

1. ทำไม handler `CreateTodo` ถึงเรียก `Binding::ReleaseJSON` แม้ว่า request จะมีขนาดเล็ก? จะเกิดอะไรขึ้นถ้าข้ามขั้นตอนนี้?
2. แอป to-do ใช้ linked list (`NewList`) สำหรับการจัดเก็บข้อมูล คุณจะเปลี่ยนไปใช้โครงสร้างข้อมูลแบบไหนเพื่อให้ค้นหาด้วย ID ได้ใน O(1) และ keyword ของ PureBasic ที่ใช้สร้างมันคืออะไร?
3. *ลองทำ:* เพิ่ม `PUT /todos/:id` handler ที่อัปเดต field `title` และ `done` ของ to-do ที่มีอยู่แล้ว ทดสอบด้วย `curl -X PUT`
