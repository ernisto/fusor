local symbol = require('init')
type symbol = symbol.symbol

local type_symbol = require('type/init')
local type_check = require('type/check')
type type_symbol = type_symbol.type_symbol

type scope_symbol = { symbols: { [string]: symbol } }

type val_symbol = symbol & { type: type_symbol? }
type func_symbol = symbol & {
    type_params: { type_symbol },
    data_params: { val_symbol },
    result: type_symbol
}

local function bindSymbols(ctx, scopeNode, parent: scope_symbol?)

    local symbols: { [string]: symbol } = {}
    local scopeSymbol: scope_symbol = { symbols = symbols }
    if parent then setmetatable({}, { __index = parent.symbols }) end

    local visitor = {
        scope = function(subScopeNode) bindSymbols(subScopeNode, scopeSymbol) end,
        read_val = function(varNode)
            
            symbols[varNode] = symbols[varNode.name] or ctx.report(`invalid var name '{varNode.name}'`)
        end,
        syntax_def = function(syntaxNode)


        end
    }
    -- traverse.scope(scopeNode, visitor)
end

return bindSymbols