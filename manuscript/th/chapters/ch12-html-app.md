# บทที่ 12: การสร้างแอปพลิเคชัน HTML

*จาก directory ว่างเปล่าสู่หน้าเว็บที่ render ได้ในการนั่งทำงานครั้งเดียว*

---

**หลังจากอ่านบทนี้แล้ว คุณจะสามารถ:**

- จัดโครงสร้างแอปพลิเคชัน HTML ด้วย directory แยกสำหรับ source, template และ static asset
- สร้าง base template และ extend ด้วยเนื้อหาเฉพาะหน้า
- สร้างหน้า list ที่ iterate ข้อมูลโดยใช้ `split` และ `for` loop ของ PureJinja
- สร้างหน้า detail ที่แสดง item เดียวโดยใช้ route parameter
- Implement หน้า error 404 และ 500 แบบกำหนดเองด้วย PureJinja template

---

## 12.1 โครงสร้างโปรเจกต์

ทุกแอปพลิเคชัน HTML ของ PureSimple ทำตาม directory layout เดียวกัน convention นี้ไม่ได้ถูก enforce โดย framework — คุณสามารถวางไฟล์ไว้ที่ไหนก็ได้ — แต่การทำตามมันจะทำให้โปรเจกต์ของคุณอ่านได้สำหรับทุกคนที่เคยเห็นแอปพลิเคชัน PureSimple มาก่อน และเนื่องจากหนึ่งในคนนั้นจะเป็นคุณเองในอีกหกเดือน นั่นจึงสำคัญ

```
blog/
  main.pb              ; entry point ของแอปพลิเคชัน
  .env                 ; configuration (PORT, MODE ฯลฯ)
  templates/
    index.html          ; template หน้า home
    post.html           ; template หน้า post เดียว
    about.html          ; template หน้า about
  static/
    style.css           ; stylesheet ร่วมกัน (optional)
```

ไฟล์ `main.pb` มีทุกอย่าง: structure definition, data initialization, handler procedure, middleware registration, route registration และ call `Engine::Run` สำหรับแอปพลิเคชันขนาดเล็ก ไฟล์เดียวก็เพียงพอ สำหรับแอปพลิเคชันที่ใหญ่กว่า คุณจะแยก handler และ data access ออกเป็นไฟล์ `.pbi` แยกและ include ด้วย `XIncludeFile` แต่สำหรับ blog ที่มีสี่ route และสาม template ไฟล์เดียวทำให้ทุกอย่างมองเห็นได้โดยไม่ต้องกระโดดระหว่างไฟล์

directory `templates/` เก็บไฟล์ Jinja template `Rendering::Render` รับ template directory เป็น parameter ดังนั้นคุณสามารถตั้งชื่อมันเป็นอะไรก็ได้ แต่ `templates/` คือ convention และค่าเริ่มต้น

directory `static/` เก็บ CSS, JavaScript, รูปภาพ และ asset อื่นๆ PureSimpleHTTPServer ให้บริการไฟล์ static โดยตรงเมื่อตั้งค่าด้วย `Engine::Static` ไฟล์เหล่านี้ข้าม router และ middleware chain ทั้งหมด — HTTP server จัดการมันที่ transport level ซึ่งทั้งเร็วกว่าและเหมาะสมกว่าสำหรับเนื้อหาที่ไม่เปลี่ยนแปลงระหว่าง request

> **เคล็ดลับ:** เก็บ template ไว้ใน directory เฉพาะที่มีนามสกุล `.html` editor ข้อความของคุณจะให้ HTML syntax highlighting และ designer สามารถทำงานกับมันได้โดยไม่ต้องติดตั้ง PureBasic delimiter `{%` และ `{{` เป็น Jinja มาตรฐาน ซึ่ง editor ส่วนใหญ่รู้จักและ highlight ได้อย่างถูกต้อง

---

## 12.2 Entry Point ของแอปพลิเคชัน

มาดู ไฟล์ `examples/blog/main.pb` ซึ่งเป็นแอปพลิเคชัน HTML ที่สมบูรณ์ใน 106 บรรทัด มันแสดงทุกแนวคิดจากบทที่ 5 ถึง 11: routing, binding, context, middleware, rendering และ template

