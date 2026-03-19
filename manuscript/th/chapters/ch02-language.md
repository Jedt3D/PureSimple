# บทที่ 2: ภาษา PureBasic

*ทุกสิ่งที่คุณต้องรู้เพื่ออ่าน framework code และเขียน handler*

---

## วัตถุประสงค์การเรียนรู้

หลังจากอ่านบทนี้จบ คุณจะสามารถ:

- ประกาศตัวแปรพร้อมกำหนด type อย่างชัดเจน และอธิบายได้ว่าทำไม `EnableExplicit` จึงจำเป็น
- จัดการ string ด้วย built-in string function ของ PureBasic
- นิยาม structure, map, list และ array และเลือกใช้ collection ที่เหมาะสมกับแต่ละสถานการณ์
- เขียน procedure ที่มี return type และใช้ `Prototype` สำหรับ function pointer
- จัดระเบียบโค้ดด้วย module โดยใช้ `DeclareModule` และ `UseModule`
- จัดการ runtime error ด้วยรูปแบบ return-code และ OnErrorGoto recovery

---

## 2.1 Type และตัวแปร

PureBasic เป็นภาษา statically typed ทุกตัวแปรมี type และ type กำหนดว่าใช้หน่วยความจำเท่าใดและสามารถดำเนินการใดได้บ้าง ถ้าคุณมาจาก Python หรือ JavaScript มันอาจรู้สึกจำกัดในช่วงแรก ลองให้เวลาตัวเองสักหนึ่งสัปดาห์ คุณจะเลิกคิดถึง dynamic type ราวกับช่วงเวลาเดียวกับที่คุณเลิก debug bug จาก type coercion

type ที่มีในตัวมีดังนี้:

| Suffix | Type | ขนาด | ช่วงค่า |
|--------|------|------|-------|
| `.b` | Byte | 1 byte | -128 ถึง 127 |
| `.w` | Word | 2 bytes | -32768 ถึง 32767 |
| `.l` | Long | 4 bytes | -2,147,483,648 ถึง 2,147,483,647 |
| `.q` | Quad | 8 bytes | 64-bit signed integer เต็ม |
| `.i` | Integer | **pointer-sized** | 4 bytes บน x86, 8 bytes บน x64 |
| `.f` | Float | 4 bytes | Single precision |
| `.d` | Double | 8 bytes | Double precision |
| `.s` | String | Variable | Unicode string |

type `.i` สมควรได้รับความสนใจเป็นพิเศษ มันไม่ใช่ 32-bit และไม่ใช่ 64-bit มันมีขนาดเท่ากับ pointer นั่นหมายความว่าเป็น 4 bytes เมื่อ compile สำหรับ x86 และ 8 bytes เมื่อ compile สำหรับ x64 PureSimple ใช้ `.i` อย่างแพร่หลายสำหรับ handle, ID, loop counter และ procedure address บนระบบ 64-bit สมัยใหม่ `.i` และ `.q` มีขนาดเท่ากัน แต่ไม่สามารถใช้แทนกันได้ในเชิงความหมาย ใช้ `.i` เมื่อค่านั้นแทน handle หรือ pointer ใช้ `.q` เมื่อค่านั้นเป็นตัวเลข 64-bit จริง ๆ

```purebasic
; Listing 2.1 -- Type declarations and EnableExplicit
EnableExplicit

Protected count.i = 0          ; pointer-sized integer
Protected name.s  = "PureSimple"
Protected price.d = 29.95      ; double-precision float
Protected flag.b  = #True      ; byte (0 or 1)

; This line would cause a compiler error with
; EnableExplicit because 'total' is not declared:
; total = count + 1
```

บรรทัดแรก `EnableExplicit` เปลี่ยนทุกอย่าง หากไม่มี PureBasic จะสร้างตัวแปรเองโดยอัตโนมัติเมื่อใช้ครั้งแรก โดยอนุมาน type จากบริบท ฟังดูสะดวก จนกว่าคุณจะพิมพ์ `coutn` แทน `count` แล้วใช้เวลาหนึ่งชั่วโมงสงสัยว่าทำไม counter ถึงไม่เพิ่ม การลืมใส่ `EnableExplicit` เหมือนกับขับรถโดยไม่คาดเข็มขัดนิรภัย คุณรู้สึกอิสระดีจนกว่าจะเกิดอุบัติเหตุ

