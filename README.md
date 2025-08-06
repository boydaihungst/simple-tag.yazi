# simple-tag

<!--toc:start-->

- [simple-tag](#simple-tag)
  - [Overview](#overview)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Previews](#previews)
  - [Configuration](#configuration)
    - [Add setup function in `yazi/init.lua`.](#add-setup-function-in-yaziinitlua)
    - [Fetcher Configuration in `yazi.toml`](#fetcher-configuration-in-yazitoml)
    - [Keybindings in `keymap.toml`](#keybindings-in-keymaptoml)
    - [Customizing the Theme for tag hints window](#customizing-the-theme-for-tag-hints-window)
  - [For Developers](#for-developers)
  <!--toc:end-->

## Overview

simple-tag is a Yazi plugin that allows you to add tags to files and folders. Each tag is associated with a unique key.

> Disclaimer: This is not mactag and does not utilize mactag.

## Features

- Toggle, Add, Remove, Replace, Clear, Edit Tag(s). Supported input multiple tags.
- Filter Files/Folders by Tag(s).
- Visual Selection files/folders by Tag(s) (Replace, Unite, Subtract, Intersect, Exclude). Undo/Redo visual selection.
- Change Tag Icon/Text/Hidden Indicator.
- Tag Hints, will show up whenever you need to input or select tag(s).
- Automatically transfer tags after moving/renaming/bulk-renaming files/folders.
- Automatically clear tags when files/folders are deleted or trashed.

## Requirements

> [!IMPORTANT]
> Minimum supported version: Yazi v25.5.31.

- [Yazi](https://github.com/sxyazi/yazi)
- Tested on Linux

## Installation

Install the plugin:

```sh
ya pkg add boydaihungst/simple-tag
```

> [!IMPORTANT]
> Tags are automatically cleared when files/folders are deleted or moved to trash within Yazi.
> However, if deleted outside Yazi and then recreated, their tags will be restored.
> It also apply with renaming and moving files/folders.

## Previews

- Tag Hints, will show up whenever you need to input or select tag(s).
  Only custom Icons or colors are shown.

  ![image](https://github.com/user-attachments/assets/5b5b9baa-044d-4fe8-a09a-46ec915b94c3)

- Tag Icon/Text/Hidden Indicator:

  ![Recording 2025-03-29 at 20 49 49](https://github.com/user-attachments/assets/261bfd3f-3249-45b0-a59a-10e2f44a70eb)

- Toggle Tag(s):

  ![Recording 2025-03-29 at 21 10 38](https://github.com/user-attachments/assets/8cdf108c-8951-4da6-a9f4-b542ab0ce8d4)

- Add, Remove, Replace, Edit Tag(s):

  ![Recording 2025-03-29 at 21 30 13](https://github.com/user-attachments/assets/2c5bef3b-cb9f-49ca-976f-fb5bad5bc323)

- Filter Files by Tag(s) and Modes:
  In all of examples below, I didn't use fixed tag keys with `--keys`/`--key`/`--tag`/`--tags`

  - Mode = and (Default), match all of the selected tags:

    ![Recording 2025-03-29 at 20 56 47](https://github.com/user-attachments/assets/e7619681-7ab8-4e2c-b8ea-ea4aeb8c22db)

  - Mode = or, match at least one of the selected tags:

    ![Recording 2025-03-29 at 21 01 39](https://github.com/user-attachments/assets/cf9e757f-d910-4dca-aec5-cf9c36e54f34)

- Visual Selection Modes:
  In all of examples below, I didn't use fixed tag keys with `--keys`/`--key`/`--tag`/`--tags`

  ![image](https://github.com/user-attachments/assets/6efabb8a-0022-4aa3-ba20-04127e3c58c1)

  - Replace selection:

    ![Recording 2025-03-29 at 23 30 56](https://github.com/user-attachments/assets/364c07a7-c1ef-4323-8e92-ccb795233fd7)

  - Unite selection:

    ![Recording 2025-03-29 at 23 36 59](https://github.com/user-attachments/assets/915ed231-f553-4eec-aaf0-5c0f0f56b729)

  - Subtract selection:

    ![Recording 2025-03-29 at 23 45 42](https://github.com/user-attachments/assets/fac67ebb-2a77-49a6-955b-ab4e08ee4066)

  - Intersect selection:

    ![Recording 2025-03-29 at 23 51 17](https://github.com/user-attachments/assets/6f46e221-d43e-49b7-8e9c-6f4aa1317e3b)

  - Exclude selection:

    ![Recording 2025-08-06 at 16 31 31](https://github.com/user-attachments/assets/c8124b16-803d-48a4-9d44-e345060629d6)

  - Undo selection:

    ![Recording 2025-03-29 at 23 54 55](https://github.com/user-attachments/assets/abf7ccc7-7591-4683-84f9-53e8cb9a280e)

## Configuration

### Add setup function in `yazi/init.lua`.

The setup function is required, while preferences are optional.

```lua
require("simple-tag"):setup({
  -- UI display mode (icon, text, hidden)
  ui_mode = "icon", -- (Optional)

  -- Disable tag key hints (popup in bottom right corner)
  hints_disabled = false, -- (Optional)

  -- linemode order: adjusts icon/text position. Fo example, if you want icon to be on the mose left of linemode then set linemode_order larger than 1000.
  -- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-plugin/preset/components/linemode.lua#L4-L5
  linemode_order = 500, -- (Optional)

  -- You can backup/restore this folder within the same OS (Linux, windows, or MacOS).
  -- But you can't restore backed up folder in the different OS because they use difference absolute path.
  -- save_path =  -- full path to save tags folder (Optional)
  --       - Linux/MacOS: os.getenv("HOME") .. "/.config/yazi/tags"
  --       - Windows: os.getenv("APPDATA") .. "\\yazi\\config\\tags"

  -- Set tag colors
  colors = { -- (Optional)
	  -- Set this same value with `theme.toml` > [mgr] > hovered > reversed
	  -- Default theme use "reversed = true".
	  -- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-config/preset/theme-dark.toml#L25
	  reversed = true, -- (Optional)

	  -- More colors: https://yazi-rs.github.io/docs/configuration/theme#types.color
    -- format: [tag key] = "color"
	  ["*"] = "#bf68d9", -- (Optional)
	  ["$"] = "green",
	  ["!"] = "#cc9057",
	  ["1"] = "cyan",
	  ["p"] = "red",
  },

  -- Set tag icons. Only show when ui_mode = "icon".
  -- Any text or nerdfont icons should work as long as you use nerdfont to render yazi.
  -- Default icon from mactag.yazi: ●; Some generic icons: , , 󱈤
  -- More icon from nerd fonts: https://www.nerdfonts.com/cheat-sheet
  icons = { -- (Optional)
    -- default icon
		default = "󰚋",

    -- format: [tag key] = "tag icon"
		["*"] = "*",
		["$"] = "",
		["!"] = "",
		["p"] = "",
  },

})
```

### Fetcher Configuration in `yazi.toml`

Use one of the following methods:

> [!IMPORTANT]
>
> For yazi nightly replace `name` with `url`

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

# For yazi nightly, name is replaced with url
  append_fetchers = [
    { id = "simple-tag", url = "*", run = "simple-tag" },
    { id = "simple-tag", url = "*/", run = "simple-tag" },
  ]
```

### Keybindings in `keymap.toml`

> [!IMPORTANT]
> Ensure there are no conflicts with [default Keybindings](https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml).

Since Yazi prioritizes the first matching key, `prepend_keymap` takes precedence over defaults.
Or you can use `keymap` to replace all other keys

```toml
[mgr]
  prepend_keymap = [
    # Tagging plugin

    #─────────────────────────── TOGGLE TAG(S) ────────────────────────────
    # Toggle a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any tag key to toggle that tag for selected or hovered files/folders.
    { on = [ "t", "t", "k" ], run = "plugin simple-tag -- toggle-tag", desc = "Toggle a tag (press any key)" },

    # Fast Toggle tag(s) with fixed keys=!1q. key=!1q tag=!1q or tags=!1q also work
    # NOTE: For key=" (Quotation mark), then use key=\" (Backslash + Quotation mark) instead.
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --keys=!1q", desc = "Toggle tag(s) with fixed tag key(s) = (! and 1 and q)" },
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --keys=*", desc = "Toggle tag with fixed tag key = *" },
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --key=*", desc = "Toggle tag with fixed tag key = *" },

    # Toggle tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input tag key(s) to toggle that tags for selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "t", "i" ], run = "plugin simple-tag -- toggle-tag --input", desc = "Toggle tag(s) with value from (input box)" },


    #─────────────────────────── ADD TAG(S) ───────────────────────────────
    # Add a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key to add to selected or hovered files/folders.
    { on = [ "t", "a", "k" ], run = "plugin simple-tag -- add-tag", desc = "Add a tag (press any key)" },

    # Fast Add tag(s) with fixed keys=!1q. key=!1q tag=!1q or tags=!1q also work
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --keys=!1q", desc = "Add tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --keys=*", desc = "Add tag with fixed tag key = *" },
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --key=*", desc = "Add tag with fixed tag key = *" },

    # Add tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input new tag key(s) to add to selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "a", "i" ], run = "plugin simple-tag -- add-tag --input", desc = "Add tag(s) with value from (input box)" },


    #─────────────────────────── REMOVE/DELETE TAG(S) ───────────────────────────
    # Remove a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any tag key to be removed from selected or hovered files/folders.
    { on = [ "t", "d", "k" ], run = "plugin simple-tag -- remove-tag", desc = "Remove a tag (press any key)" },

    # Fast Remove tag(s) with fixed keys=!1q. key=!1q tag=!1q or tags=!1q also work
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --keys=!1q", desc = "Remove tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --keys=*", desc = "Remove tag with fixed tag key = *" },
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --key=*", desc = "Remove tag with fixed tag key = *" },

    # Remove tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input tag key(s) to be removed from selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "d", "i" ], run = "plugin simple-tag -- remove-tag --input", desc = "Remove tag(s) with value from (input box)" },


    #─────────────────────────── REPLACE ALL OLD TAG(S) WITH NEW TAG(S) ───────────────────────────
    # Replace a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key for selected or hovered files/folders.
    { on = [ "t", "r", "k" ], run = "plugin simple-tag -- replace-tag", desc = "Replace with a new tag (press any key)" },

    # Fast Replace tag(s) with fixed keys=!1q. key=!1q tag=!1q or tags=!1q also work
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --keys=!1q", desc = "Replace tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --keys=*", desc = "Replace tag(s) with fixed tag key = *" },
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --key=*", desc = "Replace tag(s) with fixed tag key = *" },

    # Replace tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input new tag key(s) for selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "r", "i" ], run = "plugin simple-tag -- replace-tag --input", desc = "Replace tag(s) with value from (input box)" },


    #─────────────────────────── EDIT TAG(S) ───────────────────────────
    # Edit a tag for hovered or selected files/folders
    # An input box with current tagged keys and a tag hint window will show up for each hovered or selected files/folders.
    # Simply edit tag key(s) for selected or hovered files/folders.
    # If you cancel any input box, all changes will be discarded.
    { on = [ "t", "e" ], run = "plugin simple-tag -- edit-tag ", desc = "Edit tag(s) (input box)" },


    #  ───────────────────────────── CLEAR TAG(S) ─────────────────────────────
    # Clear all tags from selected or hovered files/folders
    { on = [ "t", "c" ], run = "plugin simple-tag -- clear", desc = "Clear all tags from selected or hovered files" },


    #  ───────────────────────────── CHANGE UI ─────────────────────────────
    # Switch tag indicator between icon > tag key > hidden.
    # Useful when u don't remember the tag key
    { on = [ "t", "u", "s" ], run = "plugin simple-tag -- toggle-ui", desc = "Toggle tag indicator (icon > tag key > hidden)" },

    # Fixed tag indicator mode = hidden (Available modes: hidden|icon|text)
    { on = [ "t", "u", "h" ], run = "plugin simple-tag -- toggle-ui --mode=hidden", desc = "Hide all tags indicator" },

    #  ─────────────────────── FILTER FILES/FOLDERS BY TAGS: ───────────────────────
    # Available filter modes:
    # and → Filter files which contain all of selected tags (Default if mode isn't specified).
    # or → Filter files which contain at least one of selected tags.

    # Filter files/folders by tags

    # Filter files/folders by a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key to filter files/folders containing that tag in current directory.
    { on = [ "t", "f" ], run = "plugin simple-tag -- filter", desc = "Filter files/folders by a tag (press any key)" },

    # Fast Filter files/folders with fixed keys=!1q. key=!1q tag=!1q or tags=!1q also work
    # { on = [ "t", "f" ], run = "plugin simple-tag -- filter --key=!", desc = "Filter files/folders by a fixed tag = !" },
    # { on = [ "t", "f" ], run = "plugin simple-tag -- filter --keys=!1q", desc = "Filter files/folders by multiple fixed tag(s) (! and 1 and q)" },

    # Filter files/folders by tag(s) with value from input box.
    # An input box and a tag hint window will show up.
    # Simply input tag key(s) to filter files/folders of current directory.
    # Do not input any delimiter.
    # For example: Input value or --keys=!1q -> filter any files/folders contain all of these tags (! and 1 and q) in current directory.
    { on = [ "t", "F" ], run = "plugin simple-tag -- filter --input", desc = "Filter files/folders by tag(s) (input box)" },

    # Filter files/folders by tag(s) with --mode=or.
    # --mode=or -> Input value or --keys = !1q -> filter any files/folders contain at least one of these tags (! or 1 or q)
    { on = [ "t", "F" ], run = "plugin simple-tag -- filter --input --mode=or", desc = "Filter files/folders by contain tags (input box)" },
    # { on = [ "t", "F" ], run = "plugin simple-tag -- filter --keys=!1q --mode=or", desc = "Filter files/folders by multiple fixed tag(s) (! or 1 or q)" },


    #  ─────────────────────── VISUAL SELECT FILES/FOLDERS BY TAGS: ───────────────────────

    # Avaiable selection actions:
    # replace → Replaces the current selection list with files/folders that have the selected tag.
    # unite → Combines the currently selected files/folders with those that have the selected tag.
    # intersect → Keeps only the files/folders that are present in both the current selection and the tagged items.
    # subtract → Deselects files/folders that have the selected tag.
    # exclude → Keeps only the files/folders that do not have the selected tag.
    # undo → Undos or redoes the last selection action.

    # which_key will popup to choose selection mode
    # And a tag hint window will show up.
    # Simply select a selection mode then press any tag key to select files/folders
    { on = [ "t", "s", "t" ], run = "plugin simple-tag -- toggle-select", desc = "Select a selection action then select a tag key (toggle-select)" },
    # fixed tag(s). --keys=!1q or --key=!1q or --tag=!1q or --tags=!1q. They are the same.
    { on = [ "t", "s", "t" ], run = "plugin simple-tag -- toggle-select --keys=!1q", desc = "" },

    # Run action on files/folders by a tag.
    # A tag hint window will show up.
    # Simply press any tag key to do the folowing action:
    { on = [ "t", "s", "r" ], run = "plugin simple-tag -- replace-select", desc = "replace-select" },
    { on = [ "t", "s", "u" ], run = "plugin simple-tag -- unite-select", desc = "unite-select" },
    { on = [ "t", "s", "i" ], run = "plugin simple-tag -- intersect-select", desc = "intersect-select" },
    { on = [ "t", "s", "s" ], run = "plugin simple-tag -- subtract-select", desc = "subtract-select" },
    { on = [ "t", "s", "e" ], run = "plugin simple-tag -- exclude-select", desc = "exclude-select" },
    # Run action on files/folders by fixed tag(s). --keys=!1q or --key=!1q or --tag=!1q or --tags=!1q. They are the same.
    { on = [ "t", "s", "e" ], run = "plugin simple-tag -- replace-select --keys=!1q", desc = "Replaces the current selection list with files/folders that have (! and 1 and q) tag(s)" },

    # Run action on files/folders by tag(s) with value from input box.
    # A tag hint window will show up.
    # Simply input tag key(s) to do the folowing action:
    { on = [ "t", "s", "R" ], run = "plugin simple-tag -- replace-select --input", desc = "replace-select --input" },
    { on = [ "t", "s", "U" ], run = "plugin simple-tag -- unite-select --input", desc = "unite-select --input" },
    { on = [ "t", "s", "I" ], run = "plugin simple-tag -- intersect-select --input", desc = "intersect-select --input" },
    { on = [ "t", "s", "S" ], run = "plugin simple-tag -- subtract-select --input", desc = "subtract-select --input" },
    { on = [ "t", "s", "E" ], run = "plugin simple-tag -- exclude-select --input", desc = "exclude-select --input" },
    # it also support --mode=or when using with --input or --keys=!1q or --key=!1q or --tag=!1q or --tags=!1q
    { on = [ "t", "s", "R" ], run = "plugin simple-tag -- replace-select --input --mode=or", desc = "replace-select --input --mode=or" },
    { on = [ "t", "s", "R" ], run = "plugin simple-tag -- replace-select --keys=!1q --mode=or", desc = "replace-select --keys=!1q --mode=or" },

    # Undo/Redo selection (only works after using 5 modes above)
    { on = [ "t", "s", "u" ], run = "plugin simple-tag -- undo-select", desc = "Undos/Redos the last selection action" },
]
```

### Customizing the Theme for tag hints window

To modify the tag hints window appearance, edit `.../yazi/theme.toml`:
You can also use Falvors file instead.

```toml

[spot]
  border = { fg = "#4fa6ed" }
  title  = { fg = "#4fa6ed" }
```

## For Developers

You can trigger this plugin programmatically:

```lua
-- In your plugin:
  local simple_tag = require("simple-tag")
-- Available actions: toggle-tag, toggle-ui, clear, toggle-select, filter, add-tag, remove-tag, replace-tag, edit-tag
  local action = "toggle-select"
	local args = ya.quote(action)
	args = args .. " " .. ya.quote("--mode=unite")
-- another arguments
-- args = args .. " " .. ya.quote("--tag=q")
	ya.emit("plugin", {
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
  ya.emit("plugin", {
		simple_tag._id,
	  args,
  })

```
