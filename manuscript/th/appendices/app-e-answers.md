# ภาคผนวก จ: เฉลยคำถามทบทวน

ภาคผนวกนี้รวบรวมเฉลยคำถามทบทวนทั้งหมดจากบทที่ 1 ถึงบทที่ 23 คำถามเชิงแนวคิดจะตอบแบบย่อหน้า คำถาม "ลองทำ" จะมีโค้ดที่สมบูรณ์และ compile ได้จริง

---

## บทที่ 1: ทำไมถึงใช้ PureBasic สำหรับเว็บ?

### คำถามที่ 1

**ถาม:** ระบุคลังโค้ดสามตัวในระบบนิเวศ PureSimple และอธิบายหน้าที่ของแต่ละตัว

**ตอบ:** คลังโค้ดทั้งสามคือ **PureSimpleHTTPServer**, **PureSimple** และ **PureJinja** PureSimpleHTTPServer เป็นตัวรับฟัง HTTP/1.1 ที่ดูแลการทำงานระดับ socket ระดับต่ำ, TLS termination, การบีบอัด gzip และการส่งไฟล์ static PureSimple คือชั้น web framework ที่ให้บริการ routing (ผ่าน radix trie), middleware chaining, การจัดการ request context, request binding, response rendering, database integration, session, authentication และ configuration PureJinja คือ template engine ที่เข้ากันได้กับ Jinja มี filter 37 รายการ (34 implementation ไม่ซ้ำ บวก alias 3 ตัว) ที่ compile template ด้วยความเร็วระดับ C คลังโค้ดทั้งสามรวม compile เป็น native binary ไฟล์เดียวผ่านกลไก `XIncludeFile` ของ PureBasic ไม่มีการ link ขณะ runtime, ไม่มี package manager และไม่มี dependency chain ในการ deploy

### คำถามที่ 2

**ถาม:** ข้อได้เปรียบของการ compile web app เป็น binary ไฟล์เดียวเทียบกับการ deploy ภาษา interpreted คืออะไร?

**ตอบ:** binary ที่ compile แล้วไฟล์เดียวขจัดปัญหาการ deploy ไปได้ทั้งหมวด ไม่ต้องติดตั้ง runtime บน server, ไม่มีปัญหา version ไม่ตรงกันระหว่าง development และ production, ไม่มีไดเรกทอรี `node_modules` ที่ต้องโอนย้าย, ไม่ต้องตั้งค่า virtual environment และไม่มี overhead จากการเริ่ม interpreter คุณแค่คัดลอกไฟล์เดียว ให้สิทธิ์รัน แล้วก็รันได้เลย binary เริ่มต้นใน millisecond ไม่ใช่ second ใช้หน่วยความจำน้อยกว่าเพราะไม่มี interpreter หรือ garbage collector ทำงานควบคู่กัน และไม่พังเพราะ system update เปลี่ยน shared library script deploy ลดเหลือเพียง `scp binary server:path && ssh server restart` การ rollback ก็ง่ายพอๆ กัน: แค่สลับกลับไปใช้ binary ก่อนหน้า

### คำถามที่ 3 (ลองทำ)

**ถาม:** Clone คลังโค้ดทั้งสาม compile แล้วรัน Hello World example

**ตอบ:**

```bash
# Clone คลังโค้ดทั้งสามเรียงกัน
cd ~/projects
git clone https://github.com/Jedt3D/PureSimpleHTTPServer
git clone https://github.com/Jedt3D/pure_jinja
git clone https://github.com/Jedt3D/PureSimple

# กำหนดเส้นทาง compiler (macOS)
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"

# Compile ตัวอย่าง Hello World
cd PureSimple
$PUREBASIC_HOME/compilers/pbcompiler examples/hello_world/main.pb -cl -o hello_world

# รันโปรแกรม
./hello_world
```

เปิดเบราว์เซอร์ไปที่ `http://localhost:8080` เพื่อดู response

---

## บทที่ 2: ภาษา PureBasic

### คำถามที่ 1

**ถาม:** ทำไม `Dim a(5)` จึงสร้างหกองค์ประกอบ และจะสร้างห้าองค์ประกอบพอดีได้อย่างไร?

**ตอบ:** `Dim a(N)` ของ PureBasic สร้างองค์ประกอบที่มี index ตั้งแต่ 0 ถึง N รวมทั้งสิ้น N+1 องค์ประกอบ นี่คือแนวทาง "maximum index" ไม่ใช่แนวทาง "count" `Dim a(5)` จึงสร้าง index 0, 1, 2, 3, 4 และ 5 รวมหกองค์ประกอบ หากต้องการห้าองค์ประกอบพอดี (index 0 ถึง 4) ให้เขียน `Dim a(4)` แนวทางนี้ต่างจาก array ขนาดคงที่ภายใน structure ที่ `arr.i[5]` สร้างองค์ประกอบ 5 ตัวพอดี (index 0 ถึง 4) ทั้งสองแนวทางตรงข้ามกัน ซึ่งเป็นหนึ่งใน gotcha ที่พบบ่อยที่สุดของ PureBasic

### คำถามที่ 2

**ถาม:** อธิบายความต่างระหว่าง `IncludeFile` กับ `XIncludeFile`

**ตอบ:** `IncludeFile` include ไฟล์ต้นทางโดยไม่มีเงื่อนไขทุกครั้งที่ปรากฏ ถ้าสอง module ต่าง `IncludeFile "Types.pbi"` compiler จะประมวลผล `Types.pbi` สองครั้ง ทำให้เกิด error "structure already declared" และ "module already declared" `XIncludeFile` (ตัว "X" ย่อมาจาก "exclusive") ติดตามไฟล์ที่เคย include แล้วและข้ามไฟล์ที่เคยผ่านมาแล้วโดยอัตโนมัติ ทำให้ปลอดภัยสำหรับ dependency graph แบบ diamond ที่หลาย module ขึ้นอยู่กับ type definition เดียวกัน ทุกไฟล์ `.pbi` ใน PureSimple ใช้ `XIncludeFile` แต่เพียงอย่างเดียว

### คำถามที่ 3 (ลองทำ)

**ถาม:** เขียน module ที่เปิดเผย procedure `Greet(name.s)` ที่คืน `"Hello, " + name + "!"`

**ตอบ:**

```purebasic
; Listing E.1 -- Greet module
EnableExplicit

DeclareModule Greeter
  Declare.s Greet(name.s)
EndDeclareModule

Module Greeter
  Procedure.s Greet(name.s)
    ProcedureReturn "Hello, " + name + "!"
  EndProcedure
EndModule

; ทดสอบ
OpenConsole()
PrintN(Greeter::Greet("Alice"))   ; "Hello, Alice!"
PrintN(Greeter::Greet("World"))   ; "Hello, World!"
CloseConsole()
```

Compile แล้วรัน:

```bash
$PUREBASIC_HOME/compilers/pbcompiler greet.pb -cl -o greet
./greet
```

Output ที่คาดหวัง:

```
Hello, Alice!
Hello, World!
```

---

## บทที่ 3: Toolchain ของ PureBasic

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง `-cl` กับ compiler mode ปกติคืออะไร และทำไมจึงสำคัญสำหรับ web server?

