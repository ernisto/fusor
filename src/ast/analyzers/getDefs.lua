return function(scope)

    local defs = {}

    for _,stat in scope.stats do

        if stat.kind == 'syntax' then table.insert(defs, stat) end
    end
    return defs
end