local M = {}

local function escape_json_for_script(json)
  return json:gsub("<", "\\u003c")
end

function M.build_script_block(css_vars)
  local safe_pairs = {}
  for _, pair in ipairs(css_vars or {}) do
    local name = tostring((pair or {}).name or "")
    if name:match("^[A-Za-z0-9_-]+$") then
      safe_pairs[#safe_pairs + 1] = {
        name = name,
        value = tostring((pair or {}).value or ""),
      }
    end
  end

  local json = escape_json_for_script(pandoc.json.encode(safe_pairs))

  local lines = {
    string.format('<script id="deck-css-vars" type="application/json">%s</script>', json),
    '<script>',
    '(function () {',
    '  const source = document.getElementById("deck-css-vars");',
    '  if (!source) return;',
    '  let entries = [];',
    '  try {',
    '    entries = JSON.parse(source.textContent || "[]");',
    '  } catch (error) {',
    '    console.error("Failed to parse CSS variable config", error);',
    '    return;',
    '  }',
    '',
    '  const rootStyle = document.documentElement && document.documentElement.style;',
    '  if (!rootStyle) return;',
    '',
    '  entries.forEach((entry) => {',
    '    if (!entry || typeof entry.name !== "string") return;',
    '    if (!/^[A-Za-z0-9_-]+$/.test(entry.name)) return;',
    '    try {',
    '      rootStyle.setProperty(`--${entry.name}`, String(entry.value ?? ""));',
    '    } catch (error) {',
    '      console.error("Failed to apply CSS variable", entry.name, error);',
    '    }',
    '  });',
    '})();',
    '</script>',
  }

  return table.concat(lines, "\n")
end

return M
