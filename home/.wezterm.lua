local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- General appearance settings

config.color_scheme = "Snazzy"
config.font = wezterm.font_with_fallback({
	{ family = "BlexMono Nerd Font", weight = "DemiBold" },
	"MesloLGS NF",
})

config.window_background_opacity = 1
config.macos_window_background_blur = 0

config.font_size = 18
config.line_height = 1.2
config.front_end = "WebGpu"
config.background = {
	{
		source = {
			File = "/Users/ponteski/Pictures/Wallpapers/the-light.jpg",
		},
		hsb = {
			hue = 1.0,
			saturation = 1.00,
			brightness = 1.00,
		},
		width = "100%",
		height = "100%",
	},
	{
		source = {
			Color = "#111111",
		},
		width = "100%",
		height = "100%",
		opacity = 0.80,
	},
}
config.colors = {
	cursor_fg = "#282c35",
}
-- Window settings
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 175
config.initial_rows = 40

-- Tab bar settings
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- Cursor settings
config.default_cursor_style = "SteadyBar"
config.cursor_thickness = "2px"

-- Keys settings
config.keys = {
	{
		key = "w",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
}

return config
