-- linus/keywords/gtk.lua
-- GTK 3 / 4 (GIMP Toolkit). Uses <gtk/gtk.h>.

return {

  -- ── Initialisation / Main Loop ──────────────────────────────────────────────

  ["gtk_init"] = [[
**`gtk_init`** — Initialise GTK (`<gtk/gtk.h>`)

```c
#include <gtk/gtk.h>

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(win), "Hello");
    gtk_widget_show(win);

    g_signal_connect(win, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
```

GTK4: use `gtk_application_new` + `GtkApplication` instead of `gtk_init`/`gtk_main`.

**See also:** `gtk_main`, `gtk_application_new`, `gtk_widget_show`, `g_signal_connect`]],

  ["gtk_main"] = [[
**`gtk_main`** — Enter the GTK main event loop (`<gtk/gtk.h>`)

```c
gtk_main();   // blocks until gtk_main_quit is called
```

GTK4: use `g_application_run` on a `GtkApplication`.

**See also:** `gtk_main_quit`, `gtk_init`, `gtk_application_new`]],

  ["gtk_main_quit"] = [[
**`gtk_main_quit`** — Exit the GTK main loop (`<gtk/gtk.h>`)

```c
gtk_main_quit();   // causes gtk_main() to return
```

**See also:** `gtk_main`, `g_signal_connect`]],

  ["gtk_application_new"] = [[
**`gtk_application_new`** — Create a GtkApplication (GTK3/4) (`<gtk/gtk.h>`)

```c
GtkApplication *app = gtk_application_new("com.example.app", G_APPLICATION_FLAGS_NONE);
g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
int status = g_application_run(G_APPLICATION(app), argc, argv);
return status;
```

GTK3: flags include `G_APPLICATION_FLAGS_NONE`. GTK4: use `G_APPLICATION_DEFAULT_FLAGS`.

**See also:** `g_application_run`, `gtk_application_window_new`, `GtkApplication`]],

  -- ── Widgets ─────────────────────────────────────────────────────────────────

  ["gtk_window_new"] = [[
**`gtk_window_new`** — Create a window (`<gtk/gtk.h>`)

```c
GtkWidget *win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
gtk_window_set_title(GTK_WINDOW(win), "My Window");
gtk_window_set_default_size(GTK_WINDOW(win), 640, 480);
gtk_window_set_resizable(GTK_WINDOW(win), TRUE);

// GTK4: use gtk_application_window_new(app);
```

**See also:** `gtk_widget_show`, `gtk_widget_destroy`, `g_signal_connect`, `GtkWindow`]],

  ["gtk_widget_show"] = [[
**`gtk_widget_show`** — Show a widget (`<gtk/gtk.h>`)

```c
gtk_widget_show(widget);           // show single widget
gtk_widget_show_all(window);       // show entire hierarchy (GTK3)
```

GTK4: `gtk_widget_set_visible(widget, TRUE)` replaces `gtk_widget_show`.

**See also:** `gtk_widget_hide`, `gtk_widget_set_visible`, `gtk_widget_destroy`]],

  ["gtk_widget_set_visible"] = [[
**`gtk_widget_set_visible`** — Show or hide a widget (`<gtk/gtk.h>`)

```c
gtk_widget_set_visible(widget, TRUE);   // show
gtk_widget_set_visible(widget, FALSE);  // hide
```

**See also:** `gtk_widget_show`, `gtk_widget_hide`, `gtk_widget_is_visible`]],

  ["gtk_widget_destroy"] = [[
**`gtk_widget_destroy`** — Destroy a widget (`<gtk/gtk.h>`)

```c
gtk_widget_destroy(widget);   // GTK3
// GTK4: gtk_window_destroy(GTK_WINDOW(window));
```

Recursively destroys child widgets and frees resources.

**See also:** `gtk_widget_show`, `g_signal_connect`]],

  ["gtk_button_new_with_label"] = [[
**`gtk_button_new_with_label`** — Create a button with text (`<gtk/gtk.h>`)

```c
GtkWidget *btn = gtk_button_new_with_label("Click Me");
g_signal_connect(btn, "clicked", G_CALLBACK(on_click), NULL);
```

**See also:** `gtk_button_new`, `gtk_toggle_button_new`, `gtk_button_set_label`, `g_signal_connect`]],

  ["gtk_label_new"] = [[
**`gtk_label_new`** — Create a label (`<gtk/gtk.h>`)

```c
GtkWidget *label = gtk_label_new("Hello, World!");
gtk_label_set_text(GTK_LABEL(label), "Updated text");
// Markup (Pango):
gtk_label_set_markup(GTK_LABEL(label), "<b>Bold</b> <span color='red'>Red</span>");
```

**See also:** `gtk_label_set_text`, `gtk_label_set_markup`, `gtk_label_set_selectable`]],

  ["gtk_entry_new"] = [[
**`gtk_entry_new`** — Create a single-line text entry (`<gtk/gtk.h>`)

```c
GtkWidget *entry = gtk_entry_new();
gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Enter name...");
const char *text = gtk_entry_get_text(GTK_ENTRY(entry));
```

**See also:** `gtk_entry_get_text`, `gtk_entry_set_text`, `gtk_editable`, `gtk_text_view_new`]],

  ["gtk_text_view_new"] = [[
**`gtk_text_view_new`** — Create a multi-line text view (`<gtk/gtk.h>`)

```c
GtkWidget *tv = gtk_text_view_new();
GtkTextBuffer *buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv));
gtk_text_buffer_set_text(buf, "Hello\nWorld", -1);
```

**See also:** `GtkTextBuffer`, `gtk_text_buffer_set_text`, `gtk_entry_new`]],

  -- ── Layout ──────────────────────────────────────────────────────────────────

  ["gtk_box_new"] = [[
**`gtk_box_new`** — Create a box container (`<gtk/gtk.h>`)

```c
GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);   // spacing: 6px
GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);

gtk_box_pack_start(GTK_BOX(hbox), label, FALSE, FALSE, 0);
gtk_box_pack_start(GTK_BOX(hbox), button, FALSE, FALSE, 0);
```

GTK4: use `gtk_box_append` instead of `gtk_box_pack_start`.

**See also:** `gtk_grid_new`, `gtk_revealer_new`, `gtk_paned_new`]],

  ["gtk_grid_new"] = [[
**`gtk_grid_new`** — Create a grid container (`<gtk/gtk.h>`)

```c
GtkWidget *grid = gtk_grid_new();
gtk_grid_attach(GTK_GRID(grid), label, 0, 0, 1, 1);  // col, row, width, height
gtk_grid_attach(GTK_GRID(grid), entry, 1, 0, 2, 1);
```

**See also:** `gtk_box_new`, `gtk_notebook_new`, `gtk_paned_new`]],

  ["gtk_scrolled_window_new"] = [[
**`gtk_scrolled_window_new`** — Create a scrollable container (`<gtk/gtk.h>`)

```c
GtkWidget *sw = gtk_scrolled_window_new(NULL, NULL);
gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(sw),
    GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
gtk_container_add(GTK_CONTAINER(sw), text_view);
```

GTK4: use `gtk_scrolled_window_set_child` instead of `gtk_container_add`.

**See also:** `gtk_text_view_new`, `gtk_tree_view_new`]],

  ["gtk_notebook_new"] = [[
**`gtk_notebook_new`** — Create a tabbed notebook (`<gtk/gtk.h>`)

```c
GtkWidget *notebook = gtk_notebook_new();
gtk_notebook_append_page(GTK_NOTEBOOK(notebook), page1, gtk_label_new("Tab 1"));
gtk_notebook_append_page(GTK_NOTEBOOK(notebook), page2, gtk_label_new("Tab 2"));
```

**See also:** `gtk_notebook_append_page`, `gtk_notebook_set_current_page`, `gtk_stack_new`]],

  -- ── Signals ─────────────────────────────────────────────────────────────────

  ["g_signal_connect"] = [[
**`g_signal_connect`** — Connect a signal to a callback (`<glib.h>`)

```c
g_signal_connect(widget, "clicked", G_CALLBACK(on_click), user_data);
g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
g_signal_connect(entry, "activate", G_CALLBACK(on_enter), NULL);

// GTK4: gesture-based instead of widget signals for input
```

Signal names depend on the widget. Common ones: `"clicked"`, `"activate"`, `"changed"`, `"destroy"`, `"realize"`, `"map"`.

**See also:** `g_signal_connect_data`, `g_signal_connect_swapped`, `G_CALLBACK`]],

  ["g_signal_connect_swapped"] = [[
**`g_signal_connect_swapped`** — Connect a signal with swapped arguments (`<glib.h>`)

```c
g_signal_connect_swapped(btn, "clicked", G_CALLBACK(gtk_widget_destroy), window);
```

Callback receives the user_data as the first argument, not the emitting object.

**See also:** `g_signal_connect`, `G_CALLBACK`]],

  -- ── CSS / Styling ───────────────────────────────────────────────────────────

  ["gtk_css_provider_new"] = [[
**`gtk_css_provider_new`** — Load CSS for styling (`<gtk/gtk.h>`)

```c
GtkCssProvider *provider = gtk_css_provider_new();
gtk_css_provider_load_from_string(provider,
    "button { background: #4a90d9; color: white; }"
    "label { font-size: 16px; }");

gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
    GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
```

GTK4: use `gtk_style_context_add_provider_for_display(gdk_display_get_default(), ...)`.

**See also:** `gtk_css_provider_load_from_file`, `GtkCssProvider`, `gtk_style_context_add_class`]],

  ["gtk_widget_add_css_class"] = [[
**`gtk_widget_add_css_class`** — Add a CSS class to a widget (GTK4) (`<gtk/gtk.h>`)

```c
gtk_widget_add_css_class(widget, "warning");
gtk_widget_remove_css_class(widget, "warning");
```

GTK3: use `gtk_style_context_add_class(gtk_widget_get_style_context(widget), "warning")`.

**See also:** `gtk_css_provider_new`, `gtk_style_context_add_class`]],

  -- ── Drawing Area (GTK3) / GL Area ───────────────────────────────────────────

  ["gtk_drawing_area_new"] = [[
**`gtk_drawing_area_new`** — Create a custom drawing area (`<gtk/gtk.h>`)

```c
GtkWidget *da = gtk_drawing_area_new();
gtk_widget_set_size_request(da, 320, 240);

g_signal_connect(da, "draw", G_CALLBACK(on_draw), NULL);

static gboolean on_draw(GtkWidget *widget, cairo_t *cr, gpointer data) {
    cairo_set_source_rgb(cr, 0.2, 0.4, 0.8);
    cairo_paint(cr);   // fill background

    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_arc(cr, 160, 120, 80, 0, 2 * M_PI);
    cairo_fill(cr);
    return FALSE;
}
```

GTK4: use `gtk_drawing_area_new` with `"snapshot"` signal instead of `"draw"`.

**See also:** `gtk_gl_area_new`, `GtkDrawingArea`, `cairo_t`]],

  ["gtk_gl_area_new"] = [[
**`gtk_gl_area_new`** — Create an OpenGL rendering area (`<gtk/gtk.h>`)

```c
GtkWidget *gl_area = gtk_gl_area_new();
g_signal_connect(gl_area, "realize", G_CALLBACK(on_realize), NULL);
g_signal_connect(gl_area, "render", G_CALLBACK(on_render), NULL);

static gboolean on_render(GtkGLArea *area, GdkGLContext *ctx) {
    glClearColor(0.2, 0.3, 0.4, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    // ... draw ...
    return TRUE;   // emit "draw" signal for overlay cairo pass
}
```

**See also:** `gtk_drawing_area_new`, `gtk_gl_area_set_has_depth_buffer`, `GtkGLArea`]],

  -- ── Builder ─────────────────────────────────────────────────────────────────

  ["gtk_builder_new_from_file"] = [[
**`gtk_builder_new_from_file`** — Load UI from XML file (`<gtk/gtk.h>`)

```c
GtkBuilder *builder = gtk_builder_new_from_file("ui/main_window.glade");
GtkWidget *window = GTK_WIDGET(gtk_builder_get_object(builder, "main_window"));
g_object_unref(builder);
```

GTK4: `.ui` files use the same format. `gtk_builder_new_from_resource` for embedded UIs.

**See also:** `gtk_builder_new_from_string`, `gtk_builder_get_object`, `gtk_builder_connect_signals`]],

  ["gtk_builder_get_object"] = [[
**`gtk_builder_get_object`** — Get a widget from a builder (`<gtk/gtk.h>`)

```c
GtkWidget *btn = GTK_WIDGET(gtk_builder_get_object(builder, "my_button"));
```

Returns `NULL` if the object name is not found. Always check the result.

**See also:** `gtk_builder_new_from_file`, `gtk_builder_get_objects`, `gtk_builder_connect_signals`]],

  -- ── File Chooser ────────────────────────────────────────────────────────────

  ["gtk_file_chooser_dialog_new"] = [[
**`gtk_file_chooser_dialog_new`** — Open file dialog (`<gtk/gtk.h>`)

```c
GtkWidget *dialog = gtk_file_chooser_dialog_new("Open File", NULL,
    GTK_FILE_CHOOSER_ACTION_OPEN,
    "_Cancel", GTK_RESPONSE_CANCEL,
    "_Open", GTK_RESPONSE_ACCEPT,
    NULL);

if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
    char *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
    // ... load file ...
    g_free(filename);
}
gtk_widget_destroy(dialog);
```

**See also:** `GtkFileChooserAction`, `gtk_file_chooser_set_filename`, `gtk_file_chooser_set_select_multiple`]],

  ["gtk_dialog_run"] = [[
**`gtk_dialog_run`** — Run a modal dialog (GTK3) (`<gtk/gtk.h>`)

```c
gint res = gtk_dialog_run(GTK_DIALOG(dialog));
if (res == GTK_RESPONSE_ACCEPT) { }
gtk_widget_destroy(dialog);
```

GTK4: use `gtk_window_set_modal` + `g_signal_connect` + `gtk_widget_set_visible` instead.

**See also:** `gtk_file_chooser_dialog_new`, `gtk_message_dialog_new`, `GtkResponseType`]],

  -- ── Menus ───────────────────────────────────────────────────────────────────

  ["gtk_menu_bar_new"] = [[
**`gtk_menu_bar_new`** — Create a menu bar (`<gtk/gtk.h>`)

```c
GtkWidget *menubar = gtk_menu_bar_new();
GtkWidget *file_menu = gtk_menu_new();
GtkWidget *file_item = gtk_menu_item_new_with_label("File");
gtk_menu_item_set_submenu(GTK_MENU_ITEM(file_item), file_menu);

GtkWidget *quit_item = gtk_menu_item_new_with_label("Quit");
g_signal_connect(quit_item, "activate", G_CALLBACK(gtk_main_quit), NULL);
gtk_menu_shell_append(GTK_MENU_SHELL(file_menu), quit_item);

gtk_menu_shell_append(GTK_MENU_SHELL(menubar), file_item);
```

GTK4: use `GMenuModel` with `gtk_popover_menu_new_from_model`.

**See also:** `gtk_menu_item_new_with_label`, `gtk_menu_shell_append`, `gtk_separator_menu_item_new`]],

  -- ── Dialogs ─────────────────────────────────────────────────────────────────

  ["gtk_message_dialog_new"] = [[
**`gtk_message_dialog_new`** — Create a message dialog (`<gtk/gtk.h>`)

```c
GtkWidget *dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
    GTK_MESSAGE_INFO, GTK_BUTTONS_OK,
    "File saved successfully.");
gtk_dialog_run(GTK_DIALOG(dialog));
gtk_widget_destroy(dialog);
```

**See also:** `gtk_dialog_run`, `gtk_messsage_dialog_format_secondary_text`, `GTK_MESSAGE_WARNING`]],

  ["gtk_about_dialog_new"] = [[
**`gtk_about_dialog_new`** — Create an About dialog (`<gtk/gtk.h>`)

```c
GtkWidget *about = gtk_about_dialog_new();
gtk_about_dialog_set_program_name(GTK_ABOUT_DIALOG(about), "MyApp");
gtk_about_dialog_set_version(GTK_ABOUT_DIALOG(about), "1.0");
gtk_about_dialog_set_comments(GTK_ABOUT_DIALOG(about), "A demonstration app");
gtk_about_dialog_set_logo(GTK_ABOUT_DIALOG(about), logo_pixbuf);
gtk_dialog_run(GTK_DIALOG(about));
gtk_widget_destroy(about);
```

**See also:** `gtk_about_dialog_set_license`, `gtk_about_dialog_set_website`, `gtk_show_about_dialog`]],
}