**ตอบ:** flag `-cl` บอก PureBasic compiler ให้ผลิต console application หากไม่ใส่ compiler จะผลิต GUI application ที่เปิด window และส่ง output ไปยัง debug panel ของ IDE web server ต้องเขียนไปยัง stdout เพื่อ log, อ่านจาก stdin สำหรับ input และทำงานโดยไม่มี GUI โดยเฉพาะบน Linux server แบบ headless หากไม่ใช้ `-cl` การเรียก `OpenConsole()`, `PrintN()` และ `Input()` จะล้มเหลวแบบเงียบหรือทำงานผิดปกติ test runner ของ PureSimple ก็ต้องการ `-cl` เช่นกันเพราะพิมพ์ผลลัพธ์ test ไปยัง terminal binary ของ server และ binary ของ test ทุกตัวในเล่มนี้ compile ด้วย `-cl`

### คำถามที่ 2

**ถาม:** ทำไม PureSimple จึงใช้ `Check()` แทน `Assert()` built-in ของ PureBasic?

**ตอบ:** PureBasic 6.x มี macro `Assert()` และ `AssertString()` built-in (นิยามใน `pureunit.res`) ที่หยุดการทำงานเมื่อเกิด failure ครั้งแรก พฤติกรรมหยุดทันทีนี้ทำให้เห็น test ที่พังได้ครั้งละหนึ่งตัวเท่านั้นต่อการรัน ซึ่งทำให้ debug ช้าเมื่อหลาย test พังพร้อมกัน harness แบบกำหนดเองของ PureSimple ใช้ macro `Check()`, `CheckEqual()` และ `CheckStr()` ที่เพิ่มจำนวนผ่าน/ล้มเหลวแล้วดำเนินต่อไป เมื่อรันเสร็จ `PrintResults()` จะแสดงสรุปที่แสดง failure ทั้งหมด ไม่ใช่แค่ตัวแรก นอกจากนี้การนิยาม `Assert()` ซ้ำใน module จะ shadow built-in และก่อให้เกิด conflict ที่ละเอียดอ่อน harness จึงตั้งใจใช้ชื่ออื่น

### คำถามที่ 3 (ลองทำ)

**ถาม:** เขียน test file พร้อม `BeginSuite`, assertion `Check` สามตัว (หนึ่งตัวล้มเหลว), compile ด้วย `-cl`, รันและอ่าน output

**ตอบ:**

```purebasic
; Listing E.2 -- Test suite ที่ตั้งใจให้มี failure
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"
XIncludeFile "../../tests/TestHarness.pbi"

OpenConsole()

BeginSuite("My First Test Suite")

; Test ที่ผ่าน: 1 + 1 เท่ากับ 2
Check(1 + 1 = 2)

; Test ที่ผ่าน: เปรียบเทียบสตริง
CheckStr("hello", "hello")

; Test ที่ล้มเหลวโดยตั้งใจ: 3 ไม่เท่ากับ 4
CheckEqual(3, 4)

PrintResults()
CloseConsole()
```

Compile แล้วรัน:

```bash
$PUREBASIC_HOME/compilers/pbcompiler my_test.pb -cl -o my_test
./my_test
```

Output ที่คาดหวัง (test ที่ผ่านไม่มีเสียง มีเฉพาะ failure เท่านั้นที่พิมพ์ออกมา):

```
  [Suite] My First Test Suite
  FAIL  CheckEqual @ my_test.pb:18 => 3 <> 4

======================================
  FAILURES: 1 / 3
======================================
```

---

## บทที่ 4: HTTP พื้นฐาน

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง path parameter (`/users/:id`) กับ query parameter (`/users?id=42`) คืออะไร?

**ตอบ:** path parameter ฝังอยู่ใน URL path เองและเป็นส่วนหนึ่งของ route pattern router ใช้มันเพื่อ match request กับ handler: `/users/:id` match กับ `/users/42`, `/users/99` ฯลฯ และดึงค่า (`42`, `99`) ออกมาตามชื่อ path parameter ระบุถึง resource เฉพาะเจาะจงและทำให้ URL อ่านง่ายและสามารถ bookmark ได้ query parameter ต่อท้าย `?` ใน URL และไม่เป็นส่วนหนึ่งของ logic การ match route `/users?id=42` และ `/users?page=2` ต่าง match กับ route `/users` query parameter ใช้สำหรับ filter, sort, paginate และ modifier เสริม ใน PureSimple path parameter เข้าถึงด้วย `Binding::Param(*C, "id")` และ query parameter ด้วย `Binding::Query(*C, "id")`

### คำถามที่ 2

**ถาม:** ทำไม HTTP จึงถือว่าไม่มี state (stateless) และ web app ใช้กลไกอะไรจดจำผู้ใช้ระหว่าง request?

**ตอบ:** HTTP ไม่มี state เพราะแต่ละ request-response cycle เป็นอิสระจากกัน server ไม่เก็บความทรงจำของ request ก่อนหน้าจาก client เดิม เมื่อเบราว์เซอร์ส่ง `GET /dashboard` server ไม่มีทางรู้ว่า client เพิ่ง login มาหรือเป็นผู้เข้าชมครั้งแรก web application แก้ข้อจำกัดนี้ด้วย cookie และ session server ส่ง header `Set-Cookie` พร้อม session ID ที่ไม่ซ้ำกัน และเบราว์เซอร์จะแนบ cookie นั้นไปกับทุก request ที่ตามมาโดยอัตโนมัติ server map session ID กับ data store (in-memory, database หรือไฟล์) ที่เก็บ state ของผู้ใช้แต่ละคน เช่น สถานะการ login, preferences และ shopping cart PureSimple ใช้งาน pattern นี้ผ่าน Cookie และ Session middleware module

---

## บทที่ 5: Routing

### คำถามที่ 1

**ถาม:** ลำดับความสำคัญเป็นอย่างไรเมื่อ URL สามารถ match กับหลาย route pattern?

**ตอบ:** router แก้ความกำกวมด้วยระบบความสำคัญสามระดับ: (1) exact literal match ชนะก่อน (2) named parameter match (`:param`) ชนะเป็นลำดับสอง (3) wildcard match (`*path`) ชนะสุดท้าย ตัวอย่างเช่น ถ้าลงทะเบียน `/users/profile`, `/users/:id` และ `/users/*path` request ไปยัง `/users/profile` match route exact, `/users/42` match route named parameter และ `/users/photos/vacation/sunset.jpg` match route wildcard ความสำคัญนี้ประเมินต่อ segment ของ path ไม่ใช่ระดับ global ดังนั้น `/users/profile` ไม่ได้แข่งกับ `/admin/:id` เพราะอยู่คนละ branch ของ radix trie

### คำถามที่ 2 (ลองทำ)

**ถาม:** ลงทะเบียน route แล้วทดสอบด้วย curl

**ตอบ:**

```purebasic
; Listing E.3 -- การลงทะเบียน route และทดสอบ
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; ประกาศ handler ก่อนดึงที่อยู่
Declare HomeHandler(*C.RequestContext)
Declare ListHandler(*C.RequestContext)
Declare GetHandler(*C.RequestContext)
Declare CreateHandler(*C.RequestContext)
Declare DeleteHandler(*C.RequestContext)
Declare FileHandler(*C.RequestContext)

Engine::GET("/",              @HomeHandler())
Engine::GET("/users",         @ListHandler())
Engine::GET("/users/:id",     @GetHandler())
Engine::POST("/users",        @CreateHandler())
Engine::DELETE("/users/:id",  @DeleteHandler())
Engine::GET("/files/*path",   @FileHandler())

Engine::Run(8080)

Procedure HomeHandler(*C.RequestContext)
  Rendering::Text(*C, "Welcome home")
EndProcedure

Procedure ListHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"[{\"id\":1},{\"id\":2}]")
EndProcedure

Procedure GetHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  Rendering::JSON(*C, ~"{\"id\":\"" + id + ~"\"}")
EndProcedure

Procedure CreateHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"created\":true}", 201)
EndProcedure

Procedure DeleteHandler(*C.RequestContext)
  Rendering::Status(*C, 204)
EndProcedure

Procedure FileHandler(*C.RequestContext)
  Protected path.s = Binding::Param(*C, "path")
  Rendering::Text(*C, "Serving: " + path)
EndProcedure
```

