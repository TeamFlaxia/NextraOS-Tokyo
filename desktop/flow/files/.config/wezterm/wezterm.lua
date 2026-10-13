local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.enable_wayland = true
config.font = wezterm.font_with_fallback { 'Noto Sans Mono', 'Noto Sans CJK JP' }
config.font_size = 11
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.integrated_title_button_alignment = 'Right'
config.integrated_title_button_style = 'Windows'
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 28
config.window_frame = {
  font = wezterm.font 'Inter', font_size = 11,
  active_titlebar_bg = '#e9edf3', inactive_titlebar_bg = '#e9edf3',
  active_titlebar_fg = '#202735', inactive_titlebar_fg = '#596273',
  button_fg = '#202735', button_bg = '#e9edf3',
  button_hover_fg = '#202735', button_hover_bg = '#d8dfe9',
}
config.colors = {
  foreground = '#e5edf5', background = '#18212d',
  cursor_bg = '#b9c9e6', cursor_fg = '#18212d',
  selection_bg = '#365681', selection_fg = '#ffffff',
  ansi = { '#263243', '#ed8796', '#a6da95', '#eed49f', '#8aadf4', '#c6a0f6', '#8bd5ca', '#cad3f5' },
  brights = { '#697b94', '#f5a5b1', '#b8e4ab', '#f5e1b8', '#a8bffa', '#d7bbfb', '#a4e4db', '#ffffff' },
  tab_bar = {
    background = '#e9edf3',
    active_tab = { bg_color = '#f8fafc', fg_color = '#202735' },
    inactive_tab = { bg_color = '#e9edf3', fg_color = '#596273' },
    inactive_tab_hover = { bg_color = '#dce3ed', fg_color = '#202735' },
    new_tab = { bg_color = '#e9edf3', fg_color = '#202735' },
    new_tab_hover = { bg_color = '#dce3ed', fg_color = '#202735' },
  },
}
config.window_padding = { left = 16, right = 16, top = 12, bottom = 12 }
config.use_resize_increments = false
config.scrollback_lines = 10000
config.use_ime = true
config.check_for_updates = false
wezterm.on('format-window-title', function(tab, pane, tabs, panes, cfg)
  return 'WezTerm — ' .. tab.active_pane.title
end)
return config
