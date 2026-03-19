# ภาคผนวก ก: คู่มืออ้างอิง PureBasic สำหรับนักพัฒนาเว็บ

ภาคผนวกนี้เป็นคู่มืออ้างอิงประจำโต๊ะทำงานสำหรับนักพัฒนาที่มาจาก Go, Python, C หรือ JavaScript แล้วต้องการเรียนรู้ PureBasic เปิดทิ้งไว้ขณะอ่านโค้ด framework เมื่อเขียน handler สักสองสามตัวแล้ว ทุกอย่างในนี้จะฝังอยู่ในหัวโดยอัตโนมัติ

---

## ก.1 ตารางเปรียบเทียบภาษา

ตารางด้านล่างแสดงการ mapping แนวคิดที่คุณรู้จักอยู่แล้วไปยังคู่เทียบใน PureBasic ในกรณีที่ PureBasic ทำงานต่างออกไป คอลัมน์ "หมายเหตุ" จะอธิบายเหตุผล

| แนวคิด | PureBasic | Go | Python | C |
|---|---|---|---|---|
| **ชนิดจำนวนเต็ม** | `.i` (ขนาดตาม pointer) | `int` | `int` | `intptr_t` |
| **จำนวนเต็ม 32-bit** | `.l` (Long) | `int32` | N/A | `int32_t` |
| **จำนวนเต็ม 64-bit** | `.q` (Quad) | `int64` | N/A | `int64_t` |
| **ทศนิยม** | `.f` (32-bit) | `float32` | N/A | `float` |
| **ทศนิยมความแม่น double** | `.d` (64-bit) | `float64` | `float` | `double` |
| **Byte** | `.b` | `byte` | N/A | `char` |
| **Word (16-bit)** | `.w` | `int16` | N/A | `int16_t` |
| **สตริง** | `.s` | `string` | `str` | `char*` |
| **บูลีน** | `.i` (`#True`/`#False`) | `bool` | `bool` | `_Bool` / `int` |
| **Struct** | `Structure...EndStructure` | `type struct` | `@dataclass` | `struct` |
| **Hash map** | `NewMap name.type()` | `map[K]V` | `dict` | N/A (สร้างเอง) |
| **Linked list** | `NewList name.type()` | `list.List` | `list` | N/A (สร้างเอง) |
| **Array** | `Dim name.type(N)` | `[N]type` | `list` | `type name[N]` |
| **ฟังก์ชัน** | `Procedure Name()` | `func Name()` | `def name():` | `void name()` |
| **ค่าที่คืนกลับ** | `ProcedureReturn val` | `return val` | `return val` | `return val` |
| **Function pointer** | `Prototype.i Fn(*arg)` | `type Fn func(arg)` | callable | `typedef int (*Fn)(arg)` |
| **ที่อยู่ของฟังก์ชัน** | `@MyProc()` | N/A (closures) | N/A | `&myFunc` |
| **Module / package** | `DeclareModule...Module` | `package` | `import module` | `#include` |
| **Import module** | `UseModule Name` | `import "pkg"` | `from pkg import *` | N/A |
| **จัดการข้อผิดพลาด** | Return code + `OnErrorGoto` | `if err != nil` | `try/except` | Return code |
| **Escape ในสตริง** | `~"hello\n"` | `"hello\n"` | `"hello\n"` | `"hello\n"` |
| **ต่อสตริง** | `a + b` | `a + b` | `a + b` | `strcat()` |
| **ประกาศตัวแปรแบบ Explicit** | `EnableExplicit` | Implicit (`:=`) | N/A | Implicit |
| **Scope qualifier** | `Protected` / `Global` | Package-level | `global` | `static` / `extern` |
| **ลูป for** | `For i = 0 To N ... Next` | `for i := 0; i <= N; i++` | `for i in range(N+1):` | `for (int i=0; i<=N; i++)` |
| **ลูป while** | `While cond ... Wend` | `for cond { }` | `while cond:` | `while (cond) { }` |
| **เงื่อนไข** | `If ... ElseIf ... Else ... EndIf` | `if ... else if ... else` | `if ... elif ... else:` | `if ... else if ... else` |
| **Switch** | `Select val ... Case ... Default ... EndSelect` | `switch val` | `match val:` (3.10+) | `switch (val)` |
| **Include file** | `XIncludeFile "file.pbi"` | `import "pkg"` | `import module` | `#include "file.h"` |
| **ค่าคงที่** | `#Name = value` | `const Name = value` | `NAME = value` | `#define NAME value` |
| **Null pointer** | `0` หรือ `#Null` | `nil` | `None` | `NULL` |
| **พิมพ์ไปยัง stdout** | `PrintN("text")` | `fmt.Println("text")` | `print("text")` | `printf("text\n")` |
| **คอมไพล์** | `pbcompiler file.pb` | `go build file.go` | Interpreted | `gcc file.c` |

