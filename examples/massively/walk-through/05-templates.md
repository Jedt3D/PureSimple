# 05 — Templates

## Template engine

PureJinja is a Jinja-compatible template engine compiled into the binary.
It supports template inheritance (`{% extends %}`), blocks (`{% block %}`),
variables (`{{ var }}`), for-loops, if-statements, and many built-in filters.

## Rendering a template

```purebasic
Ctx::Set(*C, "title", "The Heron's Patience")
Ctx::Set(*C, "body",  "It was barely four in the morning...")
Rendering::Render(*C, "post.html", _tplDir)
```

`Rendering::Render` reads all KV pairs from the context and passes them as
template variables. Every `Ctx::Set` call becomes a named variable in Jinja.

## Template inheritance

**base.html** defines the full HTML shell with nav, header, footer, and scripts.
It contains `{% block content %}{% endblock %}` as a placeholder.

```html
<!-- base.html -->
<div id="main">
  {% block content %}{% endblock %}
</div>
```

**Child templates** extend base and fill the block:

```html
<!-- post.html -->
{% extends "base.html" %}
{% block content %}
<h1>{{ title }}</h1>
<p>{{ body }}</p>
{% endblock %}
```

## The KV store tab-safety rule

The context KV store uses `Chr(9)` (tab) as the field separator. If a value
contains a tab character, it will corrupt the KV parsing.

**Always wrap values through `SafeVal()` before `Ctx::Set`:**

```purebasic
Procedure.s SafeVal(s.s)
  ProcedureReturn ReplaceString(s, Chr(9), " ")
EndProcedure

Ctx::Set(*C, "body", SafeVal(DB::GetStr(_db, 1)))
```

## Passing a list to the index template

PureJinja variables are strings. To pass a list of posts, encode them as a
newline-delimited, pipe-separated string:

```
slug|title|date|photo_url|excerpt|published
herons-patience|The Heron's Patience|2026-01-15|https://...|Excerpt...|1
doi-inthanon-mist|Doi Inthanon in the Mist|2026-01-28|https://...|Excerpt...|1
```

Set via:
```purebasic
Ctx::Set(*C, "posts_data", PostsToStr())
```

In the template, split and iterate:
```html
{% for line in posts_data.split('\n') %}{% if line %}
{% set p = line.split('|') %}
<article>
  <h2><a href="/post/{{ p[0] }}">{{ p[1] }}</a></h2>
  <span>{{ p[2] }}</span>
  <img src="{{ p[3] }}" />
  <p>{{ p[4] }}</p>
</article>
{% endif %}{% endfor %}
```

## Admin templates

Admin templates extend `admin/base.html` which loads Tabler via CDN and
provides the navbar + sidenav. They use the same `{% block content %}` pattern.

The `active_admin` variable highlights the current nav item:
```html
<li class="nav-item{% if active_admin == 'posts' %} active{% endif %}">
```
