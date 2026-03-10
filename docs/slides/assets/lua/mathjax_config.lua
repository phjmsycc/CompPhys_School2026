local M = {}

local DEFAULT_PACKAGES = {
  "mhchem",
  "physics",
  "boldsymbol",
}

local DEFAULT_MACROS = {
  bm = { "\\boldsymbol{#1}", 1 },
  num = { "{#1}", 1 },
  si = { "\\mathrm{#1}", 1 },
  SI = { "{#1}\\,\\mathrm{#2}", 2 },
  unit = { "\\mathrm{#1}", 1 },
  qty = { "{#1}\\,\\mathrm{#2}", 2 },
}

local DEFAULT_SKIP_HTML_TAGS = {
  "script",
  "noscript",
  "style",
  "textarea",
  "pre",
  "code",
}

local function copy_array(values)
  local out = {}
  for _, value in ipairs(values or {}) do
    out[#out + 1] = value
  end
  return out
end

local function copy_macro_value(value)
  if type(value) ~= "table" then
    return value
  end

  local out = {}
  for key, item in pairs(value) do
    out[key] = item
  end
  return out
end

local function copy_macro_map(source)
  local out = {}
  for name, value in pairs(source or {}) do
    out[name] = copy_macro_value(value)
  end
  return out
end

local function normalize_string(value, utils)
  local text = utils.trim(utils.meta_value_to_text(value))
  if text == "" then
    return nil
  end
  return text
end

local function append_unique(out, seen, value)
  if value == nil or seen[value] then
    return
  end
  seen[value] = true
  out[#out + 1] = value
end

local function normalize_packages(raw_packages, utils)
  local packages = {}
  local seen = {}

  for _, package_name in ipairs(DEFAULT_PACKAGES) do
    append_unique(packages, seen, package_name)
  end

  local value_type = pandoc.utils.type(raw_packages)
  if value_type == "MetaList" or value_type == "List" or type(raw_packages) == "table" then
    for _, item in ipairs(raw_packages) do
      append_unique(packages, seen, normalize_string(item, utils))
    end
  else
    append_unique(packages, seen, normalize_string(raw_packages, utils))
  end

  return packages
end

local function normalize_macro_entry(raw_value, utils)
  local value_type = pandoc.utils.type(raw_value)

  if value_type == "MetaMap" or value_type == "Map" or (type(raw_value) == "table" and raw_value.definition ~= nil) then
    local definition = normalize_string(raw_value.definition, utils)
    if definition == nil then
      return nil
    end

    local args_text = normalize_string(raw_value.args, utils)
    local args = tonumber(args_text or "")
    if args == nil or args <= 0 then
      return definition
    end

    return { definition, math.floor(args) }
  end

  return normalize_string(raw_value, utils)
end

local function normalize_macros(raw_macros, utils)
  local macros = copy_macro_map(DEFAULT_MACROS)

  local value_type = pandoc.utils.type(raw_macros)
  if value_type ~= "MetaMap" and value_type ~= "Map" and type(raw_macros) ~= "table" then
    return macros
  end

  for raw_name, raw_value in pairs(raw_macros) do
    local name = tostring(raw_name or "")
    if name ~= "" then
      local entry = normalize_macro_entry(raw_value, utils)
      if entry ~= nil then
        macros[name] = entry
      end
    end
  end

  return macros
end

local function escape_json_for_script(json)
  return json:gsub("<", "\\u003c")
end

function M.build(meta, utils, mathjax_url)
  local mathjax_meta = utils.read_path(meta, { "mathjax" }) or {}
  local packages = normalize_packages(mathjax_meta.packages, utils)
  local macros = normalize_macros(mathjax_meta.macros, utils)
  local loader = {}

  for _, package_name in ipairs(packages) do
    loader[#loader + 1] = "[tex]/" .. package_name
  end

  local config = {
    mathjax = tostring(mathjax_url or ""),
    loader = {
      load = loader,
    },
    tex = {
      inlineMath = {
        { "\\(", "\\)" },
      },
      displayMath = {
        { "\\[", "\\]" },
      },
      packages = {
        ["[+]"] = copy_array(packages),
      },
      macros = macros,
    },
    options = {
      skipHtmlTags = copy_array(DEFAULT_SKIP_HTML_TAGS),
    },
  }

  return config
end

function M.build_script_block(meta, utils, mathjax_url)
  local config = M.build(meta, utils, mathjax_url)
  local json = escape_json_for_script(pandoc.json.encode(config))
  return string.format('<script id="deck-mathjax-config" type="application/json">%s</script>', json)
end

return M
