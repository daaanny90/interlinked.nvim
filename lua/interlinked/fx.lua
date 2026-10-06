-- Interlinked — ambient fx.
--
-- 1. Neon flicker: at random intervals a UI element sputters, dips or surges
--    like failing neon / a power dip in the sea wall rain. Levels:
--      "extreme"          — cinematic: every 6–18s; everything below plus
--                           "vegas" (amber flood), "wipe" (syntax fades in
--                           waves), "joi" (keywords blush rose) and a harder
--                           blackout that dims the text itself
--      "full"   (default) — noticeable: every 12–40s; targets include the
--                           lualine statusline (always visible), a "blackout"
--                           where gutter + separators + statusline drop
--                           together, and a "scan" sweep down the gutter
--      "subtle"           — rare and tiny: every 90–240s, line-nr/separator only
--      off                — :InterlinkedFx off
--    Events that would hit invisible UI are skipped at fire time (no
--    cursorline → no cursorline dip; single window → no separator event).
--    :InterlinkedFx now fires a blackout immediately (demo/test).
--    Epilepsy-safe by construction: single short bursts, long holds instead of
--    rapid alternation (≤3 cycles spread over ≥1.1s, i.e. under the 3-flashes-
--    per-second guideline), then tens of seconds of silence. No strobing.
-- 2. :Interlinked — the post-traumatic baseline test, typed out character by
--    character in a dark float. "Cells. Interlinked."

local M = {}

local uv = vim.uv or vim.loop

M._palette = nil
M._config = nil
M._flicker_timer = nil
M._level = "full"
M._last_on = "full"
M._scene = nil

local LEVELS = {
  extreme = { first = { 2, 5 }, interval = { 6, 18 } },
  full = { first = { 4, 10 }, interval = { 12, 40 } },
  subtle = { first = { 45, 120 }, interval = { 90, 240 } },
}

local function is_active()
  return vim.g.colors_name == "interlinked"
end

local function set_hl(group, opts)
  pcall(vim.api.nvim_set_hl, 0, group, opts)
end

-- Groups used by the baseline float. Defined here (not in groups.lua) so
-- :Interlinked can restore them even if another colorscheme wiped them.
function M.ensure_groups(p)
  set_hl("InterlinkedFloat", { fg = p.s_string, bg = "#070b10" })
  set_hl("InterlinkedHeader", { fg = p.s_keyword, bold = true })
  set_hl("InterlinkedText", { fg = p.accent })
  set_hl("InterlinkedCall", { fg = p.s_keyword, italic = true })
  set_hl("InterlinkedDim", { fg = p.comment })
  set_hl("InterlinkedScan", { fg = p.accent_bright, bold = true })
  set_hl("InterlinkedAlert", { fg = p.error, bold = true })
  set_hl("InterlinkedWarn", { fg = p.warning })
end

-- ============================================================================
-- Neon flicker
-- ============================================================================

-- Run a timed multi-group sequence; every step re-checks the theme is active.
-- steps: { { at = ms, apply = { { group, opts }, ... } }, ... }
local function seq(steps)
  for _, step in ipairs(steps) do
    vim.defer_fn(function()
      if is_active() then
        for _, a in ipairs(step.apply) do
          set_hl(a[1], a[2])
        end
      end
    end, step.at)
  end
end

-- Struggling neon on one group: three off/on cycles, long uneven holds (~1.2s).
local function sputter(group, on, dim)
  seq({
    { at = 0, apply = { { group, dim } } },
    { at = 230, apply = { { group, on } } },
    { at = 380, apply = { { group, dim } } },
    { at = 700, apply = { { group, on } } },
    { at = 860, apply = { { group, dim } } },
    { at = 1180, apply = { { group, on } } },
  })
end

-- Single slow excursion and recovery (power dip / surge) on one group.
local function pulse(group, alt, normal, hold)
  seq({
    { at = 0, apply = { { group, alt } } },
    { at = hold, apply = { { group, normal } } },
  })
