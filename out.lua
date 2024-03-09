local _, parse_named_type_field, parse_type_expr, parse_type_field, parse_unnamed_type_field

export type type_expr_node = {
    name: string,
}
function parse_type_expr(popRaw, popTok, report, _1)
    if _1 == nil then _1 = popTok('identifier') end
    if _1 then
    return { kind = 'type_expr', name = _1 }
    end
    return
end
export type unnamed_type_field_node = {
    type: type_expr_node,
}
function parse_unnamed_type_field(popRaw, popTok, report, _1)
    if _1 == nil then _1 = parse_type_expr(popRaw, popTok, report) end
    if _1 then
    return { kind = 'unnamed_type_field', type = _1 }
    end
    return
end
export type named_type_field_node = {
    name: string,
    type: type_expr_node,
} & {
    isVariadic: '...',
} & {
    isOptional: '?',
}
function parse_named_type_field(popRaw, popTok, report, _1, _2, _3, _4, _5)
    if _1 == nil then _1 = popTok('identifier') end
    if _1 then
    if _2 == nil then _2 = popRaw('...') end
    if _3 == nil then _3 = popRaw('?') end
    if _4 == nil then _4 = popRaw(':'); if _4 == nil then report(`missing ':'`) end end
    if _5 == nil then _5 = parse_type_expr(popRaw, popTok, report); if _5 == nil then report(`missing type_expr_node`) end end
    return { kind = 'named_type_field', name = _1, isVariadic = _2, isOptional = _3, type = _5 }
    end
    return
end

export type node_node = name
function parse_node(popRaw, popTok, report)
    
    local incoming
    repeat
        if _1 then
            cavalo()
        else
            if incoming then _1 = incoming end
            break
        end
    until false
end
export type type_field_node_node = name
function parse_type_field_node(popRaw, popTok, report)
    
    local incoming
    repeat
        if _1 then
            cavalo()
        else
            if incoming then _1 = incoming end
            break
        end
    until false
end