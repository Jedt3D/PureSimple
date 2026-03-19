# ภาคผนวก ง: Compiler Flags Reference

PureBasic compiler (`pbcompiler`) ใช้งานผ่าน command line บน macOS เส้นทางทั่วไปคือ:

```
/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler
```

กำหนด environment variable `PUREBASIC_HOME` เพื่อให้คำสั่งสั้นลง:

```bash
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"
$PUREBASIC_HOME/compilers/pbcompiler <flags> <source.pb>
```

บน Linux มักติดตั้ง PureBasic ไว้ที่ `/usr/local/purebasic/` หรือ `~/purebasic/` บน Windows ค่าเริ่มต้นคือ `C:\Program Files\PureBasic\`

---

## ง.1 Flag พื้นฐาน

นี่คือ flag ที่ใช้ตลอดทั้งเล่ม นักพัฒนา PureSimple ทุกคนควรรู้จัก

| Flag | คำอธิบาย | เมื่อใดควรใช้ | ตัวอย่าง |
|---|---|---|---|
| `-cl` | Console application | **จำเป็น** สำหรับ web server และ test runner หากไม่ใส่ PureBasic จะผลิต binary แบบ GUI ที่เขียนไปยัง stdout ไม่ได้ | `pbcompiler main.pb -cl -o app` |
| `-o <name>` | ชื่อ binary ที่ output | ใส่เสมอ หากไม่ใส่ จะใช้ชื่อ binary ที่ derive จากชื่อไฟล์ต้นทาง | `pbcompiler main.pb -cl -o myapp` |
| `-z` | เปิดใช้ C optimiser | Build production/release ผลิต binary ที่เล็กและเร็วขึ้น แต่ compile ใช้เวลานานกว่า | `pbcompiler main.pb -cl -z -o app` |
| `-k` | ตรวจ syntax เท่านั้น | ระหว่าง development เพื่อ feedback รวดเร็ว ไม่ผลิต binary เร็วกว่า compile เต็มรูปแบบประมาณ 10 เท่า | `pbcompiler main.pb -k` |
| `-t` | Thread-safe mode | เมื่อแอปพลิเคชันใช้ thread จำเป็นสำหรับโค้ดที่ทำงานแบบ concurrent | `pbcompiler main.pb -cl -t -o app` |
| `-dl` | Shared library / DLL | เมื่อต้องการ build shared library (`.so` / `.dylib` / `.dll`) ไฟล์ต้นทางต้องมี entry `ProcedureDLL` | `pbcompiler plugin.pb -dl -o plugin.so` |

---

## ง.2 Flag ทั้งหมด

| Flag | คำอธิบาย | หมายเหตุ |
|---|---|---|
| `-cl` | Console application | เปิดใช้ `OpenConsole()`, `PrintN()`, stdin/stdout หากไม่มี flag นี้ output จะไปยัง GUI debug window แทน terminal |
| `-o <path>` | เส้นทาง output file | ชื่อหรือ path เต็มของ binary ที่ได้ บน Linux/macOS binary ไม่มี extension ตามค่าเริ่มต้น |
| `-z` | C optimiser | ส่ง optimisation flag ไปยัง C compiler ที่อยู่ข้างใต้ ใช้เวลา compile นานขึ้นแต่โค้ดเร็วขึ้นอย่างวัดได้ |
| `-k` | Syntax check | Parse และ type-check ต้นทางโดยไม่ผลิต binary เหมาะสำหรับ CI/CD pipeline และ editor integration |
| `-t` | Thread-safe mode | Link กับ runtime ของ PureBasic แบบ thread-safe จำเป็นถ้าเรียก `CreateThread()` ที่ใดก็ตาม |
| `-dl` | Shared library | ผลิต `.so` (Linux), `.dylib` (macOS) หรือ `.dll` (Windows) แทน executable |
| `-e <path>` | Executable path | ทางเลือกแทน `-o` กำหนด output executable path |
| `-r <path>` | Resident file | Include ไฟล์ `.res` resident (นิยาม constant และ structure ที่ pre-compile แล้ว) |
| `-q` | Quiet mode | ระงับ compiler output ที่ไม่ใช่ error เหมาะสำหรับ CI script ที่ต้องการเห็นเฉพาะ failure |
| `-v` | Version | แสดงเลข version ของ compiler แล้วออก |
| `-h` | Help | แสดงข้อมูลการใช้งานแล้วออก |
| `-d <name>=<val>` | กำหนด constant | กำหนด compiler constant ก่อน compile เทียบเท่ากับ `#name = val` ในต้นทาง |
| `-u` | Unicode mode | เปิดใช้การจัดการสตริงแบบ Unicode นี่คือค่าเริ่มต้นใน PureBasic 6.x |
| `-a` | ASCII mode | บังคับใช้การจัดการสตริงแบบ ASCII (legacy) ไม่แนะนำสำหรับ web application |
| `-p` | Purifier | เปิดใช้ memory purifier ตรวจจับการเข้าถึงนอก bounds และ use-after-free โดยแลกกับ performance ใช้สำหรับ development/debugging เท่านั้น |
| `-x` | Enable OnError | เปิดใช้ `OnErrorGoto` / `OnErrorResume` จำเป็นสำหรับ Recovery middleware ให้ทำงานได้ |