ไฟล์เริ่มต้นด้วย `EnableExplicit` และ include framework:

```purebasic
; ตัวอย่างที่ 12.1 -- Entry point ของแอปพลิเคชัน Blog
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"
```

จากนั้นกำหนด data structure สำหรับ blog post และเริ่มต้น in-memory array:

```purebasic
; ตัวอย่างที่ 12.2 -- Structure ของ blog post และ seed data
Structure BlogPost
  slug.s
  title.s
  author.s
  date.s
  body.s
EndStructure

Global Dim _Posts.BlogPost(2)

Procedure InitPosts()
  _Posts(0)\slug   = "hello-puresimple"
  _Posts(0)\title  = "Hello, PureSimple!"
  _Posts(0)\author = "Alice"
  _Posts(0)\date   = "2026-03-20"
  _Posts(0)\body   = "Welcome to the first post."

  _Posts(1)\slug   = "routing-in-purebasic"
  _Posts(1)\title  = "Routing in PureBasic"
  _Posts(1)\author = "Bob"
  _Posts(1)\date   = "2026-03-21"
  _Posts(1)\body   = "PureSimple uses a radix trie."

  _Posts(2)\slug   = "templates-with-purejinja"
  _Posts(2)\title  = "HTML Templates with PureJinja"
  _Posts(2)\author = "Alice"
  _Posts(2)\date   = "2026-03-22"
  _Posts(2)\body   = "PureJinja brings Jinja templates."
EndProcedure
```

นี่คือ in-memory data store — ไม่ต้องใช้ database บทที่ 13 จะแทนที่สิ่งนี้ด้วย SQLite สำหรับตอนนี้ array คงที่ของสาม post ก็เพียงพอสำหรับการแสดง routing, binding และ template rendering `Dim _Posts.BlogPost(2)` สร้างสามองค์ประกอบ (index 0 ถึง 2) ซึ่งเป็นหนึ่งในลักษณะเฉพาะที่น่าสนใจของ PureBasic: `Dim a(N)` สร้าง N+1 องค์ประกอบ ไม่ใช่ N ถ้าสิ่งนี้ทำให้คุณตกใจ ขอแสดงความยินดี — คุณเป็นนักพัฒนา PureBasic แล้ว

---

## 12.3 หน้า Home: List View

handler หน้า home สร้าง delimited string ของข้อมูล post และส่งไปยัง template:

```purebasic
; ตัวอย่างที่ 12.3 -- Handler หน้า home
Procedure HomeHandler(*C.RequestContext)
  Protected titles.s = ""
  Protected i.i
  For i = 0 To 2
    titles + _Posts(i)\slug + Chr(9) +
             _Posts(i)\title + Chr(9) +
             _Posts(i)\date + Chr(10)
  Next i
  Ctx::Set(*C, "posts", titles)
  Ctx::Set(*C, "site_name",
           Config::Get("SITE_NAME", "PureSimple Blog"))
  Rendering::Render(*C, "index.html",
                    "examples/blog/templates/")
EndProcedure
```

handler encode แต่ละ post เป็น tab-separated line (`slug<TAB>title<TAB>date`) และแยก post ด้วย newline format ที่ delimited นี้คือสะพานเชื่อมระหว่าง typed structure ของ PureBasic กับระบบตัวแปรแบบ string ของ PureJinja

ก่อนที่เราจะดู page template มาให้นิยาม base template ก่อน หน้า HTML ทั้งสามในแอปพลิเคชันนี้ใช้ navigation bar, document structure และ footer เดียวกัน แทนที่จะ duplicate boilerplate นั้นในทุก template เราใช้ template inheritance ของ PureJinja: base template กำหนด skeleton ที่ใช้ร่วมกัน และแต่ละ page template extends มันพร้อมเนื้อหาเฉพาะหน้า

```html
<!-- ตัวอย่างที่ 12.4 -- base.html: shared layout พร้อม block -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{% block title %}{{ site_name }}{% endblock %}</title>
</head>
<body>
  <nav>
    <a href="/">Home</a>
    <a href="/about">About</a>
  </nav>

  {% block content %}{% endblock %}

  <footer>
    <p>&copy; {{ site_name }}</p>
  </footer>
</body>
</html>
```

