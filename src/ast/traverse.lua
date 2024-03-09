local function traverse_syntax(syntax, visitor)

    -- local params = syntax.params
    -- if params then traverse_type_params(params, visitor) end

    -- local body = syntax.type_tuple
    -- if body then traverse_type_tuple(body, visitor) end
end
local function traverse_stat(stat, visitor)

    local callback = visitor.stat
    if callback then callback() end

    local kind = stat.kind
    if kind == 'syntax' then traverse_syntax(visitor)
    end
end
local function traverse_scope(scope, visitor)

    for _,stat in scope.stats do

        traverse_stat(stat, visitor)
    end
end

return {
    traverse_scope = traverse_scope
}