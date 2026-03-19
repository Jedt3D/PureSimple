# Appendix C: PureJinja Filter Reference

PureJinja implements 34 built-in filters plus 3 aliases, giving 37 registered filter names compatible with Jinja syntax. Filters transform values inside template expressions using the pipe operator:

```
{{ value|filtername }}
{{ value|filtername(arg1, arg2) }}
{{ value|filter1|filter2|filter3 }}
```

Filters can be chained. The output of one filter becomes the input of the next. This appendix documents every filter, grouped by category, with usage examples and expected output.

**Aliases:** Some filters have short aliases. `d` is an alias for `default`, `e` is an alias for `escape`, and `count` is an alias for `length`. Using an alias is identical to using the full name.

---

## C.1 String Filters

### upper

Converts a string to uppercase.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "hello world"|upper }}
```
**Output:** `HELLO WORLD`

---

### lower

Converts a string to lowercase.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "HELLO WORLD"|lower }}
```
**Output:** `hello world`

---

### title

Converts a string to title case (first letter of each word capitalised).

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "hello world"|title }}
```
**Output:** `Hello World`

---

### capitalize

Capitalises the first character of the string and lowercases the rest.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "hello WORLD"|capitalize }}
```
**Output:** `Hello world`

---

### trim

Removes leading and trailing whitespace from a string.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "  hello  "|trim }}
```
**Output:** `hello`

---

### replace

Replaces occurrences of a substring with another string.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `old` (string), `new` (string) |
| **Returns** | String |

```
{{ "Hello World"|replace("World", "PureBasic") }}
```
**Output:** `Hello PureBasic`

---

### truncate

Truncates a string to a given length, appending an ellipsis if the string was longer.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `length` (integer, default 255) |
| **Returns** | String |

```
{{ "This is a long sentence that needs truncating"|truncate(20) }}
```
**Output:** `This is a long se...`

---

### wordcount

Counts the number of words in a string.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | Integer |

```
{{ "Hello beautiful world"|wordcount }}
```
**Output:** `3`

---

### wordwrap

Wraps a string at a given width, inserting newlines at word boundaries.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `width` (integer, default 79) |
| **Returns** | String |

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

Centers a string within a field of a given width, padding with spaces.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `width` (integer, default 80) |
| **Returns** | String |

```
{{ "hello"|center(11) }}
```
**Output:** `   hello   `

---

### indent

Indents each line of a string by a given number of spaces.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `width` (integer, default 4) |
| **Returns** | String |

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

Removes HTML/XML tags from a string.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "<p>Hello <b>World</b></p>"|striptags }}
```
**Output:** `Hello World`

---

### split

Splits a string into a list by a delimiter.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | `delimiter` (string, default `" "`) |
| **Returns** | List |

```
{{ "a,b,c"|split(",") }}
```
**Output:** `['a', 'b', 'c']`

This filter is heavily used in the PureSimple blog application for the pipe-delimited data pattern:

```
{% for post in posts|split('\n') %}
  {% set fields = post|split('|') %}
  <h2>{{ fields[0] }}</h2>
{% endfor %}
```

---

## C.2 Number Filters

### abs

Returns the absolute value of a number.

| | |
|---|---|
| **Input type** | Number |
| **Arguments** | None |
| **Returns** | Number |

```
{{ -42|abs }}
```
**Output:** `42`

---

### round

Rounds a number to a given number of decimal places.

| | |
|---|---|
| **Input type** | Number |
| **Arguments** | `precision` (integer, default 0) |
| **Returns** | Number |

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

Converts a value to an integer.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | None |
| **Returns** | Integer |

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

Converts a value to a floating-point number.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | None |
| **Returns** | Float |

```
{{ "3.14"|float }}
```
**Output:** `3.14`

```
{{ 42|float }}
```
**Output:** `42.0`

---

## C.3 List Filters

### length / count

Returns the number of items in a list or characters in a string. `count` is an alias for `length`.

| | |
|---|---|
| **Input type** | List or String |
| **Arguments** | None |
| **Returns** | Integer |

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

Returns the first item of a list.

| | |
|---|---|
| **Input type** | List |
| **Arguments** | None |
| **Returns** | Any |

```
{{ [10, 20, 30]|first }}
```
**Output:** `10`

---

### last

Returns the last item of a list.

| | |
|---|---|
| **Input type** | List |
| **Arguments** | None |
| **Returns** | Any |

```
{{ [10, 20, 30]|last }}
```
**Output:** `30`

---

### reverse

Reverses a list or string.

| | |
|---|---|
| **Input type** | List or String |
| **Arguments** | None |
| **Returns** | List or String |

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

Sorts a list in ascending order.

| | |
|---|---|
| **Input type** | List |
| **Arguments** | None |
| **Returns** | List |

```
{{ [3, 1, 2]|sort }}
```
**Output:** `[1, 2, 3]`

---

### unique

Removes duplicate values from a list, preserving order.

| | |
|---|---|
| **Input type** | List |
| **Arguments** | None |
| **Returns** | List |

```
{{ [1, 2, 2, 3, 1]|unique }}
```
**Output:** `[1, 2, 3]`

---

### join

Joins a list into a string with a separator.

| | |
|---|---|
| **Input type** | List |
| **Arguments** | `separator` (string, default `""`) |
| **Returns** | String |

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

Groups items into fixed-size batches (sub-lists).

