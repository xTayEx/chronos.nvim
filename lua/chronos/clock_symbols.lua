local M = {}

M.digits = {
  [[
 ██████╗
██╔═████╗
██║██╔██║
████╔╝██║
╚██████╔╝
 ╚═════╝
  ]],
  [[
 ██╗
███║
╚██║
 ██║
 ██║
 ╚═╝
  ]],
  [[
██████╗
╚════██╗
 █████╔╝
██╔═══╝
███████╗
╚══════╝
  ]],
  [[
██████╗
╚════██╗
 █████╔╝
 ╚═══██╗
██████╔╝
╚═════╝
  ]],
  [[
██╗  ██╗
██║  ██║
███████║
╚════██║
     ██║
     ╚═╝
  ]],
  [[
███████╗
██╔════╝
███████╗
╚════██║
███████║
╚══════╝
  ]],
  [[
 ██████╗
██╔════╝
███████╗
██╔═══██╗
╚██████╔╝
 ╚═════╝
  ]],
  [[
███████╗
╚════██║
    ██╔╝
   ██╔╝
   ██║
   ╚═╝
  ]],
  [[
 █████╗
██╔══██╗
╚█████╔╝
██╔══██╗
╚█████╔╝
 ╚════╝
  ]],
  [[
 █████╗
██╔══██╗
╚██████║
 ╚═══██║
 █████╔╝
 ╚════╝
  ]],
}

M.colon = [[
██╗
╚═╝
██╗
╚═╝
]]

---@class SymbolDimension
---@field width integer
---@field height integer
---@field byte_width integer

---@class Symbol
local Symbol = {}

---@param ori_symbol string
function Symbol:new(ori_symbol, o)
  o = o or {}
  if ori_symbol ~= ":" then
    o.symbol = M.digits[tonumber(ori_symbol) + 1]
  else
    o.symbol = M.colon
  end
  self.__index = self
  return setmetatable(o, self)
end

---@return SymbolDimension
function Symbol:get_dimensions()
  local char_width, byte_width = 0, 0
  local lines = vim.split(self.symbol, "\n", { trimempty = true })
  for _, line in ipairs(lines) do
    local current = vim.api.nvim_strwidth(line)
    local bytes = #line
    if current > char_width or bytes > byte_width then
      char_width = current
      byte_width = bytes
    end
  end

  return { width = char_width, byte_width = byte_width, height = #lines }
end

---@param width integer
---@param height integer
function Symbol:pad_to_cell(width, height)
  local dimension = self:get_dimensions()
  width = vim.fn.max({ width, dimension.width })
  height = vim.fn.max({ height, dimension.height })

  local lines = vim.split(self.symbol, "\n", { trimempty = true })
  -- pad width
  for i = 1, #lines do
    local visual_width = vim.api.nvim_strwidth(lines[i])
    lines[i] = lines[i] .. string.rep(" ", width - visual_width)
  end

  -- pad height
  local dir = 1
  for _ = 1, height - #lines do
    if dir == 1 then
      table.insert(lines, 1, string.rep(" ", width))
    else
      lines[#lines + 1] = string.rep(" ", width)
    end
    dir = (dir + 1) % 2
  end

  self.symbol = vim.fn.join(lines, "\n")
end

function Symbol:print()
  vim.print(self.symbol)
end

---@param symbols Symbol[]
local concat_symbols = function(symbols)
  local height = symbols[1]:get_dimensions().height
  local lines = {}
  for i = 1, height do
    local line = ""
    for _, symbol in ipairs(symbols) do
      line = line .. vim.split(symbol.symbol, "\n")[i]
    end
    string.gsub(line, "\n", " ")
    line = line .. "\n"
    lines[#lines + 1] = line
  end

  return lines
end

M.Symbol = Symbol
M.concat_symbols = concat_symbols

local sym1 = Symbol:new("1")
local sym2 = Symbol:new("2")
local syms = { sym1, sym2 }
local max_height = 1
for _, symbol in ipairs(syms) do
  local dimension = symbol:get_dimensions()
  max_height = vim.fn.max({ max_height, dimension.height })
end

for _, symbol in ipairs(syms) do
  local dimension = symbol:get_dimensions()
  local width = dimension.width

  symbol:pad_to_cell(width + 1, max_height)
end

local lines = concat_symbols(syms)
vim.print(table.concat(lines, ""))

-- return M
