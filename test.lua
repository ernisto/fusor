local fs = require('@lune/fs')

local function runTest(test)

    local success, err = test()
end
local function runTests(tests: { [string]: () -> () })
    
    if typeof(tests) == 'table' then


    end
end

local function scanTests(dir: string, name)
    
    if fs.isFile(dir) and name:match("%.spec%.lua$") then

        runTests(require(dir))

    elseif fs.isDir(dir) then

        for _,name in fs.readDir(dir) do

            scanTests(`{dir}/{name}`, name)
        end
    end
end
-- scanTests('.')

require('src/ast/analyzers/syntax_tree/.spec')