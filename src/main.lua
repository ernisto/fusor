--!optimize 2
--!native

local fs = require("@lune/fs")
local display = require('display')
local color = require('../utils/color')

local lexer = require('token/lexer')
local stream = require('token/stream')
local setupParser = require('ast/parser')
local transpile = require('ast/transpiler/transpile')

--// functions
local function timing(secs)

    local critical, fair = ('%.7f'):format(secs):match("(%d.%d%d)(%d+)")
    local isOk = secs < 0.010

    return (if isOk then color.white(critical) else color.red(critical))
        .. color.blue(fair)
end

--// run
local source = fs.readFile('syntax.txt')
local a = os.clock()
local tokens = lexer.scanAll(source)
local b = os.clock()

print(`scanned {color.yellow(#tokens)} tokens in {timing(b - a)}`)

local tokenStream = stream(tokens)
local parser = setupParser(tokenStream)

local c = os.clock()
local ast = parser.scope()
local d = os.clock()

print(`syntaxes {display(ast.stats)}`)
print(`parsed {color.yellow(tokenStream.getCursor())}/{color.dark_yellow(#tokens)} tokens in {timing(d - c)}`)
print(color.red("fail on ")
    ..color.dark_red(`token#{tokenStream.getCursor()}(`)
    ..color.blue(`'{tokenStream.peek()}'`)
    ..color.dark_red(')')
    ..color.red(' at ')
    ..color.white(tokenStream.getPosition())
)

local e = os.clock()
local outSource = transpile(ast)
local f = os.clock()
print(`transpiled in {timing(f - e)}`)

fs.writeFile('out.lua', outSource)
return nil