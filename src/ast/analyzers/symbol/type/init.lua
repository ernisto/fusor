local symbol = require('../init')
type symbol = symbol.symbol

export type type_symbol = symbol & {
    params: { type_symbol },
    kind: 'specific'|'tuple'|'function',
}
return function(type_node)

    return {

    }
end