tag `{% block title %}` และ `{% block content %}` คือ extension point child template override block เหล่านี้ในขณะที่สืบทอดทุกอย่างอื่น — `<!DOCTYPE>`, `<nav>`, `<footer>` ถ้า child template ไม่ override block นั้น เนื้อหาเริ่มต้นของ base template จะถูกใช้ สำหรับ title block ค่าเริ่มต้นคือชื่อ site สำหรับ content block ค่าเริ่มต้นคือว่าง

นี่คือ inheritance model เดียวกับที่ Django, Jinja และ Twig ใช้ ถ้าคุณเคยใช้อย่างใดอย่างหนึ่ง pattern ก็คุ้นเคย ถ้าไม่เคย กฎนั้นง่าย: `{% extends %}` บอกว่า "เริ่มจาก template นี้" และ `{% block %}` บอกว่า "แทนที่ส่วนนี้"

ตอนนี้ index template extends base และให้เนื้อหาของตัวเอง:

```html
<!-- ตัวอย่างที่ 12.5 -- index.html พร้อม template inheritance -->
{% extends "base.html" %}

{% block title %}Home — {{ site_name }}{% endblock %}

{% block content %}
<h1>{{ site_name }}</h1>

{% for line in posts.split('\n') %}
  {% if line %}
    {% set parts = line.split('\t') %}
    <article>
      <h2>
        <a href="/post/{{ parts[0] }}">
          {{ parts[1] }}
        </a>
      </h2>
      <p class="date">{{ parts[2] }}</p>
      <p>
        <a href="/post/{{ parts[0] }}">
          Read more
        </a>
      </p>
    </article>
  {% endif %}
{% endfor %}
{% endblock %}
```

directive `{% extends "base.html" %}` บอก PureJinja ให้เริ่มจาก base template และเติม block `{% block title %}` override title ของหน้า `{% block content %}` ให้ body ของหน้า navigation และ footer มาจาก `base.html` โดยอัตโนมัติ — ถ้าคุณเปลี่ยน nav link ใน base template ทุกหน้าจะรับการเปลี่ยนแปลง

ภายใน content block loop `{% for line in posts.split('\n') %}` iterate ผ่านแต่ละบรรทัด `{% if line %}` guard ข้าม empty line (newline ท้ายหลัง post สุดท้ายสร้าง empty element สุดท้าย) ภายใน loop `{% set parts = line.split('\t') %}` แบ่งแต่ละบรรทัดออกเป็น tab-separated field: `parts[0]` คือ slug, `parts[1]` คือ title และ `parts[2]` คือ date

pattern นี้ — encode ใน handler, decode ใน template — ปรากฏตลอด PureSimple application ไม่ได้ elegant แต่ effective handler มี access ถึง typed structure และ database query template มี access ถึง string operation และ HTML delimited string คือการจับมือระหว่างสองโลก

> **เปรียบเทียบ:** ใน Python Flask คุณจะส่ง list ของ dictionary: `render_template('index.html', posts=posts)` ใน Gin ของ Go คุณจะส่ง slice ของ struct: `c.HTML(200, "index.html", gin.H{"posts": posts})` วิธีการแบบ string ของ PureSimple สะดวกน้อยกว่าแต่หลีกเลี่ยงความจำเป็นสำหรับ runtime reflection หรือ serialisation layer ที่ซับซ้อน trade-off ชัดเจนใน handler ทุกอัน ซึ่งหมายความว่าคุณรู้เสมอว่าข้อมูลใดที่ template ได้รับ

---

## 12.4 หน้า Detail: Single Item View

handler post detail ดึง slug จาก URL หา post ที่ตรงกัน และ render มัน:

```purebasic
; ตัวอย่างที่ 12.6 -- Handler หน้า post detail
Procedure PostHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")
  Protected i.i
  For i = 0 To 2
    If _Posts(i)\slug = slug
      Ctx::Set(*C, "title",  _Posts(i)\title)
      Ctx::Set(*C, "author", _Posts(i)\author)
      Ctx::Set(*C, "date",   _Posts(i)\date)
      Ctx::Set(*C, "body",   _Posts(i)\body)
      Ctx::Set(*C, "site_name",
               Config::Get("SITE_NAME",
                            "PureSimple Blog"))
      Rendering::Render(*C, "post.html",
                        "examples/blog/templates/")
      ProcedureReturn
    EndIf
  Next i
  Engine::HandleNotFound(*C)
EndProcedure
```

