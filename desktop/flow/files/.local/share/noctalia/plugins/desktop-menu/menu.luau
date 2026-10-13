local pending = nil

local function item(text, glyph, callback)
  return ui.button({ text = text, glyph = glyph, variant = "ghost", contentAlign = "start", height = 32, fontSize = 14, glyphSize = 18, onClick = callback })
end

local function render()
  if pending then
    panel.render(ui.column({ padding = 12, gap = 12 }, {
      ui.label({ text = pending.label .. "しますか？", fontSize = 17, fontWeight = "semibold" }),
      ui.label({ text = "作業中の内容を保存してから実行してください。", fontSize = 13, maxLines = 3 }),
      ui.row({ gap = 8 }, {
        ui.button({ text = "キャンセル", variant = "ghost", onClick = "cancel" }),
        ui.button({ text = pending.label, variant = "destructive", onClick = "confirm" }),
      }),
    }))
    return
  end
  panel.render(ui.column({ padding = 6, gap = 2 }, {
    item("システム設定…", "settings", "settings"),
    item("外観を切り替える", "sun-moon", "appearance"),
    ui.separator({ spacing = 4, color = "outline/0.3" }),
    item("画面をロック", "lock", "lock"),
    item("スリープ", "moon", "sleep"),
    ui.separator({ spacing = 4, color = "outline/0.3" }),
    item("再起動…", "refresh", "reboot"),
    item("システム終了…", "power", "shutdown"),
    ui.separator({ spacing = 4, color = "outline/0.3" }),
    item("ログアウト…", "logout", "logout"),
  }))
end

local function run(...)
  panel.close()
  local argv = { "noctalia", "msg" }
  for _, arg in ipairs({...}) do table.insert(argv, arg) end
  noctalia.runAsync(argv)
end

function onOpen(context) pending = nil; render() end
function settings() run("settings-open") end
function appearance() run("theme-mode-toggle") end
function lock() run("session", "lock") end
function sleep() run("session", "lock_and_suspend") end
function reboot() pending = { action = "reboot", label = "再起動" }; render() end
function shutdown() pending = { action = "shutdown", label = "システム終了" }; render() end
function logout() pending = { action = "logout", label = "ログアウト" }; render() end
function cancel() pending = nil; render() end
function confirm() if pending then run("session", pending.action) end end