| | |
|---|---|
| **Input type** | List |
| **Arguments** | `size` (integer) |
| **Returns** | List of lists |

```
{{ [1, 2, 3, 4, 5]|batch(2) }}
```
**Output:** `[[1, 2], [3, 4], [5]]`

Useful for creating grid layouts in templates:

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

Converts a value to a list. If the value is a string, each character becomes a list element.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | None |
| **Returns** | List |

```
{{ "abc"|list }}
```
**Output:** `['a', 'b', 'c']`

---

## C.4 Object Filters

### map

Extracts an attribute from each item in a list of objects.

| | |
|---|---|
| **Input type** | List of objects |
| **Arguments** | `attribute` (string) |
| **Returns** | List |

```
{{ users|map("name") }}
```
**Output:** A list of the `name` attribute from each user object.

---

### items

Returns the key-value pairs of an object as a list of pairs.

| | |
|---|---|
| **Input type** | Object (dictionary) |
| **Arguments** | None |
| **Returns** | List of pairs |

```
{% for key, value in config|items %}
  {{ key }}: {{ value }}
{% endfor %}
```

---

## C.5 Encoding Filters

### escape / e

Escapes HTML special characters (`&`, `<`, `>`, `"`, `'`) so they display as literal text in the browser. `e` is a short alias for `escape`.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "<script>alert('xss')</script>"|escape }}
```
**Output:** `&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;`

This is the most important filter for web security. Use it on any user-provided data that will appear in HTML.

---

### safe

Marks a string as safe, preventing auto-escaping. Use only when you trust the HTML content.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String (marked safe) |

```
{{ "<b>Bold</b>"|safe }}
```
**Output:** `<b>Bold</b>` (rendered as bold in the browser)

**Warning:** Never use `safe` on user-supplied input. It bypasses XSS protection.

---

### urlencode

Percent-encodes a string for safe inclusion in URLs.

| | |
|---|---|
| **Input type** | String |
| **Arguments** | None |
| **Returns** | String |

```
{{ "hello world"|urlencode }}
```
**Output:** `hello%20world`

```
<a href="/search?q={{ query|urlencode }}">Search</a>
```

---

### tojson

Converts a value to a JSON string representation.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | None |
| **Returns** | String (JSON) |

```
{{ name|tojson }}
```
**Output:** `"Alice"` (with quotes, suitable for embedding in JavaScript)

Useful for passing template variables into inline scripts:

```
<script>
  var config = {{ settings|tojson }};
</script>
```

---

## C.6 Special Filters

### default / d

Returns a default value if the variable is undefined or empty. `d` is a short alias for `default`.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | `default_value` (any) |
| **Returns** | Any |

```
{{ username|default("Anonymous") }}
```
**Output:** `Anonymous` (if `username` is not defined)

```
{{ title|d("Untitled") }}
```
**Output:** `Untitled` (if `title` is not defined)

---

### string

Converts a value to its string representation.

| | |
|---|---|
| **Input type** | Any |
| **Arguments** | None |
| **Returns** | String |

```
{{ 42|string }}
```
**Output:** `42`

---

## C.7 Filter Quick Reference Table

| Filter | Category | Arguments | Description |
|---|---|---|---|
| `abs` | Number | -- | Absolute value |
| `batch` | List | `size` | Group into fixed-size sub-lists |
| `capitalize` | String | -- | First letter upper, rest lower |
| `center` | String | `width=80` | Center-pad with spaces |
| `count` | List | -- | Alias for `length` |
| `d` | Special | `default_value` | Alias for `default` |
| `default` | Special | `default_value` | Fallback for undefined/empty values |
| `e` | Encoding | -- | Alias for `escape` |
| `escape` | Encoding | -- | HTML-escape special characters |
| `first` | List | -- | First item of a list |
| `float` | Number | -- | Convert to float |
| `indent` | String | `width=4` | Indent each line |
| `int` | Number | -- | Convert to integer |
| `items` | Object | -- | Key-value pairs from an object |
| `join` | List | `separator=""` | Join list into string |
| `last` | List | -- | Last item of a list |
| `length` | List | -- | Number of items or characters |
| `list` | List | -- | Convert to list |
| `lower` | String | -- | Lowercase |
| `map` | Object | `attribute` | Extract attribute from each item |
| `replace` | String | `old`, `new` | Replace substring |
| `reverse` | List | -- | Reverse a list or string |
| `round` | Number | `precision=0` | Round to decimal places |
| `safe` | Encoding | -- | Mark as safe (skip auto-escape) |
| `sort` | List | -- | Sort ascending |
| `split` | String | `delimiter=" "` | Split string into list |
| `string` | Special | -- | Convert to string |
| `striptags` | String | -- | Remove HTML tags |
| `title` | String | -- | Title Case |
| `tojson` | Encoding | -- | Convert to JSON string |
| `trim` | String | -- | Strip whitespace |
| `truncate` | String | `length=255` | Truncate with ellipsis |
| `unique` | List | -- | Remove duplicates |
| `upper` | String | -- | Uppercase |
| `urlencode` | Encoding | -- | Percent-encode for URLs |
| `wordcount` | String | -- | Count words |
| `wordwrap` | String | `width=79` | Wrap at word boundaries |

**Total:** 34 unique filters + 3 aliases (`count`, `d`, `e`) = 37 registered names mapping to 34 implementations.
