-- Interlinked — core highlight groups (editor UI, syntax, treesitter,
-- LSP semantic tokens, diagnostics).

local M = {}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

---@param p table palette
---@param config table theme config
function M.setup(p, config)
  local bg = config.transparent and p.none or p.bg
  local bg_sidebar = config.transparent and p.none or p.bg_dark
  local bg_float = config.transparent and p.none or p.bg_float
  local comment_style = config.italic_comments and { italic = true } or {}
  local keyword_style = config.bold_keywords and { bold = true } or {}

  -- ==========================================================================
  -- Editor UI
  -- ==========================================================================
  hl("Normal", { fg = p.fg, bg = bg })
  hl("NormalNC", { fg = p.fg, bg = bg })
  hl("NormalFloat", { fg = p.fg, bg = bg_float })
  hl("FloatBorder", { fg = p.border, bg = bg_float })
  hl("FloatTitle", { fg = p.accent, bg = bg_float, bold = true })
  hl("NormalSB", { fg = p.fg_sidebar, bg = bg_sidebar })

  hl("Cursor", { fg = p.bg, bg = p.cursor })
  hl("lCursor", { fg = p.bg, bg = p.cursor })
  hl("CursorIM", { fg = p.bg, bg = p.cursor })
  hl("TermCursor", { fg = p.bg, bg = p.cursor })
  hl("CursorColumn", { bg = p.bg_highlight })
  hl("CursorLine", { bg = p.bg_highlight })
  hl("ColorColumn", { bg = p.bg_highlight })
  hl("Conceal", { fg = p.fg_dark })

  hl("LineNr", { fg = p.fg_gutter })
  hl("CursorLineNr", { fg = p.accent, bold = true })
  hl("SignColumn", { fg = p.fg_gutter, bg = p.none })
  hl("FoldColumn", { fg = p.fg_gutter, bg = p.none })
  hl("Folded", { fg = p.fg_dark, bg = p.bg_highlight })

  hl("Search", { fg = p.accent_bright, bg = p.bg_search })
  hl("IncSearch", { fg = p.bg, bg = p.accent })
  hl("CurSearch", { fg = p.bg, bg = p.accent })
  hl("Substitute", { fg = p.bg, bg = p.warning })
  hl("Visual", { bg = p.bg_visual })
  hl("VisualNOS", { bg = p.bg_visual })
  hl("MatchParen", { fg = p.accent_bright, bg = p.bg_visual, bold = true })

  hl("StatusLine", { fg = p.fg_dark, bg = p.bg_statusline })
  hl("StatusLineNC", { fg = p.fg_gutter, bg = p.bg_statusline })
  hl("WinSeparator", { fg = p.border })
  hl("VertSplit", { fg = p.border })
  hl("WinBar", { fg = p.fg_dark, bg = p.none })
  hl("WinBarNC", { fg = p.fg_gutter, bg = p.none })

  hl("TabLine", { fg = p.fg_dark, bg = p.bg_statusline })
  hl("TabLineFill", { bg = p.bg_statusline })
  hl("TabLineSel", { fg = p.accent, bg = p.bg, bold = true })

  hl("Pmenu", { fg = p.fg, bg = p.bg_popup })
  hl("PmenuSel", { fg = p.fg, bg = p.bg_selected })
  hl("PmenuKind", { fg = p.s_type, bg = p.bg_popup })
  hl("PmenuExtra", { fg = p.fg_dark, bg = p.bg_popup })
  hl("PmenuSbar", { bg = p.bg_popup })
  hl("PmenuThumb", { bg = p.border })
  hl("WildMenu", { fg = p.fg, bg = p.bg_selected })

  hl("Directory", { fg = p.s_keyword })
  hl("Title", { fg = p.accent, bold = true })
  hl("ErrorMsg", { fg = p.error })
  hl("WarningMsg", { fg = p.warning })
  hl("MoreMsg", { fg = p.info })
  hl("ModeMsg", { fg = p.fg_dark, bold = true })
  hl("MsgArea", { fg = p.fg_dark })
  hl("Question", { fg = p.info })
  hl("QuickFixLine", { bg = p.bg_visual, bold = true })
  hl("qfLineNr", { fg = p.fg_gutter })
  hl("qfFileName", { fg = p.s_keyword })

  hl("NonText", { fg = p.fg_gutter })
  hl("Whitespace", { fg = p.fg_gutter })
  hl("SpecialKey", { fg = p.fg_gutter })
  hl("EndOfBuffer", { fg = p.bg })

  hl("DiffAdd", { bg = p.diff_add })
  hl("DiffChange", { bg = p.diff_change })
  hl("DiffDelete", { bg = p.diff_delete })
  hl("DiffText", { bg = p.diff_text })
  hl("diffAdded", { fg = p.git_add })
  hl("diffRemoved", { fg = p.git_delete })
  hl("diffChanged", { fg = p.git_change })
  hl("diffOldFile", { fg = p.git_delete })
  hl("diffNewFile", { fg = p.git_add })
  hl("diffFile", { fg = p.s_keyword })
  hl("diffLine", { fg = p.comment })
  hl("diffIndexLine", { fg = p.s_number })

  hl("SpellBad", { sp = p.error, undercurl = true })
  hl("SpellCap", { sp = p.warning, undercurl = true })
  hl("SpellLocal", { sp = p.info, undercurl = true })
  hl("SpellRare", { sp = p.hint, undercurl = true })

  hl("healthError", { fg = p.error })
  hl("healthSuccess", { fg = p.ok })
  hl("healthWarning", { fg = p.warning })

  -- ==========================================================================
  -- Syntax (legacy groups)
  -- ==========================================================================
  hl("Comment", vim.tbl_extend("force", { fg = p.comment }, comment_style))
  hl("SpecialComment", vim.tbl_extend("force", { fg = p.comment }, comment_style))

  hl("Constant", { fg = p.s_constant })
  hl("String", { fg = p.s_string })
  hl("Character", { fg = p.s_string })
  hl("Number", { fg = p.s_number })
  hl("Float", { fg = p.s_number })
  hl("Boolean", { fg = p.s_number })

  hl("Identifier", { fg = p.s_var })
  hl("Function", { fg = p.s_func })

  hl("Statement", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("Conditional", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("Repeat", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("Label", { fg = p.s_label })
  hl("Operator", { fg = p.s_operator })
  hl("Keyword", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("Exception", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))

  hl("PreProc", { fg = p.s_preproc })
  hl("Include", { fg = p.s_preproc })
  hl("Define", { fg = p.s_preproc })
  hl("Macro", { fg = p.s_preproc })
  hl("PreCondit", { fg = p.s_preproc })

  hl("Type", { fg = p.s_type })
  hl("StorageClass", { fg = p.s_keyword })
  hl("Structure", { fg = p.s_type })
  hl("Typedef", { fg = p.s_type })

  hl("Special", { fg = p.s_special })
  hl("SpecialChar", { fg = p.s_escape })
  hl("Tag", { fg = p.s_tag })
  hl("Delimiter", { fg = p.s_punct })
  hl("Debug", { fg = p.warning })

  hl("Underlined", { underline = true })
  hl("Bold", { bold = true })
  hl("Italic", { italic = true })
  hl("Ignore", { fg = p.fg_gutter })
  hl("Error", { fg = p.error })
  hl("Todo", { fg = p.bg, bg = p.info, bold = true })

  -- ==========================================================================
  -- Treesitter
  -- ==========================================================================
  hl("@variable", { fg = p.s_var })
  hl("@variable.builtin", { fg = p.s_builtin })
  hl("@variable.parameter", { fg = p.s_param })
  hl("@variable.member", { fg = p.s_property })

  hl("@constant", { fg = p.s_constant })
  hl("@constant.builtin", { fg = p.s_number })
  hl("@constant.macro", { fg = p.s_preproc })

  hl("@module", { fg = p.s_namespace })
  hl("@module.builtin", { fg = p.s_builtin })
  hl("@label", { fg = p.s_label })

  hl("@string", { fg = p.s_string })
  hl("@string.documentation", { fg = p.s_string })
  hl("@string.regexp", { fg = p.s_escape })
  hl("@string.escape", { fg = p.s_escape })
  hl("@string.special", { fg = p.s_special })
  hl("@string.special.symbol", { fg = p.s_constant })
  hl("@string.special.url", { fg = p.s_link, underline = true })
  hl("@character", { fg = p.s_string })
  hl("@character.special", { fg = p.s_escape })

  hl("@boolean", { fg = p.s_number })
  hl("@number", { fg = p.s_number })
  hl("@number.float", { fg = p.s_number })

  hl("@type", { fg = p.s_type })
  hl("@type.builtin", { fg = p.s_type })
  hl("@type.definition", { fg = p.s_type })
  hl("@attribute", { fg = p.s_attribute })
  hl("@property", { fg = p.s_property })

  hl("@function", { fg = p.s_func })
  hl("@function.builtin", { fg = p.s_builtin })
  hl("@function.call", { fg = p.s_func })
  hl("@function.macro", { fg = p.s_preproc })
  hl("@function.method", { fg = p.s_func })
  hl("@function.method.call", { fg = p.s_func })
  hl("@constructor", { fg = p.s_constructor })
  hl("@operator", { fg = p.s_operator })

  hl("@keyword", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("@keyword.coroutine", { fg = p.s_keyword })
  hl("@keyword.function", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("@keyword.operator", { fg = p.s_keyword })
  hl("@keyword.import", { fg = p.s_preproc })
  hl("@keyword.repeat", { fg = p.s_keyword })
  hl("@keyword.return", vim.tbl_extend("force", { fg = p.s_keyword }, keyword_style))
  hl("@keyword.debug", { fg = p.warning })
  hl("@keyword.exception", { fg = p.s_keyword })
  hl("@keyword.conditional", { fg = p.s_keyword })
  hl("@keyword.directive", { fg = p.s_preproc })
  hl("@keyword.directive.define", { fg = p.s_preproc })

  hl("@punctuation.delimiter", { fg = p.s_punct })
  hl("@punctuation.bracket", { fg = p.s_punct })
  hl("@punctuation.special", { fg = p.s_special })

  hl("@comment", vim.tbl_extend("force", { fg = p.comment }, comment_style))
  hl("@comment.documentation", vim.tbl_extend("force", { fg = p.comment }, comment_style))
  hl("@comment.error", { fg = p.bg, bg = p.error, bold = true })
  hl("@comment.warning", { fg = p.bg, bg = p.warning, bold = true })
  hl("@comment.todo", { fg = p.bg, bg = p.info, bold = true })
  hl("@comment.note", { fg = p.bg, bg = p.hint, bold = true })

  hl("@markup.strong", { bold = true })
  hl("@markup.italic", { italic = true })
  hl("@markup.strikethrough", { strikethrough = true })
  hl("@markup.underline", { underline = true })
  hl("@markup.heading", { fg = p.accent, bold = true })
  hl("@markup.heading.1", { fg = p.accent_bright, bold = true })
  hl("@markup.heading.2", { fg = p.accent, bold = true })
  hl("@markup.heading.3", { fg = p.s_keyword, bold = true })
  hl("@markup.heading.4", { fg = p.s_func, bold = true })
  hl("@markup.heading.5", { fg = p.s_number, bold = true })
  hl("@markup.heading.6", { fg = p.comment, bold = true })
  hl("@markup.quote", vim.tbl_extend("force", { fg = p.fg_dark }, comment_style))
  hl("@markup.math", { fg = p.s_special })
  hl("@markup.link", { fg = p.s_link })
  hl("@markup.link.label", { fg = p.s_link_text })
  hl("@markup.link.url", { fg = p.s_link, underline = true })
  hl("@markup.raw", { fg = p.s_string })
  hl("@markup.raw.block", { fg = p.fg })
  hl("@markup.list", { fg = p.accent })
  hl("@markup.list.checked", { fg = p.ok })
  hl("@markup.list.unchecked", { fg = p.fg_gutter })

  hl("@diff.plus", { fg = p.git_add })
  hl("@diff.minus", { fg = p.git_delete })
  hl("@diff.delta", { fg = p.git_change })

  hl("@tag", { fg = p.s_tag })
  hl("@tag.builtin", { fg = p.s_tag })
  hl("@tag.attribute", { fg = p.s_attribute })
  hl("@tag.delimiter", { fg = p.s_punct })

  -- ==========================================================================
  -- LSP semantic tokens
  -- ==========================================================================
  hl("@lsp.type.class", { link = "@type" })
  hl("@lsp.type.comment", {}) -- let treesitter win
  hl("@lsp.type.decorator", { link = "@attribute" })
  hl("@lsp.type.enum", { link = "@type" })
  hl("@lsp.type.enumMember", { link = "@constant" })
  hl("@lsp.type.event", { link = "@type" })
  hl("@lsp.type.function", { link = "@function" })
  hl("@lsp.type.interface", { link = "@type" })
  hl("@lsp.type.keyword", { link = "@keyword" })
  hl("@lsp.type.macro", { link = "@function.macro" })
  hl("@lsp.type.method", { link = "@function.method" })
  hl("@lsp.type.namespace", { link = "@module" })
  hl("@lsp.type.parameter", { link = "@variable.parameter" })
  hl("@lsp.type.property", { link = "@property" })
  hl("@lsp.type.struct", { link = "@type" })
  hl("@lsp.type.type", { link = "@type" })
  hl("@lsp.type.typeParameter", { link = "@type" })
  hl("@lsp.type.variable", { link = "@variable" })
  hl("@lsp.mod.deprecated", { strikethrough = true })

  -- ==========================================================================
  -- Diagnostics
  -- ==========================================================================
  hl("DiagnosticError", { fg = p.error })
  hl("DiagnosticWarn", { fg = p.warning })
  hl("DiagnosticInfo", { fg = p.info })
  hl("DiagnosticHint", { fg = p.hint })
  hl("DiagnosticOk", { fg = p.ok })

  hl("DiagnosticVirtualTextError", { fg = p.error, bg = p.none })
  hl("DiagnosticVirtualTextWarn", { fg = p.warning, bg = p.none })
  hl("DiagnosticVirtualTextInfo", { fg = p.info, bg = p.none })
  hl("DiagnosticVirtualTextHint", { fg = p.hint, bg = p.none })

  hl("DiagnosticVirtualLinesError", { fg = p.error })
  hl("DiagnosticVirtualLinesWarn", { fg = p.warning })
  hl("DiagnosticVirtualLinesInfo", { fg = p.info })
  hl("DiagnosticVirtualLinesHint", { fg = p.hint })

  hl("DiagnosticUnderlineError", { sp = p.error, undercurl = true })
  hl("DiagnosticUnderlineWarn", { sp = p.warning, undercurl = true })
  hl("DiagnosticUnderlineInfo", { sp = p.info, undercurl = true })
  hl("DiagnosticUnderlineHint", { sp = p.hint, undercurl = true })

  hl("DiagnosticSignError", { fg = p.error })
  hl("DiagnosticSignWarn", { fg = p.warning })
  hl("DiagnosticSignInfo", { fg = p.info })
  hl("DiagnosticSignHint", { fg = p.hint })

  hl("DiagnosticFloatingError", { fg = p.error })
  hl("DiagnosticFloatingWarn", { fg = p.warning })
  hl("DiagnosticFloatingInfo", { fg = p.info })
  hl("DiagnosticFloatingHint", { fg = p.hint })

  hl("DiagnosticUnnecessary", { fg = p.comment, sp = p.hint, undercurl = true })
  hl("DiagnosticDeprecated", { strikethrough = true })

  hl("LspReferenceText", { bg = p.bg_selected })
  hl("LspReferenceRead", { bg = p.bg_selected })
  hl("LspReferenceWrite", { bg = p.bg_selected })
  hl("LspInlayHint", { fg = p.fg_gutter, bg = p.none, italic = true })
  hl("LspCodeLens", { fg = p.comment })
  hl("LspSignatureActiveParameter", { fg = p.accent, bold = true })
end

return M