---

## ง.3 การรวม Flag ที่ใช้บ่อย

### Development Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -o app
```

Compile เร็ว ไม่มี optimisation เหมาะสำหรับ loop แก้โค้ด-compile-ทดสอบ

### Syntax Check

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -k
```

ตรวจหา syntax error และ type error โดยไม่ผลิต binary เป็น feedback loop ที่เร็วที่สุด

### Release Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -z -o app
```

เปิด optimisation เต็มรูปแบบ ใช้สำหรับการ deploy ไปยัง production

### Test Runner

```bash
$PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb -cl -o run_all
./run_all
```

Compile test harness เป็น console application แล้วรัน

### Thread-Safe Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -t -o app
```

จำเป็นเมื่อ PureSimpleHTTPServer ใช้ thread สำหรับจัดการ connection แบบ concurrent

### Shared Library

```bash
$PUREBASIC_HOME/compilers/pbcompiler plugin.pb -dl -o plugin.so
```

Build shared library เพื่อใช้เป็น plugin หรือ FFI target

### Debug ด้วย Purifier

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -p -o app_debug
./app_debug
```

ตรวจจับ memory error ขณะ runtime ช้า แต่ทรงคุณค่ามากสำหรับการติดตาม crash

### กำหนด Constant

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -d VERSION='"1.0.0"' -o app
```

ค่าคงที่ `#VERSION` จะใช้ได้ในต้นทางเป็น `"1.0.0"`

---

## ง.4 Compiler Constant

PureBasic มี constant built-in ที่ใช้ได้ขณะ compile time เหมาะสำหรับ conditional compilation และ diagnostic output

| ค่าคงที่ | ชนิด | คำอธิบาย |
|---|---|---|
| `#PB_Compiler_OS` | Integer | ระบบปฏิบัติการ: `#PB_OS_Windows`, `#PB_OS_Linux`, `#PB_OS_MacOS` |
| `#PB_Compiler_Processor` | Integer | สถาปัตยกรรม CPU: `#PB_Processor_x86`, `#PB_Processor_x64`, `#PB_Processor_arm64` |
| `#PB_Compiler_Home` | String | directory ติดตั้ง PureBasic |
| `#PB_Compiler_File` | String | เส้นทางไฟล์ต้นทางปัจจุบัน |
| `#PB_Compiler_Line` | Integer | เลขบรรทัดต้นทางปัจจุบัน |
| `#PB_Compiler_Procedure` | String | ชื่อ procedure ปัจจุบัน |
| `#PB_Compiler_Module` | String | ชื่อ module ปัจจุบัน |
| `#PB_Compiler_Date` | Integer | วันที่ compile (Unix timestamp) |
| `#PB_Compiler_Version` | Integer | เลข version ของ compiler (เช่น 630 สำหรับ v6.30) |
| `#PB_Compiler_Unicode` | Boolean | `#True` ถ้า compile ใน Unicode mode |
| `#PB_Compiler_Thread` | Boolean | `#True` ถ้า compile ด้วย flag `-t` |
| `#PB_Compiler_Debugger` | Boolean | `#True` ถ้า compile พร้อม debugger |
| `#PB_Compiler_Backend` | Integer | `#PB_Backend_C` สำหรับ C backend |

### ตัวอย่าง Cross-Platform Compilation

