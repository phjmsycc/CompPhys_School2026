local M = {}

local function copy_table(source)
  local out = {}
  for key, value in pairs(source or {}) do
    out[key] = value
  end
  return out
end

local function collect_tokens(meta, path, defaults, utils)
  local tokens = copy_table(defaults)
  local provided = utils.read_path(meta, path)
  if type(provided) ~= "table" then
    return tokens
  end

  for key, value in pairs(provided) do
    local token_key = tostring(key)
    local token_value = utils.trim(utils.meta_value_to_text(value))
    if token_value ~= "" then
      tokens[token_key] = token_value
    end
  end

  return tokens
end

local function normalize_version(meta, schema, utils)
  local raw = utils.trim(utils.meta_value_to_text(utils.read_path(meta, {"schema_version"})))
  if raw == "" then
    error("assets/_variables.yml: schema_version: 2 を指定してください。")
  end

  if tonumber(raw) ~= schema.required_schema_version then
    error(string.format("assets/_variables.yml: schema_version=%s は未対応です。schema_version: %d を指定してください。", raw, schema.required_schema_version))
  end
end

local function resolve_token(token_map, raw_value, default_token, utils)
  local requested = utils.trim(utils.meta_value_to_text(raw_value))
  if requested ~= "" and token_map[requested] ~= nil then
    return token_map[requested]
  end

  if token_map[default_token] ~= nil then
    return token_map[default_token]
  end

  return ""
end

local function normalize_value(spec, raw_value, token_sets, utils)
  if spec.kind == "string" then
    local value = utils.meta_value_to_text(raw_value)
    if value == "" then
      return tostring(spec.default or "")
    end
    return value
  end

  if spec.kind == "value" then
    return utils.css_value(raw_value, spec.default)
  end

  if spec.kind == "css_length" then
    return utils.css_length(raw_value, spec.default)
  end

  if spec.kind == "color_token" then
    return resolve_token(token_sets.color, raw_value, spec.default, utils)
  end

  if spec.kind == "spacing_token" then
    return resolve_token(token_sets.spacing, raw_value, spec.default, utils)
  end

  if spec.kind == "typography_token" then
    return resolve_token(token_sets.typography, raw_value, spec.default, utils)
  end

  return utils.css_value(raw_value, spec.default)
end

local function init_json(doc_meta)
  return {
    overlay = { position = { default = {}, title = {} }, style = {} },
    pageNumber = { position = {}, style = {} },
    titleSlide = { title = {}, subtitle = {}, author = {}, affiliation = {} },
    docMeta = {
      authorText = tostring(doc_meta.author_text or ""),
      affiliationText = tostring(doc_meta.affiliation_text or ""),
    },
    eyecatch = { background = {}, title = {} },
  }
end

function M.normalize(meta, schema, utils, doc_meta)
  normalize_version(meta, schema, utils)

  if utils.read_path(meta, {"tokens"}) == nil or utils.read_path(meta, {"components"}) == nil then
    error("assets/_variables.yml: tokens と components の両方を定義してください。")
  end

  local resolve_project_path = doc_meta and doc_meta.resolve_project_path or nil

  local token_sets = {
    color = collect_tokens(meta, {"tokens", "color"}, schema.token_defaults.color, utils),
    spacing = collect_tokens(meta, {"tokens", "spacing"}, schema.token_defaults.spacing, utils),
    typography = collect_tokens(meta, {"tokens", "typography"}, schema.token_defaults.typography, utils),
  }

  local normalized = {
    flat = {},
    css_vars = {},
    json = init_json(doc_meta or {}),
    runtime = {},
  }

  for _, spec in ipairs(schema.fields) do
    local raw_value = utils.read_path(meta, spec.path)
    local value = normalize_value(spec, raw_value, token_sets, utils)

    if spec.resolve_path == "project" and type(resolve_project_path) == "function" then
      value = resolve_project_path(value)
    end

    normalized.flat[spec.key] = value

    if spec.css_var ~= nil then
      local css_value = value
      if spec.css_transform == "url" then
        css_value = string.format('url("%s")', value)
      elseif spec.css_transform == "length" then
        css_value = utils.css_length(value, value)
      end
      table.insert(normalized.css_vars, {
        name = spec.css_var,
        value = css_value,
      })
    end

    if spec.json_path ~= nil then
      utils.set_path(normalized.json, spec.json_path, value)
    end

    if spec.runtime_path ~= nil then
      utils.set_path(normalized.runtime, spec.runtime_path, value)
    end
  end

  return normalized
end

return M