handler loop ผ่าน posts array เพื่อหา slug ที่ตรงกัน เมื่อหาเจอ มันตั้ง template variable แยกกันสำหรับแต่ละ field (`title`, `author`, `date`, `body`) และ render `post.html` ถ้าไม่มี post ที่ match กับ slug มันเรียก `Engine::HandleNotFound(*C)` เพื่อ trigger 404 response ของ framework

ต่างจาก handler หน้า home ที่รวม post หลายอันเป็น delimited string เดียว detail handler ตั้งแต่ละ field เป็น KV store entry แยกกัน นี่คือวิธีที่ง่ายกว่าเมื่อแสดง item เดียวที่มี field คงที่ template อ่านแต่ละตัวแปรโดยตรง:

```html
<!-- ตัวอย่างที่ 12.7 -- post.html พร้อม template inheritance -->
{% extends "base.html" %}

{% block title %}{{ title }} — {{ site_name }}{% endblock %}

{% block content %}
  <h1>{{ title }}</h1>
  <p class="meta">By {{ author }} on {{ date }}</p>
  <p class="body">{{ body }}</p>
{% endblock %}
```

ชัดเจน อ่านง่าย และปราศจาก parsing logic navigation และ document structure มาจาก `base.html` post template กำหนดเฉพาะสิ่งที่ unique ของหน้านี้: title และเนื้อหา article สำหรับหน้า single-item หนึ่งตัวแปรต่อ field คือตัวเลือกที่ถูกต้องเสมอ ประหยัด gymnastics ของ `split` ไว้สำหรับหน้า list ที่ต้องส่ง record หลายอัน

---

## 12.5 หน้า Static

ไม่ใช่ทุกหน้าที่ต้องการข้อมูล dynamic handler หน้า about ตั้งเฉพาะชื่อ site และ render template ที่มีเนื้อหา static เป็นส่วนใหญ่:

```purebasic
; ตัวอย่างที่ 12.8 -- Handler หน้า about
Procedure AboutHandler(*C.RequestContext)
  Ctx::Set(*C, "site_name",
           Config::Get("SITE_NAME", "PureSimple Blog"))
  Rendering::Render(*C, "about.html",
                    "examples/blog/templates/")
EndProcedure
```

template เป็น HTML ล้วนๆ ที่มีการแทนที่ตัวแปรเพียงครั้งเดียว:

```html
<!-- ตัวอย่างที่ 12.9 -- about.html พร้อม template inheritance -->
{% extends "base.html" %}

{% block title %}About — {{ site_name }}{% endblock %}

{% block content %}
<h1>About {{ site_name }}</h1>
<p>
  This blog is built with <strong>PureSimple</strong>,
  a lightweight web framework for PureBasic 6.x
  inspired by Go's Gin and Chi.
</p>
<p>
  Templates are rendered by PureJinja, a
  Jinja-compatible template engine written
  entirely in PureBasic.
</p>
{% endblock %}
```

แม้แต่หน้า static ก็ได้ประโยชน์จาก template inheritance หน้า about สืบทอด navigation และ footer จาก `base.html` และกำหนดเฉพาะ title และเนื้อหาของตัวเอง ชื่อ site มาจาก configuration ดังนั้นสามารถเปลี่ยนได้โดยไม่ต้อง recompile handler code ไม่จำเป็นต้องรู้อะไรเกี่ยวกับ base template — มันตั้งตัวแปรเดิมโดยไม่คำนึงว่า template ใช้ inheritance หรือไม่

---

## 12.6 Flash Message

แอปพลิเคชันเว็บมักต้องแสดงข้อความครั้งเดียวหลัง redirect ผู้ใช้ส่งฟอร์ม handler ประมวลผลและ redirect ไปหน้าอื่น และหน้านั้นแสดง "โพสต์ถูกสร้างแล้ว!" หรือ "บันทึกการตั้งค่าแล้ว" ข้อความปรากฏครั้งเดียวและหายไปใน page load ถัดไป สิ่งเหล่านี้เรียกว่า flash message

