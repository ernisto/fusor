--!optimize 2
--!native
local ast = require('..')
-- local bindSymbols = require('../analyzers/symbol/bind')
-- local getPathName = require('../analyzers/getPathName')
-- local getDefs = require('../analyzers/getDefs')

--// Utils
local function arrayfyPath(path: ast.path_node): {string}

    local array = {}
    local node = path

    while node do

        table.insert(array, node.name)
        node = node.base
    end
    return array
end
local function getFullPathName(path: ast.path_node): string

    return table.concat(arrayfyPath(path), '_')
end
local function treefy(sequences: { [string]: {any} })

    local root = {}

    for name, sequence in sequences do
        
        local finalIndex = #sequence
        local branch = root

        for index, token in sequence do

            branch[token] = if index == finalIndex then name else branch[token] or {}
            branch = branch[token]
        end
    end
    return root
end

local function eachDescendant(root, callback)

    for index, child in root do

        callback(index, child)
        if typeof(child) == 'table' then eachDescendant(child, callback) end
    end
end

--// Parser Transpilers
local function transpileFieldPop(fieldType: ast.type_node): (string, string)    -- popCode, typeCode

    if fieldType.kind == 'read_type' then

        local path = fieldType.path

        if path.kind == 'read_prop' and path.base.name == 'token' then

            return `popTok('{path.name}')`,
                `string`
        else
            local paramsCode = `popRaw, popTok, report`

            for _,paramField in ipairs(fieldType.params and fieldType.params.params or {}) do

                local paramType = paramField.type

                assert(paramType.kind == 'type_read', `generics only can consume anothers parsers for while`)
                paramsCode ..= `, {paramType.path.name}`
            end
            return `parse_{getFullPathName(path)}({paramsCode})`,
                `{getFullPathName(path)}_node`
        end
    elseif fieldType.kind == 'type_string' then

        return `popRaw('{fieldType.content}')`,
            `'{fieldType.content}'`
    elseif fieldType.kind == 'type_tuple' then

        return transpileFieldPop(fieldType.fields[1].type)
    end
    return "", ""
end
local function transpilePops(fields: {ast.type_field_node}, totalFields: number, mainNodeBuildCode: string?)

    local discriminatorIndex: number?
    local nodeFieldsBuildCode = ''
    local nodeTypeExtensionsCode = ''
    local nodeFieldsTypeCode = ''
    local poppersCode = ''

    local finalIndex = #fields

    for index, field in fields do

        totalFields += 1

        local isOptional = field.isOptional
        local isVariadic = field.isVariadic
        local fieldType = field.type
        
        local isRequired = not isOptional and not isVariadic
        local isDiscriminator = isRequired and not discriminatorIndex
        
        --// Adjust fieldType Settings
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

        --// Popper
        local id = `_{totalFields}`
        local tokenCode, fieldTypeCode = transpileFieldPop(fieldType)
        
        local reporter = if discriminatorIndex then `; if {id} == nil then report(\`missing {fieldTypeCode}\`) end` else ""
        local popperCode = `\nif {id} == nil then {id} = {tokenCode}{reporter} end`

        if fieldType.kind == 'type_tuple' then

            local fieldBuildCode
            popperCode, fieldTypeCode, fieldBuildCode = transpilePops(fieldType.fields, totalFields-1)
            
            if not isVariadic then nodeTypeExtensionsCode ..= ` & {fieldTypeCode}` end
            nodeFieldsBuildCode ..= fieldBuildCode
        else
            if isDiscriminator and (mainNodeBuildCode or index ~= finalIndex) then
            
                discriminatorIndex = index
                popperCode ..= `\nif {id} then`
            end
            if isVariadic then
    
                fieldTypeCode = `\{{fieldTypeCode}\}`
                popperCode = `\nrepeat`
                    ..     popperCode:gsub('\n', "\n    ")
                    .. `\nuntil not {id}`
    
            elseif isOptional then
    
                fieldTypeCode = `{fieldTypeCode}?`
            end
        end
        if field.name then
            
            nodeFieldsBuildCode ..= `, {field.name} = {id}`
            nodeFieldsTypeCode ..= `\n{field.name}: {fieldTypeCode},`
        end
        poppersCode ..= popperCode
    end
    if mainNodeBuildCode then poppersCode ..= `{mainNodeBuildCode}{nodeFieldsBuildCode} \}` end
    if discriminatorIndex then poppersCode ..= `\nend\nreturn` end
    
    return poppersCode,
        `\{{nodeFieldsTypeCode}\n\}{nodeTypeExtensionsCode}`,
        nodeFieldsBuildCode,
        totalFields
