local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local main = dofile(pandoc.path.join({ script_dir, "lua", "main.lua" }))

return main(script_dir)
