-- Interlinked — a melancholic Blade Runner 2049 colorscheme.
-- LA fog, Vegas amber, hologram cyan. No neon purple.

local M = {}

M.config = {
  transparent = false,
  italic_comments = true,
  bold_keywords = false,
  terminal_colors = true,
  flicker = "extreme", -- "extreme" | "full" | "subtle" | false — dying-neon fx (:InterlinkedFx switches at runtime)
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.palette()
  return require("interlinked.palette").get_palette()
end

local function set_terminal_colors(p)
  local t = p.terminal
  vim.g.terminal_color_0 = t.black
  vim.g.terminal_color_1 = t.red
  vim.g.terminal_color_2 = t.green
  vim.g.terminal_color_3 = t.yellow
  vim.g.terminal_color_4 = t.blue
  vim.g.terminal_color_5 = t.magenta
  vim.g.terminal_color_6 = t.cyan
  vim.g.terminal_color_7 = t.white
  vim.g.terminal_color_8 = t.br_black
  vim.g.terminal_color_9 = t.br_red
  vim.g.terminal_color_10 = t.br_green
  vim.g.terminal_color_11 = t.br_yellow
  vim.g.terminal_color_12 = t.br_blue
  vim.g.terminal_color_13 = t.br_magenta
  vim.g.terminal_color_14 = t.br_cyan
  vim.g.terminal_color_15 = t.br_white
end

function M.load()
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "interlinked"

  local p = M.palette()
  require("interlinked.groups").setup(p, M.config)
  require("interlinked.plugins").setup(p, M.config)
  require("interlinked.fx").setup(p, M.config)

  if M.config.terminal_colors then
    set_terminal_colors(p)
  end
end

-- Lualine theme, auto-discovered via lua/lualine/themes/interlinked.lua
function M.lualine_theme()
  local p = M.palette()
  local function mode(color)
    return {
      a = { fg = p.bg, bg = color, gui = "bold" },
      b = { fg = p.fg_dark, bg = p.bg_selected },
      c = { fg = p.fg_dark, bg = p.bg_statusline },
    }
  end
  local theme = {
    normal = mode("#7f9cb5"), -- cold steel: K on duty
    insert = mode(p.accent), -- Vegas amber
    visual = mode("#b58a98"), -- Joi rose
    replace = mode(p.error),
    command = mode(p.warning),
    terminal = mode("#7fb2c4"),
    inactive = {
      a = { fg = p.fg_gutter, bg = p.bg_statusline },
      b = { fg = p.fg_gutter, bg = p.bg_statusline },
      c = { fg = p.fg_gutter, bg = p.bg_statusline },
    },
  }
  return theme
end

return M
