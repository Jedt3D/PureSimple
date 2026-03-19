# ภาคผนวก ค: PureJinja Filter Reference

PureJinja มี filter built-in 34 ตัวบวก alias อีก 3 ตัว รวมเป็น 37 ชื่อที่รองรับ syntax เดียวกับ Jinja filter ใช้แปลงค่าภายใน template expression ด้วย pipe operator:

```
{{ value|filtername }}
{{ value|filtername(arg1, arg2) }}
{{ value|filter1|filter2|filter3 }}
```

filter สามารถต่อกันเป็น chain ได้ output ของ filter หนึ่งกลายเป็น input ของ filter ถัดไป ภาคผนวกนี้บันทึก filter ทุกตัว จัดกลุ่มตามหมวดหมู่ พร้อมตัวอย่างการใช้และ output ที่คาดหวัง

**Alias:** filter บางตัวมีชื่อย่อ `d` เป็น alias ของ `default`, `e` เป็น alias ของ `escape` และ `count` เป็น alias ของ `length` การใช้ alias มีผลเหมือนกับการใช้ชื่อเต็มทุกประการ

---

## ค.1 String Filter

### upper

แปลงสตริงเป็นตัวพิมพ์ใหญ่ทั้งหมด

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "hello world"|upper }}
```
**Output:** `HELLO WORLD`

---

### lower

แปลงสตริงเป็นตัวพิมพ์เล็กทั้งหมด

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "HELLO WORLD"|lower }}
```
**Output:** `hello world`

---

### title

แปลงสตริงเป็น title case (ตัวอักษรแรกของทุกคำเป็นตัวพิมพ์ใหญ่)

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "hello world"|title }}
```
**Output:** `Hello World`

---

### capitalize

ทำให้ตัวอักษรแรกของสตริงเป็นตัวพิมพ์ใหญ่ ส่วนที่เหลือเป็นตัวพิมพ์เล็ก

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "hello WORLD"|capitalize }}
```
**Output:** `Hello world`

---

### trim

ลบ whitespace ที่ต้นและท้ายสตริง

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "  hello  "|trim }}
```
**Output:** `hello`

---

### replace

แทนที่ occurrence ของสตริงย่อยด้วยสตริงอื่น

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `old` (string), `new` (string) |
| **คืน** | String |

```
{{ "Hello World"|replace("World", "PureBasic") }}
```
**Output:** `Hello PureBasic`

---

### truncate

ตัดสตริงให้มีความยาวตามที่กำหนด โดยเพิ่ม ellipsis ต่อท้ายถ้าสตริงยาวกว่า

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `length` (integer, ค่าเริ่มต้น 255) |
| **คืน** | String |

```
{{ "This is a long sentence that needs truncating"|truncate(20) }}
```
**Output:** `This is a long se...`

---

### wordcount

นับจำนวนคำในสตริง

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | Integer |

```
{{ "Hello beautiful world"|wordcount }}
```
**Output:** `3`

---

### wordwrap

ตัดสตริงที่ความกว้างที่กำหนด โดยแทรก newline ที่ขอบคำ

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `width` (integer, ค่าเริ่มต้น 79) |
| **คืน** | String |

```
{{ "This is a sentence that should be wrapped"|wordwrap(20) }}
```
**Output:**
```
This is a sentence
that should be
wrapped
```

---

### center

จัดสตริงให้อยู่กึ่งกลางในความกว้างที่กำหนด โดย padding ด้วย space

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `width` (integer, ค่าเริ่มต้น 80) |
| **คืน** | String |

```
{{ "hello"|center(11) }}
```
**Output:** `   hello   `

---

### indent

เพิ่มการย่อหน้าให้แต่ละบรรทัดของสตริงตามจำนวน space ที่กำหนด

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `width` (integer, ค่าเริ่มต้น 4) |
| **คืน** | String |

```
{{ "line1\nline2"|indent(2) }}
```
**Output:**
```
  line1
  line2
```

---

### striptags

ลบ HTML/XML tag ออกจากสตริง

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "<p>Hello <b>World</b></p>"|striptags }}
```
**Output:** `Hello World`

---

### split

แยกสตริงออกเป็น list ด้วย delimiter ที่กำหนด

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | `delimiter` (string, ค่าเริ่มต้น `" "`) |
| **คืน** | List |

```
{{ "a,b,c"|split(",") }}
```
**Output:** `['a', 'b', 'c']`

filter นี้ใช้บ่อยมากในแอปพลิเคชัน blog ของ PureSimple สำหรับ pattern ข้อมูลคั่นด้วย pipe:

```
{% for post in posts|split('\n') %}
  {% set fields = post|split('|') %}
  <h2>{{ fields[0] }}</h2>
{% endfor %}
```

---

## ค.2 Number Filter

### abs

คืนค่าสัมบูรณ์ของตัวเลข

| | |
|---|---|
| **ชนิด input** | Number |
| **Argument** | ไม่มี |
| **คืน** | Number |

```
{{ -42|abs }}
```
**Output:** `42`

---

### round

ปัดเศษตัวเลขให้มีทศนิยมตามจำนวนที่กำหนด

