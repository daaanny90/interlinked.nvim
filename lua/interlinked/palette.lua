-- Interlinked — Blade Runner 2049 colorscheme
-- Melancholic, not neon: Deakins' LA fog (cold blue-grey base), the Vegas
-- irradiated amber as the single warm accent, Joi's hologram cyan for
-- keywords, dusty rose for constants, oxidized "sea wall" green for types.
-- Everything desaturated — no pure hue anywhere.

local M = {}

M.palette = {
  -- Surfaces (LA night fog, bottom to top)
  bg = "#0e141a",
  bg_dark = "#0a0f14", -- sidebars (neo-tree)
  bg_float = "#111821",
  bg_highlight = "#141c25", -- cursorline
  bg_popup = "#121a23",
  bg_statusline = "#0b1016",
  bg_visual = "#1d2a38", -- cold steel selection
  bg_selected = "#18222d", -- pmenu/list selection
  bg_search = "#3a2b16", -- amber glow

  -- Foreground (fog whites)
  fg = "#b6c2cc",
  fg_dark = "#8292a0",
  fg_gutter = "#3d4a57",
  fg_sidebar = "#9aa8b4",

  -- Chrome
  comment = "#52606d", -- ghosts in the rain
  border = "#1f2a35",
  border_dim = "#1a232d",
  cursor = "#d9985f",
  accent = "#d9985f", -- Vegas amber — the one warm accent
  accent_bright = "#e2a56b",

  -- Status
  error = "#c4605c",
  warning = "#c9a35c",
  info = "#6e9fb5",
  hint = "#6fa893",
  ok = "#7ca87c",

  -- VCS
  git_add = "#6f9f7a",
  git_change = "#c9a35c",
  git_delete = "#c4605c",
  diff_add = "#122019",
  diff_change = "#1f1b10",
  diff_delete = "#241214",
  diff_text = "#2a2416",

  -- Syntax (cold machine palette, amber reserved for human data: strings)
  s_keyword = "#7fb2c4", -- hologram cyan
  s_func = "#a8bdd0", -- pale steel
  s_string = "#cf9663", -- Vegas amber, slightly muted
  s_type = "#7aa693", -- sea-wall copper green
  s_number = "#b58a98", -- dusty rose
  s_constant = "#b58a98",
  s_var = "#b6c2cc",
  s_property = "#93a6b5",
  s_param = "#a7b4bf",
  s_operator = "#7d8c99",
  s_tag = "#7fb2c4",
  s_attribute = "#7aa693",
  s_constructor = "#a8bdd0",
  s_preproc = "#c0875f", -- rust
  s_punct = "#5e6d7a",
  s_title = "#d9985f",
  s_special = "#86b0a0",
  s_escape = "#c9a35c",
  s_builtin = "#8fb5c9",
  s_namespace = "#93a6b5",
  s_label = "#c9a35c",
  s_link = "#6e9fb5",
  s_link_text = "#a8bdd0",

  none = "NONE",

  terminal = {
    black = "#0e141a",
    red = "#c4605c",
    green = "#7ca87c",
    yellow = "#c9a35c",
    blue = "#7f9cb5",
    magenta = "#b58a98",
    cyan = "#7fb2c4",
    white = "#b6c2cc",
    br_black = "#52606d",
    br_red = "#d3756f",
    br_green = "#8fb98f",
    br_yellow = "#d9b26a",
    br_blue = "#93b0c9",
    br_magenta = "#c49aa8",
    br_cyan = "#93c4d6",
    br_white = "#d0dae2",
  },
}

function M.get_palette()
  return M.palette
end

return M
