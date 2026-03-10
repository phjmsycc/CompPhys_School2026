local M = {}

local function trim(value)
  if value == nil then
    return ""
  end
  return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_slashes(path)
  return tostring(path or ""):gsub("\\", "/")
end

local function is_absolute(path)
  local normalized = normalize_slashes(path)
  return normalized:match("^/") ~= nil or normalized:match("^[A-Za-z]:/") ~= nil
end

local function normalize_path(path)
  return normalize_slashes(pandoc.path.normalize(path))
end

local function to_absolute(path, base_dir)
  local raw = trim(path)
  if raw == "" then
    return ""
  end
  if is_absolute(raw) then
    return normalize_path(raw)
  end
  return normalize_path(pandoc.path.join({ base_dir, raw }))
end

local function split_absolute(path)
  local normalized = normalize_slashes(path)
  local drive = normalized:match("^([A-Za-z]:)")
  if drive then
    normalized = normalized:sub(#drive + 1)
  end

  if normalized:sub(1, 1) == "/" then
    normalized = normalized:sub(2)
  end

  local parts = {}
  for part in normalized:gmatch("[^/]+") do
    table.insert(parts, part)
  end

  return {
    drive = drive and drive:lower() or "",
    parts = parts,
  }
end

local function split_relative_parts(path)
  local normalized = normalize_slashes(trim(path))
  if normalized == "" or normalized == "." then
    return {}
  end

  local parts = {}
  for part in normalized:gmatch("[^/]+") do
    if part ~= "" and part ~= "." then
      table.insert(parts, part)
    end
  end
  return parts
end

local function ends_with_parts(values, suffix)
  if #suffix > #values then
    return false
  end

  local offset = #values - #suffix
  for index = 1, #suffix do
    if values[offset + index] ~= suffix[index] then
      return false
    end
  end
  return true
end

local function relative_path(base_dir, target_path)
  local base = split_absolute(normalize_path(base_dir))
  local target = split_absolute(normalize_path(target_path))

  if base.drive ~= target.drive then
    return normalize_slashes(target_path)
  end

  local index = 1
  while index <= #base.parts and index <= #target.parts and base.parts[index] == target.parts[index] do
    index = index + 1
  end

  local out = {}
  for i = index, #base.parts do
    table.insert(out, "..")
  end
  for i = index, #target.parts do
    table.insert(out, target.parts[i])
  end

  if #out == 0 then
    return "."
  end

  return table.concat(out, "/")
end

local function is_external_path(path)
  local value = trim(path)
  if value == "" then
    return false
  end

  if value:match("^#") then
    return true
  end

  if value:match("^//") then
    return true
  end

  if value:match("^[A-Za-z][A-Za-z0-9+.-]*:") then
    if value:match("^[A-Za-z]:[/\\]") then
      return false
    end
    return true
  end

  return false
end

local function state_value(path)
  local current = rawget(_G, "PANDOC_STATE")
  for _, key in ipairs(path) do
    if current == nil then
      return nil
    end
    current = current[key]
  end
  return current
end

local function detect_output_dir(cwd)
  local output_file = trim(state_value({ "output_file" }))
  if output_file == "-" then
    output_file = ""
  end

  local reference = output_file
  if reference == "" then
    local inputs = state_value({ "input_files" })
    if type(inputs) == "table" and #inputs > 0 then
      reference = trim(inputs[1])
    end
  end

  if reference == "" then
    return cwd
  end

  local absolute_reference = to_absolute(reference, cwd)
  local directory = normalize_path(pandoc.path.directory(absolute_reference))
  if directory == "" then
    return cwd
  end

  return directory
end

local function detect_input_dir(cwd)
  local inputs = state_value({ "input_files" })
  if type(inputs) ~= "table" or #inputs == 0 then
    return ""
  end

  local reference = trim(inputs[1])
  if reference == "" then
    return ""
  end

  local absolute_reference = to_absolute(reference, cwd)
  local directory = normalize_path(pandoc.path.directory(absolute_reference))
  if directory == "" then
    return cwd
  end

  return directory
end

local function detect_output_root(project_root, output_dir, input_dir)
  if output_dir == "" then
    return project_root
  end
  if input_dir == "" then
    return project_root
  end

  local relative_input_dir = relative_path(project_root, input_dir)
  if relative_input_dir == "." then
    return output_dir
  end
  if relative_input_dir == ".." or relative_input_dir:match("^%.%./") then
    return project_root
  end

  local relative_parts = split_relative_parts(relative_input_dir)
  if #relative_parts == 0 then
    return output_dir
  end

  local output_parts = split_absolute(output_dir).parts
  if not ends_with_parts(output_parts, relative_parts) then
    return project_root
  end

  local output_root = output_dir
  for _ = 1, #relative_parts do
    output_root = normalize_path(pandoc.path.directory(output_root))
  end

  return output_root
end

function M.create_context(script_dir)
  local get_cwd = pandoc.system and pandoc.system.get_working_directory or function()
    return "."
  end

  local cwd = normalize_path(get_cwd())
  local absolute_script_dir = to_absolute(script_dir, cwd)
  local project_root = normalize_path(pandoc.path.directory(absolute_script_dir))
  local output_dir = detect_output_dir(cwd)
  local input_dir = detect_input_dir(cwd)
  local output_root = detect_output_root(project_root, output_dir, input_dir)

  return {
    project_root = project_root,
    output_dir = output_dir,
    output_root = output_root,
  }
end

function M.resolve_project_path(raw_path, context)
  local raw = trim(raw_path)
  if raw == "" then
    return raw
  end

  if is_external_path(raw) then
    return raw
  end

  if is_absolute(raw) then
    return normalize_slashes(raw)
  end

  local project_root = context and context.project_root or ""
  local output_root = context and context.output_root or ""
  local output_dir = context and context.output_dir or ""
  if project_root == "" or output_dir == "" then
    return raw
  end

  local target_base = output_root ~= "" and output_root or project_root
  local target_path = to_absolute(raw, target_base)
  return relative_path(output_dir, target_path)
end

return M
