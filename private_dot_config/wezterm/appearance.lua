-- =============================================================================
-- 外観設定（フォント、カラー、ウィンドウ、カーソルなど）
-- =============================================================================
local wezterm = require("wezterm")
local colors = require("modules.colors")

local M = {}

function M.apply_to_config(config)
  -- =============================================================================
  -- TYPOGRAPHY & READABILITY
  -- =============================================================================
  config.font = wezterm.font_with_fallback({
    {
      family = "Firge35Nerd Console",
      stretch = "UltraCondensed",
      weight = "DemiBold",
    },
    {
      family = "UDEV Gothic 35NF",
      stretch = "UltraExpanded",
      weight = "ExtraBlack",
    },
    {
      family = "JetBrainsMonoNL Nerd Font",
      weight = "DemiBold",
    },
    {
      family = "IBM Plex Sans JP"
    },
  })
  config.font_size = 8.5
  config.line_height = 1.0

  -- =============================================================================
  -- INPUT & ACCESSIBILITY
  -- =============================================================================
  config.use_ime = true
  config.ime_preedit_rendering = "System"
  config.send_composed_key_when_left_alt_is_pressed = true
  config.scrollback_lines = 10000

  -- =============================================================================
  -- COLOR SCHEME
  -- =============================================================================
  config.color_scheme = "Tokyo Night Storm (Gogh)"
  config.colors = {
    cursor_bg = colors.accent_purple,
    cursor_border = colors.accent_purple,
    cursor_fg = colors.bg_primary,

    selection_bg = colors.bg_tertiary,
    selection_fg = colors.fg_primary,

    split = colors.accent_blue,

    -- tab_bar の色は format-tab-title で制御するため、背景のみ設定
    tab_bar = {
      background = colors.bg_primary,
    },

    copy_mode_active_highlight_bg = { Color = colors.accent_green },
    copy_mode_active_highlight_fg = { Color = colors.bg_primary },
    copy_mode_inactive_highlight_bg = { Color = colors.bg_tertiary },
    copy_mode_inactive_highlight_fg = { Color = colors.fg_primary },

    visual_bell = colors.accent_blue,
  }

  -- =============================================================================
  -- WINDOW & LAYOUT
  -- =============================================================================
  config.window_decorations = "RESIZE"
  config.window_background_opacity = 0.80
  config.text_background_opacity = 0.80
  config.adjust_window_size_when_changing_font_size = false

  config.window_padding = {
    left = 5,
    right = 2,
    top = 3,
    bottom = 0,
  }

  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 20,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 20,
  }

  -- =============================================================================
  -- TAB BAR OPTIMIZATION
  -- =============================================================================
  config.use_fancy_tab_bar = false
  config.tab_max_width = 25
  config.hide_tab_bar_if_only_one_tab = false

  -- =============================================================================
  -- PANE MANAGEMENT
  -- =============================================================================
  config.inactive_pane_hsb = {
    hue = 1.0,
    saturation = 0.8,
    brightness = 0.4,
  }

  -- =============================================================================
  -- CURSOR & ANIMATION
  -- =============================================================================
  config.default_cursor_style = "SteadyBar"
  config.animation_fps = 60
  config.cursor_thickness = "2pt"

  -- =============================================================================
  -- SCROLLING & PERFORMANCE
  -- =============================================================================
  config.enable_scroll_bar = true
  config.min_scroll_bar_height = "3cell"
end

return M
