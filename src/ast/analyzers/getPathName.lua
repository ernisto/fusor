return function(path)

    local node = path
    while node.kind ~= 'read_var' do node = node.base end

    return node.name
end