> **คำเตือน:** `EnableExplicit` ไม่ใช่ทางเลือก ทุกไฟล์ใน PureSimple ใช้มัน ทุกไฟล์ที่คุณเขียนควรใช้มัน compiler เป็นพันธมิตรของคุณ แต่ต้องให้มันตรวจสอบงานคุณด้วย

### Scope: Protected vs Global vs Shared

ตัวแปรที่ประกาศภายใน procedure จะ local ต่อ procedure นั้นโดยค่าเริ่มต้น แต่ PureBasic มี scope qualifier หลายตัว:

- **`Protected`** -- ตัวแปรนี้มีอยู่เฉพาะภายใน procedure ปัจจุบัน นี่คือสิ่งที่คุณต้องการ 95% ของเวลา ทุกตัวแปร local ใน PureSimple ใช้ `Protected`
- **`Global`** -- ตัวแปรนี้มองเห็นได้ทุกที่ในโปรแกรม รวมถึงภายใน procedure ใช้อย่างจำกัด Global state คือศัตรูของโค้ดที่ทดสอบได้
- **`Shared`** -- ทำให้ตัวแปร `Global` ที่ประกาศไว้แล้วเข้าถึงได้ภายใน procedure เฉพาะ คุณจะแทบไม่ต้องการสิ่งนี้
- **`Static`** -- ตัวแปรรักษาค่าไว้ระหว่างการเรียก procedure เหมือน `static` ของ C มีประโยชน์สำหรับ counter และ cache แต่ทำให้การวิเคราะห์ state ซับซ้อนขึ้น

กฎของ PureSimple เรียบง่าย: ใช้ `Protected` ภายใน procedure ใช้ `Global` ที่ระดับ module เมื่อ module จำเป็นต้องมี shared state จริง ๆ (เช่น counter ของ test harness) และหลีกเลี่ยง `Shared` เว้นแต่มีเหตุผลเฉพาะเจาะจง

## 2.2 String

String ใน PureBasic เป็น Unicode, mutable และจัดการผ่าน built-in function ไม่ใช่ method ไม่มี syntax `str.split()` แทนที่จะใช้ คุณเรียก `StringField(str, index, delimiter)`

การต่อ string ใช้ operator `+`:

```purebasic
Protected greeting.s = "Hello, " + "world" + "!"
; greeting = "Hello, world!"
```

string function ที่สำคัญที่สุดสำหรับ web development ได้แก่:

```purebasic
; Listing 2.2 -- String manipulation: StringField splitting
EnableExplicit

Protected csv.s = "alice,bob,charlie"

; Split by delimiter -- fields are 1-indexed
Protected first.s  = StringField(csv, 1, ",")  ; "alice"
Protected second.s = StringField(csv, 2, ",")  ; "bob"
Protected third.s  = StringField(csv, 3, ",")  ; "charlie"

; Count occurrences of a substring
Protected commas.i = CountString(csv, ",")     ; 2

; Find position of substring (1-based, 0 = not found)
Protected pos.i = FindString(csv, "bob")       ; 7

; Substring extraction
Protected sub.s = Mid(csv, 7, 3)               ; "bob"
Protected lft.s = Left(csv, 5)                 ; "alice"
Protected rgt.s = Right(csv, 7)                ; "charlie"

; Case conversion
Protected up.s  = UCase("hello")               ; "HELLO"
Protected lo.s  = LCase("HELLO")               ; "hello"

; Length
Protected len.i = Len(csv)                     ; 17

; Trim whitespace
Protected trimmed.s = Trim("  hello  ")        ; "hello"
```

Escape sequence ต้องใช้ prefix `~"..."` string ธรรมดา `"Hello\nWorld"` คือ backslash ตามด้วย `n` แบบ literal ถ้าต้องการขึ้นบรรทัดใหม่จริง ๆ ให้เขียน `~"Hello\nWorld"`

```purebasic
Protected plain.s   = "Hello\nWorld"     ; literal: Hello\nWorld
Protected escaped.s  = ~"Hello\nWorld"   ; actual newline between Hello and World
```

