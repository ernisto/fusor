local escapes = {
    dark_red = "\027[31m",
    light_red = "\027[91m", red = "\027[91m", peach = "\027[91m",
    dark_yellow = "\027[33m", orange = "\027[33m",
    light_yellow = "\027[93m", yellow = "\027[93m",
    light_green = "\027[92m", green = "\027[92m",
    dark_green = "\027[32m",
    dark_cyan = "\027[36m", baby_blue = "\027[96m",
    light_cyan = "\027[96m", cyan = "\027[96m",
    light_blue = "\027[94m", blue = "\027[94m",
    dark_blue = "\027[34m", navy = "\027[34m",
    dark_pink = "\027[35m", purple = "\027[35m", magenta = "\027[35m",
    light_pink = "\027[95m", pink = "\027[95m",
    light_gray = "\027[37m", light_grey = "\027[37m", gray = "\027[37m", grey = "\027[37m",
    dark_gray = "\027[90m", dark_grey = "\027[90m",
    white = "",

    back_dark_red = "\027[41m",
    back_red = "\027[101m", back_light_red = "\027[101m", back_peach = "\027[101m",
    back_dark_yellow = "\027[43m", back_orange = "\027[43m",
    back_yellow = "\027[103m", back_light_yellow = "\027[103m",
    back_green = "\027[102m", back_light_green = "\027[102m",
    back_dark_green = "\027[42m",
    back_dark_cyan = "\027[46m", back_baby_blue = "\027[46m",
    back_cyan = "\027[106m", back_light_cyan = "\027[106m",
    back_blue = "\027[104m", back_light_blue = "\027[104m",
    back_dark_blue = "\027[44m", back_navy = "\027[44m",
    back_dark_pink = "\027[45m", back_purple = "\027[45m", back_magenta = "\027[45m",
    back_pink = "\027[105m", back_light_pink = "\027[105m",
    back_gray = "\027[47m", back_light_gray = "\027[47m", back_grey = "\027[47m", back_light_grey = "\027[47m",
    back_dark_gray = "\027[100m", back_dark_grey = "\027[100m",

    strikethrough = "\027[9m",
    underline = "\027[4m",
    clear = "\027[0m",
    bold = "\027[1m",
}

--// Class
local Color = {}
function Color.new(escape)

    return setmetatable({ escape = escape }, Color)
end

function Color:__call(text) return self.escape .. (text or '') .. escapes.clear end
function Color:__index(tag)

    local escape = escapes[tag] or error(`invalid escape '{tag}'`)
    return Color.new(self.escape .. escape)
end

return Color.new("")