**เส้นทาง compiler แยกตามแพลตฟอร์ม:**

| แพลตฟอร์ม | `PUREBASIC_HOME` | เส้นทาง compiler |
|---|---|---|
| macOS | `/Applications/PureBasic.app/Contents/Resources` | `$PUREBASIC_HOME/compilers/pbcompiler` |
| Linux | `/usr/local/purebasic` (โดยทั่วไป) | `$PUREBASIC_HOME/compilers/pbcompiler` |
| Windows (CMD) | `C:\Program Files\PureBasic` | `"%PUREBASIC_HOME%\Compilers\pbcompiler.exe"` |
| Windows (PowerShell) | `C:\Program Files\PureBasic` | `& "$env:PUREBASIC_HOME\Compilers\pbcompiler.exe"` |

---

## ก.2 Cheat Sheet Standard Library

### ฟังก์ชันจัดการสตริง

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `Len(s)` | ความยาวสตริง | `Len("hello")` = 5 |
| `Left(s, n)` | n ตัวอักษรแรก | `Left("hello", 3)` = `"hel"` |
| `Right(s, n)` | n ตัวอักษรสุดท้าย | `Right("hello", 3)` = `"llo"` |
| `Mid(s, start, len)` | สตริงย่อย (นับจาก 1) | `Mid("hello", 2, 3)` = `"ell"` |
| `FindString(s, sub)` | ค้นหาสตริงย่อย (นับจาก 1, 0 = ไม่พบ) | `FindString("hello", "ll")` = 3 |
| `ReplaceString(s, old, new)` | แทนที่ทุก occurrence | `ReplaceString("aab", "a", "x")` = `"xxb"` |
| `UCase(s)` | ตัวพิมพ์ใหญ่ทั้งหมด | `UCase("hello")` = `"HELLO"` |
| `LCase(s)` | ตัวพิมพ์เล็กทั้งหมด | `LCase("HELLO")` = `"hello"` |
| `Trim(s)` | ตัด whitespace หน้า-หลัง | `Trim("  hi  ")` = `"hi"` |
| `LTrim(s)` | ตัด whitespace หน้า | `LTrim("  hi")` = `"hi"` |
| `RTrim(s)` | ตัด whitespace หลัง | `RTrim("hi  ")` = `"hi"` |
| `StringField(s, index, delim)` | แยกสตริงและดึง field ที่ N (นับจาก 1) | `StringField("a,b,c", 2, ",")` = `"b"` |
| `CountString(s, sub)` | นับจำนวน occurrence | `CountString("abab", "ab")` = 2 |
| `Str(n)` | แปลงจำนวนเต็มเป็นสตริง | `Str(42)` = `"42"` |
| `StrD(d, decimals)` | แปลง double เป็นสตริง | `StrD(3.14, 2)` = `"3.14"` |
| `Val(s)` | แปลงสตริงเป็นจำนวนเต็ม | `Val("42")` = 42 |
| `ValD(s)` | แปลงสตริงเป็น double | `ValD("3.14")` = 3.14 |
| `Chr(n)` | รหัสตัวอักษรเป็นสตริง | `Chr(65)` = `"A"` |
| `Asc(s)` | ตัวอักษรแรกเป็นรหัส | `Asc("A")` = 65 |
| `Space(n)` | สตริง space จำนวน n ตัว | `Space(5)` = `"     "` |

