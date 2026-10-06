-- Interlinked — marquee: infinite scrolling band for statusline text.
--
-- Pure utility, theme-agnostic: components call M.scroll(text, width) on
-- every statusline evaluation. Short text passes through untouched; long
-- text starts a shared ticker that advances one character per tick and
-- forces a lualine refresh. The ticker self-stops a few seconds after the
-- last long text disappears (no idle timer churn).

local M = {}

local uv = vim.uv or vim.loop

local TICK_MS = 160
local IDLE_STOP_MS = 3000

M._timer = nil
M._offset = 0
M._last_active = 0

local function stop_timer()
  if M._timer then
    M._timer:stop()
    M._timer:close()
    M._timer = nil
  end
end

-- Battery saver: while this nvim doesn't have focus nobody reads its band,
-- so stop the ticker outright. It restarts by itself on the next scroll()
-- call (lualine's own 1s refresh re-evaluates the components after focus
-- returns). Inside tmux this needs `set -g focus-events on`.
vim.api.nvim_create_autocmd("FocusLost", {
  group = vim.api.nvim_create_augroup("interlinked-marquee", { clear = true }),
  callback = stop_timer,
})

local function ensure_timer()
  if M._timer then
    return
  end
  local timer = uv.new_timer()
  if not timer then
    return
  end
  M._timer = timer
  timer:start(
    TICK_MS,
    TICK_MS,
    vim.schedule_wrap(function()
      if not M._timer then
        return
      end
      if uv.now() - M._last_active > IDLE_STOP_MS then
        stop_timer()
        return
      end
      M._offset = (M._offset + 1) % 1000000
      pcall(function()
        require("lualine").refresh({ place = { "statusline" } })
      end)
    end)
  )
end

--- Scroll `text` inside a window of `width` characters.
--- Returns the text unchanged when it already fits.
---@param text string|nil
---@param width integer|nil display window (default 24)
---@param sep string|nil loop separator (default "   ·   ")
function M.scroll(text, width, sep)
  if text == nil or text == "" then
    return text or ""
  end
  width = width or 24
  if vim.fn.strchars(text) <= width then
    return text
  end

  M._last_active = uv.now()
  ensure_timer()

  local band = text .. (sep or "   ·   ")
  local band_len = vim.fn.strchars(band)
  local off = M._offset % band_len
  return vim.fn.strcharpart(band .. band, off, width)
end

return M
