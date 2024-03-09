local function treefy(syntaxes)

    local root = {}

    for name, tokens in syntaxes do
        
        local lastIndex = #tokens
        local branch = root

        for index, token in tokens do

            branch[token] = if index == lastIndex then name else branch[token] or {}
            branch = branch[token]
        end
    end
    return root
end

-- expr.biop.or_op      = expr '|' expr
-- expr.posop.optn_op   = expr '?'
-- expr.preop.not_op    = '!' expr
-- expr.atom.read       = identifier

local expr = {
    ['expr'] = {
        ['|'] = {
            ['expr'] = 'expr.biop.or_op',
        },
        ['?'] = 'expr.posop.optn_op'
    },
    ['!'] = {
        ['expr'] = 'expr.preop.not_op'
    },
    ['identifier'] = 'expr.atom.read'
}


local function pop(kind) return end
local function oarse_expr()
    
    local incomingExpr
    local lastExpr

    local function pushExpr(expr)

        if incomingExpr then incomingExpr.right = expr end
        return expr
    end
    repeat
        if lastExpr then
            
            if pop('?') then

                lastExpr = pushExpr{ kind = 'optn_op', left = lastExpr }
                -- lastExpr = nil
            
            elseif pop('|') then

                incomingExpr = pushExpr{ kind = 'or_op', left = lastExpr, right = 'incoming' }
                lastExpr = nil
            else
                
                break
            end
        elseif pop('!') then

            incomingExpr = pushExpr{ kind = 'not_op', right = 'incoming' }
            -- lastExpr = nil

        elseif pop('{') then

            incomingExpr = pushExpr{ kind = 'arr_op', right = 'incoming' }
            -- lastExpr = nil

        elseif pop('identifier') then

            lastExpr = pushExpr{ kind = 'read_type', name = 'identifier' }
        else

            if incomingExpr then lastExpr = incomingExpr end
            break
        end
    until false
    return lastExpr
end

local ast = oarse_expr()