### ฟังก์ชันจัดการไฟล์

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `FileSize(path)` | ขนาดไฟล์เป็นไบต์ (-1 = ไม่พบ, -2 = เป็น directory) | `If FileSize("app.db") >= 0` |
| `ReadFile(id, path)` | เปิดไฟล์เพื่ออ่าน | `f = ReadFile(#PB_Any, "data.txt")` |
| `CreateFile(id, path)` | สร้าง/เขียนทับเพื่อเขียน | `f = CreateFile(#PB_Any, "out.txt")` |
| `OpenFile(id, path)` | เปิดเพื่ออ่านและเขียน | `f = OpenFile(#PB_Any, "log.txt")` |
| `CloseFile(f)` | ปิด file handle | `CloseFile(f)` |
| `ReadString(f)` | อ่านหนึ่งบรรทัด | `line.s = ReadString(f)` |
| `WriteStringN(f, s)` | เขียนบรรทัดพร้อม newline | `WriteStringN(f, "hello")` |
| `WriteString(f, s)` | เขียนโดยไม่มี newline | `WriteString(f, "data")` |
| `Eof(f)` | ถึงท้ายไฟล์แล้วหรือยัง | `While Not Eof(f) ... Wend` |
| `Lof(f)` | ขนาดไฟล์เป็นไบต์ | `size = Lof(f)` |
| `FileSeek(f, pos)` | เลื่อนไปยัง byte offset ที่กำหนด | `FileSeek(f, Lof(f))` |
| `GetCurrentDirectory()` | directory ทำงานปัจจุบัน | `cwd.s = GetCurrentDirectory()` |
| `GetTemporaryDirectory()` | directory temp ของ OS | `tmp.s = GetTemporaryDirectory()` |

### ฟังก์ชัน JSON

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `ParseJSON(id, text)` | แปลง JSON string | `j = ParseJSON(#PB_Any, body)` |
| `JSONValue(j)` | root value handle | `*root = JSONValue(j)` |
| `GetJSONString(*val)` | ดึงค่าสตริงจาก value | `name.s = GetJSONString(*val)` |
| `GetJSONInteger(*val)` | ดึงค่าจำนวนเต็มจาก value | `age.i = GetJSONInteger(*val)` |
| `GetJSONDouble(*val)` | ดึงค่า double จาก value | `score.d = GetJSONDouble(*val)` |
| `GetJSONBoolean(*val)` | ดึงค่าบูลีนจาก value | `ok.i = GetJSONBoolean(*val)` |
| `JSONObjectMember(*obj, key)` | ดึง member ตามชื่อ key | `*name = JSONObjectMember(*root, "name")` |
| `JSONArraySize(*arr)` | จำนวน element ใน array | `n = JSONArraySize(*arr)` |
| `GetJSONElement(*arr, idx)` | ดึง element ตาม index | `*elem = GetJSONElement(*arr, 0)` |
| `FreeJSON(j)` | คืน memory ของ JSON ที่ parse แล้ว | `FreeJSON(j)` |
| `CreateJSON(id)` | สร้าง JSON ว่าง | `j = CreateJSON(#PB_Any)` |
| `SetJSONString(*val, s)` | กำหนดค่าสตริง | `SetJSONString(*val, "hello")` |
| `SetJSONInteger(*val, n)` | กำหนดค่าจำนวนเต็ม | `SetJSONInteger(*val, 42)` |
| `ComposeJSON(j)` | แปลง JSON เป็นสตริง | `result.s = ComposeJSON(j)` |

