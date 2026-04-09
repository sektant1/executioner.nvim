local function run(opts)
  require("executioner.picker").run(opts)
end

return require("telescope").register_extension({
  exports = {
    executioner = run,
    scripts = run,
  },
})
