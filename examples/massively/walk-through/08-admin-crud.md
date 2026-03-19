# 08 — Admin CRUD

## Full CRUD route table

| Method | Pattern | Handler | Action |
|--------|---------|---------|--------|
| GET | `/admin/posts` | `AdminPostsHandler` | List all posts |
| GET | `/admin/posts/new` | `AdminPostNewHandler` | Empty create form |
| POST | `/admin/posts/new` | `AdminPostCreateHandler` | Insert new post |
| GET | `/admin/posts/:id/edit` | `AdminPostEditHandler` | Populated edit form |
| POST | `/admin/posts/:id/edit` | `AdminPostUpdateHandler` | UPDATE row |
| POST | `/admin/posts/:id/delete` | `AdminPostDeleteHandler` | DELETE row |

## Shared form template

`admin/post_form.html` is used for both Create and Edit. The form's action
URL and button label are passed as template variables:

**Create:**
```purebasic
Ctx::Set(*C, "form_title",   "New Post")
Ctx::Set(*C, "form_action",  "/admin/posts/new")
Ctx::Set(*C, "submit_label", "Create Post")
Ctx::Set(*C, "post_title",   "")    ; empty fields
```

**Edit:**
```purebasic
Ctx::Set(*C, "form_title",   "Edit Post")
Ctx::Set(*C, "form_action",  "/admin/posts/" + id + "/edit")
Ctx::Set(*C, "submit_label", "Save Changes")
Ctx::Set(*C, "post_title",   SafeVal(DB::GetStr(_db, 2)))    ; pre-filled
```

In the template:
```html
<form method="post" action="{{ form_action }}">
  <input type="text" name="title" value="{{ post_title }}" />
  ...
  <button type="submit">{{ submit_label }}</button>
</form>
```

## Create handler

```purebasic
Procedure AdminPostCreateHandler(*C.RequestContext)
  Protected title.s = SafeVal(Trim(Binding::PostForm(*C, "title")))
  Protected slug.s  = SafeVal(Trim(Binding::PostForm(*C, "slug")))
  ; ... bind all 11 parameters ...
  DB::BindStr(_db, 0, slug)
  DB::BindStr(_db, 1, title)
  ; ...
  DB::Exec(_db, "INSERT INTO posts (slug, title, ...) VALUES (?, ?, ...)")
  Rendering::Redirect(*C, "/admin/posts")
EndProcedure
```

## Update handler

The `:id` route parameter identifies the row:

```purebasic
Procedure AdminPostUpdateHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  ; ... bind fields ...
  DB::BindStr(_db, 9, id)
  DB::Exec(_db, "UPDATE posts SET title=?, slug=?, ... WHERE id=?")
  Rendering::Redirect(*C, "/admin/posts")
EndProcedure
```

## Delete handler

HTML forms only support GET and POST. To delete via a form, use `method="post"`:

```html
<form method="post" action="/admin/posts/{{ p[0] }}/delete"
      onsubmit="return confirm('Delete this post?');">
  <button type="submit" class="btn btn-danger">Delete</button>
</form>
```

```purebasic
Procedure AdminPostDeleteHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  DB::BindStr(_db, 0, id)
  DB::Exec(_db, "DELETE FROM posts WHERE id = ?")
  Rendering::Redirect(*C, "/admin/posts")
EndProcedure
```

## Parameter binding index

`DB::BindStr(_db, idx, val)` uses 0-based indices matching the `?` placeholders
in the SQL statement, left to right. Always verify the index matches the
column order in the SQL.
