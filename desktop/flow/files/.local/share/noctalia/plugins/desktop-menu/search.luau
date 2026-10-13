local query = ""
function update()
  barWidget.render(ui.row({ gap = 5, align = "center" }, {
    ui.button({ glyph = "search", glyphSize = 18, variant = "ghost", width = 32, height = 32, onClick = "search" }),
    ui.input({ key = "search-input", placeholder = "アプリを検索…", width = 190, height = 32, fontSize = 13, onChange = "changed", onSubmit = "search" }),
  }))
end
function changed(value) query = value end
function search() noctalia.runAsync({ "noctalia", "msg", "panel-open", "launcher", query }) end
