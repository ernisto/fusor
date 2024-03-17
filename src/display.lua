local color = require('../utils/color')
local stackColors = {
    color.yellow,
    color.green,
    color.dark_blue,
}

local function isArray(tab) return type(tab) == 'table' and type(next(tab)) == 'number' end
local function isToken(tab) return type(tab) == 'table' and rawget(tab, 'kind') end
local function isSyntaxNode(tab) return type(tab) == 'table' and rawget(tab, 'nextClauses') end


local function display(value, stack)

    stack = stack or {}
    table.insert(stack, value)

    local start = string.rep('   ', #stack)
    local stackColor = stackColors[1+ #stack % #stackColors]
    local out = color.blue(tostring(value))

    if isArray(value) then

        out = stackColor('[')

        for index, value in value do
            
            out ..= '\n'..start
                ..display(value, stack)
        end
        out ..= '\n'
            ..start:sub(1+3)
            ..stackColor(']')

    elseif isToken(value) then

        local nodes = {}
        out = color.pink(value.kind)
            ..stackColor('(')

        for index, value in value do

            if index == 'kind' then continue
            elseif type(value) == 'table' then
                
                nodes[index] = value
                continue
            end
            out ..= color.white(index)
                ..color.dark_red('=')
                ..color.blue(if type(value) == 'string' then `'{value}'` else tostring(value))
                ..color.dark_red(', ')
        end

        if next(nodes) then out ..= '\n' end
        for index, node in nodes do
            
            out ..= start
                ..color.bold(index)
                ..color.dark_red(' ')
                ..display(node, stack)
                ..'\n'
        end
        if next(nodes)
            then out ..= start:sub(1+3)
            else out = out:sub(1, -10)
        end
        out ..= stackColor(')')

    elseif isSyntaxNode(value) then
        
        local clauses = value.nextClauses
        out = stackColor('(')

        --// data
        for index, value in value do

            if index == 'kind' then continue end
            if index == 'nextClauses' then continue end

            out ..= color.white(index)
                ..color.dark_red('=')
                ..color.blue(display(value, stack))
                ..color.dark_red(', ')
        end

        --// clauses
        if next(clauses) then out ..= '\n' end
        for clause, node in clauses do
            
            out ..= start
                ..color.dark_red(`{if clause.checkKind then 'kind' else 'raw'} `)
                ..display(clause.checkRaw or clause.checkKind)
                ..' '
                ..display(node, stack)
                ..'\n'
        end
        if next(clauses)
            then out ..= start:sub(1+3)
            else out = out:sub(1, -10)
        end
        out ..= stackColor(')')

    elseif type(value) == 'string' then

        out = color.blue(`'{value}'`)
    end
    table.remove(stack)
    return out
end
return display