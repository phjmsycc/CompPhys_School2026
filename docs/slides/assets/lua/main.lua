return function(base_dir)
  local function load(relative_path)
    return dofile(pandoc.path.join({ base_dir, relative_path }))
  end

  local utils = load("lua/meta_utils.lua")
  local schema = load("lua/schema_v2.lua")
  local normalize_config = load("lua/normalize_config.lua")
  local emit_css_vars = load("lua/emit_css_vars.lua")
  local emit_overlay_json = load("lua/emit_overlay_json.lua")
  local mathjax_config = load("lua/mathjax_config.lua")
  local slide_transform = load("lua/slide_transform.lua")
  local path_utils = load("lua/path_utils.lua")

  local function escape_attr(value)
    return tostring(value or "")
      :gsub("&", "&amp;")
      :gsub('"', "&quot;")
      :gsub("<", "&lt;")
      :gsub(">", "&gt;")
  end

  local function build_deck_assets_html(resolve_project_path)
    local lines = {}
    local css_paths = {
      "assets/overlay.css",
      "assets/pointer.css",
    }

    for _, css_path in ipairs(css_paths) do
      local css_href = resolve_project_path(css_path)
      lines[#lines + 1] = string.format('<link rel="stylesheet" href="%s">', escape_attr(css_href))
    end

    local script_paths = {
      "assets/js/overlay/namespace.js",
      "assets/js/overlay/config.js",
      "assets/js/overlay/model.js",
      "assets/js/overlay/layout.js",
      "assets/js/overlay/render.js",
      "assets/js/overlay/events.js",
      "assets/js/overlay/index.js",
      "assets/js/pointer/index.js",
    }

    for _, script_path in ipairs(script_paths) do
      local src = resolve_project_path(script_path)
      lines[#lines + 1] = string.format('<script defer src="%s"></script>', escape_attr(src))
    end

    return table.concat(lines, "\n")
  end

  local function apply_header_includes(doc, snippets)
    local header_includes = doc.meta["header-includes"] or pandoc.MetaList({})
    if pandoc.utils.type(header_includes) ~= "MetaList" then
      header_includes = pandoc.MetaList({ header_includes })
    end

    for _, snippet in ipairs(snippets or {}) do
      if snippet ~= nil and snippet ~= "" then
        header_includes[#header_includes + 1] = pandoc.MetaBlocks({ pandoc.RawBlock("html", snippet) })
      end
    end

    doc.meta["header-includes"] = header_includes
  end

  local function run(doc)
    local path_context = path_utils.create_context(base_dir)
    local function resolve_project_path(raw_path)
      return path_utils.resolve_project_path(raw_path, path_context)
    end

    local doc_author_text = utils.meta_value_to_text(doc.meta.author)
    local doc_affiliation_text = utils.meta_value_to_text(doc.meta.institute or doc.meta.affiliation or doc.meta.institution)

    local normalized = normalize_config.normalize(doc.meta, schema, utils, {
      author_text = doc_author_text,
      affiliation_text = doc_affiliation_text,
      resolve_project_path = resolve_project_path,
    })

    local deck_assets_html = build_deck_assets_html(resolve_project_path)
    local overlay_json_html = emit_overlay_json.build_script_block(normalized.json)
    local css_vars_html = emit_css_vars.build_script_block(normalized.css_vars)
    local mathjax_config_html = mathjax_config.build_script_block(doc.meta, utils, "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js")

    doc.blocks = slide_transform.mark_eyecatch_headers(doc.blocks, {
      image = normalized.runtime.eyecatch.background.image,
      size = normalized.runtime.eyecatch.background.size,
      position = normalized.runtime.eyecatch.background.position,
    })

    doc.blocks = slide_transform.wrap_body_slides(doc.blocks, {
      image = normalized.runtime.body.background.image,
      size = normalized.runtime.body.background.size,
      opacity = normalized.runtime.body.background.opacity,
    })

    apply_header_includes(doc, {
      mathjax_config_html,
      deck_assets_html,
      overlay_json_html,
      css_vars_html,
    })
    return doc
  end

  return {
    {
      Pandoc = run,
    }
  }
end
