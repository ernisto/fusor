--!optimize 2
--!native
local ast = require('../ast')

--// Types
export type parser_symbol = leaf_parser_symbol | parent_parser_symbol
export type parent_parser_symbol = { kind: 'parent_parser_symbol', children: { [parent_parser_symbol]: parser_symbol} }
export type leaf_parser_symbol = { kind: 'leaf_parser_symbol', def: ast.parser_def_node }

--// Functions
local function newLeafParserSymbol(parserDef: ast.parser_def_node): leaf_parser_symbol

    return { kind = 'leaf_parser_symbol', def = parserDef }
end
local function newParentParserSymbol(): parent_parser_symbol

    return { kind = 'parent_parser_symbol', children = {} }
end
local function getParentParserSymbol(self: parent_parser_symbol, name: string): parent_parser_symbol
    
    local children = self.children
    if children[name] then return children[name] end
    
    local symbol = newParentParserSymbol()
    children[name] = symbol
    
    return symbol
end
return table.freeze{
    parent = table.freeze{ new = newParentParserSymbol, get = getParentParserSymbol },
    leaf = table.freeze{ new = newLeafParserSymbol },
}