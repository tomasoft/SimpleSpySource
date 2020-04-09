--[[
    higlight.lua v0.1 by exxtremewa#9394
    
     - uses the power of fancy gradient api shenanigans to do line-based syntax higlighting
     - is cool
]]

local TextService = game:GetService("TextService")
--- The metatable of the Highlight class
local HighlightMeta = {}
--- The Highlight class
--- @class Highlight
local Highlight = {}

-- PRIVATE METHODS/PROPERTIES --

--[[
    Char Object:
    {
        Char: string -- A single character
        Color: Color3 -- The intended color of the char
    }
]]

local scrollingFrame
local lineNumberFrame
local lineNumbers
local lines = {}

--- Contents of the table- array of char objects
local tableContents = {}

--- Whether or not the previous line had an unfinished string
local continuingString = false

local backgroundColor = Color3.fromRGB(40, 44, 52)
local operatorColor = Color3.fromRGB(198, 120, 221)
local functionColor = Color3.fromRGB(97, 175, 239)
local stringColor = Color3.fromRGB(152, 195, 121)
local numberColor = Color3.fromRGB(209, 154, 102)
local booleanColor = numberColor
local objectColor = Color3.fromRGB(229, 192, 123)
local defaultColor = Color3.fromRGB(204, 160, 163)
local lineNumberColor = Color3.fromRGB(187, 85, 255)
local commentColor = Color3.fromRGB(148, 148, 148)
local genericColor = Color3.fromRGB(240, 240, 240)

local operators = {"function", "local", "if", "for", "while", "then", "do", "else", "elseif", "return", "end", "=", ">", "~", "<", "%-", "%+", "=", "%*"}
--- In this case, patterns could not be used, so just the string characters are provided
local strings = {'"', "'"}
local comments = {"(--.)\n", "--[[.]]"}
local functions = {"[%s%-%+=%*%.:<>]([%a_][%a%d_]*)%s*%(", "^([%a_][%a%d_]*)%s*%("}
local numbers = {"[%s%-%+%=%*<>](%d+)", "[%s%-%+=%*<>](%.%d+)", "[%s%-%+=%*<>](%d+%.%d+)", "^(%d+)", "^(%.%d+)", "^(%d+%.%d+)"}
local booleans = {"[%s%-%+%=%*<>]true", "^true", "[%s%-%+%=%*<>]false", "^false"}
local objects = {"[%s%-%+=%*<>]([%a_][%a%d_]*):", "^([%a_][%a%d_]*):"}
local other = {"%p", "%(", "%)", "{", "}", "[", "]"}

local offLimits = {}

--- Determines if index is in a string
function isOffLimits(index)
    for _, v in pairs(offLimits) do
        if index > v[1] and index < v[2] then
            return true
        end
    end
    return false
end

--- Find iterator
function gfind(str, pattern)
    local start = 0
    return function()
        local findStart, findEnd = str:find(pattern, start)
        if findStart and findEnd ~= #str then
            start = findEnd + 1
            return findStart, findEnd
        else
            return nil
        end
    end
end

--- Finds and highlights comments with `commentColor`
function renderComments() 
    local str = Highlight:getRaw()
    for _, pattern in pairs(comments) do
        for commentStart, commentEnd in gfind(str, pattern) do
            for i = commentStart, commentEnd do
                table.insert(offLimits, {commentStart, commentEnd})
                tableContents[i].Color = commentColor
            end
        end
    end
end

-- Finds and highlights strings with `stringColor`
function renderStrings()
    local stringType = ""
    local stringStart
    local stringEnd
    for i, char in pairs(tableContents) do
        if stringType then
            char.Color = stringColor
            if char.Char == stringType and tableContents[i - 1].Char ~= "\\" then
                stringType = ""
                stringEnd = i
                table.insert(offLimits, {stringStart, stringEnd})
            end
        end
        for _, v in pairs(strings) do
            if char.Char == v then
                stringType = v
                char.Color = stringColor
                stringStart = i
            end
        end
    end
end

--- Highlights the specified patterns with the specified color
--- @param patternArray string[]
---@param color userdata
function highlightPattern(patternArray, color)
    local str = Highlight:getRaw()
    for _, pattern in pairs(patternArray) do
        for findStart, findEnd in gfind(str, pattern) do
            if not isOffLimits(findStart) and not isOffLimits(findEnd) then
                for i = findStart, findEnd do
                    tableContents[i].Color = color
                end
            end
        end
    end
end

--- Main function for syntax highlighting tableContents
function render()
    offLimits = {}
    for _, char in pairs(tableContents) do
        char.Color = defaultColor
    end
    renderComments()
    renderStrings()
    highlightPattern(functions, functionColor)
    highlightPattern(numbers, numberColor)
    highlightPattern(operators, operatorColor)
    highlightPattern(objects, objectColor)
    highlightPattern(booleans, booleanColor)
    highlightPattern(other, genericColor)
end

-- PUBLIC METHODS --

--- Runs when a new object is instantiated
--- @param frame Frame
function Highlight:init(frame)
    if typeof(frame) == "Instance" and frame:IsA("Frame") then

    else
        error("Initialization error: argument " .. tostring(frame) .. " is not a Frame Instance")
    end
end

--- Sets the raw text of the code box (\n = new line, \t converted to spaces)
--- @param raw string
function Highlight:setRaw(raw)
    
end

--- Returns the (string) raw text of the code box (\n = new line)
--- @return string
function Highlight:getRaw()
    local result = ""
    for _, char in pairs(tableContents) do
        result = result .. char.Char
    end
    return result
end

--- Returns the (char[]) array that holds all the lines in order as strings
--- @return string[]
function Highlight:getTable()
    return tableContents
end

--- Returns the (int) number of lines in the code box
--- @return number
function Highlight:size()
    return #tableContents
end

--- Returns the (string) line of the specified line number
--- @param line number
--- @return string
function Highlight:getLine(line)
    local currentline = 0
    local rightLine = false
    local result = ""
    for _, v in pairs(tableContents) do
        currentline = currentline + 1
        if v.Char == "\n" and not rightLine then
            rightLine = true
        end
        if rightLine and v.Char ~= "\n" then
            result = result .. v.Char
        elseif rightLine then
            break
        end
    end
    return result
end

--- Replaces the specified line number with the specified string (\n will overwrite further lines)
--- @param line number
---@param text string
function Highlight:setLine(line, text)

end

--- Inserts a line made from the specified string and moves all existing lines down (\n will insert further lines)
--- @param line number
---@param text string
function Highlight:insertLine(line, text)

end

local oldIndex = HighlightMeta.__index
--- @param table table
---@param key any
HighlightMeta.__index = function(table, key)
    local old = {oldIndex()}
    if typeof(key) == "string" then

    end
    return unpack(old)
end

setmetatable(Highlight, HighlightMeta)

-- CONSTRUCTOR --

local constructor = {}
--- responsible for instantiation
function constructor.new(...)
    local class = Highlight
    local new = {}
    class.__index = class
    setmetatable(new, class)
    new:init(...)
    return new
end

return constructor

--- @class Frame
--- @class Line
