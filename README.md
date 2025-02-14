# simple-tag

<!--toc:start-->

- [simple-tag](#simple-tag)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Add setup function in `yazi/init.lua`.](#add-setup-function-in-yaziinitlua)
    - [Add fetcher `yazi.toml`](#add-fetcher-yazitoml)
    - [Add `keymap.toml`](#add-keymaptoml)
  - [For developers](#for-developers)
  <!--toc:end-->

This is a Yazi plugin that add tags to files/folders. Each tag has its own tag key.
DISCLAIM: This is not mactag, and won't use mactag.

## Requirements

> [!IMPORTANT]
> Minimum version: yazi v25.2.7.

- [yazi](https://github.com/sxyazi/yazi)
- Tested on Linux.

## Installation

Install the plugin:

```sh
ya pack -a boydaihungst/simple-tag
```

> [!IMPORTANT]
> Deleted files/folders in Yazi will also have their tags cleared.
> However, if you delete them using a different file manager or through the command line, then re-create them,
> all tags will be restored. Using trash also retains tags, and only permanently deleting files/folders will clear the tags.

### Prevews

- Tag icon indicator:

![tag_with_icon](assets/2025-02-13-21-17-07.png)

- Tag text indicator a.k.a tag key

![tag_with_tag_key](assets/2025-02-13-21-17-56.png)

### Add setup function in `yazi/init.lua`.

Prefs is optional but the setup function is required.

```lua
require("simple-tag"):setup({
  -- icon,text,hidden indicator.
  ui_mode = "icon", -- (Optional)

  -- linemode order: icon/text indicator position if linemode
  -- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-plugin/preset/components/linemode.lua#L4-L5
  linemode_order = 500 -- (Optional)


  -- You can backup/restore this folder. But don't use same folder in the different OS.
  -- save_path =  -- full path to save tags folder (Optional)
  --       - Linux/MacOS: os.getenv("HOME") .. "/.config/yazi/tags"
  --       - Windows: os.getenv("APPDATA") .. "\\yazi\\config\\tags"

  -- Set colors for tag icon|text
	colors = { -- (Optional)
		-- Set this same with value `theme.toml` > [manager] > hovered > reversed
		-- Default theme use "reversed = true".
		-- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-config/preset/theme-dark.toml#L25
		reversed = true, -- (Optional)

		-- color for tag by tag key = "*". More colors: https://yazi-rs.github.io/docs/configuration/theme#types.color
		["*"] = "#bf68d9", -- (Optional)
		-- color for tag with key = "$"
		["$"] = "green",
		["!"] = "#cc9057",
		-- color for tag with key = "1"
		["1"] = "cyan",
		["p"] = "red",
	},

  -- Tag icons. Only show when ui_mode = "icon".
  -- Any text or nerdfont icons should work
  -- Default icon from mactag.yazi: ●; , , 󱈤
  -- More icon from nerd fonts: https://www.nerdfonts.com/cheat-sheet
  icons = {
    -- default icon
		default = "󰚋",
		-- Add icon "*" tag for tag key = "*".
		["*"] = "*",
		-- Add icon tag for tag key = "$"
		["$"] = "",
		-- Add icon tag for tag key = "!"
		["!"] = "",
		["p"] = "",
  }, -- (Optional)

})
```

### Add fetcher `yazi.toml`

Use one of these ways:

```toml
[plugin]

  fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]
# or
  prepend_fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]
# or
  append_fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]

```

### Add `keymap.toml`

> [!IMPORTANT]
> Check overlapped with default keys: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml

Since Yazi selects the first matching key to run, `prepend_keymap` always has a higher priority than default.
Or you can use `keymap` to replace all other keys

```toml
[manager]
  prepend_keymap = [
    # Tagging plugin

    # Toggle tag with any key (press any key to toggle tag)
    # This won't show the which_key popup. Simply press any tag key to toggle that tag for selected or hovered files/folders.
    # If the selected files/folders already have the pressed tag key, the tag will be removed from those files/folders.
    { on = [ '~' ], run = "plugin simple-tag -- toggle-tag", desc = "Toggle tag with any key (press any key to toggle tag)" },

    # Fixed key = *
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --key=*", desc = "Toggle tag with tag key = *" },

    # Switch tag indicator between icon > tag key > hidden.
    { on = [ "t", "t" ], run = "plugin simple-tag -- toggle-ui", desc = "Toggle tag indicator (icon > tag key > hidden)" },

    # Fixed tag indicator mode = hidden (Available modes: hidden|icon|text)
    { on = [ "T", "h" ], run = "plugin simple-tag -- toggle-ui --mode=hidden", desc = "Hide all tags indicator" },

    # Clear all tags from selected or hovered files/folders
    { on = [ "T", "c" ], run = "plugin simple-tag -- clear", desc = "Remove all tags from selected or hovered files" },

    # Selection Mode:
    # replace → Replace selected list with tagged files
    # unite → Combine all files from already selected files and files with selected tag.
    # intersect → Keep only the overlapping files.
    # subtract → Deselect files which has selected tag
    # exclude → Keep only the non-overlapping files.
    # undo → Undo/Redo selection (5 mode above)

    # Default mode = replace -> replace the whole selection list with tagged files/folders
    # which_key will popup to choose selection mode, after that you have to press a tag key to select.
    { on = [ "T", "s" ], run = "plugin simple-tag -- toggle-select", desc = "Selection only tagged files (press any tag key to select)" },

    # Fixed selection mode = unite.
    # This won't show which_key popup, just press any tag key to select
    { on = [ "T", "a" ], run = "plugin simple-tag -- toggle-select --mode=unite", desc = "Add tagged files to selection (press any tag key to select)" },

    # Fixed key = q and selection mode = replace
    { on = [ "T", "q" ], run = "plugin simple-tag -- toggle-select --mode=replace --tag=q", desc = "Selection only files with tag key = q" },

    # Undo/Redo selection (only works with 5 modes above)
    { on = [ "T", "u" ], run = "plugin simple-tag -- toggle-select --mode=undo", desc = "Undo selection action" },
]
```

## For developers

Trigger this plugin programmatically:

```lua
-- In your plugin:
  local simple_tag = require("simple-tag")
-- Available actions: toggle-tag, toggle-ui, clear, toggle-select
  local action = "toggle-select"
	local args = ya.quote(action)
	args = args .. " " .. ya.quote("--mode=unite")
-- another arguments
-- args = args .. " " .. ya.quote("--tag=q")
	ya.manager_emit("plugin", {
		simple_tag._id,
		args,
	})


-- Special action: "files-deleted" -> clear all tags from these files/folders
  local args = ya.quote("files-deleted")
-- A array of string url
  local files_to_clear_tags = selected_or_hovered_files()
  for _, url in ipairs(files_to_clear_tags) do
	  args = args .. " " .. ya.quote(url)
  end
  ya.manager_emit("plugin", {
		simple_tag._id,
	  args,
  })


```