ความท้าทายคือ redirect คือสอง request แยกกัน handler ที่ประมวลผลฟอร์มคือ request หนึ่ง หน้าที่แสดง confirmation คือ request ต่างกัน ข้อความต้องอยู่รอดจาก redirect แต่ไม่คงอยู่เกินกว่านั้น Session แก้ปัญหานี้ได้อย่างดี

pattern ตรงไปตรงมา ก่อน redirect ให้เก็บข้อความใน session ด้วย key ที่รู้จัก:

```purebasic
; ตัวอย่างที่ 12.10 -- การตั้ง flash message ก่อน redirect
Procedure CreatePostHandler(*C.RequestContext)
  ; ... ประมวลผลข้อมูลฟอร์ม แทรกลงใน database ...
  Session::Set(*C, "_flash", "Post created!")
  Rendering::Redirect(*C, "/", 302)
EndProcedure
```

ใน handler ที่ render destination page ให้ดึง flash message ส่งไปยัง template แล้ว clear มันเพื่อไม่ให้ปรากฏอีก:

```purebasic
; ตัวอย่างที่ 12.11 -- การอ่านและล้าง flash message
Procedure HomeHandler(*C.RequestContext)
  Protected flash.s = Session::Get(*C, "_flash")
  If flash <> ""
    Ctx::Set(*C, "flash", flash)
    Session::Set(*C, "_flash", "")  ; ล้างหลังอ่าน
  EndIf
  ; ... เตรียมข้อมูล template อื่นๆ ...
  Rendering::Render(*C, "index.html",
                    "examples/blog/templates/")
EndProcedure
```

template ตรวจสอบ flash variable และ render เมื่อมีอยู่:

```html
{% if flash %}
<div class="alert">{{ flash }}</div>
{% endif %}
```

key `_flash` คือ convention ไม่ใช่ framework feature คุณสามารถใช้ชื่อ key ใดก็ได้ underscore prefix บ่งบอกว่ามันเป็น concern ระดับ framework แทนที่จะเป็น application data ตรงกับ convention `_psid` และ `_auth_user` ที่ใช้ที่อื่นใน PureSimple

pattern นี้ทำงานได้เพราะ session คงอยู่ข้าม request request แรกเขียนข้อความ redirect trigger request ที่สอง request ที่สองอ่านข้อความ ส่งไปยัง template และ clear มัน request ถัดไปจะพบ key `_flash` ว่างและ render ไม่มีข้อความ

> **หมายเหตุ:** Session ครอบคลุมอย่างละเอียดในบทที่ 15 สำหรับตอนนี้ สิ่งที่คุณต้องรู้คือ `Session::Set` เก็บค่าที่คงอยู่ข้าม request สำหรับผู้ใช้คนเดียวกัน และ `Session::Get` ดึงมัน session middleware ต้องถูก register ก่อน handler ใดๆ ที่ใช้ flash message

---

## 12.7 หน้า Error: 404 และ 500

ทุกแอปพลิเคชันต้องการหน้า error หน้า error เริ่มต้นของ PureSimple อยู่ใน `templates/404.html` และ `templates/500.html` และถูก render โดย framework เมื่อไม่มี route ที่ match (404) หรือเมื่อ handler crash (500)

template 404 ใช้ตัวแปร `{{ request.path }}` เพื่อแสดง URL ที่ผู้ใช้พยายามเข้าถึง:

```html
<!-- ตัวอย่างที่ 12.12 -- Template 404.html เริ่มต้น -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>404 Not Found — PureSimple</title>
</head>
<body>
  <h1>404</h1>
  <h2>Page Not Found</h2>
  <p>
    The page you requested —
    <code>{{ request.path }}</code> —
    does not exist.
  </p>
  <p><a href="/">Go home</a></p>
</body>
</html>
```

ตัวแปร `{{ request.path }}` ไม่ได้ปรากฏขึ้นอย่างน่าอัศจรรย์ 404 handler ของ framework ตั้งมันก่อน render template:

