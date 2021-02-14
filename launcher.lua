-- A launcher (kludge) for scripts with descriptions.
--
-- Launcher
-- v0.1.0
--
-- E1   scroll
-- K3  select
--

local tabutil = require 'tabutil'
local json = include('lib/json')

local data = {}
local keys = {}
local faves = tabutil.load(_path.favorites)

local selection = nil

local type_size = 8
local line_height = math.ceil(type_size * 1.25)

--- Print truncated text to screen, if longer than length add '...'
local function text_trunc(str, len)
  len = math.floor(len) or 10
  local trunc = ''

  if str ~= nil then
    trunc = string.sub(str, 1, len)
    if #str > #trunc then
      trunc = trunc .. '...'
    end
  end
  
  trunc = trunc:gsub('^%s*(.-)%s*$', '%1')
  screen.text(trunc)
  
  return trunc
end

--- Load JSON script metadata.
local function load_data(filename)
  local path = norns.state.path .. filename

  if util.file_exists(path) then
    local file = io.open(path, 'rb')
    local content = file:read('*all')
    file:close()

    return json.decode(content)
  end

  return {}
end

-- TODO(frederickk): I believe there's a native Norns way to read the first line.
local function get_first_line(path)
  local first_line = ''

  if util.file_exists(path) then
    local file = io.open(path, 'rb')
    local lines = {}
    for line in file:lines() do 
      lines[#lines + 1] = line
    end
    first_line = (lines[1] .. lines[2]):gsub('[%-%-]', '')
    file:close()
  end

  return text_trunc(first_line, type_size * 1.5)
end

--- Init
function init()
  params:add_number('pos', 'Position', 0)
  params:hide('pos')

  screen.aa(0)
  screen.level(15)
  screen.line_width(1)
  screen.font_size(type_size)
  redraw()
  screen.ping()

  -- Load JSON
  data = load_data('data.json')
  if (not data.favorites) then
    data.favorites = {}
  end

  -- Ensure alphabetical order
  for k in pairs(data) do table.insert(keys, k) end
  table.sort(keys)
  table.insert(keys, 1, 'favorites')

  -- Insert Favorites
  if (faves) then
    for k in pairs(faves) do
      tab.print(faves[k])
      table.insert(data.favorites, {
        faves[k].name,
        get_first_line(faves[k].file) -- hacky way to pull metadata from top of script file.
      })
    end
  end

  params:read()
end

function enc(index, delta)
  if index == 1 then
    params:delta('pos', delta)
  end

  redraw()
end

function key(index, state)
  if selection ~= nil and index == 3 and state == 1 then
    norns.script.load('code/' .. selection .. '/' .. selection .. '.lua')
  end
end

function redraw()
  screen.clear()

  local index = 2
  local y
  local pos = -params:get('pos')

  for i, k in ipairs(keys) do
    y = ((pos * line_height) + (line_height * index))

    screen.level(2)
    if (y == 10) then
      screen.move(1, 10)
    else
      screen.move(1, y)
    end
    screen.text(k:gsub('^%l', string.upper))

    for j = 1, #data[k] do
      local details = data[k][j]

      y = line_height + ((pos * line_height) + (line_height * index))

      if y == (line_height * 3) then
        screen.level(15)
        selection = details[1]
      else
        screen.level(2)
      end

      screen.move(8, y)
      text_trunc(details[1], type_size * 1.25)

      screen.move(64, y)
      text_trunc(details[2], type_size * 1.5)

      index = index + 1
    end

    index = index + 1
  end

  screen.update()
end

function cleanup()
  params:write()
end
