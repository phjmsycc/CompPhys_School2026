local M = {}

function M.build_script_block(json_config)
  local json = pandoc.json.encode(json_config)
  json = json:gsub("<", "\\u003c")
  return string.format('<script id="overlay-config" type="application/json">%s</script>', json)
end

return M
