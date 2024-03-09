local unnamed_type_field, named_type_field;

function type_expr(popRaw, popTok, report)
end
export type type_expr_node = {}


export type unnamed_node = {
    type: type_expr_node,
}
function unnamed_type_field(popRaw, popTok, report, _1)

    _1 = _1 or type_expr(popRaw, popTok, report)
    if _1 then

        return { kind = 'unnamed_type_field', type = _1,  }
    end
    return
end
export type named_node = {
    name: string,
    type: type_expr_node,
}
function named_type_field(popRaw, popTok, report, _1, _2, _3, _4, _5)

    _1 = _1 or popTok('identifier')
    if _1 then

        _2 = _2 or popRaw('...')
        _3 = _3 or popRaw('?')
        _4 = _4 or popRaw(':')
        _5 = _5 or type_expr(popRaw, popTok, report)
        return { kind = 'named_type_field', name = _1, type = _5,  }
    end
    return
end


function type_field(popRaw, popTok, report, backpoint, _1, _2, _3, _4, _5)

    local rollback = backpoint()

    _1 = _1 or popTok('identifier')
    if _1 then
        _2 = _2 or popRaw('...')
        _3 = _3 or popRaw('?')
        _4 = _4 or popRaw(':')
        if _4 then
            return named_type_field(popRaw, popTok, report, backpoint, _1, _2, _3, _4)
        else
            rollback()
            return unnamed_type_field(popRaw, popTok, report, backpoint)
        end
    end
    return
end

type_field()