ทดสอบด้วย curl:

```bash
curl http://localhost:8080/
curl http://localhost:8080/users
curl http://localhost:8080/users/42
curl -X POST http://localhost:8080/users
curl -X DELETE http://localhost:8080/users/42
curl http://localhost:8080/files/images/photo.jpg
```

---

## บทที่ 6: Request Context

### คำถามที่ 1

**ถาม:** ทำไมชื่อ method ของ handler chain จึงเป็น `Advance` แทนที่จะเป็น `Next`?

**ตอบ:** `Next` เป็น reserved keyword ใน PureBasic ใช้ปิดลูป `For...Next` และ PureBasic ไม่อนุญาตให้ใช้ reserved keyword เป็นชื่อ procedure แม้แต่ภายใน module การพยายามนิยาม `Procedure Next(*C.RequestContext)` จะเกิด compiler error framework PureSimple เลือก `Advance` เป็นชื่อทดแทนเพราะสื่อความหมายชัดเจน: ก้าวไปยัง handler ตัวถัดไปใน chain นี่คือความต่างที่เด่นชัดที่สุดระหว่าง PureSimple กับ framework ของ Go อย่าง Gin (ใช้ `c.Next()`) หรือ Express.js (ใช้ `next()`)

### คำถามที่ 2

**ถาม:** KV store ช่วยให้ middleware ส่งข้อมูลไปยัง handler ได้อย่างไร?

**ตอบ:** KV store คือคู่ field สตริงที่คั่นด้วย Chr(9) บน `RequestContext` (`StoreKeys` และ `StoreVals`) เมื่อ middleware เรียก `Ctx::Set(*C, "user_id", "42")` key และ value จะถูก append เข้า field เหล่านี้ เมื่อ handler ปลายทางเรียก `Ctx::Get(*C, "user_id")` มันจะค้นหา key ใน `StoreKeys` แล้วคืนค่าที่สอดคล้องจาก `StoreVals` เนื่องจาก store อยู่บน per-request context ข้อมูลจึง scope อยู่กับ request ปัจจุบันโดยอัตโนมัติและไม่รั่วไหลระหว่าง request ที่ทำงานพร้อมกัน store เดียวกันนี้ถูกใช้โดย `Rendering::Render` เพื่อเติม template variable ด้วย คู่ key/value ใดก็ตามที่ตั้งด้วย `Ctx::Set` จะใช้ได้เป็น `{{ key }}` ใน Jinja template

---

## บทที่ 7: Middleware

### คำถามที่ 1

**ถาม:** ทำไมลำดับ middleware จึงสำคัญ?

**ตอบ:** middleware ทำงานตามลำดับที่ลงทะเบียน ก่อตัวเป็น chain ที่ middleware แต่ละตัวห่อหุ้มตัวที่ลงทะเบียนทีหลัง ถ้า Logger ลงทะเบียนก่อน Recovery Logger จะวัดเวลารวมรวมถึงการ error recovery ด้วย ถ้า Recovery ลงทะเบียนก่อน Logger runtime error อาจทำให้ Logger พัง ลำดับที่ถูกต้องคือ Logger ก่อน (เพื่อวัดเวลาทุกอย่าง) แล้วจึง Recovery (เพื่อดัก error ใน downstream handler) ในทำนองเดียวกัน Session middleware ต้องลงทะเบียนก่อน CSRF middleware เพราะ CSRF อ่าน token จาก session การลงทะเบียนผิดลำดับทำให้ CSRF พบ session ว่างและปฏิเสธทุก request หลักการทั่วไปคือ: middleware ที่ต้องการข้อมูลจาก middleware อื่นต้องลงทะเบียนหลังตัวที่ให้ข้อมูลนั้น

### คำถามที่ 2 (ลองทำ)

**ถาม:** เขียน request-ID middleware

**ตอบ:**

```purebasic
; Listing E.4 -- Request-ID middleware
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; สร้าง unique ID แบบง่ายจาก timestamp + random
Procedure.s GenerateRequestID()
  Protected ts.s = Str(ElapsedMilliseconds())
  Protected rn.s = Str(Random(99999))
  ProcedureReturn "req-" + ts + "-" + rn
EndProcedure

; ตัว middleware
Procedure RequestIDMiddleware(*C.RequestContext)
  Protected reqID.s = GenerateRequestID()
  Ctx::Set(*C, "request_id", reqID)
  PrintN("[RequestID] " + reqID + " " +
         *C\Method + " " + *C\Path)
  Ctx::Advance(*C)
EndProcedure

; ลงทะเบียน
Engine::Use(@RequestIDMiddleware())

; handler ที่อ่าน request ID
Engine::GET("/", @HomeHandler())
Engine::Run(8080)

Procedure HomeHandler(*C.RequestContext)
  Protected rid.s = Ctx::Get(*C, "request_id")
  Rendering::JSON(*C,
    ~"{\"message\":\"hello\",\"request_id\":\"" +
    rid + ~"\"}")
EndProcedure
```

---

## บทที่ 8: Request Binding

### คำถามที่ 1

**ถาม:** ทำไม procedure ทำความสะอาด JSON จึงชื่อ `ReleaseJSON` แทนที่จะเป็น `FreeJSON`?

**ตอบ:** PureBasic มีฟังก์ชัน `FreeJSON()` built-in เป็นส่วนหนึ่งของ JSON library ถ้า PureSimple นิยาม procedure `FreeJSON` ของตัวเองภายใน module มันจะ shadow built-in และก่อให้เกิดความสับสนหรือ bug ที่ละเอียดอ่อนเมื่อเรียกผิดเวอร์ชัน แนวทางของ PureSimple คือหลีกเลี่ยง name collision กับ built-in ของ PureBasic โดยเลือกชื่ออื่น `ReleaseJSON` สื่อความหมายเดียวกัน (คืน JSON handle และทำความสะอาด resource) โดยไม่ขัดแย้งกับ standard library pattern นี้ใช้กับ built-in อื่นด้วย PureSimple ใช้ `DB::NextRow` แทน `Next`, `Log::Dbg` แทน `Debug` และ `Ctx::Advance` แทน `Next`

### คำถามที่ 2

**ถาม:** จะเกิดอะไรขึ้นถ้าลืมเรียก `Binding::ReleaseJSON` หลัง `Binding::BindJSON`?

**ตอบ:** JSON object ที่ parse แล้วจะยังคงถูกจองในหน่วยความจำตลอดอายุของ process JSON handle ที่ไม่ได้คืนทุกตัวรั่วหน่วยความจำตามสัดส่วนขนาดของ JSON body ที่ parse ใน web server ที่รับ request หลายร้อยหรือหลายพันครั้ง นำไปสู่การเติบโตของหน่วยความจำอย่างสม่ำเสมอจนกว่า process จะถูก OS kill หรือ address space หมด เรียก `ReleaseJSON` ใน handler ทุกตัวที่เรียก `BindJSON` เสมอ รวมถึง error path ด้วย pattern ที่ดีคือเรียก `BindJSON`, ดึง field ทั้งหมด แล้วเรียก `ReleaseJSON` ทันทีก่อน business logic ใดๆ ที่อาจ return ก่อนกำหนด

