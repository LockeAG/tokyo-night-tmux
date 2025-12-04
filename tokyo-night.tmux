#!/usr/bin/env bash
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# title      Tokyo Night (Merged Edition)                             +
# version    1.1.0                                                    +
# repository https://github.com/logico-dev/tokyo-night-tmux           +
# author     Lógico (merged by LockeAG)                               +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Merged features from janoamaral + LockeAG rounded edges
#
# Available options:
#   @tokyo-night-tmux_theme              - storm | day | night (default)
#   @tokyo-night-tmux_transparent        - 1 | 0 (default)
#   @tokyo-night-tmux_rounded            - 1 (default) | 0
#   @tokyo-night-tmux_window_id_style    - digital | roman | fsquare | hsquare | dsquare | super | sub | none | hide
#   @tokyo-night-tmux_pane_id_style      - (same as above)
#   @tokyo-night-tmux_zoom_id_style      - (same as above)
#   @tokyo-night-tmux_terminal_icon      - custom icon (default: )
#   @tokyo-night-tmux_active_terminal_icon - custom icon (default: )
#   @tokyo-night-tmux_window_tidy_icons  - 1 | 0 (default) - remove extra spaces
#   @tokyo-night-tmux_show_datetime      - 1 (default) | 0
#   @tokyo-night-tmux_date_format        - YMD | MDY | DMY
#   @tokyo-night-tmux_time_format        - 24H | 12H
#   @tokyo-night-tmux_show_music         - 1 | 0 (default)
#   @tokyo-night-tmux_show_netspeed      - 1 | 0 (default)
#   @tokyo-night-tmux_show_path          - 1 | 0 (default)
#   @tokyo-night-tmux_show_battery_widget - 1 | 0 (default)
#   @tokyo-night-tmux_show_hostname      - 1 | 0 (default)
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source $SCRIPTS_PATH/themes.sh

tmux set -g status-left-length 80
tmux set -g status-right-length 150

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
# Highlight colors
tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"

tmux set -g message-style "bg=${THEME[blue]},fg=${THEME[background]}"
tmux set -g message-command-style "fg=${THEME[white]},bg=${THEME[black]}"

tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off

tmux set -g status-style bg="${THEME[background]}"

TMUX_VARS="$(tmux show -g)"

# Rounded edges option (LockeAG feature)
rounded_edges="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_rounded' | cut -d" " -f2)"
rounded_edges="${rounded_edges:-1}"  # Default to enabled

if [[ "$rounded_edges" == "1" ]]; then
  LEFT_ROUNDED=""
  RIGHT_ROUNDED=""
else
  LEFT_ROUNDED=""
  RIGHT_ROUNDED=""
fi

# Default styles
default_window_id_style="digital"
default_pane_id_style="hsquare"
default_zoom_id_style="dsquare"

# Default icons
default_terminal_icon=""
default_active_terminal_icon=""

# Read user configurations
window_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_window_id_style' | cut -d" " -f2)"
pane_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_pane_id_style' | cut -d" " -f2)"
zoom_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_zoom_id_style' | cut -d" " -f2)"
terminal_icon="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_terminal_icon' | cut -d" " -f2)"
active_terminal_icon="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_active_terminal_icon' | cut -d" " -f2)"
window_tidy="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_window_tidy_icons' | cut -d" " -f2)"

# Apply defaults if not set
window_id_style="${window_id_style:-$default_window_id_style}"
pane_id_style="${pane_id_style:-$default_pane_id_style}"
zoom_id_style="${zoom_id_style:-$default_zoom_id_style}"
terminal_icon="${terminal_icon:-$default_terminal_icon}"
active_terminal_icon="${active_terminal_icon:-$default_active_terminal_icon}"
window_tidy="${window_tidy:-0}"

# Window spacing
window_space=$([[ $window_tidy == "1" ]] && echo "" || echo " ")

# Widget scripts
netspeed="#($SCRIPTS_PATH/netspeed.sh)"
cmus_status="#($SCRIPTS_PATH/music-tmux-statusbar.sh)"
git_status="#($SCRIPTS_PATH/git-status.sh #{pane_current_path})"
wb_git_status="#($SCRIPTS_PATH/wb-git-status.sh #{pane_current_path} &)"
window_number="#($SCRIPTS_PATH/custom-number.sh #I $window_id_style)"
custom_pane="#($SCRIPTS_PATH/custom-number.sh #P $pane_id_style)"
zoom_number="#($SCRIPTS_PATH/custom-number.sh #P $zoom_id_style)"
date_and_time="$($SCRIPTS_PATH/datetime-widget.sh)"
current_path="#($SCRIPTS_PATH/path-widget.sh #{pane_current_path})"
battery_status="#($SCRIPTS_PATH/battery-widget.sh)"
hostname="#($SCRIPTS_PATH/hostname-widget.sh)"

#+--- Bars LEFT ---+
# Session name with optional rounded edges
if [[ "$rounded_edges" == "1" ]]; then
  tmux set -g status-left "#[fg=${THEME[blue]}]${LEFT_ROUNDED}#[fg=${THEME[bblack]},bg=${THEME[blue]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S$hostname #[fg=${THEME[blue]},bg=${THEME[background]}]${RIGHT_ROUNDED}"
else
  tmux set -g status-left "#[fg=${THEME[bblack]},bg=${THEME[blue]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S$hostname "
fi

#+--- Windows ---+
# Focus (active window)
if [[ "$rounded_edges" == "1" ]]; then
  tmux set -g window-status-current-format "$RESET#[fg=${THEME[bblack]},bg=${THEME[background]}]${LEFT_ROUNDED}#[fg=${THEME[green]},bg=${THEME[bblack]}]#{?#{==:#{pane_current_command},ssh},󰣀 ,$active_terminal_icon$window_space}#[fg=${THEME[foreground]},bold,nodim]$window_number#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane}#{?window_last_flag, , }#[fg=${THEME[bblack]},bg=${THEME[background]}]${RIGHT_ROUNDED}"
else
  tmux set -g window-status-current-format "$RESET#[fg=${THEME[green]},bg=${THEME[bblack]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,$active_terminal_icon$window_space}#[fg=${THEME[foreground]},bold,nodim]$window_number#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane}#{?window_last_flag, , }"
fi

# Unfocused (inactive windows)
tmux set -g window-status-format "$RESET#[fg=${THEME[foreground]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,$terminal_icon$window_space}${RESET}$window_number#W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane}#[fg=${THEME[yellow]}]#{?window_last_flag,󰁯  , }"

#+--- Bars RIGHT ---+
if [[ "$rounded_edges" == "1" ]]; then
  tmux set -g status-right "$battery_status$current_path$cmus_status$netspeed$git_status$wb_git_status#[fg=${THEME[black]}]${LEFT_ROUNDED}$date_and_time#[fg=${THEME[black]},bg=${THEME[background]}]${RIGHT_ROUNDED} "
else
  tmux set -g status-right "$battery_status$current_path$cmus_status$netspeed$git_status$wb_git_status$date_and_time"
fi

tmux set -g window-status-separator ""
