return require("telescope").register_extension({
  exports = {
    executioner = function(opts)
      require("executioner.picker").run(opts)
    end,
  },
})
