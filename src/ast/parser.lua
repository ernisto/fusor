--!optimize 2
--!native

return function(stream)
    
    local getPosition = stream.getPosition
    local backpoint = stream.backpoint
    local popToken = stream.popToken
    local popRaw = stream.popRaw
    local peek = stream.peek

    local tokens = {}
    local errors = {}

    --// utils
    local function report(message: string)

        local parser = debug.info(2, 'n')
        local position = getPosition()

        if not errors[position] then return end
        errors[position] = `{parser}:{position}: {message}, got {peek()}`
    end
    local function token(data: { kind: string })

        table.insert(tokens, data)
        return data
    end

    --// parsers
    local type_expr

    local function binding(value_expr: () -> {})

        local name = popToken('word')
        if not name then return end

        local rename = if popRaw('as')
            then popToken('word') or report(`identifier expected`) else nil

        local isVariadic = popRaw('...')
        local isOptional = popRaw('?')

        local isStrict = popRaw(':')
        local type = isStrict and type_expr()

        local default = if popRaw('=')
            then value_expr() or report(`value expected`) else nil

        return token{ kind = 'binding',
            name = name,
            rename = rename,
            isVariadic = isVariadic,
            isOptional = isOptional,
            isStrict = isStrict,
            type = type,
            default = default,
        }
    end
    
    local function read_var()

        local name = popToken('word')
        if not name then return end

        return token{ kind = 'read_var',
            name = name,
        }
    end
    local function read_prop()

        if not popRaw('.') then return end
        local name = popToken('word') or report('read_prop.name: word expected')

        return token{ kind = 'read_prop',
            name = name,
        }
    end
    local function read_path()

        local base = read_var()
        repeat
            local op = read_prop()
            if not op then break end

            op.base = base
            base = op
        until false

        return base
    end

    local function type_field_frag()
        
        local rollback = backpoint()

        local name = popToken('word')
        if not name then return end
        
        local isVariadic = popRaw('...')
        local isOptional = if not isVariadic then popRaw('?') else nil

        if not popRaw(':') then return rollback() end
        return { name, isVariadic, isOptional }
    end
    local function type_field()

        local name, isVariadic, isOptional = unpack(type_field_frag() or {})
        local type = type_expr()

        if not type and not name then return end
        if not type then report(`type_expr expected`) end

        return token{ kind='type_field',
            name = name,
            isVariadic = isVariadic,
            isOptional = isOptional,
            type = type,
        }
    end
    local function type_params_def()

        if not popRaw('<') then return end

        local params = {}
        repeat
            local param = binding(type_expr)
            if not param then break end

            popRaw(',')
            table.insert(params, param)
        until false
        local _1 = popRaw('>') or report(`'>' expected`)

        return token{ kind='type_params_def',
            params = params
        }
    end
    local function type_params()

        if not popRaw('<') then return end

        local params = {}
        repeat
            local param = type_field()
            if not param then break end

            popRaw(',')
            table.insert(params, param)
        until false
        local _1 = popRaw('>') or report(`'>' expected`)

        return token{ kind='type_params',
            params = params
        }
    end
    local function type_tuple()

        if not popRaw('(') then return end

        local fields = {}
        repeat
            local field = type_field()
            if not field then break end

            popRaw(',')
            table.insert(fields, field)
        until false
        local _1 = popRaw(')') or report(`')' expected`)

        return token{ kind = 'type_tuple',
            fields = fields,
        }
    end
    local function read_type()

        local path = read_path()
        if not path then return end

        local params = type_params()

        return token{ kind='read_type',
            params = params,
            path = path,
        }
    end
    local function type_string()

        local str = popToken('string')
        if not str then return end

        return token{ kind='type_string',
            content = string.sub(str, 2, -2)
        }
    end
    local function type_atom()

        return read_type()
            or type_string()
            or type_tuple()
    end

    local function optional_type()

        if not popRaw('?') then return end
        return token{ kind = 'optional_type' }
    end
    local function variadic_type()

        if not popRaw('...') then return end
        return token{ kind = 'variadic_type' }
    end
    local function array_type()

        if not popRaw('[') then return end
        -- local bound = range()
        local _1 = popRaw(']') or report(`']' expected`)

        return token{ kind='array_type',
            -- bound = bound,
        }
    end
    local function type_suffix()

        return optional_type()
            or variadic_type()
            or array_type()
    end

    local function type_expr1()

        local base = type_atom()
        if popRaw('|') then
    
            local operand = type_expr1() or report(`type_expr expected`)
            return token{ kind = 'type_or',
                base = base, operand = operand
            }
        end
        return base
    end
    function type_expr()

        local base = type_expr1()
        
        local suffix = type_suffix()
        if not suffix then return base end

        suffix.base = base
        return suffix
    end

    local function syntax_def()

        if not popRaw('syntax') then return end

        local path = read_path()
        local params = type_params_def()
        local body = type_tuple() or report(`'(' expected`)

        return token{ kind = 'syntax',
            path = path,
            params = params,
            body = body,
        }
    end
    local function def()

        return syntax_def()
    end

    local function stat()

        return def()
    end
    local function scope()

        local sta = stat()
        local stats = {sta}

        while sta do popRaw(';')

            sta = stat() or report(`stat expected`)
            table.insert(stats, sta)
        end
        return token{ kind='scope',
            stats = stats
        }
    end

    --// End
    return {
        errors = errors,
        type_tuple = type_tuple,
        path = read_path,
        scope = scope,
    }
end