```purebasic
; ตัวอย่างที่ 12.13 -- 404 handler ที่ตั้ง request.path
Procedure HandleNotFound(*C.RequestContext)
  Ctx::Set(*C, "request.path", SafeVal(*C\Path))
  Rendering::Render(*C, "404.html", "templates/")
EndProcedure
```

call `SafeVal` จะ HTML-escape path เพื่อป้องกัน cross-site scripting — หากปราศจากมัน ผู้โจมตีสามารถสร้าง URL ที่มี `<script>` tag ซึ่งจะ execute ใน browser ของผู้ใช้เมื่อหน้า 404 render

template 500 มี conditional debug section:

```html
<!-- ตัวอย่างที่ 12.14 -- Template 500.html เริ่มต้น -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>500 Internal Server Error — PureSimple</title>
</head>
<body>
  <h1>500</h1>
  <h2>Internal Server Error</h2>
  <p>Something went wrong on our end.</p>
  {% if debug %}
  <pre>{{ error }}</pre>
  {% endif %}
  <p><a href="/">Go home</a></p>
</body>
</html>
```

block `{% if debug %}` แสดง error message เฉพาะเมื่อแอปพลิเคชันทำงานในโหมด debug ใน production ผู้ใช้เห็นหน้า error ที่สะอาดโดยไม่มีรายละเอียดทางเทคนิค นี่เป็นทั้ง security practice (error message อาจรั่วโครงสร้างภายใน) และการตัดสินใจด้าน user experience (stack trace ทำให้คนทั่วไปตกใจ)

> **คำเตือน:** อย่าเปิดเผยรายละเอียด error ใน production pattern `{% if debug %}` รับรองว่า `{{ error }}` render เฉพาะเมื่อ `Engine::SetMode("debug")` ทำงานอยู่ ใน release mode error จะถูก log ไปยัง server console แต่ซ่อนจากผู้ใช้ ถ้าคุณถูกล่อใจให้ลบการตรวจสอบ `{% if debug %}` เพื่อ "ช่วย debug ใน production" ให้ต่อต้านการล่อใจนั้น ใช้ `Log::Error` แทน และอ่าน log ของคุณอย่างมืออาชีพ

หน้า error แบบกำหนดเองควรตรงกับ visual design ของแอปพลิเคชันของคุณ หน้า 404 ที่มีหน้าตาเหมือนกับส่วนที่เหลือของ site ทำให้ผู้ใช้มั่นใจว่าตนอยู่ในที่ที่ถูกต้อง หน้า 404 ที่มีหน้าตาเหมือน server error เริ่มต้นทำให้พวกเขาสงสัยว่า site ทั้งหมดพัง ความแตกต่างคือ HTML สิบนาทีและ first impression ตลอดชีวิต

---

## 12.8 การ Bootstrap แอปพลิเคชัน

ส่วน bootstrap ที่ท้ายสุดของ `main.pb` รวมทุกอย่างเข้าด้วยกัน:

```purebasic
; ตัวอย่างที่ 12.15 -- Application bootstrap
InitPosts()
Config::Load(".env")
Protected port.i = Config::GetInt("PORT", 8080)
Engine::SetMode(Config::Get("MODE", "debug"))

Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

Engine::GET("/",            @HomeHandler())
Engine::GET("/post/:slug",  @PostHandler())
Engine::GET("/about",       @AboutHandler())
Engine::GET("/health",      @HealthHandler())

Log::Info("Blog starting on :" + Str(port) +
          " [" + Engine::Mode() + "]")
Engine::Run(port)
```

ลำดับขั้นตอนคือ: เริ่มต้นข้อมูล, โหลด configuration, ตั้งโหมดการทำงาน, register global middleware, register route, log ข้อความเริ่มต้น และเริ่ม server ลำดับนี้ไม่ได้ random Middleware ต้องถูก register ก่อน route เพราะ `Engine::Use` เพิ่มไปยัง global middleware list ที่ถูกรวมกับ route handler ณ เวลา dispatch Configuration ต้องถูกโหลดก่อน middleware และ route ที่พึ่งพา config value

`HealthHandler` คืน JSON response แทน HTML:

```purebasic
; ตัวอย่างที่ 12.16 -- Handler health check
Procedure HealthHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure
```