---

## บทที่ 9: Response Rendering

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง `Rendering::Redirect(*C, "/login")` กับ `Rendering::Redirect(*C, "/login", 301)` คืออะไร?

**ตอบ:** status code เริ่มต้นของ `Redirect` คือ 302 (Found) ซึ่งเป็น temporary redirect เบราว์เซอร์ตาม redirect แต่ไม่ cache ไว้ ครั้งถัดไปที่ผู้ใช้เข้า URL เดิม เบราว์เซอร์จะส่ง request ไปยัง URL เดิมอีกครั้งและ server ตัดสินใจว่าจะ redirect อีกหรือให้ content 301 (Moved Permanently) บอกเบราว์เซอร์ให้ cache redirect ไว้ตลอดไป เบราว์เซอร์จะไปยัง URL ใหม่โดยตรงในการเยี่ยมชมครั้งถัดไปโดยไม่ติดต่อ URL เดิม ใช้ 302 สำหรับสถานการณ์เช่น "ยังไม่ได้ login ไปที่หน้า login" (เพราะหลัง login แล้ว URL เดิมควรใช้ได้) ใช้ 301 สำหรับการเปลี่ยน URL ถาวร เช่น "หน้านี้ย้ายจาก /old-path ไปยัง /new-path ตลอดไป"

### คำถามที่ 2

**ถาม:** `Rendering::Render` ดึงตัวแปร template มาจากที่ไหน?

**ตอบ:** `Rendering::Render` อ่านตัวแปร template จาก KV store ของ request context (`*C\StoreKeys` และ `*C\StoreVals`) ก่อนเรียก `Render` handler (หรือ middleware) เติม store ด้วย `Ctx::Set(*C, "key", "value")` เมื่อ `Render` สร้าง PureJinja environment จะวน iterate คู่ key-value ที่เก็บไว้ทั้งหมดแล้วลงทะเบียนเป็นตัวแปร template ใน template `{{ key }}` จะ output ค่าที่สอดคล้องกัน การออกแบบนี้หมายความว่าไม่จำเป็นต้องสร้าง "template context" object แยกต่างหาก KV store เดียวกันที่ใช้สื่อสาร middleware ทำหน้าที่เป็นแหล่งตัวแปร template ด้วย

---

## บทที่ 10: Route Group

### คำถามที่ 1

**ถาม:** จะเกิดอะไรขึ้นกับ middleware เมื่อสร้าง sub-group ด้วย `Group::SubGroup`?

**ตอบ:** `SubGroup` คัดลอก middleware stack ของ parent group ไปยัง child ณ เวลาที่สร้าง หมายความว่า child ได้รับ middleware ทั้งหมดที่ลงทะเบียนกับ parent จนถึงตอนนั้น middleware ที่เพิ่มให้ parent หลังจากเรียก `SubGroup` แล้วจะไม่ propagate ไปยัง child และ middleware ที่เพิ่มให้ child จะไม่กระทบ parent เมื่อ request match route ของ child group handler chain จะมี: global engine middleware ทั้งหมด แล้วจึง middleware ของ child (ซึ่งรวมถึง middleware ที่ inherit จาก parent บวก middleware ที่เฉพาะเจาะจงกับ child) แล้วจึง route handler พฤติกรรม copy-on-create นี้ป้องกันการ interact ที่ไม่คาดคิดระหว่าง group ที่มี parent ร่วมกัน

### คำถามที่ 2

**ถาม:** จะจัดโครงสร้าง group สำหรับ API ที่มีเวอร์ชัน v1 และ v2 ได้อย่างไร?

**ตอบ:** สร้าง parent group สำหรับ `/api` แล้วสร้าง sub-group สองตัวสำหรับ `/v1` และ `/v2` แต่ละเวอร์ชันสามารถมี middleware เป็นของตัวเอง (ตัวอย่างเช่น v2 อาจต้องการ authentication scheme ที่ต่างออกไป) route ที่ลงทะเบียนกับแต่ละ sub-group จะได้ prefix เต็มโดยอัตโนมัติ (`/api/v1/users`, `/api/v2/users`) handler สามารถใช้ร่วมกันระหว่าง version ได้เมื่อพฤติกรรมเหมือนกัน หรือเขียน handler เฉพาะเวอร์ชันเมื่อ API เปลี่ยนแปลง

```purebasic
Protected api.PS_RouterGroup
Group::Init(@api, "/api")
Group::Use(@api, @Logger::Middleware())

Protected v1.PS_RouterGroup
Group::SubGroup(@api, @v1, "/v1")
Group::GET(@v1, "/users", @ListUsersV1())

Protected v2.PS_RouterGroup
Group::SubGroup(@api, @v2, "/v2")
Group::Use(@v2, @NewAuthMiddleware())
Group::GET(@v2, "/users", @ListUsersV2())
```

---

## บทที่ 11: PureJinja

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง `{{ variable }}` กับ `{% block %}` ใน Jinja คืออะไร?

**ตอบ:** `{{ variable }}` เป็น expression tag ที่ output ค่าของตัวแปรหรือ expression ไปยัง HTML ที่ render แล้ว มันถูกแทนที่ด้วยค่าสตริงของตัวแปรขณะ render `{% block %}` เป็น statement tag ที่นิยาม named content block สำหรับ template inheritance เมื่อ child template extend parent template มันสามารถ override block เฉพาะเพื่อแทนที่เนื้อหาของ block ในขณะที่รักษาทุกอย่างอื่นจาก parent expression tag ผลิต output โดยตรง statement tag ควบคุมโครงสร้างและ logic ของ template (รวมถึง `if`, `for`, `extends` และ `block`) ใช้ `{{ }}` เมื่อต้องการแสดงข้อมูล และ `{% %}` เมื่อต้องการควบคุมสิ่งที่จะแสดง

### คำถามที่ 2 (ลองทำ)

**ถาม:** สร้าง base template พร้อม child page สองหน้า

**ตอบ:**

สร้าง `templates/base.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}My Site{% endblock %}</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/about">About</a>
  </nav>
  <main>
    {% block content %}{% endblock %}
  </main>
  <footer>
    <p>Built with PureSimple</p>
  </footer>
</body>
</html>
```

สร้าง `templates/index.html`:

```html
{% extends "base.html" %}
{% block title %}Home - My Site{% endblock %}
{% block content %}
  <h1>Welcome</h1>
  <p>Hello, {{ username|default("visitor") }}!</p>
{% endblock %}
```

สร้าง `templates/about.html`:

```html
{% extends "base.html" %}
{% block title %}About - My Site{% endblock %}
{% block content %}
  <h1>About Us</h1>
  <p>This site is powered by PureSimple.</p>
{% endblock %}
```

โค้ด handler:

```purebasic
Procedure IndexHandler(*C.RequestContext)
  Ctx::Set(*C, "username", "Alice")
  Rendering::Render(*C, "index.html")
EndProcedure

Procedure AboutHandler(*C.RequestContext)
  Rendering::Render(*C, "about.html")
EndProcedure

Engine::GET("/", @IndexHandler())
Engine::GET("/about", @AboutHandler())
```

---

## บทที่ 12: การสร้าง HTML Application