เรื่องนี้ทำให้ทุกคนเจอปัญหาอย่างน้อยหนึ่งครั้ง PureBasic ถือว่า string ใน double quote เป็น literal เว้นแต่คุณจะเลือกใช้ escape processing ด้วย prefix tilde

## 2.3 โครงสร้างข้อมูล

PureBasic มี collection หลักสามประเภท บวกกับ structure สำหรับนิยาม record type ของเอง การเลือกให้ถูกประเภทส่งผลต่อทั้ง performance และความชัดเจนของโค้ด

### Structure

`Structure` ใน PureBasic เทียบเท่ากับ C struct หรือ Go struct มันนิยาม collection ของ field ที่มี type ชัดเจน:

```purebasic
; Listing 2.3 -- Structure definition and pointer access
EnableExplicit

Structure User
  Name.s
  Email.s
  Age.i
EndStructure

Protected user.User
user\Name  = "Alice"
user\Email = "alice@example.com"
user\Age   = 30

; Pointer to a structure
Protected *ptr.User = @user
PrintN(*ptr\Name)   ; prints "Alice"
```

การเข้าถึง field ใช้ operator backslash `\` ไม่ใช่จุด ถ้าคุณมาจากภาษาอื่นส่วนใหญ่ เรื่องนี้ต้องใช้เวลาสองสามวันกว่าจะเป็นนิสัยอัตโนมัติ prefix `*` บนชื่อตัวแปรหมายความว่าเป็น pointer `*ptr.User` คือ pointer ไปยัง structure `User`

structure `RequestContext` ใน `Types.pbi` ของ PureSimple คือ structure ที่สำคัญที่สุดใน framework มันบรรจุ HTTP method, path, query string, body, status code, response body, content type, route parameter, KV store และ session data ทุก handler รับ pointer ไปยังมัน

### Map

`NewMap` สร้าง hash map ที่มี string key:

```purebasic
NewMap headers.s()
headers("Content-Type") = "application/json"
headers("X-Request-ID") = "abc-123"

If FindMapElement(headers(), "Content-Type")
  PrintN("Found: " + headers())  ; prints the value at current position
EndIf
```

Map เหมาะที่สุดสำหรับ key-value lookup: HTTP header, query parameter, configuration setting

### List

`NewList` สร้าง doubly-linked list:

```purebasic
NewList names.s()
AddElement(names()) : names() = "Alice"
AddElement(names()) : names() = "Bob"
AddElement(names()) : names() = "Charlie"

ForEach names()
  PrintN(names())
Next
```

List เหมาะสำหรับ collection แบบเรียงลำดับที่เพิ่มหรือลบ element บ่อย แต่ไม่เหมาะสำหรับการเข้าถึงแบบ random access ตาม index

### Array

`Dim` สร้าง array ขนาดคงที่:

```purebasic
; Listing 2.4 -- Map, List, and Array comparison
EnableExplicit

; Array: Dim a(N) creates N+1 elements (indices 0 to N)
Dim scores.i(4)    ; creates 5 elements: scores(0) through scores(4)
scores(0) = 95
scores(4) = 87

; Use ReDim to resize (preserves existing data)
ReDim scores.i(9)  ; now 10 elements: scores(0) through scores(9)
```

> **ข้อควรระวังใน PureBasic:** `Dim a(5)` สร้าง **หก** element (index 0 ถึง 5) ไม่ใช่ห้า แต่หก เรื่องนี้สอดคล้องกันภายใน PureBasic -- argument คือ index สูงสุด ไม่ใช่จำนวนนับ -- แต่จะทำให้นักพัฒนาจากทุกภาษาอื่นประหลาดใจ ถ้าต้องการ element ห้าตัวพอดี ให้เขียน `Dim a(4)`

เมื่อไหร่ควรใช้ตัวไหน:

| Collection | เหมาะที่สุดสำหรับ | การเข้าถึงด้วย index | การเพิ่ม/ลบ |
|-----------|---------|---------------|--------------|
| `NewMap` | Key-value lookup | ด้วย string key | เร็ว |
| `NewList` | เรียงลำดับ ขนาดแปรผัน | Sequential เท่านั้น | เร็ว |
| `Dim` | ขนาดคงที่ เข้าถึงด้วย index | ด้วย integer index | ช้า (ReDim คัดลอก) |

## 2.4 Procedure และ Prototype

Procedure คือ function ของ PureBasic มีชื่อ, parameter ที่เลือกใส่หรือไม่ก็ได้, return type ที่เลือกใส่หรือไม่ก็ได้ และ body:

```purebasic
Procedure.s Greet(name.s)
  ProcedureReturn "Hello, " + name + "!"