ทุกแอปพลิเคชัน production ต้องการ health check load balancer, monitoring system และ deploy script poll endpoint นี้เพื่อตรวจสอบว่าแอปพลิเคชันทำงานอยู่ health check ที่คืน JSON ทั้ง machine-readable และ human-readable health check ที่ render HTML template คือ health check ที่สามารถ fail ได้เพราะ template parsing error ซึ่งทำลายจุดประสงค์ทั้งหมด ทำให้ health check เรียบง่าย ปราศจาก dependency น่าเบื่อ health check ที่น่าเบื่อคือ health check ที่ดีที่สุด เพราะมันคือตัวที่ไม่เคยโกหกคุณ

---

## 12.9 การรันแอปพลิเคชัน

Compile และรัน:

```bash
# ตัวอย่างที่ 12.17 -- Compile และรัน blog
$PUREBASIC_HOME/compilers/pbcompiler \
  examples/blog/main.pb -cl -o blog

./blog
```

เปิด `http://localhost:8080/` ใน browser คุณจะเห็นหน้า home พร้อม blog post สามอัน คลิก title ของ post เพื่อดูหน้า detail คลิก "About" เพื่อดูหน้า about ไปที่ URL ที่ไม่มีอยู่เช่น `/nope` เพื่อดูหน้า 404

แอปพลิเคชันทั้งหมด — web server, router, middleware, template engine และ blog post ทั้งสามอัน — compile เป็น binary เดียว ไม่มี `node_modules` ไม่มี virtualenv ไม่มี Docker container ไม่มี runtime แค่ไฟล์ที่คุณสามารถ copy ไปยัง machine ใดก็ได้ที่มีระบบปฏิบัติการเดียวกันแล้วรัน React app ของคุณมีไฟล์ configuration มากกว่าแอปพลิเคชันนี้มี source file

---

## สรุป

แอปพลิเคชัน HTML ใน PureSimple ทำตามโครงสร้างที่ตรงไปตรงมา: entry point `main.pb`, directory `templates/` สำหรับ Jinja template และ directory `static/` สำหรับ CSS และ asset (optional) Handler เตรียมข้อมูลโดยใช้ KV store ของ context และ render template ด้วย `Rendering::Render` หน้า list ใช้ pattern `split` เพื่อส่ง record หลายอันเป็น delimited string หน้า detail ตั้งตัวแปรแยกสำหรับแต่ละ field หน้า error (404 และ 500) ใช้ conditional block เพื่อแสดงข้อมูล debug เฉพาะในโหมด development ส่วน bootstrap load configuration register middleware และ route และเริ่ม server ตามลำดับที่แน่นอนและคาดเดาได้

## ประเด็นสำคัญ

- จัดโครงสร้างโปรเจกต์ด้วย `main.pb` ที่ root, `templates/` สำหรับไฟล์ HTML และ `static/` สำหรับ asset convention ไม่ได้ถูก enforce แต่ทุกคนเข้าใจ
- ใช้ pattern `split` สำหรับหน้า list: encode record เป็น delimited string ใน handler, decode ด้วย `split('\n')` และ `split('\t')` ใน template
- สำหรับหน้า detail ตั้งแต่ละ field เป็น KV store entry แยกกันแทนที่จะ encode ทุกอย่างเป็น string เดียว
- จัดเตรียมหน้า 404 และ 500 แบบกำหนดเองเสมอ ใช้ `{% if debug %}` เพื่อซ่อนรายละเอียดทางเทคนิคใน production

## คำถามทบทวน

1. เพราะเหตุใด handler หน้า home จึง encode ข้อมูล post เป็น tab-and-newline-delimited string แทนที่จะส่ง structured object ไปยัง template?
2. `Engine::HandleNotFound(*C)` มีวัตถุประสงค์อะไรใน post detail handler และเกิดอะไรขึ้นเมื่อถูกเรียก?
3. *ลองทำ:* เพิ่ม field "tags" ให้กับ structure `BlogPost` และ seed แต่ละ post ด้วย tag สองหรือสามอัน คั่นด้วย comma แก้ไข template `post.html` เพื่อแสดง tag เป็น list โดยใช้ `split(',')` แก้ไข template หน้า home เพื่อแสดง tag แรกถัดจาก title ของแต่ละ post