```purebasic
CompilerSelect #PB_Compiler_OS
  CompilerCase #PB_OS_MacOS
    #PathSep = "/"
    #CompilerPath = "/Applications/PureBasic.app/Contents/Resources/compilers/"
  CompilerCase #PB_OS_Linux
    #PathSep = "/"
    #CompilerPath = "/usr/local/purebasic/compilers/"
  CompilerCase #PB_OS_Windows
    #PathSep = "\"
    #CompilerPath = "C:\Program Files\PureBasic\Compilers\"
CompilerEndSelect
```

### ตัวอย่าง Diagnostic Output

```purebasic
Procedure LogError(msg.s)
  PrintN("[ERROR] " + msg)
  PrintN("  File: " + #PB_Compiler_File)
  PrintN("  Line: " + Str(#PB_Compiler_Line))
  PrintN("  Proc: " + #PB_Compiler_Procedure)
EndProcedure
```

---

## ง.5 Include Directive

สิ่งเหล่านี้ไม่ใช่ compiler flag แต่ควบคุมว่าไฟล์ต้นทางใดจะรวมอยู่ใน compilation unit ใช้อย่างแพร่หลายตลอด PureSimple

| Directive | คำอธิบาย |
|---|---|
| `XIncludeFile "path.pbi"` | Include ไฟล์ ถ้าเคย include แล้วจะข้าม (ป้องกัน duplicate definition) **ใช้นี้เสมอ** |
| `IncludeFile "path.pbi"` | Include ไฟล์โดยไม่มีเงื่อนไข ถ้า include สองครั้งจะเกิด duplicate definition error |
| `IncludePath "path/"` | กำหนด base path สำหรับ `IncludeFile` / `XIncludeFile` ที่ตามมา |
| `IncludeBinary "path"` | ฝังไฟล์ binary (ภาพ, ข้อมูล) เข้าใน executable |

### เหตุใดจึงใช้ XIncludeFile

เมื่อ module A include `Types.pbi` และ module B ก็ include `Types.pbi` เช่นกัน การใช้ `IncludeFile` ในทั้งสองจะทำให้ compiler ประมวลผล `Types.pbi` สองครั้ง เกิด error "structure already declared" `XIncludeFile` ติดตามไฟล์ที่เคย include แล้วและข้ามไฟล์ซ้ำโดยอัตโนมัติ ทำให้ปลอดภัยสำหรับ dependency graph แบบ diamond ที่หลาย module ขึ้นอยู่กับ type definition เดียวกัน ทุกไฟล์ `.pbi` ใน PureSimple ใช้ `XIncludeFile` เท่านั้น

---

## ง.6 การใช้ Compiler บน Windows

บน Windows PureBasic ติดตั้งไว้ที่ `C:\Program Files\PureBasic` ตามค่าเริ่มต้น compiler flag เหมือนกับ macOS และ Linux ต่างกันแค่เส้นทางและ extension ของ output

```
# Windows (Command Prompt)
"C:\Program Files\PureBasic\Compilers\pbcompiler.exe" main.pb -cl -o app.exe

# Windows (PowerShell)
& "C:\Program Files\PureBasic\Compilers\pbcompiler.exe" main.pb -cl -o app.exe
```

กำหนด `PUREBASIC_HOME` เพื่อให้คำสั่งซ้ำๆ กระทัดรัดขึ้น:

```
# Command Prompt
set PUREBASIC_HOME=C:\Program Files\PureBasic
"%PUREBASIC_HOME%\Compilers\pbcompiler.exe" main.pb -cl -o app.exe

# PowerShell
$env:PUREBASIC_HOME = "C:\Program Files\PureBasic"
& "$env:PUREBASIC_HOME\Compilers\pbcompiler.exe" main.pb -cl -o app.exe
```

---

## ง.7 บัตรอ้างอิงฉบับย่อ

ปริ้นออกมาแล้วติดไว้ข้างจอ

```
Development:    pbcompiler main.pb -cl -o app
Syntax check:   pbcompiler main.pb -k
Release:        pbcompiler main.pb -cl -z -o app
Tests:          pbcompiler tests/run_all.pb -cl -o run_all && ./run_all
Thread-safe:    pbcompiler main.pb -cl -t -o app
Debug memory:   pbcompiler main.pb -cl -p -o app_debug
```