| | |
|---|---|
| **ชนิด input** | Number |
| **Argument** | `precision` (integer, ค่าเริ่มต้น 0) |
| **คืน** | Number |

```
{{ 3.14159|round(2) }}
```
**Output:** `3.14`

```
{{ 42.6|round }}
```
**Output:** `43`

---

### int

แปลงค่าเป็น integer

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | ไม่มี |
| **คืน** | Integer |

```
{{ "42"|int }}
```
**Output:** `42`

```
{{ 3.7|int }}
```
**Output:** `3`

---

### float

แปลงค่าเป็น floating-point number

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | ไม่มี |
| **คืน** | Float |

```
{{ "3.14"|float }}
```
**Output:** `3.14`

```
{{ 42|float }}
```
**Output:** `42.0`

---

## ค.3 List Filter

### length / count

คืนจำนวน item ใน list หรือจำนวนตัวอักษรในสตริง `count` เป็น alias ของ `length`

| | |
|---|---|
| **ชนิด input** | List หรือ String |
| **Argument** | ไม่มี |
| **คืน** | Integer |

```
{{ [1, 2, 3]|length }}
```
**Output:** `3`

```
{{ "hello"|length }}
```
**Output:** `5`

---

### first

คืน item แรกของ list

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | ไม่มี |
| **คืน** | Any |

```
{{ [10, 20, 30]|first }}
```
**Output:** `10`

---

### last

คืน item สุดท้ายของ list

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | ไม่มี |
| **คืน** | Any |

```
{{ [10, 20, 30]|last }}
```
**Output:** `30`

---

### reverse

กลับลำดับ list หรือสตริง

| | |
|---|---|
| **ชนิด input** | List หรือ String |
| **Argument** | ไม่มี |
| **คืน** | List หรือ String |

```
{{ [1, 2, 3]|reverse }}
```
**Output:** `[3, 2, 1]`

```
{{ "hello"|reverse }}
```
**Output:** `olleh`

---

### sort

เรียงลำดับ list จากน้อยไปมาก

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | ไม่มี |
| **คืน** | List |

```
{{ [3, 1, 2]|sort }}
```
**Output:** `[1, 2, 3]`

---

### unique

ลบค่าซ้ำออกจาก list โดยรักษาลำดับเดิม

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | ไม่มี |
| **คืน** | List |

```
{{ [1, 2, 2, 3, 1]|unique }}
```
**Output:** `[1, 2, 3]`

---

### join

รวม list ให้เป็นสตริงโดยมีตัวคั่นระหว่าง item

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | `separator` (string, ค่าเริ่มต้น `""`) |
| **คืน** | String |

```
{{ ["a", "b", "c"]|join(", ") }}
```
**Output:** `a, b, c`

```
{{ [1, 2, 3]|join("-") }}
```
**Output:** `1-2-3`

---

### batch

จัดกลุ่ม item เป็น batch ขนาดคงที่ (sub-list)

| | |
|---|---|
| **ชนิด input** | List |
| **Argument** | `size` (integer) |
| **คืน** | List of lists |

```
{{ [1, 2, 3, 4, 5]|batch(2) }}
```
**Output:** `[[1, 2], [3, 4], [5]]`

มีประโยชน์สำหรับการสร้าง grid layout ใน template:

```
{% for row in items|batch(3) %}
  <div class="row">
    {% for item in row %}
      <div class="col">{{ item }}</div>
    {% endfor %}
  </div>
{% endfor %}
```

---

### list

แปลงค่าเป็น list ถ้าค่าเป็นสตริง แต่ละตัวอักษรจะกลายเป็น element ของ list

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | ไม่มี |
| **คืน** | List |

```
{{ "abc"|list }}
```
**Output:** `['a', 'b', 'c']`

---

## ค.4 Object Filter

### map

ดึง attribute จาก item แต่ละตัวใน list ของ object

| | |
|---|---|
| **ชนิด input** | List of objects |
| **Argument** | `attribute` (string) |
| **คืน** | List |

```
{{ users|map("name") }}
```
**Output:** รายการ attribute `name` จาก user object แต่ละตัว

---

### items

คืนคู่ key-value ของ object เป็น list ของ pair

| | |
|---|---|
| **ชนิด input** | Object (dictionary) |
| **Argument** | ไม่มี |
| **คืน** | List of pairs |

```
{% for key, value in config|items %}
  {{ key }}: {{ value }}
{% endfor %}
```

---

## ค.5 Encoding Filter

### escape / e