### คำถามที่ 1

**ถาม:** ทำไม template ควรอยู่ใน directory `templates/` แยกต่างหาก แทนที่จะอยู่ข้างๆ โค้ดต้นทาง?

**ตอบ:** การแยก template ออกจากโค้ดต้นทางกำหนดขอบเขตที่ชัดเจนระหว่าง logic และ presentation designer สามารถแก้ HTML โดยไม่ต้องไปยุ่งกับไฟล์ต้นทาง PureBasic โครงสร้าง directory สะท้อนการ deploy: `Rendering::Render` มีค่าเริ่มต้นให้มองหาใน `templates/` และ directory แยกทำให้การกำหนด template search path เป็นเรื่องง่าย นอกจากนี้ยังป้องกันการรวม template file เข้า compilation unit โดยไม่ตั้งใจ เพราะ `XIncludeFile` ของ PureBasic จะสำลักกับ HTML syntax ถ้า template ถูก include โดยไม่ตั้งใจ

### คำถามที่ 2

**ถาม:** flash message ทำงานร่วมกับ session ได้อย่างไร?

**ตอบ:** flash message คือการแจ้งเตือนครั้งเดียวที่เก็บใน session และแสดงเมื่อโหลดหน้าถัดไป pattern ทั่วไปคือ: (1) handler ดำเนินการบางอย่าง เช่น สร้าง post (2) เก็บข้อความใน session ด้วย `Session::Set(*C, "flash", "Post created successfully")` (3) redirect ไปยังหน้าอื่นด้วย `Rendering::Redirect(*C, "/posts")` (4) handler ปลายทางอ่าน flash message ด้วย `Session::Get(*C, "flash")` ส่งไปยัง template ผ่าน `Ctx::Set` แล้วลบออกจาก session ข้อความปรากฏครั้งเดียวและหายไปเมื่อ navigate ไปที่อื่น นี่คือ pattern Post-Redirect-Get (PRG) และป้องกันการส่ง form ซ้ำเมื่อ refresh เบราว์เซอร์

---

## บทที่ 13: SQLite Integration

### คำถามที่ 1

**ถาม:** ทำไมจึงควรใช้ parameterised query แทนการต่อสตริงเสมอ?

**ตอบ:** การต่อสตริงฝัง user input ลงใน SQL โดยตรง สร้าง SQL injection vulnerability โดยตรง ถ้าผู้ใช้ส่งชื่อ `'; DROP TABLE users; --` การต่อสตริงจะผลิต `SELECT * FROM users WHERE name = ''; DROP TABLE users; --'` ซึ่งลบตารางทิ้ง parameterised query ที่ใช้ `DB::BindStr` และ `DB::BindInt` จะส่ง SQL template และค่าแยกกัน database engine ปฏิบัติต่อค่าที่ bind มาเป็นข้อมูล ไม่ใช่คำสั่ง SQL ไม่ว่าค่านั้นจะมีอักขระอะไรก็ตาม การใช้ parameter ไม่มี performance penalty และยังจัดการ quoting และ escaping อย่างถูกต้องสำหรับทุกชนิดข้อมูล อย่าต่อ user input เข้า SQL เด็ดขาด ใช้ placeholder `?` และ `DB::BindStr`/`DB::BindInt` ทุก query ที่มีข้อมูลจากภายนอก

### คำถามที่ 2 (ลองทำ)

**ถาม:** สร้าง migration ที่เพิ่มตารางพร้อม seed data

**ตอบ:**

```purebasic
; Listing E.5 -- Migration พร้อม seed data
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; ลงทะเบียน migration
DB::AddMigration(1,
  "CREATE TABLE IF NOT EXISTS categories (" +
  "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
  "name TEXT NOT NULL, " +
  "slug TEXT NOT NULL UNIQUE)")

DB::AddMigration(2,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Technology', 'technology')")

DB::AddMigration(3,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Travel', 'travel')")

DB::AddMigration(4,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Food', 'food')")

; เปิด in-memory database แล้วรัน migration
Protected db.i = DB::Open(":memory:")
If db
  DB::Migrate(db)

  ; ตรวจสอบ
  OpenConsole()
  DB::Query(db, "SELECT id, name, slug FROM categories")
  While DB::NextRow(db)
    PrintN(Str(DB::GetInt(db, 0)) + ": " +
           DB::GetStr(db, 1) + " (" +
           DB::GetStr(db, 2) + ")")
  Wend
  DB::Done(db)
  DB::Close(db)
  CloseConsole()
EndIf

DB::ResetMigrations()
```

Output ที่คาดหวัง:

```
1: Technology (technology)
2: Travel (travel)
3: Food (food)
```

---

## บทที่ 14: Database Pattern

### คำถามที่ 1

**ถาม:** repository pattern คืออะไรและมีประโยชน์อย่างไร?

**ตอบ:** repository pattern แยก database access ทั้งหมดสำหรับ entity หนึ่งออกไปไว้หลัง module แยกต่างหาก แทนที่จะกระจาย SQL query ไว้ทั่ว handler คุณสร้าง module (เช่น `PostRepo`) ที่เปิดเผย procedure อย่าง `PostRepo::FindAll()`, `PostRepo::FindByID(id)`, `PostRepo::Create(title, body)` และ `PostRepo::Delete(id)` handler เรียก procedure เหล่านี้โดยไม่รู้จัก SQL ข้างใต้ ทำให้เปลี่ยน database schema ได้โดยไม่ต้องแก้ handler, เขียน test ด้วยการสลับ mock repository และรวม SQL ไว้ที่เดียวเพื่อตรวจสอบความถูกต้องและความปลอดภัยได้ง่าย

### คำถามที่ 2

**ถาม:** ทำไม `:memory:` จึงมีประโยชน์สำหรับ test database?

**ตอบ:** in-memory SQLite database มีอยู่ใน RAM เท่านั้นและถูกทำลายเมื่อ connection ปิด ให้ประโยชน์ต่อ test สามประการ: ความเร็ว (ไม่มี disk I/O), isolation (แต่ละ test ได้ database ใหม่สะอาด ไม่มีข้อมูลเหลือค้าง) และการทำความสะอาด (ปิด handle คือทุกสิ่งที่ต้องทำ ไม่มีไฟล์ที่ต้องลบ) ใน test suite คุณเปิด `:memory:` database, รัน migration, seed test data, ดำเนินการ assertion แล้วปิด handle test ถัดไปเริ่มต้นใหม่สะอาด นี่เร็วกว่า file-based database อย่างมากและขจัด bug ประเภท "ลืมทำความสะอาด test data"

---

## บทที่ 15: Cookie และ Session

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง cookie กับ session คืออะไร?

**ตอบ:** cookie คือข้อมูลขนาดเล็กที่เก็บในเบราว์เซอร์และส่งไปยัง server พร้อมทุก request มองเห็นได้จาก client และมีขีดจำกัดขนาด (ทั่วไปประมาณ 4 KB) session คือ server-side storage ที่ระบุด้วย session ID ซึ่ง session ID นั้นเองเก็บใน cookie เบราว์เซอร์เห็นแค่ session ID (random hex string 32 ตัวอักษร) ข้อมูล session จริงๆ (user ID, preferences, flash message) อยู่บน server ใน map, database หรือไฟล์ cookie เหมาะสำหรับ preferences ที่ไม่ sensitive session จำเป็นสำหรับข้อมูล sensitive เช่น สถานะ authentication เพราะข้อมูลไม่เคยออกไปจาก server