EndProcedure

Protected msg.s = Greet("PureBasic")  ; "Hello, PureBasic!"
```

`.s` หลัง `Procedure` ประกาศ return type เป็น string ใช้ `.i` สำหรับ integer, `.d` สำหรับ double หรือละ suffix ไว้สำหรับ procedure ที่ไม่ return ค่า

### Function Pointer ด้วย Prototype

PureSimple ลงทะเบียน handler และ middleware โดยส่ง procedure address ในการทำเช่นนี้ PureBasic ใช้ `Prototype` เพื่อนิยาม function signature และ `@MyProc()` เพื่อนำ address ของ procedure:

```purebasic
; Define the handler signature
Prototype.i PS_HandlerFunc(*Ctx.RequestContext)

; Register a handler by address
Engine::GET("/users", @ListUsersHandler())

; The handler procedure matches the prototype signature
Procedure ListUsersHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"users\":[]}")
EndProcedure
```

operator `@` คืน memory address ของ procedure address นี้ถูกเก็บไว้ใน route table เมื่อมี request ที่ตรงกันเข้ามา router จะดึง address มา cast เป็น prototype `PS_HandlerFunc` แล้วเรียกใช้งาน นี่คือ mechanism เดียวกับ C function pointer และเป็นวิธีที่ handler และ middleware ทุกตัวใน PureSimple ถูกเรียกใช้

### Forward Declaration

ถ้า procedure A เรียก procedure B และ B นิยามไว้ภายหลังในไฟล์ คุณต้องมี statement `Declare`:

```purebasic
Declare.s FormatName(first.s, last.s)

; Now you can call FormatName before its body appears
Protected full.s = FormatName("Jedt", "Sitth")

Procedure.s FormatName(first.s, last.s)
  ProcedureReturn first + " " + last
EndProcedure
```

ในทางปฏิบัติ PureSimple หลีกเลี่ยงปัญหานี้โดยใส่ procedure ไว้ใน module ซึ่ง declaration order ถูกจัดการโดย block `DeclareModule`

## 2.5 Module

Module คือกลไก encapsulation ของ PureBasic ไม่ใช่ package ในแบบ Go และไม่ใช่ class ในแบบ Java ใกล้เคียงกับ C++ namespace ที่มีความพิเศษเพิ่มเติม: body ของ module เป็น black box ไม่มีอะไรใน block `Module` ที่จะเห็นตัวแปรหรือ type ที่นิยามไว้ภายนอก เว้นแต่คุณจะ import เข้ามาอย่างชัดเจน

```purebasic
; Listing 2.5 -- Module declaration and UseModule
EnableExplicit

DeclareModule Greeter
  Declare.s Hello(name.s)
  Declare.s Goodbye(name.s)
EndDeclareModule

Module Greeter
  Procedure.s Hello(name.s)
    ProcedureReturn "Hello, " + name + "!"
  EndProcedure

  Procedure.s Goodbye(name.s)
    ProcedureReturn "Goodbye, " + name + "."
  EndProcedure
EndModule

; Call with module prefix
PrintN(Greeter::Hello("World"))

; Or import the module to skip the prefix
UseModule Greeter
PrintN(Hello("World"))
```

Module body เปรียบเสมือนห้องพักโรงแรม เรื่องที่เกิดขึ้นข้างในอยู่ข้างในเว้นแต่คุณจะเปิดประตูด้วย `DeclareModule`

`DeclareModule` คือ public interface เฉพาะ procedure และ type ที่ระบุไว้ที่นั่นเท่านั้นที่มองเห็นจากภายนอก `Module` คือ implementation helper procedure ส่วนตัวที่ไม่ได้ปรากฏใน `DeclareModule` จะมองไม่เห็นจาก caller

> **เปรียบเทียบ:** Module ของ PureBasic เหมือน Go package ยกเว้นว่าไม่แชร์อะไรเป็น default ใน Go ทุกชื่อที่ขึ้นต้นด้วยตัวพิมพ์ใหญ่จะถูก export ใน PureBasic มีเพียงชื่อที่ระบุใน `DeclareModule` เท่านั้นที่ถูก export การ isolation เข้มงวดกว่า

### รูปแบบ Types Module

มีผลสืบเนื่องสำคัญจาก module isolation: ถ้าคุณนิยาม structure ภายนอก module ทั้งหมด procedure ภายใน module จะไม่สามารถใช้มันได้ PureSimple แก้ปัญหานี้โดยใส่ type ที่แชร์ร่วมกันทั้งหมดไว้ใน module `Types`:

```purebasic
DeclareModule Types
  Structure RequestContext
    Method.s
    Path.s
    ; ... other fields
  EndStructure
