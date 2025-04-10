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
  loc_preset = "center", --- location of the clock window.
                         --- available values: "center" | "top_left" | "top_right" | "bottom_left"
                         --- "bottom_right"
  win = {
    relative = "editor",
    anchor = "NW",
    style = "minimal",
    border = "rounded",
    --- (the same as opts for `nvim_open_win`, except `anchor`, `col`, `row`, `width` and `height`)
  },
  alarm_opts = {
    alarm_path = vim.fs.joinpath(vim.fn.stdpath("data"), "/chronos.nvim/sound/mixkit-morning-clock-alarm-1003.wav"), --- path to alarm sound
    alarm_text = "󰀠 ALARM!" --- alarm notification text
  }
}
```

## Roadmap

- [ ] More clock styles.
- [x] Support alarm with audio.
- [x] Support different clock location.