### คำถามที่ 2

**ถาม:** ทำไม PureSimple จึงใช้ in-memory session storage และ trade-off คืออะไร?

**ตอบ:** in-memory session storage ใช้ global PureBasic map ที่ key คือ session ID เร็ว (ไม่มี disk หรือ network I/O), ง่ายต่อการ implement และไม่ต้องการ external dependency trade-off คือ session ทั้งหมดหายไปเมื่อ server process restart ยอมรับได้ในระหว่าง development และสำหรับแอปพลิเคชันที่ยอมรับ session loss ได้ (ผู้ใช้แค่ login ใหม่) สำหรับ production ที่ไม่สามารถรับ session loss ได้ จำเป็นต้องใช้ storage backend แบบ persistent (SQLite, Redis หรือตาราง database) in-memory store ของ PureSimple เป็นจุดเริ่มต้นที่เป็นประโยชน์

---

## บทที่ 16: Authentication

### คำถามที่ 1

**ถาม:** ทำไมจึงไม่ควรเก็บ password ในรูป plaintext เด็ดขาด?

**ตอบ:** ถ้า attacker เข้าถึง database ของคุณได้ (ผ่าน SQL injection, backup รั่ว หรือ server ถูก compromise) password แบบ plaintext ใช้ได้ทันที attacker สามารถ login เข้า account ทุก user ได้ และเพราะคนเรา reuse password มักจะสามารถเข้า account บน service อื่นได้ด้วย การ hash password ด้วยฟังก์ชัน one-way เช่น SHA-256 (ผ่าน `Fingerprint` ของ PureBasic) หมายความว่า database เก็บเฉพาะ hash เมื่อผู้ใช้ login server จะ hash password ที่ส่งมาแล้วเปรียบเทียบ hash แม้ database ถูกขโมยไป attacker ก็ได้แค่ hash ไม่ใช่ password และไม่สามารถ reverse ได้ เพื่อความปลอดภัยสูงสุดควรใช้ salt (สตริงสุ่มที่เติมต้น password แต่ละตัวก่อน hash) เพื่อป้องกัน rainbow table attack

### คำถามที่ 2

**ถาม:** BasicAuth middleware ถอดรหัส Authorization header อย่างไร?

**ตอบ:** header `Authorization: Basic <base64>` มีสตริงที่เข้ารหัสด้วย Base64 ในรูปแบบ `username:password` BasicAuth middleware ดึง header จาก `*C\Authorization`, ตัด prefix `Basic ` ออก, ถอดรหัส Base64 ส่วนที่เหลือ แล้วแยกผลลัพธ์ที่ `:` ตัวแรกเพื่อแยก username กับ password จากนั้นเปรียบเทียบ credential เหล่านี้กับค่าที่ตั้งด้วย `BasicAuth::SetCredentials` ถ้า header หายไป, รูปแบบผิด หรือ credential ไม่ตรง middleware จะเรียก `Ctx::AbortWithError(*C, 401, "Unauthorized")` แล้ว return โดยไม่เรียก `Ctx::Advance` เมื่อสำเร็จ จะเก็บ username ที่ยืนยันแล้วใน KV store ภายใต้ `_auth_user` แล้วเรียก `Advance` เพื่อดำเนินต่อใน chain

---

## บทที่ 17: CSRF Protection

### คำถามที่ 1

**ถาม:** CSRF attack คืออะไรและ token pattern ป้องกันได้อย่างไร?

**ตอบ:** Cross-Site Request Forgery (CSRF) คือการโจมตีที่หลอกเบราว์เซอร์ของผู้ใช้ที่ login แล้วให้ส่ง request ไปยัง site อื่นที่ผู้ใช้ authenticated อยู่ ตัวอย่างเช่น หน้าที่เป็นอันตรายอาจมี hidden form ที่ส่ง `POST /admin/delete-all` ไปยัง blog ของคุณ เบราว์เซอร์แนบ session cookie ของผู้ใช้โดยอัตโนมัติ ทำให้ server คิดว่าผู้ใช้ตั้งใจส่ง form token pattern ป้องกันด้วยการฝัง random token ในทุก form ที่ถูกต้องแล้ว validate เมื่อส่ง หน้าของ attacker ไม่สามารถอ่าน token ได้ (same-origin policy ป้องกันการอ่านข้าม site) ดังนั้น form submission ปลอมจึงมาโดยไม่มี token ที่ถูกต้องและถูกปฏิเสธด้วย 403 Forbidden

### คำถามที่ 2

**ถาม:** เมื่อใดจึงไม่จำเป็นต้องมี CSRF protection?

**ตอบ:** CSRF protection ไม่จำเป็นสำหรับ JSON API ที่ใช้ `Authorization` header (Bearer token, API key) แทน cookie เพราะเบราว์เซอร์แนบ cookie โดยอัตโนมัติคือสิ่งที่ทำให้ CSRF เป็นไปได้ ถ้า authentication พึ่งพา header ที่ client ต้องตั้งเองอย่างชัดเจน (ไม่ใช่แนบโดยเบราว์เซอร์อัตโนมัติ) หน้าข้าม site ไม่สามารถปลอม request ได้เพราะ set custom header บน cross-origin request ไม่ได้ request แบบ `GET` และ `HEAD` ก็ exempt เช่นกันเพราะควร idempotent (ไม่ควรแก้ไข state) CSRF middleware ของ PureSimple ข้าม `GET` และ `HEAD` request โดยอัตโนมัติและ validate token เฉพาะสำหรับ `POST`, `PUT`, `PATCH` และ `DELETE`

---

## บทที่ 18: Configuration และ Logging

### คำถามที่ 1

**ถาม:** ทำไมไฟล์ `.env` จึงไม่ควร commit เข้า version control เด็ดขาด?

**ตอบ:** ไฟล์ `.env` มี configuration ที่เฉพาะกับ environment: database credential, API key, secret token และ server address การ commit เข้า Git หมายความว่าทุกคนที่เข้าถึง repository (รวมถึงผู้ดู GitHub สาธารณะถ้า repo เผยแพร่ต่อสาธารณะ) สามารถอ่าน production secret ของคุณได้ แต่ละ environment (development, staging, production) ควรมีไฟล์ `.env` ของตัวเองที่สร้างในเครื่องหรือถูก inject โดย deployment pipeline เพิ่ม `.env` เข้า `.gitignore` แล้ว commit ไฟล์ `.env.example` ที่มีค่า placeholder แทน เพื่อให้นักพัฒนาใหม่รู้ว่าต้อง configure key ใดบ้าง นี่คือหนึ่งใน twelve-factor app principle: เก็บ config ไว้ใน environment ไม่ใช่ใน code

### คำถามที่ 2

**ถาม:** ความต่างระหว่าง `Log::#LevelDebug` กับ `Log::#LevelInfo` คืออะไร และควรเปลี่ยน level เมื่อใด?

**ตอบ:** `Log::#LevelDebug` (ค่า 0) คือระดับที่ verbose ที่สุด ผลิต output ละเอียดที่เป็นประโยชน์ระหว่าง development เช่น query timing, ค่าตัวแปร, middleware entry/exit `Log::#LevelInfo` (ค่า 1) คือระดับ production เริ่มต้น log เหตุการณ์ปกติของการทำงาน เช่น server startup, request handling summary และค่า configuration เมื่อ `SetLevel` ตั้งเป็น `Info` ข้อความระดับ `Debug` ทั้งหมดจะถูกระงับ ควรตั้ง `Debug` ระหว่าง local development เพื่อเห็นทุกอย่าง และตั้ง `Info` หรือ `Warn` ใน production เพื่อลด log volume และหลีกเลี่ยงการเปิดเผยรายละเอียดภายใน pattern ทั่วไปของ PureSimple คือ อ่านค่า config `MODE` แล้วตั้งระดับ `Debug` สำหรับ mode `"debug"` และระดับ `Info` สำหรับ mode `"release"`

