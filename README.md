# chronos.nvim

A simple plugin to show a clock in a floating window. I create this plugin just for fun 😊.

<center>
  <image src="https://raw.githubusercontent.com/xTayEx/chronos.nvim/refs/heads/main/doc/assets/demo.png"></image>
</center>

## Usage

- `:ChronosOpen`: Turn on the clock.
- `:ChronosClose`: Turn off the clock.
- `:ChronosHide`: Hide the alarm window.
- `:ChronosShow`: Show the alarm window.
- `:ChronosSetAlarmAt`: Set alarm at specified time. Time format should be `%H:%M`, in 24-hour notation. (e.g. "14:05")

## Dependencies

- neovim>=v0.11.0. Older version may work.
- mpv (for playing alarm sound.)

## Installation

### 💤 Lazy.nvim

```lua

{
  "xTayEx/chronos.nvim",
  opts = {}, -- `opts` field is necenarry for calling the `setup` function.
}

```

## Configuration

chronos.nvim comes with the following default configuration.

```lua
{
  loc_preset = "center", --- location of the clock window.
                         --- available values: "center" | "top_left" | "top_right" | "bottom_left"
                         --- "bottom_right"
  win = {
    relative = "editor",
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