end

-- lualine paints the statusline with its own groups; our lualine theme gives
-- sections b and c the same colors in every mode, so dimming all mode
-- variants is safe and always lands on the visible statusline.
local STATUS_MODES = { "normal", "insert", "visual", "replace", "command", "terminal" }

local function status_pairs(p, dim)
  local b_on = { fg = p.fg_dark, bg = p.bg_selected }
  local c_on = { fg = p.fg_dark, bg = p.bg_statusline }
  local b_dim = { fg = dim, bg = p.bg_selected }
  local c_dim = { fg = dim, bg = p.bg_statusline }
  local on, off = {}, {}
  for _, mode in ipairs(STATUS_MODES) do
    on[#on + 1] = { "lualine_b_" .. mode, b_on }
    on[#on + 1] = { "lualine_c_" .. mode, c_on }
    off[#off + 1] = { "lualine_b_" .. mode, b_dim }
    off[#off + 1] = { "lualine_c_" .. mode, c_dim }
  end
  return on, off
end

local function split_windows_visible()
  local n = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      n = n + 1
    end
  end
  return n > 1
end

-- Spinner scanner: a bright amber line number sweeps down the visible
-- window, one row at a time (~28ms/row). Continuous motion, not flashing.
local function scan_run()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local top = vim.fn.line("w0", win)
  local bot = vim.fn.line("w$", win)
  if bot <= top then
    return
  end
  local ns = vim.api.nvim_create_namespace("interlinked-scan")
  local row = top
  local timer = uv.new_timer()
  if not timer then
    return
  end
  timer:start(
    0,
    28,
    vim.schedule_wrap(function()
      local done = not vim.api.nvim_buf_is_valid(buf) or row > bot or not is_active()
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
      end
      if done then
        timer:stop()
        timer:close()
        return
      end
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, row - 1, 0, {
        number_hl_group = "InterlinkedScan",
        priority = 300,
      })
      row = row + 1
    end)
  )
end

local function build_events(p, cfg, level)
  local cstyle = (cfg and cfg.italic_comments) and { italic = true } or {}
  local nr_on = { fg = p.accent, bold = true }
  local nbg = (cfg and cfg.transparent) and "NONE" or p.bg
  local events = {}
  local function add(key, w, run)
    events[#events + 1] = { key = key, w = w, run = run }
  end

  -- the amber line number fights to stay lit (visible: number+relativenumber)
  add("nr", 3, function()
    sputter("CursorLineNr", nr_on, { fg = "#2a333d", bold = true })
  end)
  -- the line number surges bright, then settles — Joi leaning in
  add("surge", 2, function()
    pulse("CursorLineNr", { fg = p.accent_bright, bold = true }, nr_on, 520)
  end)
  -- a window separator browns out — only when a split is on screen
  if split_windows_visible() then
    add("sep", 2, function()
      sputter("WinSeparator", { fg = p.border }, { fg = p.bg_highlight })
    end)
  end

  if level ~= "subtle" then
    local extreme = level == "extreme"

    -- statusline brown-out: the city grid struggles (always visible)
    add("status", 3, function()
      local on, off = status_pairs(p, "#39434e")
      seq({
        { at = 0, apply = off },
        { at = 480, apply = on },
      })
    end)
    -- blackout: gutter + separators + statusline drop together, double-tap
    -- recover. On extreme the text itself loses power too.
    add("blackout", extreme and 3 or 2, function()
      local on, off = status_pairs(p, "#2e3842")
      local gutter_on =
        { { "LineNr", { fg = p.fg_gutter } }, { "CursorLineNr", nr_on }, { "WinSeparator", { fg = p.border } } }
      local gutter_off = {
        { "LineNr", { fg = "#151c24" } },
        { "CursorLineNr", { fg = "#2a333d", bold = true } },
        { "WinSeparator", { fg = "#121921" } },
      }
      local function cat(a, b)
        local out = {}
        vim.list_extend(out, a)
        vim.list_extend(out, b)
        return out
      end
      local all_off = cat(off, gutter_off)
      local all_on = cat(on, gutter_on)
      if extreme then
        table.insert(all_off, { "Normal", { fg = "#5a6672", bg = nbg } })
        table.insert(all_on, { "Normal", { fg = p.fg, bg = nbg } })
      end
      seq({
        { at = 0, apply = all_off },
        { at = 600, apply = all_on },
        { at = 740, apply = all_off },
        { at = 980, apply = all_on },
      })
    end)
    -- the spinner scanner sweeps the gutter
    add("scan", extreme and 3 or 2, scan_run)
    -- whole gutter dims: city power dip
    add("gutter", 2, function()
      pulse("LineNr", { fg = "#151c24" }, { fg = p.fg_gutter }, 500)
    end)
    -- comments fade like unstable memories, then return
    add("comment", 2, function()
      pulse(
        "Comment",
        vim.tbl_extend("force", { fg = "#313a44" }, cstyle),
        vim.tbl_extend("force", { fg = p.comment }, cstyle),
        800
      )
    end)
    -- cursorline light drops out — only when cursorline is actually on
    if vim.o.cursorline then
      add("cline", 2, function()
        pulse("CursorLine", { bg = p.bg_dark }, { bg = p.bg_highlight }, 450)
      end)
    end

    if extreme then
      -- Las Vegas: the whole frame drowns in irradiated amber dust, then
      -- the fog rolls back in (two slow transitions — no strobing)
      add("vegas", 2, function()
        seq({
          {
            at = 0,
            apply = {
              { "Normal", { fg = "#c9a083", bg = nbg } },
              { "LineNr", { fg = "#8a6a4a" } },
              { "CursorLineNr", { fg = "#e8b57a", bold = true } },
              { "Comment", vim.tbl_extend("force", { fg = "#7a5f49" }, cstyle) },
              { "WinSeparator", { fg = "#6a4f35" } },
            },
          },
          {
            at = 1100,
            apply = {
              { "Normal", { fg = p.fg, bg = nbg } },
              { "LineNr", { fg = p.fg_gutter } },
              { "CursorLineNr", nr_on },
              { "Comment", vim.tbl_extend("force", { fg = p.comment }, cstyle) },
              { "WinSeparator", { fg = p.border } },
            },
          },
        })
      end)
      -- memory wipe: comments, then strings, then functions fade in waves
      -- and everything floods back
      add("wipe", 2, function()
        local com = function(fg)
          return vim.tbl_extend("force", { fg = fg }, cstyle)
        end
        seq({
          { at = 0, apply = { { "Comment", com("#2b343e") }, { "@comment", com("#2b343e") } } },
          { at = 260, apply = { { "String", { fg = "#6e5a45" } }, { "@string", { fg = "#6e5a45" } } } },
          { at = 520, apply = { { "Function", { fg = "#56636f" } }, { "@function", { fg = "#56636f" } } } },
          {
            at = 1250,
            apply = {
              { "Comment", com(p.comment) },
              { "@comment", com(p.comment) },
              { "String", { fg = p.s_string } },
              { "@string", { fg = p.s_string } },
              { "Function", { fg = p.s_func } },
              { "@function", { fg = p.s_func } },
            },
          },
        })
      end)
      -- Joi interference: keywords blush rose for a blink, then back to cyan
      add("joi", 2, function()
        local rose = { fg = "#c49aa8", italic = true }
        local cyan = { fg = p.s_keyword }
        seq({
          {
            at = 0,
            apply = {
              { "Keyword", rose },
              { "@keyword", rose },
              { "@keyword.function", rose },
              { "@keyword.return", vim.tbl_extend("force", {}, rose, { bold = false }) },
            },
          },
          {
            at = 450,
            apply = {
              { "Keyword", cyan },
              { "@keyword", cyan },
              { "@keyword.function", cyan },
              { "@keyword.return", cyan },
            },
          },
        })
      end)
    end
  end

  return events
end

local function pick_event(events, key)
  if key then
    for _, e in ipairs(events) do
      if e.key == key then
        return e
      end
    end
  end
  local total = 0
  for _, e in ipairs(events) do
    total = total + e.w
  end
  local roll = math.random(total)
  for _, e in ipairs(events) do
    roll = roll - e.w
    if roll <= 0 then
      return e
    end
  end
  return events[1]
end

--- Fire one flicker event immediately (demo/test). `key` picks a specific
--- event ("blackout", "vegas", "scan", ...); nil picks a weighted random one.
--- Builds the extreme set so every event is available regardless of level.
function M.flicker_now(key)
  if not M._palette or not is_active() then
    return
  end
  pick_event(build_events(M._palette, M._config, "extreme"), key).run()
end

function M.start_flicker()
  local lvl = LEVELS[M._level]
  if M._flicker_timer or not lvl then
    return
  end
  local timer = uv.new_timer()
  if not timer then
    return
  end
  M._flicker_timer = timer

  local function fire()
    if not M._flicker_timer then
      return
    end
    if not is_active() then
      M.stop_flicker()
      return
    end
    local cfg = LEVELS[M._level]
    if not cfg then
      M.stop_flicker()
      return
    end
    local events = build_events(M._palette, M._config, M._level)
    pick_event(events).run()
    M._flicker_timer:start(math.random(cfg.interval[1], cfg.interval[2]) * 1000, 0, vim.schedule_wrap(fire))
  end

  timer:start(math.random(lvl.first[1], lvl.first[2]) * 1000, 0, vim.schedule_wrap(fire))
end

function M.stop_flicker()
  if M._flicker_timer then
    M._flicker_timer:stop()
    M._flicker_timer:close()
    M._flicker_timer = nil
  end
end

function M.set_level(level)
  if level ~= "off" and not LEVELS[level] then
    return
  end
  M._level = level
  if level ~= "off" then
    M._last_on = level
  end
  vim.g.interlinked_fx_level = level
  M.stop_flicker()
  if level ~= "off" and is_active() then
    M.start_flicker()
  end
end

-- ============================================================================
-- :Interlinked — baseline test
-- ============================================================================

-- :Interlinked poem — the original scene, kept as the easter egg.
local POEM = {
  { text = "POST-TRAUMATIC BASELINE TEST — OFFICER KD6-3.7", hl = "InterlinkedHeader" },
  { text = "" },
  { text = "Recite your baseline.", hl = "InterlinkedCall" },
  { text = "" },
  { text = "And blood-black nothingness began to spin.", hl = "InterlinkedText" },
  { text = "A system of cells interlinked within", hl = "InterlinkedText" },
  { text = "cells interlinked within cells interlinked", hl = "InterlinkedText" },
  { text = "within one stem.", hl = "InterlinkedText" },
  { text = "And dreadfully distinct against the dark,", hl = "InterlinkedText" },
  { text = "a tall white fountain played.", hl = "InterlinkedText" },
  { text = "" },
  { text = "Cells.", hl = "InterlinkedCall" },
  { text = "Interlinked.", hl = "InterlinkedText" },
  { text = "Within cells interlinked.", hl = "InterlinkedText" },
  { text = "" },
  { text = "We're done. Constant K. You can pick up your bonus.", hl = "InterlinkedDim" },
}

local CURSOR = "▌"

local function trunc(s, max)
  if vim.fn.strchars(s) > max then
    return vim.fn.strcharpart(s, 0, max - 1) .. "…"
  end
  return s
end

-- :Interlinked (no args) — the baseline test as a real session report:
-- the questions are the film's verses, the answers are live data.
local function build_report(d)
  local lines = {}
  local function add(text, hl)
    lines[#lines + 1] = { text = text or "", hl = hl }
  end

  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  add(("POST-TRAUMATIC BASELINE TEST — %s"):format(project:upper()), "InterlinkedHeader")
  add("")
  add("Recite your baseline.", "InterlinkedCall")
  add("")

  -- repo state
  add("Officer.", "InterlinkedCall")
  if d.git then
    local bits = { d.git.branch or "detached" }
    if d.git.dirty == 0 and d.git.untracked == 0 then
      bits[#bits + 1] = "clean"
    else
      bits[#bits + 1] = ("%d changed · %d untracked"):format(d.git.dirty, d.git.untracked)
    end
    if (d.git.ahead or 0) > 0 then
      bits[#bits + 1] = ("ahead %d"):format(d.git.ahead)
    end
    if (d.git.behind or 0) > 0 then
      bits[#bits + 1] = ("behind %d"):format(d.git.behind)
    end
    local hl = (d.git.dirty + d.git.untracked) > 0 and "InterlinkedText" or "InterlinkedDim"
    add(trunc(table.concat(bits, " · "), 58), hl)
  else
    add("Off-world. No records found.", "InterlinkedDim")
  end

  -- workspace diagnostics
  add("Cells.", "InterlinkedCall")
  local diag_hl = d.errors > 0 and "InterlinkedAlert" or (d.warns > 0 and "InterlinkedWarn" or "InterlinkedDim")
  if d.errors + d.warns + d.infos + d.hints == 0 then
    add("No anomalies detected.", diag_hl)
  else
    add(("%d errors · %d warnings · %d info · %d hints"):format(d.errors, d.warns, d.infos, d.hints), diag_hl)
  end

  -- attached LSP clients
  add("Interlinked.", "InterlinkedCall")
  if #d.lsp > 0 then
    add(trunc(table.concat(d.lsp, " · "), 58), "InterlinkedText")
  else
    add("No systems attached.", "InterlinkedDim")
  end

  -- last commit
  add("Within cells interlinked.", "InterlinkedCall")
  if d.commit then
    add(trunc(d.commit, 58), "InterlinkedText")
  else
    add("No memories on record.", "InterlinkedDim")
  end

  -- pending updates
  add("Dreadfully distinct.", "InterlinkedCall")
  local ups = {}
  if d.mason > 0 then
    ups[#ups + 1] = ("Mason %d"):format(d.mason)
  end
  if d.lazy then
    ups[#ups + 1] = ("lazy %s"):format(d.lazy)
  end
  if d.nvim_up then
    ups[#ups + 1] = "Nvim ↑"
  end
  if #ups > 0 then
    add(table.concat(ups, " · ") .. " pending", "InterlinkedWarn")
  else
    add("All systems current.", "InterlinkedDim")
  end

  add("")
  local dirty = d.git and (d.git.dirty + d.git.untracked) > 0
  if d.errors > 0 then
    add("You're not even close to baseline.", "InterlinkedAlert")
  elseif d.warns > 0 or #ups > 0 or dirty then
    add("Within acceptable parameters.", "InterlinkedText")
  else
    add("Constant K. You can pick up your bonus.", "InterlinkedText")
  end
  return lines
end

-- Gather live data; git bits are async, cb runs on the main loop when done.
local function collect(cb)
  local d = { errors = 0, warns = 0, infos = 0, hints = 0 }

  local sev = vim.diagnostic.severity
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local c = vim.diagnostic.count(buf)
      d.errors = d.errors + (c[sev.ERROR] or 0)
      d.warns = d.warns + (c[sev.WARN] or 0)
      d.infos = d.infos + (c[sev.INFO] or 0)
      d.hints = d.hints + (c[sev.HINT] or 0)
    end
  end

  local names, seen = {}, {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    if not seen[client.name] then
      seen[client.name] = true
      names[#names + 1] = client.name
    end
  end
  d.lsp = names

  d.mason = vim.g.mason_outdated_count or 0
  d.nvim_up = vim.g.nvim_update_available == true
  local ok, lazy_status = pcall(require, "lazy.status")
  if ok and lazy_status.has_updates() then
    d.lazy = lazy_status.updates()
  end

  local pending = 2
  local function step()
    pending = pending - 1
    if pending == 0 then
      cb(d)
    end
  end
  vim.system(
    { "git", "status", "--porcelain=v1", "--branch" },
    { text = true, timeout = 2000 },
    vim.schedule_wrap(function(res)
      if res.code == 0 and res.stdout then
        local g = { dirty = 0, untracked = 0 }
        for line in res.stdout:gmatch("[^\n]+") do
          if line:sub(1, 2) == "##" then
            g.branch = line:match("^## (.-)%.%.%.") or line:match("^## (%S+)")
            g.ahead = tonumber(line:match("ahead (%d+)"))
            g.behind = tonumber(line:match("behind (%d+)"))
          elseif line:sub(1, 2) == "??" then
            g.untracked = g.untracked + 1
          else
            g.dirty = g.dirty + 1
          end
        end
        d.git = g
      end
      step()
    end)
  )
  vim.system(
    { "git", "log", "-1", "--format=%h — %cr" },
    { text = true, timeout = 2000 },
    vim.schedule_wrap(function(res)
      if res.code == 0 and res.stdout and res.stdout ~= "" then
        d.commit = vim.trim(res.stdout)
      end
      step()
    end)
  )
end

local function scene_cleanup()
  local s = M._scene
  if not s then
    return
  end
  M._scene = nil
  for _, timer in ipairs({ s.type_timer, s.blink_timer }) do
    if timer then
      timer:stop()
      timer:close()
    end
  end
  if s.win and vim.api.nvim_win_is_valid(s.win) then
    pcall(vim.api.nvim_win_close, s.win, true)
  end
  if s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    pcall(vim.api.nvim_buf_delete, s.buf, { force = true })
  end
end

local function scene_set_line(s, lnum, text)
  if not vim.api.nvim_buf_is_valid(s.buf) then
    return false
  end
  vim.api.nvim_buf_set_lines(s.buf, lnum - 1, lnum, false, { text })
  return true
end

local function start_blink(s)
  local timer = uv.new_timer()
  if not timer then
    return
  end
  s.blink_timer = timer
  local shown = true
  -- Slow terminal-cursor blink (~0.9Hz) on one character: not a flash hazard.
  timer:start(
    530,
    530,
    vim.schedule_wrap(function()
      if M._scene ~= s then
        return
      end
      shown = not shown
      scene_set_line(s, #s.script + 1, shown and CURSOR or "")
    end)
  )
end

local function type_tick(s)
  if M._scene ~= s then
    return
  end
  local entry = s.script[s.line]
  if not entry then
    -- Done: park a blinking cursor under the last line.
    scene_set_line(s, #s.script + 1, CURSOR)
    start_blink(s)
    return
  end

  local delay
  s.col = s.col + 1
  if s.col > #entry.text then
    -- Line complete: write it without the cursor and lock in its color.
    if not scene_set_line(s, s.line, entry.text) then
      return scene_cleanup()
    end
    if entry.hl then
      pcall(vim.api.nvim_buf_set_extmark, s.buf, s.ns, s.line - 1, 0, { line_hl_group = entry.hl })
    end
    s.line = s.line + 1
    s.col = 0
    delay = entry.text == "" and s.speed.blank or s.speed.line
  else
    local partial = entry.text:sub(1, s.col)
    if not scene_set_line(s, s.line, partial .. CURSOR) then
      return scene_cleanup()
    end
    delay = math.random(s.speed.char[1], s.speed.char[2])
    local ch = entry.text:sub(s.col, s.col)
    if ch == "." or ch == "," then
      delay = delay + s.speed.punct
    end
  end
  s.type_timer:start(
    delay,
    0,
    vim.schedule_wrap(function()
      type_tick(s)
    end)
  )
end

local function open_scene(script, speed)
  scene_cleanup()
  if M._palette then
    M.ensure_groups(M._palette)
  end

  local width = 0
  for _, entry in ipairs(script) do
    width = math.max(width, vim.fn.strdisplaywidth(entry.text))
  end
  width = width + 4
  local height = #script + 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  local blank = {}
  for _ = 1, height do
    blank[#blank + 1] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, blank)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = { " ", " ", " ", " ", " ", " ", " ", " " },
    zindex = 200,
  })
  vim.wo[win].winhighlight = "NormalFloat:InterlinkedFloat,FloatBorder:InterlinkedFloat"

  local s = {
    buf = buf,
    win = win,
    ns = vim.api.nvim_create_namespace("interlinked-baseline"),
    script = script,
    speed = speed,
    line = 1,
    col = 0,
    type_timer = uv.new_timer(),
  }
  M._scene = s

  for _, lhs in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", lhs, scene_cleanup, { buffer = buf, nowait = true, silent = true })
  end
  vim.api.nvim_create_autocmd({ "WinClosed", "BufWipeout" }, {
    buffer = buf,
    once = true,
    callback = scene_cleanup,
  })

  s.type_timer:start(
    350,
    0,
    vim.schedule_wrap(function()
      type_tick(s)
    end)
  )
end

M.close = scene_cleanup

--- :Interlinked — baseline-test session report; :Interlinked poem — the scene.
function M.baseline(opts)
  if opts and opts.args == "poem" then
    open_scene(POEM, { char = { 14, 32 }, punct = 180, line = 300, blank = 140 })
    return
  end
  collect(function(d)
    open_scene(build_report(d), { char = { 8, 18 }, punct = 100, line = 180, blank = 80 })
  end)
end

-- ============================================================================
-- Setup (called from load(); must stay idempotent — the ThemePicker preview
-- re-runs load() on every cursor move)
-- ============================================================================

local function normalize_level(flicker)
  if flicker == false or flicker == "off" then
    return "off"
  end
  if flicker == "subtle" or flicker == "extreme" then
    return flicker
  end
  return "full" -- true, "full", nil
end

function M.setup(p, config)
  M._palette = p
  M._config = config
  M.ensure_groups(p)

  -- A level chosen at runtime (:InterlinkedFx) wins over the config default.
  -- The effective level is mirrored to g:interlinked_fx_level so other
  -- modules (marquee glitch) can read it.
  M._level = vim.g.interlinked_fx_level or normalize_level(config.flicker)
  if M._level ~= "off" then
    M._last_on = M._level
  end
  vim.g.interlinked_fx_level = M._level

  vim.api.nvim_create_user_command("Interlinked", M.baseline, {
    nargs = "?",
    complete = function()
      return { "poem" }
    end,
    desc = "Interlinked: baseline-test session report (:Interlinked poem for the scene)",
  })
  vim.api.nvim_create_user_command("InterlinkedFx", function(cmd)
    local arg = cmd.args ~= "" and cmd.args or "toggle"
    local now_key = arg:match("^now%s*(%S*)")
    if now_key then
      M.flicker_now(now_key ~= "" and now_key or "blackout")
      return
    end
    if arg == "toggle" then
      arg = M._level == "off" and M._last_on or "off"
    end
    if arg ~= "off" and not LEVELS[arg] then
      vim.notify(
        "interlinked: unknown fx level '" .. arg .. "' (off | subtle | full | extreme | now)",
        vim.log.levels.WARN
      )
      return
    end
    M.set_level(arg)
    vim.notify("interlinked: neon fx " .. arg)
  end, {
    nargs = "*",
    complete = function()
      return { "off", "subtle", "full", "extreme", "toggle", "now" }
    end,
    desc = "Interlinked: set neon flicker level (off | subtle | full | extreme | toggle) or fire one now",
  })

  if M._level ~= "off" then
    M.start_flicker()
  else
    M.stop_flicker()
  end

  local group = vim.api.nvim_create_augroup("interlinked-fx", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if not is_active() then
        M.stop_flicker()
      end
    end,
  })
end

return M