---

## บทที่ 19: Deployment

### คำถามที่ 1

**ถาม:** ทำไม deploy script จึงควรมีการ health check?

**ตอบ:** health check ยืนยันว่า binary ที่ deploy ใหม่เริ่มต้นแล้วและ serve request ได้อย่างถูกต้อง หากไม่มี deploy script อาจรายงานว่าสำเร็จแม้ว่า binary จะ crash ตอนเริ่มต้น (config ผิด, database หาย, port ชน) health check ส่ง `GET /health` แล้วคาดหวัง response `200 OK` ถ้าตรวจสอบล้มเหลว deploy script สามารถเรียก rollback ไปยัง binary ก่อนหน้า (`app.bak`) โดยอัตโนมัติ เปลี่ยน recovery ที่อาจใช้เวลาหลายชั่วโมงให้เป็น automated recovery ที่ใช้เวลาเป็นวินาที health check endpoint ควร execute ราคาถูก (ไม่มี database query, ไม่มี external call) และควรคืน 200 เฉพาะเมื่อแอปพลิเคชันพร้อม serve traffic จริงๆ เท่านั้น

### คำถามที่ 2

**ถาม:** Caddy ให้อะไรที่ PureSimple ไม่ได้ให้?

**ตอบ:** Caddy ทำหน้าที่เป็น reverse proxy หน้า PureSimple และให้บริการ: (1) HTTPS อัตโนมัติพร้อม Let's Encrypt certificate provisioning และ renewal, (2) รองรับ HTTP/2, (3) การบีบอัด gzip/brotli, (4) การส่งไฟล์ static พร้อม caching header ที่เหมาะสม, (5) request rate limiting และ (6) graceful connection handling PureSimpleHTTPServer ดูแล HTTP/1.1 protocol หลัก แต่ Caddy ดูแล TLS termination และ edge-server concern ที่ซับซ้อนและอันตรายหากทำผิด สถาปัตยกรรมคือ: traffic จากอินเทอร์เน็ตเข้า Caddy ที่ port 80/443, Caddy terminate TLS แล้ว proxy ไปยัง PureSimple ที่ `localhost:8080` และ PureSimple ดูแล routing และ application logic การแยกนี้ให้แต่ละ component ทำในสิ่งที่ทำได้ดีที่สุด

---

## บทที่ 20: Testing

### คำถามที่ 1

**ถาม:** ทำไมจึงควรเรียก `ResetMiddleware()`, `Session::ClearStore()` และ `Config::Reset()` ระหว่าง test suite?

**ตอบ:** function เหล่านี้คืน global state กลับสู่ baseline ที่สะอาด หากไม่เรียก middleware ที่ลงทะเบียนใน test suite หนึ่งจะรั่วเข้า suite ถัดไป ทำให้ handler chain ไม่คาดคิด session data จาก test หนึ่งอาจตอบสนอง authentication check ใน test อื่น ผลิต test ที่ผ่านแบบ false positive config value ที่ตั้งใน suite หนึ่งอาจเปลี่ยนพฤติกรรมของ suite ถัดไป หลักการทั่วไปคือ test isolation: ทุก suite ควรเริ่มต้นจาก state ที่รู้จักและสะอาด เพื่อให้ test ผ่านหรือล้มเหลวตาม logic ของตัวเอง ไม่ใช่ตามลำดับการรัน เรียก reset function เหล่านี้ในส่วน setup ของแต่ละ suite ก่อนลงทะเบียน middleware หรือ config ใหม่

### คำถามที่ 2 (ลองทำ)

**ถาม:** เขียน test suite สำหรับ handler ใหม่

**ตอบ:**

```purebasic
; Listing E.6 -- การทดสอบ handler
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"
XIncludeFile "../../tests/TestHarness.pbi"

; handler ที่กำลังทดสอบ
Procedure GreetHandler(*C.RequestContext)
  Protected name.s = Binding::Query(*C, "name")
  If name = ""
    name = "World"
  EndIf
  Rendering::JSON(*C,
    ~"{\"greeting\":\"Hello, " + name + ~"!\"}")
EndProcedure

OpenConsole()

; Reset state
Engine::ResetMiddleware()

BeginSuite("GreetHandler Tests")

; Test 1: greeting ค่าเริ่มต้นเมื่อไม่มี name
Protected c1.RequestContext
Ctx::Init(@c1, 0)
c1\Method = "GET"
c1\Path = "/greet"
c1\RawQuery = ""
GreetHandler(@c1)
CheckEqual(c1\StatusCode, 200)
CheckStr(c1\ContentType, "application/json")
Check(FindString(c1\ResponseBody, "Hello, World!") > 0)

; Test 2: greeting พร้อม name
Protected c2.RequestContext
Ctx::Init(@c2, 1)
c2\Method = "GET"
c2\Path = "/greet"
c2\RawQuery = "name=Alice"
GreetHandler(@c2)
CheckEqual(c2\StatusCode, 200)
Check(FindString(c2\ResponseBody, "Hello, Alice!") > 0)

; Test 3: greeting พร้อม URL-encoded name
Protected c3.RequestContext
Ctx::Init(@c3, 2)
c3\Method = "GET"
c3\Path = "/greet"
c3\RawQuery = "name=Bob+Smith"
GreetHandler(@c3)
CheckEqual(c3\StatusCode, 200)
Check(FindString(c3\ResponseBody, "Hello, Bob Smith!") > 0)

PrintResults()
CloseConsole()
```

---

## บทที่ 21: การสร้าง REST API (To-Do List)

### คำถามที่ 1

**ถาม:** ความต่างระหว่าง in-memory storage กับ SQLite persistence สำหรับ To-Do API คืออะไร?

**ตอบ:** in-memory storage (ใช้ PureBasic map หรือ list) เร็วและง่ายแต่ข้อมูลทั้งหมดหายเมื่อ server restart เหมาะสำหรับ prototype, demo และ test SQLite persistence เขียนข้อมูลลงไฟล์บน disk ข้อมูลอยู่รอดหลัง server restart และให้การรับประกัน ACID (atomicity, consistency, isolation, durability) สำหรับ production To-Do API SQLite คือตัวเลือกขั้นต่ำที่ใช้งานได้จริง การเปลี่ยนจาก in-memory เป็น SQLite ต้องแทนที่ map operation ตรงๆ ด้วยการเรียก `DB::Exec` และ `DB::Query` แต่ handler signature และ JSON response ยังเหมือนเดิม

### คำถามที่ 2

**ถาม:** จะเพิ่ม authentication เข้า To-Do API ได้อย่างไร?

**ตอบ:** สร้าง route group สำหรับ API endpoint แล้วแนบ BasicAuth middleware เข้า group route ทั้งหมดภายใน group ต้องการ credential ที่ถูกต้อง health check endpoint อยู่นอก group เพื่อให้ monitoring tool เข้าถึงได้โดยไม่ต้อง authenticate