### การเข้ารหัสและ Hashing

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `Fingerprint(mem, size, type)` | Hash memory buffer | `Fingerprint(*buf, sz, #PB_Cipher_SHA2)` |
| `StringFingerprint(s, type)` | Hash สตริง | `StringFingerprint("pass", #PB_Cipher_SHA2, 256)` |
| `Base64Encoder(*in, inLen, *out, outLen)` | เข้ารหัส Base64 | `Base64Encoder(*src, sz, *dst, dstSz)` |
| `Base64Decoder(*in, inLen, *out, outLen)` | ถอดรหัส Base64 | `Base64Decoder(*src, sz, *dst, dstSz)` |

### วันที่และเวลา

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `Date()` | Unix timestamp ปัจจุบัน | `now.i = Date()` |
| `FormatDate(fmt, date)` | จัดรูปแบบวันที่ | `FormatDate("%yyyy-%mm-%dd", Date())` |
| `Year(date)` | ดึงปี | `y = Year(Date())` |
| `Month(date)`, `Day(date)` | ดึงเดือน/วัน | `m = Month(Date())` |
| `ElapsedMilliseconds()` | นาฬิกา monotonic | `start = ElapsedMilliseconds()` |
| `Delay(ms)` | หยุดรอ (sleep) | `Delay(1000)` (รอ 1 วินาที) |

### หน่วยความจำและระบบ

| ฟังก์ชัน | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `AllocateMemory(size)` | จองหน่วยความจำ | `*buf = AllocateMemory(1024)` |
| `FreeMemory(*buf)` | คืนหน่วยความจำ | `FreeMemory(*buf)` |
| `PokeS(*mem, s)` | เขียนสตริงลง memory | `PokeS(*buf, "hello")` |
| `PeekS(*mem)` | อ่านสตริงจาก memory | `s.s = PeekS(*buf)` |
| `CopyMemory(*src, *dst, size)` | คัดลอก bytes | `CopyMemory(*a, *b, 100)` |
| `Random(max)` | จำนวนสุ่ม 0..max | `n = Random(100)` |
| `RandomSeed(seed)` | กำหนด seed สุ่ม | `RandomSeed(Date())` |

---

## ก.3 ตารางข้อผิดพลาดที่พบบ่อย (Common Gotchas)

สิ่งเหล่านี้คือจุดพลาดที่มือใหม่ PureBasic ทุกคนเคยสะดุด กล่อง "PureBasic Gotcha" ตลอดทั้งเล่มล้วนอ้างอิงตารางนี้ ทุก entry ได้มาจากการทำงานจริงบนโปรเจค PureSimple

