--!optimize 2
--!native
local kinds = {}
export type token = string

--// Functions
local function scanChar(source: string, init: number):  (token?, number?)

    return string.sub(source, init, init), init+1
end
local function scanWord(source: string, init: number):  (token?, number?)

    local _,cursor, raw = string.find(source, "^([%a_][%w_]+)", init)
    if not raw then return end

    kinds[raw] = 'word'
    return raw, cursor+1
end
local function scanNumber(source: string, init: number): (token?, number?)

    local _,cursor, raw = string.find(source, "%d+", init)
    if not raw then return end

    kinds[raw] = 'number'
    return raw, cursor+1
end
local function scanString(source: string, init: number): (token?, number?)

    local _,cursor, raw = string.find(source, "^(%b\'\')", init)
    if not raw then return end

    kinds[raw] = 'string'
    return raw, cursor+1
end
local function scanSymbol(source: string, init: number): (token?, number?)

    local _,cursor, raw = string.find(source, '^(%.%.?%.?)', init)
    if not raw then return end

    kinds[raw] = 'symbol'
    return raw, cursor+1
end

local function scanToken(source: string, init: number): (token?, number?)

    local token, cursor = scanString(source, init)
    if token then return token, cursor end

    token, cursor = scanNumber(source, init)
    if token then return token, cursor end

    token, cursor = scanSymbol(source, init)
    if token then return token, cursor end

    token, cursor = scanWord(source, init)
    if token then return token, cursor end

    return scanChar(source, init)
end
local function skipSpace(source: string, init: number): number

    local _,cursor = string.find(source, "^(%s+)", init)
    return if cursor then cursor+1 else init
end

local function is(token, kind: string)

    return (kinds[token] or 'char') == kind
end
local function scanAll(source: string)

    local tokens = {}
    local cursor = 1
    repeat
        cursor = skipSpace(source, cursor)

        local token, newCursor = scanToken(source, cursor)
        if not token then break end

        cursor = newCursor
        table.insert(tokens, token)

    until cursor >= #source

    return tokens
end

--// End
return {
    is = is,
    scanAll = scanAll,

    scanString = scanString,
    scanWord = scanWord,
    scanChar = scanChar,
    scanToken = scanToken,
}