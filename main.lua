--- @since 25.5.31

local PackageName = "simple-tag"
local M = {}

--          ╭─────────────────────────────────────────────────────────╮
--          │                          ENUM                           │
--          ╰─────────────────────────────────────────────────────────╯

local TARGET_FAMILY = ya.target_family()

-- stylua: ignore
local CAND_TAG_KEYS = {
	-- number + special characters
	{ on = "0" }, { on = "1" }, { on = "2" }, { on = "3" }, { on = "4" },
	{ on = "5" }, { on = "6" }, { on = "7" }, { on = "8" }, { on = "9" },
	{ on = "-" }, { on = "=" }, { on = "!" }, { on = "@" }, { on = "#" },
	{ on = "$" }, { on = "%" }, { on = "^" }, { on = "&" }, { on = "*" },
	{ on = "(" }, { on = ")" }, { on = "_" }, { on = "+" }, { on = "`" },
	{ on = "~" },	{ on = "[" },	{ on = "{" },	{ on = "]" },	{ on = "}" },
	{ on = "\\" },	{ on = "|" },	{ on = ";" },	{ on = ":" },	{ on = "'" },
	{ on = "\"" },	{ on = "," },	{ on = "<" },	{ on = "." },	{ on = ">" },
	{ on = "/" },	{ on = "?" },
	-- word
	{ on = "q" }, { on = "w" }, { on = "e" }, { on = "r" }, { on = "t" },
	{ on = "y" }, { on = "u" }, { on = "i" }, { on = "o" }, { on = "p" },
	{ on = "a" }, { on = "s" }, { on = "d" }, { on = "f" }, { on = "g" },
	{ on = "h" }, { on = "j" }, { on = "k" }, { on = "l" }, { on = "z" },
	{ on = "x" }, { on = "c" }, { on = "v" }, { on = "b" }, { on = "n" },
	{ on = "m" }
}

local CAND_SELECTION_ACTION = {
	-- number + special characters
	{ on = "1", desc = "Select Only tagged files" },
	{ on = "2", desc = "Select tagged files (Unite mode)" },
	{ on = "3", desc = "Select tagged files (Subtract mode)" },
	{ on = "4", desc = "Select tagged files (Intersect mode)" },
	{ on = "5", desc = "Select tagged files (Exclude mode)" },
	{ on = "6", desc = "Select tagged files (Undo mode)" },
}
local DEFAULT_TAG_ICON = "󰚋"
local DEFAULT_LINEMODE_ORDER = 500

local STATE_KEY = {
	ui_mode = "ui_mode",
	preserve_selected_files = "preserve_selected_files",
	colors = "colors",
	save_path = "save_path",
	tags_database = "tags_database",
	icons = "icons",
	hints_table = "hints_table",
	hints_disabled = "hints_disabled",
	linemode_order = "linemode_order",
	tasks_write_tags_db = "tasks_write_tags_db",
	tasks_delete_tags = "tasks_delete_tags",
	tasks_rename_tags = "tasks_rename_tags",
	tasks_write_tags_db_running = "tasks_write_tags_db_running",
	tasks_delete_tags_running = "tasks_delete_tags_running",
	tasks_rename_tags_running = "tasks_rename_tags_running",
}

---@enum UI_MODE
local UI_MODE = {
	hidden = "hidden",
	icon = "icon",
	text = "text",
}

---@enum FILTER_MODE
local FILTER_MODE = {
	["or"] = "or",
	["and"] = "and",
}

---@enum SELECTION_MODE
local SELECTION_MODE = {
	["or"] = "or",
	["and"] = "and",
}

---@enum ACTION_TAG_MODE
local TAG_ACTION = {
	remove = "remove-tag",
	add = "add-tag",
	replace = "replace-tag",
	toggle = "toggle-tag",
	edit = "edit-tag",
	clear = "clear",
	toggle_ui = "toggle-ui",

	toggle_select = "toggle-select",
	unite_select = "unite-select",
	subtract_select = "subtract-select",
	intersect_select = "intersect-select",
	exclude_select = "exclude-select",
	replace_select = "replace-select",
	undo_select = "undo-select",

	filter = "filter",
	files_deleted = "files-deleted",
	files_transferred = "files-transferred",
}

local UI_MODE_ORDERED = {
	UI_MODE.hidden,
	UI_MODE.icon,
	UI_MODE.text,
}

---@enum NOTIFY_MSG
local NOTIFY_MSG = {
	TAG_KEY_INVALID = "Tag key should be a single character",
}

---@enum PUBSUB_KIND
local PUBSUB_KIND = {
	tags_tbl_changed = PackageName .. "-tags-changed",
	-- "@" persist state
	ui_mode_changed = "@" .. PackageName .. "-ui-mode-changed",
	files_deleted = "delete",
	files_trash = "trash",
	file_renamed = "rename",
	files_bulk_renamed = "bulk",
	files_yank = "yank",
	files_move = "move",
}

