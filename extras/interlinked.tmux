################################################################################
# TMUX THEME: Interlinked — Blade Runner 2049 (matches Neovim interlinked)
# LA fog blue-grey base, Vegas amber accent, hologram cyan structure.
################################################################################

# Status bar colors
# Background: nvim bg_statusline, Foreground: fog white
set -g status-style "bg=#0b1016,fg=#b6c2cc"

# Left side: session name
# Vegas amber for the session name — the one warm accent
set -g status-left-length 50
set -g status-left "#[fg=#d9985f,bold] #S #[fg=#8292a0]| "

# Right side: date and time
set -g status-right-length 50
set -g status-right "#[fg=#8292a0]%d.%m. %H:%M "

# Window status format - just show number and name
# Show pane count indicator with superscript (▪²) when window has multiple panes - RED indicator
# Inactive windows: ghost grey
set -g window-status-format "#[fg=#52606d] #I:#W#{?#{>:#{window_panes},1}, #[fg=#c4605c]▪#{?#{==:#{window_panes},2},²,#{?#{==:#{window_panes},3},³,#{?#{==:#{window_panes},4},⁴,#{?#{==:#{window_panes},5},⁵,#{?#{==:#{window_panes},6},⁶,#{?#{==:#{window_panes},7},⁷,#{?#{==:#{window_panes},8},⁸,⁹}}}}}}},} "
# Active window: Vegas amber
set -g window-status-current-format "#[fg=#d9985f,bold] #I:#W#{?#{>:#{window_panes},1}, #[fg=#c4605c]▪#{?#{==:#{window_panes},2},²,#{?#{==:#{window_panes},3},³,#{?#{==:#{window_panes},4},⁴,#{?#{==:#{window_panes},5},⁵,#{?#{==:#{window_panes},6},⁶,#{?#{==:#{window_panes},7},⁷,#{?#{==:#{window_panes},8},⁸,⁹}}}}}}},} "

# Pane border colors
# Inactive border: barely-there fog line
set -g pane-border-style "fg=#1a232d"
# Active border: hologram cyan (amber text vs cyan structure — Vegas vs LA)
set -g pane-active-border-style "fg=#6e9fb5"

# Message colors (elevated surface)
set -g message-style "bg=#111821,fg=#b6c2cc"

# Mode style (copy/scroll mode) — cold steel selection
set -g mode-style "bg=#1d2a38,fg=#b6c2cc"
