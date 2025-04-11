local Clock = require("chronos.clock").Clock

describe("Creat a Clock instance", function()
  it("Should not be nil", function()
    local config = {
      win = {
        relative = "editor",
        anchor = "NW",
        style = "minimal",
        border = "rounded",
      },
    }
    local clock = Clock:new(config)
    assert.is.truthy(clock)
  end)
end)