--          ╭─────────────────────────────────────────────────────────╮
--          │                        Utilities                        │
--          ╰─────────────────────────────────────────────────────────╯

-- Encode binary string to hex (e.g., "\xED" => "\\xED")
local function hex_encode(s)
	return (s:gsub(".", function(c)
		return string.format("\\x%02X", c:byte())
	end))
end

-- Decode hex-encoded string (e.g., "\\xED" => "\xED")
local function hex_decode(s)
	return (s:gsub("\\x(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function hex_encode_table(t)
	local out = {}
	for k, v in pairs(t) do
		local new_k = type(k) == "string" and hex_encode(k) or k
		local new_v
		if type(v) == "table" then
			new_v = hex_encode_table(v)
		elseif type(v) == "string" then
			new_v = hex_encode(v)
		else
			new_v = v
		end
		out[new_k] = new_v
	end
	return out
end

local function hex_decode_table(t)
	local out = {}
	for k, v in pairs(t) do
		local new_k = type(k) == "string" and hex_decode(k) or k
		local new_v
		if type(v) == "table" then
			new_v = hex_decode_table(v)
		elseif type(v) == "string" then
			new_v = hex_decode(v)
		else
			new_v = v
		end
		out[new_k] = new_v
	end
	return out
end

local enqueue_task = ya.sync(function(state, task_name, task_data)
	if not state[task_name] or type(state[task_name]) ~= "table" then
		state[task_name] = {}
	end
	table.insert(state[task_name], task_data)
end)

local dequeue_task = ya.sync(function(state, task_name)
	if not state[task_name] or type(state[task_name]) ~= "table" then
		return {}
	end
	return table.remove(state[task_name], 1)
end)

local set_state = ya.sync(function(state, key, value)
	state[key] = value
end)

local get_state = ya.sync(function(state, key)
	return state[key]
end)

local function fail(s, ...)
	ya.notify({ title = PackageName, content = string.format(s, ...), timeout = 3, level = "error" })
end

local function warn(s, ...)
	ya.notify({ title = PackageName, content = string.format(s, ...), timeout = 3, level = "warn" })
end

--- broadcast through pub sub to other instances
---@param _ table state
---@param pubsub_kind PUBSUB_KIND
---@param data any
---@param to number default = 0 to all instances
local broadcast = ya.sync(function(_, pubsub_kind, data, to)
	ps.pub_to(to or 0, pubsub_kind, data)
end)

local function pathJoin(...)
	-- Detect OS path separator ('\' for Windows, '/' for Unix)
	local separator = package.config:sub(1, 1)
	local parts = { ... }
	local filteredParts = {}
	-- Remove empty strings or nil values
	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(filteredParts, part)
		end
	end
	-- Join the remaining parts with the separator
	local path = table.concat(filteredParts, separator)
	-- Normalize any double separators (e.g., "folder//file" → "folder/file")
	path = path:gsub(separator .. "+", separator)

	return path
end

local function ordered_pairs(tbl)
	local keys = {} -- Store all keys in a separate table

	for k in pairs(tbl) do
		table.insert(keys, k)
	end

	table.sort(keys) -- Sort keys alphabetically (or numerically)

	local i = 0
	return function()
		i = i + 1
		local key = keys[i]
		if key then
			return key, tbl[key]
		end
	end
end

local function tbl_deep_clone(original)
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in pairs(original) do
		copy[tbl_deep_clone(key)] = tbl_deep_clone(value)
	end

	return copy
end

-- Helper function: Convert an array into a set (table for fast lookup)
local function tbl_to_set(array)
	local set = {}
	for _, v in ipairs(array) do
		local _v = tostring(v)
		set[_v] = true
	end
	return set
end

-- Unite: Combine all unique elements from both arrays
local function tbl_unite(array1, array2)
	local set = tbl_to_set(array1)
	for _, v in ipairs(array2) do
		local _v = tostring(v)
		set[_v] = true
	end
	local result = {}
	for k in pairs(set) do
		table.insert(result, k)
	end
	return result
end

-- Subtract: Remove elements of array2 from array1
local function tbl_subtract(array1, array2)
	local set2 = tbl_to_set(array2)
	local result = {}
	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if not set2[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

-- Intersect: Keep only common elements between both arrays
local function tbl_intersect(array1, array2)
	local set2 = tbl_to_set(array2)
	local result = {}
	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if set2[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

-- Exclude: Remove common elements, keeping only unique ones from both arrays
local function tbl_exclude(array1, array2)
	local set1, set2 = tbl_to_set(array1), tbl_to_set(array2)
	local result = {}

	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if not set2[_v] then
			table.insert(result, _v)
		end
	end
	for _, v in ipairs(array2) do
		local _v = tostring(v)
		if not set1[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

local function tbl_is_subset(small, large)
	local set1 = tbl_to_set(large)

	for _, v in ipairs(small) do
		if not set1[v] then
			return false
		end
	end

	return true
end

local function tbl_contains_any(large, small)
	local set1 = tbl_to_set(large)

	for _, v in ipairs(small) do
		if set1[tostring(v)] then
			return true
		end
	end

	return false
end

local render = ya.sync(function()
	--TODO: remove this after next yazi released
	(ui.render or ya.render)()
end)

local get_cwd = ya.sync(function()
	return cx.active.current.cwd
end)

local selected_files = ya.sync(function()
	local tab, raw_urls = cx.active, {}
	for _, u in pairs(tab.selected) do
		raw_urls[#raw_urls + 1] = tostring(u)
	end
	return raw_urls
end)

local selected_or_hovered_files = ya.sync(function()
	local tab, raw_urls = cx.active, selected_files()
	if #raw_urls == 0 and tab.current.hovered then
		raw_urls[1] = tostring(tab.current.hovered.url)
	end
	return raw_urls
end)

--          ╭─────────────────────────────────────────────────────────╮
--          │                    Database section                     │
--          ╰─────────────────────────────────────────────────────────╯

---@param tags_tbl string tags database table
---@return table<{[string]:string[]}
local function read_tags_tbl(tags_tbl)
	local save_path = get_state(STATE_KEY.save_path)
	local tbl = TARGET_FAMILY == "windows" and tags_tbl:gsub(":", "") or tags_tbl
	local tbl_saved_file = pathJoin(save_path, tbl, "tags.json")

	local file = io.open(tbl_saved_file, "r")
	if file == nil then
		return {}
	end
	local tags_tbl_records_encoded = file:read("*all")
	file:close()
	local tag_records = hex_decode_table(ya.json_decode(tags_tbl_records_encoded))
	return tag_records
end

-- tags_db format: { "parent_abs_path a.k.a tags_tbl" = { "filename" = [ "q", "w", ... ] } }
local function write_tags_db()
	if get_state(STATE_KEY.tasks_write_tags_db_running) or #get_state(STATE_KEY.tasks_write_tags_db) == 0 then
		return
	end
	set_state(STATE_KEY.tasks_write_tags_db_running, true)
	local changed_tags_db = dequeue_task(STATE_KEY.tasks_write_tags_db)

	local save_path = get_state(STATE_KEY.save_path)
	for tags_tbl, tags_tbl_records in pairs(changed_tags_db) do
		local tbl = TARGET_FAMILY == "windows" and tags_tbl:gsub(":", "") or tags_tbl
		local tags_tbl_save_dir = pathJoin(save_path, tbl)
		for fname, tags in pairs(tags_tbl_records) do
			if #tags == 0 then
				changed_tags_db[tags_tbl][fname] = nil
			end
		end
		if next(changed_tags_db[tags_tbl]) == nil then
			-- delete mode
			fs.remove("file", Url(pathJoin(tags_tbl_save_dir, "tags.json")))
			fs.remove("dir_clean", Url(tags_tbl_save_dir))
			local save_dir_url = Url(tags_tbl_save_dir)
			local tags_parent_tbl = save_dir_url.parent
			if tags_parent_tbl and tags_parent_tbl ~= save_path then
				fs.remove("dir_clean", tags_parent_tbl)
			end
		else
			-- create/update mode
			local _, err_create_save_dir = fs.create("dir_all", Url(tags_tbl_save_dir))
			if err_create_save_dir then
				fail("Can't create save tags file: %s", tags_tbl_save_dir)
				break
			else
				local _, err_write_tags_tbl = fs.write(
					Url(pathJoin(tags_tbl_save_dir, "tags.json")),
					ya.json_encode(hex_encode_table(tags_tbl_records))
				)
				if err_write_tags_tbl then
					fail("Can't save tags to file: %s", tags_tbl_save_dir)
				end
			end
		end
		broadcast(PUBSUB_KIND.tags_tbl_changed, hex_encode(tags_tbl))
	end
	set_state(STATE_KEY.tasks_write_tags_db_running, false)
	write_tags_db()
end

--          ╭─────────────────────────────────────────────────────────╮
--          │                      Exposed APIs                       │
--          ╰─────────────────────────────────────────────────────────╯

function M:fetch(job)
	local tags_db = get_state(STATE_KEY.tags_database)
	for _, file in ipairs(job.files) do
		local tags_tbl = tostring(file.url.parent)
		if tags_db[tags_tbl] == nil then
			tags_db[tags_tbl] = read_tags_tbl(tags_tbl)
		end
	end
	set_state(STATE_KEY.tags_database, tags_db)
	render()
	return true
end

function M:has_tags(file, filter_tags)
	local url
	if type(file) == "string" then
		url = Url(file)
	else
		url = file.url
	end
	local tags_tbl = tostring(url.parent)
	local fname = tostring(url.name)

	local tags_database = get_state(STATE_KEY.tags_database)
	if tags_database[tags_tbl] and tags_database[tags_tbl][fname] then
		local tags = tags_database[tags_tbl][fname] or {}
		return tbl_is_subset(filter_tags, tags)
	end
	return false
end

local function delete_tags()
	if get_state(STATE_KEY.tasks_delete_tags_running) or #get_state(STATE_KEY.tasks_delete_tags) == 0 then
		return
	end
	set_state(STATE_KEY.tasks_delete_tags_running, true)
	local files_to_clear = dequeue_task(STATE_KEY.tasks_delete_tags)

	-- get changes tags
	local changed_tags_db = {}
	local tags_db = get_state(STATE_KEY.tags_database)
	for _, raw_url in ipairs(files_to_clear) do
		local url = type(raw_url) == "string" and Url(raw_url) or raw_url
		if url == nil then
			goto continue
		end
		local tags_tbl = tostring(url.parent)
		local fname = tostring(url.name)
		if tags_db and tags_tbl and tags_db[tags_tbl] then
			tags_db[tags_tbl][fname] = nil
			changed_tags_db[tags_tbl] = tags_db[tags_tbl]
		end
		::continue::
	end
	enqueue_task(STATE_KEY.tasks_write_tags_db, changed_tags_db)
	write_tags_db()
	set_state(STATE_KEY.tasks_delete_tags_running, false)
	delete_tags()
end

function M:setup(opts)
	local st = self
	local save_path = pathJoin(
		(TARGET_FAMILY == "windows" and os.getenv("APPDATA") .. "\\yazi\\config\\tags")
			or (os.getenv("HOME") .. "/.config/yazi/tags")
	)
	st[STATE_KEY.tasks_write_tags_db] = {}
	st[STATE_KEY.tasks_delete_tags] = {}
	st[STATE_KEY.tasks_rename_tags] = {}
	st[STATE_KEY.tags_database] = {}
	st[STATE_KEY.save_path] = save_path
	st[STATE_KEY.ui_mode] = UI_MODE.icon
	st[STATE_KEY.colors] = {}
	st[STATE_KEY.icons] = {
		default = DEFAULT_TAG_ICON,
	}
	st[STATE_KEY.linemode_order] = DEFAULT_LINEMODE_ORDER
	if type(opts) == "table" then
		st[STATE_KEY.ui_mode] = opts.ui_mode or st[STATE_KEY.ui_mode]
		st[STATE_KEY.save_path] = pathJoin(opts.save_path or save_path)
		st[STATE_KEY.colors] = opts.colors or st[STATE_KEY.colors]
		st[STATE_KEY.icons] = ya.dict_merge(st[STATE_KEY.icons], opts.icons or {})
		st[STATE_KEY.linemode_order] = tonumber(opts.linemode_order) or st[STATE_KEY.linemode_order]
		st[STATE_KEY.hints_disabled] = opts.hints_disabled or false
	end

	st[STATE_KEY.hints_table] = ya.dict_merge(tbl_deep_clone(st[STATE_KEY.icons]), tbl_deep_clone(st[STATE_KEY.colors]))
	-- render tags
	Linemode:children_add(function(_self)
		if st[STATE_KEY.ui_mode] == UI_MODE.hidden then
			return ""
		end
		local tags_tbl = tostring(_self._file.url.parent)
		local fname = _self._file.name
		local spans = {}
		if st[STATE_KEY.tags_database][tags_tbl] and st[STATE_KEY.tags_database][tags_tbl][fname] then
			-- default true
			local is_reversed_color = not st[STATE_KEY.colors]
				or st[STATE_KEY.colors].reversed == nil
				or st[STATE_KEY.colors].reversed == true
			local tags = st[STATE_KEY.tags_database][tags_tbl][fname] or {}
			table.sort(tags)
			for _, tag in ipairs(tags) do
				local style = ui.Style()
				if _self._file.is_hovered then
					if is_reversed_color then
						style:bg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
					else
						style:fg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
					end
				else
					style:fg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
				end
				if st[STATE_KEY.ui_mode] == UI_MODE.icon then
					spans[#spans + 1] = ui.Span(" " .. (st[STATE_KEY.icons][tag] or st[STATE_KEY.icons].default))
						:style(style)
				elseif st[STATE_KEY.ui_mode] == UI_MODE.text then
					spans[#spans + 1] = ui.Span(" " .. tag):style(style):bold()
				end
			end
		end
		return ui.Line(spans)
	end, st[STATE_KEY.linemode_order])

	ps.sub(PUBSUB_KIND.files_move, function(payload)
		local changed_files = {}
		for _, item in pairs(payload.items) do
			local from = item.from
			local to = item.to
			changed_files[tostring(from)] = tostring(to)
		end
		enqueue_task(STATE_KEY.tasks_rename_tags, changed_files)
		local args = ya.quote(TAG_ACTION.files_transferred)
		ya.emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub(PUBSUB_KIND.file_renamed, function(payload)
		local changed_files = {}
		changed_files[tostring(payload.from)] = tostring(payload.to)
		enqueue_task(STATE_KEY.tasks_rename_tags, changed_files)
		local args = ya.quote(TAG_ACTION.files_transferred)
		ya.emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub(PUBSUB_KIND.files_bulk_renamed, function(payload)
		local changed_files = {}
		for from, to in pairs(payload) do
			changed_files[tostring(from)] = tostring(to)
		end
		enqueue_task(STATE_KEY.tasks_rename_tags, changed_files)
		local args = ya.quote(TAG_ACTION.files_transferred)
		ya.emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub(PUBSUB_KIND.files_deleted, function(payload)
		local args = ya.quote(TAG_ACTION.files_deleted)
		local changed_files = {}
		for _, url in ipairs(payload.urls) do
			table.insert(changed_files, tostring(url))
		end
		enqueue_task(STATE_KEY.tasks_delete_tags, changed_files)
		ya.emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub(PUBSUB_KIND.files_trash, function(payload)
		local args = ya.quote(TAG_ACTION.files_deleted)
		local changed_files = {}
		for _, url in ipairs(payload.urls) do
			table.insert(changed_files, tostring(url))
		end
		enqueue_task(STATE_KEY.tasks_delete_tags, changed_files)
		ya.emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub_remote(PUBSUB_KIND.ui_mode_changed, function(mode)
		set_state(STATE_KEY.ui_mode, mode)
		render()
	end)

	ps.sub_remote(PUBSUB_KIND.tags_tbl_changed, function(tags_tbl)
		tags_tbl = hex_decode(tags_tbl)
		local tags_db = get_state(STATE_KEY.tags_database)
		if tags_db and tags_tbl and tags_db[tags_tbl] then
			tags_db[tags_tbl] = read_tags_tbl(tags_tbl)
			set_state(STATE_KEY.tags_database, tags_db)
			render()
		end
	end)
end

local function toggle_tag(files, new_tag_keys, mode)
	local tags_db = get_state(STATE_KEY.tags_database)
	local changed_tags_db = {}
	for _, raw_url in ipairs(files) do
		local url = Url(raw_url)
		local tags_tbl = tostring(url.parent)
		local fname = tostring(url.name)
		if not tags_db[tags_tbl] then
			tags_db[tags_tbl] = {}
		end
		if not tags_db[tags_tbl][fname] then
			tags_db[tags_tbl][fname] = {}
		end
		local tags = tags_db[tags_tbl][fname] or {}

		if mode == TAG_ACTION.toggle then
			local lookup = {}

			-- Convert array into a lookup table for fast searching
			for i, v in ipairs(tags) do
				lookup[v] = i -- Store the index of each element
			end
			-- Toggle each value in the values array
			for _, v in ipairs(new_tag_keys) do
				if lookup[v] then
					-- If found, remove it
					table.remove(tags, lookup[v])
					lookup = {} -- Reset lookup (indexes shift after removal)
					for i, item in ipairs(tags) do
						lookup[item] = i
					end
				else
					-- If not found, add it
					table.insert(tags, v)
					lookup[v] = #tags -- Update lookup with new index
				end
			end
		elseif mode == TAG_ACTION.remove then
			-- remove if exist
			tags = tbl_subtract(tags, new_tag_keys)
		elseif mode == TAG_ACTION.add then
			-- add if not exist
			tags = tbl_unite(tags, new_tag_keys)
		elseif mode == TAG_ACTION.replace then
			-- replace if exist
			tags = #new_tag_keys == 0 and nil or new_tag_keys
		end
		tags_db[tags_tbl][fname] = tags
		changed_tags_db[tags_tbl] = tags_db[tags_tbl]
	end

	enqueue_task(STATE_KEY.tasks_write_tags_db, changed_tags_db)
	write_tags_db()
end

local function show_cands_ui_modes()
	local choice_action = ya.which({ cands = CAND_SELECTION_ACTION })
	if not choice_action then
		return
	end
	local action = CAND_SELECTION_ACTION[choice_action].on
	if action == "1" then
		return TAG_ACTION.replace_select
	elseif action == "2" then
		return TAG_ACTION.unite_select
	elseif action == "3" then
		return TAG_ACTION.subtract_select
	elseif action == "4" then
		return TAG_ACTION.intersect_select
	elseif action == "5" then
		return TAG_ACTION.exclude_select
	elseif action == "6" then
		return TAG_ACTION.undo_select
	end
end

--          ╭─────────────────────────────────────────────────────────╮
--          │                       UI Section                        │
--          ╰─────────────────────────────────────────────────────────╯

local toggle_tags_hints = ya.sync(function(self)
	if self[STATE_KEY.hints_disabled] then
		return
	end
	if self.children then
		Modal:children_remove(self.children)
		self.children = nil
	else
		self.children = Modal:children_add(self, 20)
	end
	--TODO: remove this after next yazi released
	(ui.render or ya.render)()
end)

function M:new(area)
	self:layout(area)
	return self
end

local function table_length(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function M:layout(area)
	local length = table_length(get_state(STATE_KEY.hints_table) or {})
	local chunks = ui.Layout()
		:constraints({
			ui.Constraint.Fill(1),
			ui.Constraint.Length(length + 1),
			ui.Constraint.Percentage(5),
		})
		:split(area)

	chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Fill(9),
			ui.Constraint.Fill(1),
			ui.Constraint.Percentage(1),
		})
		:split(chunks[2])

	self._area = chunks[2]
end

function M:reflow()
	return { self }
end

function M:redraw()
	local rows = {}
	local colors = get_state(STATE_KEY.colors) or {}
	local icons = get_state(STATE_KEY.icons) or {}
	local rendered_tags = get_state(STATE_KEY.hints_table)
	for tag, _ in ordered_pairs(rendered_tags) do
		if tag ~= "default" and tag ~= "reversed" then
			rows[#rows + 1] = ui.Row({
				ui.Line(ui.Span(tag):fg(colors[tag] and colors[tag] or "reset")):align(ui.Align.CENTER),
				ui.Line(ui.Span(icons[tag] or icons.default):fg(colors[tag] and colors[tag] or "reset"))
					:align(ui.Align.CENTER),
			})
		end
	end

	return {
		ui.Clear(self._area),
		ui.Border(ui.Edge.ALL)
			:area(self._area)
			:type(ui.Border.ROUNDED)
			:style(th.spot.border or ui.Style():fg("blue"))
			:title(ui.Line("Tags"):align(ui.Align.CENTER):style(th.spot.title or ui.Style():fg("blue"))),
		ui.Table(rows)
			:area(self._area:pad(ui.Pad(1, 1, 1, 1)))
			:header(
				ui.Row({ ui.Line("Key"):align(ui.Align.CENTER), ui.Line("Icon"):align(ui.Align.CENTER) })
					:style(ui.Style():bold())
			)
			:widths({
				ui.Constraint.Length(20),
				ui.Constraint.Length(20),
				ui.Constraint.Percentage(70),
				ui.Constraint.Length(10),
			}),
	}
end

local function show_cands_input_tags(title, input_mode, default_input_value)
	local choice
	if not input_mode then
		toggle_tags_hints()
		choice = ya.which({ cands = CAND_TAG_KEYS, silent = true })
		toggle_tags_hints()
		if not choice then
			return
		end
		return CAND_TAG_KEYS[choice].on
	else
		toggle_tags_hints()
		local title_len = utf8.len(title) or 0
		local input_width = 50
		local max_width = 200
		if title_len > input_width then
			input_width = title_len > max_width and max_width or title_len
			title = title_len > input_width and (string.sub(title, 1, input_width) .. "...") or title
		end
		local input_value, input_event = ya.input({
			title = title,
			value = default_input_value or "",
			pos = { "center", w = input_width },
			-- TODO: remove this after next yazi released
			position = { "center", w = input_width },
		})
		toggle_tags_hints()
		if input_event == 1 and input_value then
			return input_value or ""
		else
			return
		end
	end
end

function M:entry(job)
	local action = job.args[1]
	ya.emit("escape", { visual = true })
	if
		action == TAG_ACTION.toggle
		or action == TAG_ACTION.add
		or action == TAG_ACTION.remove
		or action == TAG_ACTION.replace
	then
		local selected_tag_keys = {}
		local inputted_files = selected_or_hovered_files()
		local inputted_tags = job.args.tags or job.args.tags or job.args.keys or job.args.key
		local input_mode = job.args.input
		-- Mode: remove, add, toggle
		local toggle_mode = action
		local title = (
			toggle_mode == TAG_ACTION.add and "Add"
			or toggle_mode == TAG_ACTION.remove and "Remove"
			or toggle_mode == TAG_ACTION.replace and "Replace"
			or "Toggle"
		) .. " tags:"

		if not inputted_tags then
			inputted_tags = show_cands_input_tags(title, input_mode)
		end

		if not inputted_tags then
			return
		end
		for _, code in utf8.codes(inputted_tags) do
			table.insert(selected_tag_keys, utf8.char(code))
		end
		toggle_tag(inputted_files, selected_tag_keys, toggle_mode)
	elseif action == TAG_ACTION.edit then
		local files_to_update = selected_or_hovered_files()
		if #files_to_update == 0 then
			return
		end

		local tags_db = get_state(STATE_KEY.tags_database)
		local changed_tags_db = {}
		for _, url_raw in ipairs(files_to_update) do
			local updated_tags = {}
			local url = Url(url_raw)
			local tags_tbl = tostring(url.parent)
			if not tags_db[tags_tbl] then
				tags_db[tags_tbl] = {}
			end
			local fname = url.name
			local title = "Edit tags (" .. fname .. "):"
			local inputted_tags = show_cands_input_tags(title, true, table.concat(tags_db[tags_tbl][fname] or {}))
			if inputted_tags == nil then
				return
			end

			for _, code in utf8.codes(inputted_tags) do
				table.insert(updated_tags, utf8.char(code))
			end
			tags_db[tags_tbl][fname] = #updated_tags == 0 and nil or updated_tags
			changed_tags_db[tags_tbl] = tags_db[tags_tbl]
		end
		enqueue_task(STATE_KEY.tasks_write_tags_db, changed_tags_db)
		write_tags_db()
	elseif action == TAG_ACTION.clear then
		enqueue_task(STATE_KEY.tasks_delete_tags, selected_or_hovered_files())
		delete_tags()
	elseif action == TAG_ACTION.toggle_ui then
		local ui_mode = job.args.mode
		-- toggle between show icons/text keys/hidden
		if not ui_mode then
			local old_ui_mode = get_state(STATE_KEY.ui_mode)
			for idx, m in ipairs(UI_MODE_ORDERED) do
				if m == old_ui_mode then
					ui_mode = UI_MODE_ORDERED[idx + 1 > #UI_MODE_ORDERED and 1 or idx + 1]
					break
				end
			end
		end
		broadcast(PUBSUB_KIND.ui_mode_changed, ui_mode)
	elseif
		action == TAG_ACTION.toggle_select
		or action == TAG_ACTION.replace_select
		or action == TAG_ACTION.unite_select
		or action == TAG_ACTION.subtract_select
		or action == TAG_ACTION.intersect_select
		or action == TAG_ACTION.exclude_select
		or action == TAG_ACTION.undo_select
	then
		local select_mode = job.args.mode or SELECTION_MODE["and"]
		local inputted_tags = job.args.tags or job.args.tags or job.args.keys or job.args.key
		local input_mode = job.args.input
		local selected_tag_keys = {}
		-- NOTE: BACKWARD COMPATIBILITY warning
		if select_mode ~= SELECTION_MODE["and"] and select_mode ~= SELECTION_MODE["or"] then
			warn(
				"Unsupported selection mode: %s, may be you are using an old configuration of simple-tag plugin, please check the documentation.",
				select_mode
			)
		end
		-- NOTE: BACKWARD COMPATIBILITY warning

		local new_selected_files = {}
		if action == TAG_ACTION.toggle_select then
			action = show_cands_ui_modes()
			if not action then
				return
			end
		end

		-- Mode undo
		if action == TAG_ACTION.undo_select then
			new_selected_files = get_state(STATE_KEY.preserve_selected_files) or {}
			if new_selected_files == nil then
				return
			end
			local preserve_selected_files = selected_files()
			set_state(STATE_KEY.preserve_selected_files, preserve_selected_files)
		else
			if not inputted_tags then
				local title = "Select tags"
					.. (select_mode == SELECTION_MODE["and"] and "" or ", MODE=(" .. select_mode .. ")")
					.. ", ACTION=("
					.. action:gsub("%-select", "")
					.. ")"
					.. ":"

				if not inputted_tags then
					inputted_tags = show_cands_input_tags(title, input_mode)
				end

				if not inputted_tags then
					return
				end
			end
			for _, code in utf8.codes(inputted_tags) do
				local key = utf8.char(code)
				table.insert(selected_tag_keys, key)
			end

			local tags_tbl = tostring(get_cwd())
			local tags_db = get_state(STATE_KEY.tags_database)
			local tagged_filenames = tags_db[tags_tbl] or {}
			for fname, tags in pairs(tagged_filenames) do
				if
					(select_mode == SELECTION_MODE["and"] and tbl_is_subset(selected_tag_keys, tags))
					or (select_mode == SELECTION_MODE["or"] and tbl_contains_any(tags, selected_tag_keys))
				then
					table.insert(new_selected_files, pathJoin(tags_tbl, fname))
				end
			end
			local preserve_selected_files = selected_files()
			set_state(STATE_KEY.preserve_selected_files, preserve_selected_files)
			local old_selected_files = tbl_deep_clone(preserve_selected_files)
			if action == TAG_ACTION.replace_select then
				-- no needs to do anything else
			elseif action == TAG_ACTION.unite_select then
				new_selected_files = tbl_unite(old_selected_files, new_selected_files)
			elseif action == TAG_ACTION.intersect_select then
				new_selected_files = tbl_intersect(old_selected_files, new_selected_files)
			elseif action == TAG_ACTION.subtract_select then
				new_selected_files = tbl_subtract(old_selected_files, new_selected_files)
			elseif action == TAG_ACTION.exclude_select then
				new_selected_files = tbl_exclude(old_selected_files, new_selected_files)
			else
				return
			end
		end

		-- clear selection
		ya.emit("escape", { select = true })
		if #new_selected_files == 0 then
			return
		end
		local valid_selected_files = {}
		for _, url_raw in ipairs(new_selected_files) do
			local url = Url(url_raw)
			local cha = fs.cha(url, {})
			if cha then
				valid_selected_files[#valid_selected_files + 1] = url_raw
			end
		end
		valid_selected_files.state = "on"
		ya.emit("toggle_all", valid_selected_files)
	elseif action == TAG_ACTION.filter then
		local filter_tags = {}
		local inputted_tags = job.args.tags or job.args.tags or job.args.keys or job.args.key
		local filter_mode = job.args.mode or FILTER_MODE["and"]
		local input_mode = job.args.input
		local title = "Search tags" .. (filter_mode == FILTER_MODE["or"] and " (or)" or "") .. ":"
		if not inputted_tags then
			inputted_tags = show_cands_input_tags(title, input_mode)
		end

		if not inputted_tags then
			return
		end

		for _, code in utf8.codes(inputted_tags) do
			local key = utf8.char(code)
			table.insert(filter_tags, key)
		end

		local tags_tbl = tostring(get_cwd())
		local tags_db = get_state(STATE_KEY.tags_database)
		local tagged_filenames = tags_db[tags_tbl] or {}
		local cwd = get_cwd()

		local id = ya.id("ft")
		local filter_title = "MODE=(" .. filter_mode .. ")" .. " Tags=(" .. table.concat(filter_tags, "") .. ")"
		local _cwd = cwd:into_search(filter_title)
		ya.emit("cd", { Url(_cwd) })
		ya.emit("update_files", { op = fs.op("part", { id = id, url = Url(_cwd), files = {} }) })

		local files = {}
		for fname, tags in pairs(tagged_filenames) do
			if
				(filter_mode == FILTER_MODE["and"] and tbl_is_subset(filter_tags, tags))
				or (filter_mode == FILTER_MODE["or"] and tbl_contains_any(tags, filter_tags))
			then
				local url = _cwd:join(fname)
				local cha = fs.cha(url, true)
				if cha then
					files[#files + 1] = File({ url = url, cha = cha })
				end
			end
		end

		ya.emit("update_files", { op = fs.op("part", { id = id, url = Url(_cwd), files = files }) })
		ya.emit("update_files", { op = fs.op("done", { id = id, url = _cwd, cha = Cha({ kind = 16 }) }) })
	elseif action == TAG_ACTION.files_deleted then
		delete_tags()
	elseif action == TAG_ACTION.files_transferred then
		local changes = dequeue_task(STATE_KEY.tasks_rename_tags)
		if changes then
			local changed_tags_db = {}
			local tags_db = get_state(STATE_KEY.tags_database)
			for from, to in pairs(changes) do
				local from_url = Url(from)
				local to_url = Url(to)
				local old_tags_tbl = tostring(from_url.parent)
				local new_tags_tbl = tostring(to_url.parent)
				local old_fname = tostring(from_url.name)
				local new_fname = tostring(to_url.name)

				if old_tags_tbl and old_fname and new_fname then
					if tags_db and old_tags_tbl and tags_db[old_tags_tbl] and new_tags_tbl then
						if not tags_db[new_tags_tbl] then
							tags_db[new_tags_tbl] = {}
						end
						tags_db[new_tags_tbl][new_fname] = tags_db[old_tags_tbl][old_fname]
						tags_db[old_tags_tbl][old_fname] = nil
						changed_tags_db[old_tags_tbl] = tags_db[old_tags_tbl]
						changed_tags_db[new_tags_tbl] = tags_db[new_tags_tbl]
					end
				end
			end
			enqueue_task(STATE_KEY.tasks_write_tags_db, changed_tags_db)
			write_tags_db()
		end
	end
end

return M
