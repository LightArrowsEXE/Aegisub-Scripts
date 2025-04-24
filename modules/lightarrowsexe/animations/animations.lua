--[[
    animations.lua
    A collection of drawing animations for Aegisub karaoke templates

    Version: 0.0.1
    Author: LightArrowsEXE <https://github.com/LightArrowsEXE>
]]

-- First load all required modules
local frame = require("lightarrowsexe.animations.utils.frame")

local sparkles = require("lightarrowsexe.animations.drawings.sparkles")

local animal = require("lightarrowsexe.animations.drawings.animal")

local pixelart_heart = require("lightarrowsexe.animations.drawings.pixelart.heart")
local pixelart_rings = require("lightarrowsexe.animations.drawings.pixelart.rings")
local pixelart_sparkburst = require("lightarrowsexe.animations.drawings.pixelart.sparkburst")
local pixelart_plasma = require("lightarrowsexe.animations.drawings.pixelart.plasma")


-- Then create the animations table
local animations = {
    version = "0.0.1",
    frame = frame,
    shapes = {
        -- common shapes
        starburst = sparkles.starburst,

        -- specific shapes
        animal = animal,

        -- pixel art
        pixelart = {
            heart = pixelart.heart,
            rings = pixelart.rings,
            sparkburst = pixelart.sparkburst,
            plasma = pixelart.plasma
        }
    }
}

return animations