ทำ escape อักขระพิเศษ HTML (`&`, `<`, `>`, `"`, `'`) เพื่อแสดงเป็นข้อความธรรมดาในเบราว์เซอร์ `e` เป็นชื่อย่อของ `escape`

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "<script>alert('xss')</script>"|escape }}
```
**Output:** `&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;`

นี่คือ filter ที่สำคัญที่สุดด้านความปลอดภัยเว็บ ใช้กับข้อมูลที่ผู้ใช้ป้อนมาทุกชิ้นที่จะแสดงใน HTML

---

### safe

กำหนดให้สตริงปลอดภัย ป้องกันการ auto-escaping ใช้เฉพาะเมื่อคุณเชื่อถือเนื้อหา HTML นั้น

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String (ที่กำหนดว่าปลอดภัย) |

```
{{ "<b>Bold</b>"|safe }}
```
**Output:** `<b>Bold</b>` (แสดงเป็นตัวหนาในเบราว์เซอร์)

**คำเตือน:** อย่าใช้ `safe` กับข้อมูลที่ผู้ใช้ส่งมาเด็ดขาด เพราะจะ bypass การป้องกัน XSS

---

### urlencode

เข้ารหัสสตริงแบบ percent-encoding เพื่อใส่ใน URL ได้อย่างปลอดภัย

| | |
|---|---|
| **ชนิด input** | String |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ "hello world"|urlencode }}
```
**Output:** `hello%20world`

```
<a href="/search?q={{ query|urlencode }}">Search</a>
```

---

### tojson

แปลงค่าเป็น JSON string

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | ไม่มี |
| **คืน** | String (JSON) |

```
{{ name|tojson }}
```
**Output:** `"Alice"` (มี quote ครอบ เหมาะสำหรับฝังใน JavaScript)

มีประโยชน์สำหรับส่งตัวแปร template ไปยัง inline script:

```
<script>
  var config = {{ settings|tojson }};
</script>
```

---

## ค.6 Special Filter

### default / d

คืนค่า default ถ้าตัวแปรไม่มีค่าหรือว่าง `d` เป็นชื่อย่อของ `default`

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | `default_value` (any) |
| **คืน** | Any |

```
{{ username|default("Anonymous") }}
```
**Output:** `Anonymous` (ถ้า `username` ไม่ได้นิยามไว้)

```
{{ title|d("Untitled") }}
```
**Output:** `Untitled` (ถ้า `title` ไม่ได้นิยามไว้)

---

### string

แปลงค่าเป็น string representation

| | |
|---|---|
| **ชนิด input** | Any |
| **Argument** | ไม่มี |
| **คืน** | String |

```
{{ 42|string }}
```
**Output:** `42`

---

## ค.7 ตาราง Filter อ้างอิงฉบับย่อ

| Filter | หมวดหมู่ | Argument | คำอธิบาย |
|---|---|---|---|
| `abs` | Number | -- | ค่าสัมบูรณ์ |
| `batch` | List | `size` | จัดกลุ่มเป็น sub-list ขนาดคงที่ |
| `capitalize` | String | -- | ตัวแรกพิมพ์ใหญ่ ที่เหลือพิมพ์เล็ก |
| `center` | String | `width=80` | จัดกลางด้วย space |
| `count` | List | -- | Alias ของ `length` |
| `d` | Special | `default_value` | Alias ของ `default` |
| `default` | Special | `default_value` | ค่า fallback เมื่อไม่มีค่าหรือว่าง |
| `e` | Encoding | -- | Alias ของ `escape` |
| `escape` | Encoding | -- | Escape อักขระพิเศษ HTML |
| `first` | List | -- | Item แรกของ list |
| `float` | Number | -- | แปลงเป็น float |
| `indent` | String | `width=4` | ย่อหน้าแต่ละบรรทัด |
| `int` | Number | -- | แปลงเป็น integer |
| `items` | Object | -- | คู่ key-value จาก object |
| `join` | List | `separator=""` | รวม list เป็นสตริง |
| `last` | List | -- | Item สุดท้ายของ list |
| `length` | List | -- | จำนวน item หรือตัวอักษร |
| `list` | List | -- | แปลงเป็น list |
| `lower` | String | -- | ตัวพิมพ์เล็กทั้งหมด |
| `map` | Object | `attribute` | ดึง attribute จากแต่ละ item |
| `replace` | String | `old`, `new` | แทนที่สตริงย่อย |
| `reverse` | List | -- | กลับลำดับ list หรือสตริง |
| `round` | Number | `precision=0` | ปัดเศษทศนิยม |
| `safe` | Encoding | -- | กำหนดเป็น safe (ข้าม auto-escape) |
| `sort` | List | -- | เรียงจากน้อยไปมาก |
| `split` | String | `delimiter=" "` | แยกสตริงเป็น list |
| `string` | Special | -- | แปลงเป็นสตริง |
| `striptags` | String | -- | ลบ HTML tag |
| `title` | String | -- | Title Case |
| `tojson` | Encoding | -- | แปลงเป็น JSON string |
| `trim` | String | -- | ตัด whitespace |
| `truncate` | String | `length=255` | ตัดพร้อม ellipsis |
| `unique` | List | -- | ลบค่าซ้ำ |
| `upper` | String | -- | ตัวพิมพ์ใหญ่ทั้งหมด |
| `urlencode` | Encoding | -- | Percent-encode สำหรับ URL |
| `wordcount` | String | -- | นับคำ |
| `wordwrap` | String | `width=79` | ตัดที่ขอบคำ |

**รวมทั้งหมด:** filter ไม่ซ้ำ 34 ตัว + alias 3 ตัว (`count`, `d`, `e`) = 37 ชื่อที่ลงทะเบียน mapping ไปยัง 34 implementation
