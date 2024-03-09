--!optimize 2
--!native

local lexer = require('lexer')
local is = lexer.is
type token = lexer.token

--// Factory
return function(tokens: {token})

    local cToken = tokens[1]
    local cursor = 1

    --// traveling
    local function advance()

        cursor += 1
        cToken = tokens[cursor]
    end
    local function backpoint(): () -> ()

        local lastCursor = cursor
        return function()

            cursor = lastCursor
            cToken = tokens[cursor]
        end
    end
    local function getPosition()

        return cursor
    end
    local function getCursor() return cursor end

    --// popping
    local function peek(): token?

        return cToken
    end
    local function popToken(kind: string): token?

        local tok = cToken
        if not is(cToken, kind) then return end

        advance()
        return tok
    end
    local function popRaw(word: string): token?

        local tok = cToken
        if cToken ~= word then return end

        advance()
        return tok
    end

    --// End
    return {
        getPosition = getPosition,
        getCursor = getCursor,
        backpoint = backpoint,
        popToken = popToken,
        popRaw = popRaw,
        peek = peek,
    }
end
