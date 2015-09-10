require 'torch'

totem = {}

local ondemand = {nn = true}
local mt = {}

function mt.__index(table, key)
    if ondemand[key] then
        torch.include('totem', key .. '.lua')
        return totem[key]
    end
end

setmetatable(totem, mt)

torch.include('totem', 'asserts.lua')
torch.include('totem', 'Tester.lua')
torch.include('totem', 'TestSuite.lua')

return totem
