Micro plugin for running shell commands on the content of the current buffer.

Type `:Run <command>` or `:Run` and run suggested prompt/type your own command. Use similar `:RunErr` and `:RunAll` commands for stderr and combined stdout/stderr output.

## Configuration
```lua
require("run").setup({
    -- map from file type to default command
    ft_defaults = {
        javascript = "node",
        python = "python3"
    }
})
```