| # | ข้อผิดพลาด | สิ่งที่คาดหวัง | สิ่งที่เกิดขึ้นจริง | วิธีแก้ไข |
|---|---|---|---|---|
| 1 | **`FileExists()` ไม่มีอยู่** | ฟังก์ชันตรวจสอบว่าไฟล์มีอยู่หรือไม่ | Compiler error: ไม่รู้จักฟังก์ชัน | ใช้ `FileSize(path) >= 0` แทน คืน -1 ถ้าไม่พบ, -2 ถ้าเป็น directory |
| 2 | **`Dim a(N)` สร้าง N+1 elements** | `Dim a(5)` สร้าง 5 elements | สร้าง 6 elements (index 0 ถึง 5) | ใช้ `Dim a(N-1)` ถ้าต้องการ N elements พอดี |
| 3 | **ชนิด `.i` มีขนาดตาม pointer** | `.i` มีขนาด 4 ไบต์เสมอ | 4 ไบต์บน x86, 8 ไบต์บน x64 | ใช้ `.l` สำหรับ 32-bit คงที่, `.q` สำหรับ 64-bit คงที่ ใช้ `.i` สำหรับ handle, ID และตัวแปรลูป |
| 4 | **`Next` เป็น reserved keyword** | ใช้ `Next()` เป็นชื่อ procedure | Compiler error: `Next` ปิดลูป `For...Next` | PureSimple ใช้ `Advance` แทน วางแผนชื่อให้หลีกเลี่ยง reserved word |
| 5 | **`Default` เป็น reserved keyword** | ใช้ `Default` เป็นชื่อ parameter | Compiler error: `Default` เป็นส่วนหนึ่งของ `Select...Case...Default` | ใช้ชื่ออื่น เช่น `DefaultVal`, `Fallback` |
| 6 | **Module body มองไม่เห็น global** | เข้าถึง structure ในโค้ดหลักได้จากใน `Module` | Compiler error: ไม่พบ structure | ห่อ shared type ไว้ใน `DeclareModule` (เช่น module `Types`) แล้ว `UseModule Types` ในที่ที่ใช้งาน |
| 7 | **`EnableExplicit` เป็นสิ่งจำเป็น** | ตัวแปรประกาศอัตโนมัติเมื่อใช้ครั้งแรก | Typo จะสร้างตัวแปรใหม่แบบเงียบๆ ที่มีค่าเป็น 0 หรือว่าง | เพิ่ม `EnableExplicit` ทุกไฟล์ ไม่มีข้อยกเว้น |
| 8 | **`FreeJSON` เป็น built-in** | กำหนด procedure `FreeJSON` เองใน module | ชื่อชน หรือ shadow กัน | PureSimple ใช้ `ReleaseJSON` เพื่อหลีกเลี่ยงการชน |
| 9 | **สตริง escape ต้องมี prefix `~`** | `"\n"` ได้ newline | ได้ backslash ตามด้วย `n` | เขียน `~"\n"` สำหรับ escape sequence มีเพียงสตริงที่มี `~` นำหน้าเท่านั้นที่แปล `\n`, `\t` ฯลฯ |
| 10 | **`@Proc()` ต้องมีวงเล็บ** | `@MyHandler` เพื่อดึงที่อยู่ | Compiler error หรือได้ที่อยู่ผิด | เขียน `@MyHandler()` พร้อมวงเล็บเปล่าเสมอ |
| 11 | **`@Module::Proc()` ใน Global initializer** | ดึงที่อยู่ procedure ของ module ใน `Global` variable initializer | ได้ค่า 0 เพราะ module procedure address ยังไม่ resolve ตอน `Global` initialisation (ใช้ได้ปกติในระดับโปรแกรม เช่น `Engine::Use(@Logger::Middleware())`) | ห่อไว้ใน procedure ธรรมดาแล้วใช้ที่อยู่ของมันแทน: `Procedure GetAddr() : ProcedureReturn @Module::Proc() : EndProcedure` แล้ว `Global handler.i = GetAddr()` |
| 12 | **Fixed-size struct array ต่างจาก `Dim`** | `arr.i[32]` ใน `Structure` สร้าง 32+1 elements | สร้าง 32 elements พอดี (index 0 ถึง 31) | จำไว้: `Dim a(N)` = N+1 elements; `arr.type[N]` ใน struct = N elements พอดี ทั้งสองใช้แนวทางตรงข้ามกัน |

---

## ก.4 ตารางขนาดชนิดข้อมูล

| ชนิด | Suffix | ขนาด (ไบต์) | ช่วงค่า | การใช้งานทั่วไป |
|---|---|---|---|---|
| Byte | `.b` | 1 | -128 ถึง 127 | Flag, ตัวนับขนาดเล็ก |
| ASCII | `.a` | 1 | 0 ถึง 255 | ค่า byte แบบไม่มีเครื่องหมาย |
| Word | `.w` | 2 | -32768 ถึง 32767 | จำนวนเต็มขนาดเล็ก |
| Unicode | `.u` | 2 | 0 ถึง 65535 | อักขระ UTF-16 |
| Long | `.l` | 4 | -2^31 ถึง 2^31-1 | จำนวนเต็ม 32-bit คงที่ |
| Integer | `.i` | 4 หรือ 8 | ขึ้นอยู่กับแพลตฟอร์ม | Handle, ID, pointer, ตัวแปรลูป |
| Quad | `.q` | 8 | -2^63 ถึง 2^63-1 | จำนวนเต็มขนาดใหญ่, timestamp |
| Float | `.f` | 4 | ~7 ตำแหน่งทศนิยม | ทศนิยม single-precision |
| Double | `.d` | 8 | ~15 ตำแหน่งทศนิยม | ทศนิยม double-precision |
| String | `.s` | ขึ้นอยู่กับเนื้อหา | N/A | ข้อความ (ภายในเก็บเป็น UTF-16) |

