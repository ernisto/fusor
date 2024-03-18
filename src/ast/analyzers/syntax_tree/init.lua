--!optimize 2
--!native
local ast = require('../..')
local parserSymbol = require('../../../symbol/parser')
local path = require('../../path')

--// Types
type syntax_clause = {
    isVariadic: boolean,
    checkKind: string?,
    checkRaw: string?,
}
type syntax_node = {
    haveRecursion: boolean,
    nextClauses: { [syntax_clause]: syntax_node },
    elseParse: parserSymbol.leaf_parser_symbol?,
    haveKindClause: boolean,
}
export type node = syntax_node
export type clause = syntax_clause

local function newSyntaxNode(): syntax_node

    return { haveRecursion = false, nextClauses = {}, haveKindClause = false, elseParse = nil }
end
local function getClauseSyntaxNode(root: syntax_node, clauseType: ast.type_node, isOptional: boolean, isVariadic: boolean)

    local checkRaw = clauseType.kind == 'type_string' and clauseType.content
    local checkKind = clauseType.kind == 'read_type' and path.getFullName(clauseType.path)

    for clause, node in root.nextClauses do

        if clause.checkKind ~= checkKind then continue end
        if clause.checkRaw ~= checkRaw then continue end
        
        return node
    end
    local node = newSyntaxNode()
    local clause = { checkKind = checkKind, checkRaw = checkRaw, isVariadic = isVariadic }

    if checkKind then root.haveKindClause = true end

    root.nextClauses[clause] = node
    return node
end

--// Utils
local function adjustField(field: ast.type_field_node)
    
    local isOptional = field.isOptional
    local isVariadic = field.isVariadic
    local fieldType = field.type
    
    if fieldType.kind == 'optional_type' then
        
        assert(not isOptional, `field already is optional`)
        assert(not isVariadic, `variadic types cannot be optional`)
        fieldType = fieldType.base
        isOptional = true
        
    elseif fieldType.kind == 'variadic_type' then
        
        assert(not isVariadic, `field already is variadic`)
        assert(not isOptional, `variadic types cannot be optional`)
        fieldType = fieldType.base
        isVariadic = true
    end
    if isVariadic then
        
        assert(fieldType.kind == 'array_type', `variadic fields must to be an array`)
        fieldType = fieldType.base
    end
    return fieldType, isOptional, isVariadic
end

--// Methods
type parser_symbol_resolver = (requestedPath: ast.path_node) -> parserSymbol.parser_symbol?
local function insertSyntaxClauses(
    syntaxNode: syntax_node,
    tupleNode: ast.type_tuple_node,
    leafParser: parserSymbol.leaf_parser_symbol,
    resolveParserSymbol: parser_symbol_resolver,
    parentParsers: { [parserSymbol.parent_parser_symbol]: syntax_node },
    optionalNodes: { syntax_node }
)
    local requiredNode = syntaxNode

    local function pushNode(newNode: syntax_node, isOptional: boolean?)

        if isOptional then
    
            table.insert(optionalNodes, newNode)
        else
    
            requiredNode = newNode
            optionalNodes = {}
        end
    end
    local function pushClause(fieldType: ast.type_node, isOptional: boolean, isVariadic: boolean)

        for _,previousNode in optionalNodes do
            
            getClauseSyntaxNode(previousNode, fieldType, isOptional, isVariadic)
        end
        local newNode = getClauseSyntaxNode(requiredNode, fieldType, isOptional, isVariadic)
        pushNode(newNode, isOptional)
    end
    for _,field in tupleNode.fields do

        local fieldType, isOptional, isVariadic = adjustField(field)
        if fieldType.kind == 'type_tuple' then
            
            local lastRequiredNode, lastOptionalNodes = insertSyntaxClauses(syntaxNode, fieldType, leafParser, resolveParserSymbol, parentParsers, optionalNodes)

            if lastOptionalNodes ~= optionalNodes then
                table.move(lastOptionalNodes, 1, #lastOptionalNodes, #optionalNodes+1, optionalNodes)
            end
            pushNode(lastRequiredNode)

        elseif fieldType.kind == 'type_string' then

            pushClause(fieldType, isOptional, isVariadic)

        elseif fieldType.kind == 'read_type' then

            local isParserSymbol, parserSymbol = pcall(resolveParserSymbol, fieldType.path)
            if isParserSymbol then

                local parentParser = parentParsers[parserSymbol]
                if parentParser then

                    pushClause(fieldType, isOptional, isVariadic)
                else

                    local lastRequiredNode, lastOptionalNodes = insertSyntaxClauses(syntaxNode, parserSymbol.def.body, leafParser, resolveParserSymbol, parentParsers, optionalNodes)
                    
                    if lastOptionalNodes ~= optionalNodes then
                        table.move(lastOptionalNodes, 1, #lastOptionalNodes, #optionalNodes+1, optionalNodes)
                    end
                    pushNode(lastRequiredNode)
                end
            else
                
                pushClause(fieldType, isOptional, isVariadic)
            end
        end
    end
    return requiredNode, optionalNodes
end

--// End
return table.freeze{ new = newSyntaxNode, insertSyntaxClauses = insertSyntaxClauses }