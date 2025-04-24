--[[
    frame.lua
    Frame-related utility functions for Aegisub karaoke templates

    Author: LightArrowsEXE <https://github.com/LightArrowsEXE>
]]

--[[
    Calculate frame duration in milliseconds based on timebase

    @param numerator number Timebase numerator (e.g. 24000)
    @param denominator number Timebase denominator (e.g. 1001)
    @return number Frame duration in milliseconds
]]
local frame = {
  duration = function (numerator, denominator)
    return (1000 * denominator) / numerator
  end
}

return frame
