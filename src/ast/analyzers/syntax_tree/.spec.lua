local display = require('../../../display')
local setupParser = require('../../parser')
local stream = require('../../../token/stream')
local lexer = require('../../../token/lexer')
local parserSymbol = require('../../../symbol/parser')
local path = require('../../path')
local module = require('init')
local ast = require('../../init')

local function getAst(source)
    
    local tokens = lexer.scanAll(source)
    local tokenStream = stream(tokens)
    local parser = setupParser(tokenStream)
    
    return parser.type_tuple()
end

--// Test
local root_syntaxTree = module.new()
local root_symbol = parserSymbol.parent.new()

local expr_symbol = parserSymbol.parent.new()
root_symbol.children.expr = expr_symbol

local parents = { [expr_symbol] = root_syntaxTree }
local function resolveParserSymbol(requestedPath: ast.path_node): parserSymbol.parser_symbol?

    local arrayedPath = path.arrayfy(requestedPath)
    local root = root_symbol

    for index, name in arrayedPath do

        assert(root.kind == 'parent_parser_symbol', `invalid field '{name}' of parser '{table.concat(arrayedPath, '.', 1, index)}'`)
        
        root = root.children[name]
        assert(root, `invalid field '{name}' of parser '{table.concat(arrayedPath, '.', 1, index)}'`)
    end
    return root
end

local andSymbol = parserSymbol.leaf.new({ kind='syntax' } :: any)
module.insertSyntaxClauses(root_syntaxTree,
    getAst(`(expr '&' expr)`), andSymbol,
    resolveParserSymbol, parents, {}
)
local optSymbol = parserSymbol.leaf.new({ kind='syntax' } :: any)
module.insertSyntaxClauses(root_syntaxTree,
    getAst(`(expr '?')`), optSymbol,
    resolveParserSymbol, parents, {}
)
local notSymbol = parserSymbol.leaf.new({ kind='syntax' } :: any)
module.insertSyntaxClauses(root_syntaxTree,
    getAst(`('!' expr)`), notSymbol,
    resolveParserSymbol, parents, {}
)
local readSymbol = parserSymbol.leaf.new({ kind='syntax' } :: any)
module.insertSyntaxClauses(root_syntaxTree,
    getAst(`(identifier)`), readSymbol,
    resolveParserSymbol, parents, {}
)

return print(display(root_syntaxTree))