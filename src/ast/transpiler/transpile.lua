--!optimize 2
--!native
local ast = require('..')
local syntax_tree = require('../analyzers/syntax_tree')
local parserSymbol = require('../../symbol/parser')
local path = require('../path')

--// Transpiler
return function(ast: ast.scope_node)

    --// Parsers Tree
    local parentParserSymbol = parserSymbol.parent.new()
    for _,parserDef in ast.stats do

        if parserDef.kind ~= 'syntax' then continue end

        local rootSymbol = parentParserSymbol
        local root = parserDef.path

        for _,name in path.arrayfy(root) do

            rootSymbol = parserSymbol.parent.get(rootSymbol, name)
        end
        local symbol = parserSymbol.leaf.new(parserDef)
        
        if rootSymbol.children[root.name] then warn(`replaced parser symbol '{table.concat(path.arrayfy(parserDef.path), '.')}'`) end
        rootSymbol.children[root.name] = symbol
    end

    --// Functions
    local function resolveParserSymbol(requestedPath: ast.path_node): parserSymbol.parser_symbol?

        local arrayedPath = path.arrayfy(requestedPath)
        local root = parentParserSymbol

        for index, name in arrayedPath do

            assert(root.kind == 'parent_parser_symbol', `invalid field '{name}' of parser '{table.concat(arrayedPath, '.', 1, index)}'`)
            
            root = root.children[name]
            assert(root, `invalid field '{name}' of parser '{table.concat(arrayedPath, '.', 1, index)}'`)
        end
        return root
    end
    local function transpileParentParser(
        parser: parserSymbol.parent_parser_symbol,
        parents: { [parserSymbol.parser_symbol]: syntax_tree.node }
    )
        local syntaxTree = syntax_tree.new()
        parents[parser] = syntaxTree

        for name, child in parser.children do

            if child.kind == 'parent_parser_symbol' then

                transpileParentParser(child, parents)

            elseif child.kind == 'leaf_parser_symbol' then

                syntax_tree.insertSyntaxClauses(parents, child.def.body, child, resolveParserSymbol, {}).elseParse = child
            end
        end
        parents[parser] = nil
    end
    local function transpileLeafParser(parser: parserSymbol.leaf_parser_symbol)

    end
    return transpileParentParser(parentParserSymbol) 
end