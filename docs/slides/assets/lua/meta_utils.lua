local M = {}

local function is_blank(value)
  return value == nil or value == ""
end

function M.trim(value)
  if value == nil then
    return ""
  end
  return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end

function M.inlines_to_text(inlines)
  local out = {}

  local function walk(items)
    for _, inline in ipairs(items) do
      local t = inline.t
      if t == "Str" then
        table.insert(out, inline.text)
      elseif t == "Space" then
        table.insert(out, " ")
      elseif t == "SoftBreak" or t == "LineBreak" then
        table.insert(out, "\n")
      elseif t == "Code" then
        table.insert(out, inline.text)
      elseif t == "RawInline" or t == "Math" then
        if inline.text ~= nil then
          table.insert(out, inline.text)
        elseif type(inline.c) == "table" then
          table.insert(out, tostring(inline.c[2] or ""))
        end
      elseif t == "Emph" or t == "Strong" or t == "Underline" or t == "Strikeout" or t == "SmallCaps" or t == "Span" then
        walk(inline.content)
      elseif t == "Link" or t == "Image" or t == "Quoted" then
        walk(inline.content)
      elseif t == "Note" then
      elseif inline.content then
        walk(inline.content)
      else
        table.insert(out, pandoc.utils.stringify({ inline }))
      end
    end
  end

  walk(inlines)
  return table.concat(out)
end

function M.meta_value_to_text(value)
  if value == nil then
    return ""
  end

  local value_type = pandoc.utils.type(value)

  if value_type == "Inlines" then
    return M.inlines_to_text(value)
  elseif value_type == "Blocks" then
    local parts = {}
    for _, block in ipairs(value) do
      if block.t == "Para" or block.t == "Plain" or block.t == "Header" then
        table.insert(parts, M.inlines_to_text(block.content))
      elseif block.t == "CodeBlock" then
        table.insert(parts, block.text)
      elseif block.t == "BulletList" or block.t == "OrderedList" then
        local items = {}
        for _, item in ipairs(block.content) do
          local item_parts = {}
          for _, subblock in ipairs(item) do
            if subblock.t == "Para" or subblock.t == "Plain" then
              table.insert(item_parts, M.inlines_to_text(subblock.content))
            end
          end
          table.insert(items, table.concat(item_parts, "\n"))
        end
        table.insert(parts, table.concat(items, "\n"))
      else
        table.insert(parts, pandoc.utils.stringify(block))
      end
    end
    return table.concat(parts, "\n\n")
  elseif value_type == "List" then
    local parts = {}
    for _, item in ipairs(value) do
      if type(item) == "table" and item.name ~= nil then
        table.insert(parts, M.meta_value_to_text(item.name))
      elseif type(item) == "table" and item.text ~= nil then
        table.insert(parts, M.meta_value_to_text(item.text))
      else
        table.insert(parts, M.meta_value_to_text(item))
      end
    end
    return table.concat(parts, ", ")
  elseif value_type == "Map" then
    if value.name ~= nil then
      return M.meta_value_to_text(value.name)
    elseif value.text ~= nil then
      return M.meta_value_to_text(value.text)
    end
    return pandoc.utils.stringify(value)
  elseif type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
    return tostring(value)
  else
    return pandoc.utils.stringify(value)
  end
end

function M.read_path(root, path)
  local current = root
  for _, key in ipairs(path) do
    if current == nil then
      return nil
    end
    current = current[key]
  end
  return current
end

function M.set_path(root, path, value)
  local current = root
  for i = 1, #path - 1 do
    local key = path[i]
    if current[key] == nil then
      current[key] = {}
    end
    current = current[key]
  end
  current[path[#path]] = value
end

function M.css_length(raw_value, default_value)
  local raw = M.meta_value_to_text(raw_value ~= nil and raw_value or default_value)
  if is_blank(raw) then
    return "0px"
  end

  local trimmed = M.trim(raw)
  if trimmed:match("^[+-]?%d+%.?%d*$") then
    return trimmed .. "px"
  end
  return trimmed
end

function M.css_value(raw_value, default_value)
  local raw = M.meta_value_to_text(raw_value ~= nil and raw_value or default_value)
  if is_blank(raw) then
    return tostring(default_value or "")
  end
  return M.trim(raw)
end

return M
