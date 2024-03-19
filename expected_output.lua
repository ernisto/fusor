--[[ GRAMMAR DEF
    syntax type_expr(name: token.identifier)
    syntax type_field.unnamed(type: type_expr)
    syntax type_field.named(
        name: token.identifier
        (isVariadic: '...')?
        (isOptional: '?')?
        ':'
        type: type_expr
    )
--]]
--[[ PARSERS TREE
    type_expr {
        tuple_type { type_expr[] }          -- recursive
        read_type { identifier ('.', identifier)[] params? }    -- maybe recursive
        str_type { content }

        variadic { type_expr '...' }
    }
    type_field {
        unnamed { type_expr }
        named {
            identifier
            ('named'? 'as' identifier)?
            '?'?
            '...'?
            ':'         -- discriminator
            type_expr
        }
    }
--]]
--[[ SYNTAX TREE
    identifier {
        'named' { 'as'... }
        'as' {
            identifier {
                '?', '...', ':'
            }
        }
        '?' { '...', ':'
            type_field.unnamed(type_expr.optional(type_expr.read_type()))
        }
        '...' { ':'
            type_field.unnamed(type_expr.variadic(type_expr.read_type()))
        }
        ':' {
            type_expr {
                type_field.named
            }
        }
        type_field.unnamed(type_expr.read_type())
    }
--]]
local kinds = {}

local function parse_type_field(tokens: {string}, cursor, token, kind)

    local token_1 = token or tokens[cursor]
    local kind_1 = kind or kinds[token_1]

    if kind_1 == 'word' then cursor += 1

        local token_2 = tokens[cursor]
        -- local kind_2 = kinds[token_2]

        -- named
        if token_2 == '...' then cursor += 1

            local token_3 = tokens[cursor]
            -- local kind_3 = kinds[token_3]

            if token_3 == ':' then cursor += 1

                return named{ name=token_1, isVariadic=true, type=parse_type_expr() }
            else

                warn(`missing ':'`)
            end
        elseif token_2 == '?' then cursor += 1

            local token_3 = tokens[cursor]
            -- local kind_3 = kinds[token_3]

            if token_3 == ':' then cursor += 1

                return named{ name=token_1, isVariadic=true, type=parse_type_expr() }
            else

                warn(`missing ':'`)
            end
        elseif token_2 == ':' then cursor += 1
            
            return named{ name=token_1, type=parse_type_expr() }
        else    -- unnamed
            if token == '<' then cursor += 1
                
                cursor += 1

                local types = {}
                repeat until false

                local token_3 = tokens[cursor]
                if token_3 ~= '>' then warn(`missing '>'`) end

                return unnamed(read_type(token_1), types)
            else

                return unnamed(read_type(token_1))
            end
        end
    end
end