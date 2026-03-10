local M = {}

local function has_class(attr, class_name)
  if not attr or not attr.classes then
    return false
  end
  for _, class in ipairs(attr.classes) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function add_class(header, class_name)
  if has_class(header.attr, class_name) then
    return header
  end
  local classes = pandoc.List(header.classes)
  classes:insert(class_name)
  return pandoc.Header(header.level, header.content, pandoc.Attr(header.identifier, classes, header.attributes))
end

local function ensure_header_background(header, background)
  local new_header = header
  if new_header.attributes["background-image"] == nil or new_header.attributes["background-image"] == "" then
    new_header.attributes["background-image"] = background.image
  end
  if new_header.attributes["background-size"] == nil or new_header.attributes["background-size"] == "" then
    new_header.attributes["background-size"] = background.size
  end
  if new_header.attributes["background-opacity"] == nil or new_header.attributes["background-opacity"] == "" then
    new_header.attributes["background-opacity"] = background.opacity
  end
  return new_header
end

function M.mark_eyecatch_headers(blocks, eyecatch)
  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 1 then
      block.level = 2
      block.attr = block.attr or pandoc.Attr()

      local classes = block.attr.classes or {}
      local found = false
      for _, class in ipairs(classes) do
        if class == "deck-eyecatch-slide" then
          found = true
          break
        end
      end
      if not found then
        table.insert(classes, "deck-eyecatch-slide")
      end
      block.attr.classes = classes

      if block.attr.attributes["background-image"] == nil or block.attr.attributes["background-image"] == "" then
        block.attr.attributes["background-image"] = eyecatch.image
      end
      if block.attr.attributes["background-size"] == nil or block.attr.attributes["background-size"] == "" then
        block.attr.attributes["background-size"] = eyecatch.size
      end
      if block.attr.attributes["background-position"] == nil or block.attr.attributes["background-position"] == "" then
        block.attr.attributes["background-position"] = eyecatch.position
      end
    end
  end

  return blocks
end

function M.wrap_body_slides(blocks, body_background)
  local out = pandoc.List()
  local i = 1

  while i <= #blocks do
    local block = blocks[i]

    if block.t == "Header" and block.level == 2 then
      if has_class(block.attr, "deck-eyecatch-slide") then
        out:insert(block)
        i = i + 1

        while i <= #blocks do
          local inner = blocks[i]
          if inner.t == "Header" and inner.level == 2 then
            break
          end
          out:insert(inner)
          i = i + 1
        end
      else
        local header = add_class(block, "deck-body-slide")
        out:insert(ensure_header_background(header, body_background))

        local body_blocks = pandoc.List()
        i = i + 1

        while i <= #blocks do
          local inner = blocks[i]
          if inner.t == "Header" and inner.level == 2 then
            break
          end
          body_blocks:insert(inner)
          i = i + 1
        end

        if #body_blocks == 1 and body_blocks[1].t == "Div" and has_class(body_blocks[1].attr, "slide-body") then
          out:insert(body_blocks[1])
        elseif #body_blocks > 0 then
          out:insert(pandoc.Div(body_blocks, pandoc.Attr("", { "slide-body" }, {})))
        end
      end
    else
      out:insert(block)
      i = i + 1
    end
  end

  return out
end

return M