end
local function transpileParserTree(tree)

    for token, subTree in tree do


    end
end

local function getParserCode(
    identifier: string,
    paramsCode: string,
    nodeTypeCode: string,
    poppersCode: string
)
    return `\nexport type {identifier}_node = {nodeTypeCode}`
        .. `\nfunction parse_{identifier}(popRaw, popTok, report{paramsCode})`
        ..      poppersCode:gsub("\n", "\n    ")
        .. `\nend`
end
local function transpileParentParser(fullName: string, name: string, children)

    print(children)

    local nodeTypeCode = "name"
    local parsersCode = ""
    local id = `_{1}`
    local poppersCode = `\n`
        .. `\nlocal incoming`
        .. `\nrepeat`
        .. `\n    if {id} then`
        .. `\n        cavalo()`
        .. `\n    else`
        .. `\n        if incoming then {id} = incoming end`
        .. `\n        break`
        .. `\n    end`
        .. `\nuntil false`

    local syntaxes = {}
    eachDescendant(children, function(name, fullName)
    
        if typeof(fullName) ~= 'string' then return end

        local parserDef = ctx.symbols[fullName]
        syntaxes[name] = parserDef.fields
    end)
    for name, child in children do

        if typeof(child) == 'string' then continue end -- is leaf
        parsersCode ..= transpileParentParser(`{name}_{fullName}`, name, child)
    end
    return getParserCode(fullName, "", nodeTypeCode, poppersCode)
        .. parsersCode
end
local function transpileLeafParser(parserDef: ast.parser_def_node)

    local fullName = getFullPathName(parserDef.path)
    local poppersCode, nodeTypeCode, _nodeFieldsBuildCode, totalFields
        = transpilePops(parserDef.body.fields, 0, `\nreturn \{ kind = '{fullName}'`)

    local paramsCode = ""
    if parserDef.params then

        for _,param in parserDef.params.params do paramsCode ..= `, {param.name}` end
    end
    for count = 1, totalFields do paramsCode ..= `, _{count}` end

    return getParserCode(
        getFullPathName(parserDef.path),
        paramsCode,
        nodeTypeCode:gsub('\n([^%}])', "\n    %1"),
        poppersCode
    )
end

local function transpileScope(scope: ast.scope_node)

    local prototypes = ""
    local statementsCode = ""
    local leafParsers = {}  -- non-leaf parsers
    local parentParsers = {}

    for _,stat in scope.stats do

        if stat.kind == 'syntax' then

            local array = arrayfyPath(stat.path)
            for i = 1, math.floor(#array / 2) do
                
                array[i], array[#array-i+1] = array[#array-i+1], array[i]
            end
            
            local fullName
            for index, name in array do
                
                fullName = if index == 1 then name
                    else `{name}_{fullName}`
                parentParsers[fullName] = true
            end
            leafParsers[fullName] = array
            statementsCode ..= transpileLeafParser(stat)
        end
    end
    for fullName in parentParsers do prototypes ..= `, parse_{fullName}` end
    return `local _{prototypes}\n`
        .. `{statementsCode}\n`
        .. `{transpileParentParser('node', 'node', treefy(leafParsers))}`
end

type parserSymbol = { def: ast.parser_def_node }
return transpileScope