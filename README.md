# chronos.nvim

A simple plugin to show a clock in a floating window. I create this plugin just for fun 😊.

## Usage

- `:ChronosOpen`: Open the clock.
- `:ChronosClose`: Close the clock.

## Dependencies
No extra dependencies (as for now). Only tested on neovim v0.11.0. Older version may work.

## Configuration
chronos.nvim comes with the following default configuration.

```lua
{
  win = {
    relative = "editor",
    anchor = "NW",
    style = "minimal",
    border = "rounded",
    --- (the same as opts for `nvim_open_win`, except `col`, `row`, `width` and `height`)
  }
}
```

## Roadmap
- [ ] More clock styles.
- [ ] Support alarm with audio.
- [ ] Support different clock location.
