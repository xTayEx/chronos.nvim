local Clock = require("chronos.clock").Clock

describe("Create new Clock instance", function()
  it("work as expect", function()
    local clock = Clock:new()
    assert.is.truthy(clock)
  end)
end)