```purebasic
BasicAuth::SetCredentials("admin", "secret")

Protected api.PS_RouterGroup
Group::Init(@api, "/api")
Group::Use(@api, @BasicAuth::Middleware())

Group::GET(@api,    "/todos",     @ListTodos())
Group::POST(@api,   "/todos",     @CreateTodo())
Group::GET(@api,    "/todos/:id", @GetTodo())
Group::PUT(@api,    "/todos/:id", @UpdateTodo())
Group::DELETE(@api, "/todos/:id", @DeleteTodo())

; Health check อยู่นอก auth group
Engine::GET("/health", @HealthCheck())
```

---

## บทที่ 22: การสร้าง Blog

### คำถามที่ 1

**ถาม:** `PostsToStr` pipe-delimited data pattern คืออะไรและทำไม blog จึงใช้ pattern นี้?

**ตอบ:** `PostsToStr` แปลง list ของ database row เป็นสตริงเดียวที่แถวคั่นด้วย newline (`\n`) และ field ภายในแถวคั่นด้วย pipe (`|`) ตัวอย่างเช่น: `"Post Title|post-slug|2026-01-15|Summary text\nAnother Post|another|2026-01-16|More text"` template จะใช้ `{{ posts|split('\n') }}` เพื่อ iterate แถวและ `{{ row|split('|') }}` เพื่อเข้าถึง field pattern นี้มีเพราะ template context ของ PureJinja คือ flat KV store ของสตริง (ไม่ใช่ structured object) แทนที่จะส่งโครงสร้างข้อมูลซับซ้อนผ่าน template engine blog จะ serialize ข้อมูลเป็นสตริงที่คั่นด้วยตัวอักษร แล้วใช้ filter `split` ของ PureJinja เพื่อ reconstruct โครงสร้างใน template pattern นี้เรียบง่าย มีประสิทธิภาพ และหลีกเลี่ยงการต้องมี custom object serialisation layer

### คำถามที่ 2

**ถาม:** Post-Redirect-Get (PRG) pattern คืออะไรและทำไม contact form จึงใช้ pattern นี้?

**ตอบ:** PRG คือ web development pattern ที่ป้องกันการส่ง form ซ้ำ เมื่อผู้ใช้ส่ง contact form (POST) handler ประมวลผลข้อมูล (บันทึกลง database) แล้ว respond ด้วย 302 redirect ไปยังหน้า confirmation (GET) แทนที่จะ render response โดยตรง ถ้าผู้ใช้ refresh หน้า confirmation เบราว์เซอร์จะทำ GET request ซ้ำ ไม่ใช่ POST หากไม่มี PRG การ refresh จะส่ง form ซ้ำ อาจสร้าง contact message ซ้ำ PureSimple ใช้ PRG ด้วย `Rendering::Redirect(*C, "/contact/ok")` หลังจากประมวลผล form สำเร็จ

### คำถามที่ 3 (ลองทำ)

**ถาม:** เพิ่มระบบ tag เข้า blog

**ตอบ:** ต้องการสามองค์ประกอบ: ตาราง tag, ตาราง post-tag join และ migration สำหรับสร้างทั้งสอง

```purebasic
; Listing E.7 -- Tag system migrations
DB::AddMigration(11,
  "CREATE TABLE IF NOT EXISTS tags (" +
  "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
  "name TEXT NOT NULL UNIQUE, " +
  "slug TEXT NOT NULL UNIQUE)")

DB::AddMigration(12,
  "CREATE TABLE IF NOT EXISTS post_tags (" +
  "post_id INTEGER NOT NULL, " +
  "tag_id INTEGER NOT NULL, " +
  "PRIMARY KEY (post_id, tag_id), " +
  "FOREIGN KEY (post_id) REFERENCES posts(id), " +
  "FOREIGN KEY (tag_id) REFERENCES tags(id))")

DB::AddMigration(13,
  "INSERT INTO tags (name, slug) VALUES " +
  "('PureBasic', 'purebasic')")

DB::AddMigration(14,
  "INSERT INTO tags (name, slug) VALUES " +
  "('Web Development', 'web-development')")
```

Handler แสดง post ตาม tag:

```purebasic
Procedure TagHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")

  DB::BindStr(_db, 0, slug)
  DB::Query(_db,
    "SELECT p.title, p.slug, p.created_at " +
    "FROM posts p " +
    "JOIN post_tags pt ON p.id = pt.post_id " +
    "JOIN tags t ON t.id = pt.tag_id " +
    "WHERE t.slug = ?")

  Protected posts.s = ""
  While DB::NextRow(_db)
    If posts <> "" : posts + ~"\n" : EndIf
    posts + DB::GetStr(_db, 0) + "|" +
            DB::GetStr(_db, 1) + "|" +
            DB::GetStr(_db, 2)
  Wend
  DB::Done(_db)

  Ctx::Set(*C, "posts", posts)
  Ctx::Set(*C, "tag", slug)
  Rendering::Render(*C, "tag.html")
EndProcedure

Engine::GET("/tag/:slug", @TagHandler())
```

---

## บทที่ 23: Multi-Database Support

### คำถามที่ 1

**ถาม:** `DBConnect::Open` กำหนด database driver ที่จะใช้ได้อย่างไร?

**ตอบ:** `DBConnect::Open` ตรวจสอบ prefix ของ DSN (Data Source Name) เพื่อกำหนด driver DSN ที่ขึ้นต้นด้วย `sqlite:` จะเปิดใช้ SQLite driver แล้วส่งส่วนที่เหลือเป็น file path (หรือ `:memory:` สำหรับ in-memory) DSN ที่ขึ้นต้นด้วย `postgres://` หรือ `postgresql://` จะเปิดใช้ PostgreSQL driver, parse URL เพื่อดึง host, port, ชื่อ database และ credential แล้วเปิด PostgreSQL connection DSN ที่ขึ้นต้นด้วย `mysql://` ทำเช่นเดียวกันสำหรับ MySQL ภายใน `DBConnect::Driver(DSN)` คืน driver constant (`#Driver_SQLite`, `#Driver_Postgres`, `#Driver_MySQL` หรือ `#Driver_Unknown`) และ `Open` dispatch ไปยัง `OpenDatabase()` พร้อม driver constant ที่เหมาะสม (`#PB_Database_SQLite`, `#PB_Database_PostgreSQL` หรือ `#PB_Database_MySQL`) handle ที่คืนมาใช้ร่วมกับ procedure ทั้งหมดใน `DB::*` ได้ โค้ดของแอปพลิเคชันจึงไม่ต้องเปลี่ยนเมื่อสลับ database

### คำถามที่ 2

**ถาม:** ข้อได้เปรียบของการอ่าน database DSN จาก configuration แทนการ hardcode คืออะไร?

**ตอบ:** การอ่าน DSN จาก configuration (ผ่าน `DBConnect::OpenFromConfig()` ที่อ่าน key `DB_DSN` จากไฟล์ `.env`) แยก application code ออกจาก database ที่จะ connect binary เดียวกันสามารถ connect กับ in-memory SQLite สำหรับ test, file-based SQLite สำหรับ development และ PostgreSQL server สำหรับ production เพียงแค่เปลี่ยนไฟล์ `.env` ไม่ต้อง recompile ซ้ำ นี่คือ twelve-factor app principle ของการเก็บ configuration ไว้ใน environment นอกจากนี้ยังหมายความว่า database credential ไม่เคยปรากฏใน source code ลดความเสี่ยงการเปิดเผยโดยไม่ตั้งใจผ่าน version control
