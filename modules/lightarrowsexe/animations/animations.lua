--[[
    animations.lua
    A collection of drawing animations for Aegisub karaoke templates

    Version: 0.0.1
    Author: LightArrowsEXE <https://github.com/LightArrowsEXE>
]]

local animations = {
    version = "0.0.1",

    -- Import utility modules
    frame = require("utils.frame")
}

-- Import shape definitions
animations.shapes = {
    -- common shapes
    sparkles = require("drawings.sparkles"),

    -- specific shapes
    animal = require("drawings.animal"),
}

return animations