---

## ก.5 ตาราง Operator

| Operator | จุดประสงค์ | ตัวอย่าง |
|---|---|---|
| `+` | บวก / ต่อสตริง | `a + b`, `"hello" + " world"` |
| `-` | ลบ | `a - b` |
| `*` | คูณ | `a * b` |
| `/` | หาร | `a / b` |
| `%` | Modulo | `a % b` |
| `=` | กำหนดค่า / ทดสอบความเท่ากัน | `a = 5`, `If a = 5` |
| `<>` | ไม่เท่ากัน | `If a <> b` |
| `<`, `>`, `<=`, `>=` | เปรียบเทียบ | `If a > b` |
| `And` | AND แบบลอจิก/บิต | `If a And b` |
| `Or` | OR แบบลอจิก/บิต | `If a Or b` |
| `Not` | NOT แบบลอจิก/บิต | `If Not ok` |
| `XOr` | XOR แบบบิต | `result = a XOr b` |
| `<<` | Shift ซ้าย | `val << 2` |
| `>>` | Shift ขวา | `val >> 2` |
| `@` | ที่อยู่ของ procedure | `@MyHandler()` |
| `*` | Dereference pointer | `*ctx.RequestContext` |
| `\` | เข้าถึง field ของ structure | `*ctx\Method` |
| `#` | prefix ของค่าคงที่ | `#PB_Any`, `#True` |

---

## ก.6 Control Flow อ้างอิงฉบับย่อ

```purebasic
; If / ElseIf / Else
If condition
  ; ...
ElseIf other
  ; ...
Else
  ; ...
EndIf

; Select / Case (switch)
Select value
  Case 1
    ; ...
  Case 2, 3
    ; ...
  Case 4 To 10
    ; ...
  Default
    ; ...
EndSelect

; For / Next
For i = 0 To 10
  ; i วิ่ง 0, 1, 2, ..., 10 (รวม 10 ด้วย)
Next

; For / Next พร้อม Step
For i = 0 To 100 Step 10
  ; i วิ่ง 0, 10, 20, ..., 100
Next

; While / Wend
While condition
  ; ...
Wend

; Repeat / Until
Repeat
  ; ...
Until condition

; ForEach (สำหรับ list และ map)
ForEach myList()
  ; myList() คือ element ปัจจุบัน
Next
ForEach myMap()
  ; MapKey(myMap()) คือ key ปัจจุบัน
  ; myMap() คือค่าปัจจุบัน
Next
```

---

## ก.7 Module Pattern อ้างอิงฉบับย่อ

```purebasic
; ประกาศ module (ส่วน interface สาธารณะ)
DeclareModule MyModule
  ; ค่าคงที่สาธารณะ
  #Version = 1

  ; Structure สาธารณะ
  Structure Config
    Port.i
    Name.s
  EndStructure

  ; ประกาศ procedure สาธารณะ
  Declare Init(port.i)
  Declare.s GetName()
EndDeclareModule

; ส่วนที่ implement module (body ส่วนตัว)
Module MyModule
  ; ตัวแปรระดับ module (ส่วนตัว)
  Global g_Port.i
  Global g_Name.s

  Procedure Init(port.i)
    g_Port = port
    g_Name = "MyApp"
  EndProcedure

  Procedure.s GetName()
    ProcedureReturn g_Name
  EndProcedure
EndModule

; การใช้งาน module
MyModule::Init(8080)
name.s = MyModule::GetName()

; หรือใช้ UseModule
UseModule MyModule
Init(8080)
name.s = GetName()
UnuseModule MyModule
```
