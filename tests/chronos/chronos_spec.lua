local clock = require("chronos.clock").clock

describe("check the clock instance.", function()
  it("Should not be nil", function()
    assert.is.truthy(clock)
  end)
end)
