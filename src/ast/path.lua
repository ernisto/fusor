--!optimize 2
--!native
local ast = require('.')

--// Functions
local function arrayfyPath(path: ast.path_node): {string}

    local array = {}
    local node = path

    while node do

        table.insert(array, 1, node.name)
        node = node.base
    end
    return array
end
local function getFullPathName(path: ast.path_node): string
    
    local fullname = path.name
    local root = path

    while root.kind == 'read_prop' do

        root = root.base
        fullname ..= `_{root.name}`
    end
    return fullname
end
return table.freeze{ arrayfy = arrayfyPath, getFullName = getFullPathName }