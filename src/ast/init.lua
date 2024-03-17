export type binding_node<expr = read_var_node> = { kind: 'binding',
    name: string,
    rename: string?,
    isOptional: '?'?,
    isVariadic: '...'?,
    isStrict: ':'?,
    default: expr?,
    type: expr?,
}

export type path_node = read_prop_node | read_var_node
export type read_prop_node = { kind: 'read_prop', base: path_node, name: string }
export type read_var_node = { kind: 'read_var', name: string }

export type type_node = read_type_node | type_tuple_node | type_string_node
export type read_type_node = { kind: 'read_type', path: path_node, params: type_params_node? }
export type type_tuple_node = { kind: 'type_tuple', fields: {type_field_node} }
export type type_string_node = { kind: 'type_string', content: string }

export type type_field_node = { kind: 'type_field',
    name: string?,
    isVariadic: '...'?,
    isOptional: '?'?,
    type: type_node,
}
export type type_params_node = { kind: 'type_params', params: {type_node|type_field_node}? }
export type type_params_def_node = { kind: 'type_param', params: {binding_node<type_node>} }

export type parser_def_node = { kind: 'syntax',
    path: path_node,
    params: type_params_def_node?,
    body: type_tuple_node,
}
export type stat_node = parser_def_node

export type scope_node = { kind: 'scope', stats: {stat_node} }
return nil