EndDeclareModule

Module Types
  ; No runtime code -- pure type library
EndModule
```

จากนั้น ทุก module ที่ต้องการใช้จะเพิ่ม `UseModule Types` ไว้ด้านบนของ block `Module`:

```purebasic
Module Engine
  UseModule Types   ; now *C.RequestContext works here
  ; ...
EndModule
```

และโปรแกรมหลักเพิ่ม `UseModule Types` ที่ระดับโปรแกรม เพื่อให้ application code เขียน `*C.RequestContext` ได้แทน `Types::RequestContext` รูปแบบนี้ปรากฏใน `src/PureSimple.pb`:

```purebasic
XIncludeFile "Types.pbi"
UseModule Types        ; import into global scope
```

## 2.6 การจัดการ Error

PureBasic ไม่มี exception ในแบบ try/catch มันมีกลไกการจัดการ error สองแบบ และคุณจะใช้ทั้งสอง

### รูปแบบ Return-Code

รูปแบบที่พบบ่อยที่สุดคือการตรวจสอบค่าที่ return กลับมา:

```purebasic
; Listing 2.6 -- Return-code and OnErrorGoto patterns
EnableExplicit

Protected file.i = ReadFile(#PB_Any, "config.txt")
If file = 0
  PrintN("Cannot open config.txt")
  End 1
EndIf

; File is open, proceed
Protected line.s = ReadString(file)
CloseFile(file)
```

function ส่วนใหญ่ของ PureBasic return 0 เมื่อเกิดข้อผิดพลาด และ handle ที่ไม่ใช่ศูนย์เมื่อสำเร็จ เรื่องนี้ชัดเจนและเชื่อถือได้

### OnErrorGoto

สำหรับการดักจับ runtime error เช่น null pointer dereference หรือการหารด้วยศูนย์ PureBasic มี `OnErrorGoto`:

```purebasic
OnErrorGoto(?ErrorHandler)

; Code that might fail
Protected *ptr.Integer = 0
*ptr\i = 42  ; null pointer dereference

; This label catches the error
ErrorHandler:
PrintN("Error: " + ErrorMessage())
PrintN("  at line " + Str(ErrorLine()))
PrintN("  in file " + ErrorFile())
End 1
```

`ErrorMessage()`, `ErrorLine()` และ `ErrorFile()` ให้ข้อมูลวิเคราะห์เกี่ยวกับสิ่งที่ผิดพลาดและที่ไหน Recovery middleware ใน PureSimple ใช้รูปแบบนี้เพื่อดักจับ runtime error ภายใน handler และส่ง response 500 แทนการ crash server

> **ข้อควรระวังใน PureBasic:** ไม่มี function `FileExists()` ในการตรวจสอบว่าไฟล์มีอยู่จริง ให้ใช้ `FileSize(path) >= 0` `FileSize` return -1 สำหรับไฟล์ที่ไม่มีอยู่ และ -2 สำหรับ directory เคยใช้เวลาสามชั่วโมง debug การเรียก `FileExists()` ก่อนจะค้นพบว่ามันไม่มีอยู่จริง ในหมายความว่า function นะ ส่วนไฟล์นั้นอยู่ครบดี

## 2.7 คำสงวนที่จะทำให้คุณสะดุด

PureBasic สงวนคำภาษาอังกฤษทั่วไปหลายคำไว้สำหรับ syntax ของตัวเอง ถ้าคุณพยายามใช้คำเหล่านี้เป็นชื่อ procedure, ชื่อตัวแปร หรือชื่อ parameter compiler จะแสดง error message ที่ทำให้งงมาก นี่คือตารางคำที่สำคัญที่สุดสำหรับ web development:

```purebasic
; Listing 2.7 -- Reserved word workarounds
;
; Reserved Word  | PureBasic Uses It For     | PureSimple Workaround
; ---------------------------------------------------------------
; Next           | For...Next loop closing   | Ctx::Advance
; Default        | Select...Case...Default   | Use "fallback" or "def"
; Data           | Data statement (inline)   | Use "payload" or "body"
; Debug          | IDE debug output          | Use Log:: module instead
; Read           | Read from Data block      | Use "fetch" or "load"
; End            | Program termination       | (use carefully)
; FreeJSON       | Built-in JSON cleanup     | Binding::ReleaseJSON
; Assert         | PureUnit halt-on-fail     | Check (test harness)
; AssertString   | PureUnit string assert    | CheckStr (test harness)
```

method ชื่อว่า `Advance` เพราะ `Next` เป็นคำสงวน PureBasic มีความคิดเห็นที่แน่วแน่เกี่ยวกับ loop `For...Next` และจะไม่ยอมต่อรอง

ในทำนองเดียวกัน PureSimple ใช้ `ReleaseJSON` แทน `FreeJSON` เพราะ PureBasic 6.x นิยาม `FreeJSON` ไว้เป็น built-in function อยู่แล้ว การนิยามซ้ำทำให้เกิด silent conflict ที่เรียกใช้เวอร์ชันผิด

---

## สรุป

PureBasic เป็นภาษา typed ที่ compile แล้ว มีการประกาศตัวแปรอย่างชัดเจน และมีระบบ module ที่บังคับใช้ encapsulation อย่างเข้มงวด ระบบ type มีขนาดเล็กแต่ต้องให้ความสนใจกับ `.i` type ที่มีขนาดเท่ากับ pointer String จัดการผ่าน function ไม่ใช่ method Structure, map, list และ array ต่างมีจุดประสงค์ต่างกัน และการเลือกให้ถูกประเภทส่งผลต่อทั้งความถูกต้องและ performance Module แยก implementation detail ไว้หลัง interface ของ `DeclareModule` และรูปแบบ `Types` module ทำให้ shared structure ใช้ได้ข้ามขอบเขต module คำภาษาอังกฤษทั่วไปหลายคำถูกสงวนไว้ และ framework เปลี่ยนชื่อ API เพื่อหลีกเลี่ยงการชนกัน

## ประเด็นสำคัญ

- **ใช้ `EnableExplicit` เสมอ** มันเปลี่ยน compiler จากผู้สมรู้ร่วมคิดที่เงียบงันให้กลายเป็นผู้ช่วยดักจับ error ทุกไฟล์ใน PureSimple เริ่มต้นด้วยมัน
- **`.i` มีขนาดเท่ากับ pointer ไม่ใช่ 32-bit** เป็น 4 bytes บน x86 และ 8 bytes บน x64 ใช้สำหรับ handle และ pointer ใช้ `.l` หรือ `.q` เมื่อต้องการขนาดเฉพาะ
- **Module body เป็น black box** ใช้ `DeclareModule` เพื่อเปิดเผย public interface และ `UseModule Types` เพื่อแชร์ structure ข้าม module
- **คำภาษาอังกฤษทั่วไปหลายคำถูกสงวนไว้** `Next`, `Default`, `Data`, `Debug`, `Assert` และ `FreeJSON` ไม่สามารถใช้เป็น identifier ของตัวเอง PureSimple มีทางแก้ไขสำหรับแต่ละอัน

## คำถามทบทวน

1. ทำไม `Dim a(5)` จึงสร้างหก element และจะเขียน declaration ที่สร้าง element ห้าตัวพอดีได้อย่างไร
2. อธิบายความแตกต่างระหว่าง `IncludeFile` และ `XIncludeFile` ทำไม PureSimple จึงใช้ `XIncludeFile` เท่านั้น
3. *ลองทำ:* เขียน module ชื่อ `Greeter` ที่เปิดเผย procedure `Greet(name.s)` ที่ return `"Hello, " + name + "!"` เรียกใช้จาก main code โดยใช้ทั้ง syntax `Greeter::Greet()` และ syntax `UseModule` Compile ด้วย `EnableExplicit` และตรวจสอบว่ารันได้
