-- Run from the resource directory: lua tests/vehicle_state.lua
local function read(path)
    local file = assert(io.open(path, 'r'))
    local contents = file:read('*a')
    file:close()
    return contents
end

local events, callbacks, bag, writes, replies = {}, {}, {}, {}, {}
local owner = 7
local exists = true
local server = setmetatable({
    source = 7,
    exports = function() end,
    RegisterNetEvent = function(name, fn) events[name] = fn end,
    AddStateBagChangeHandler = function(key, _, fn) callbacks[key] = fn end,
    AddEventHandler = function(name, fn) events[name] = fn end,
    NetworkGetEntityFromNetworkId = function(id) return exists and id == 101 and 11 or 0 end,
    NetworkGetNetworkIdFromEntity = function(entity)
        assert(entity == 11, 'The entity must still exist before resolving its network ID')
        return 101
    end,
    DoesEntityExist = function(entity) return entity == 11 end,
    GetEntityType = function() return 2 end,
    NetworkGetEntityOwner = function() return owner end,
    TriggerClientEvent = function(name, player, netId, value)
        replies[#replies + 1] = {player, value, event = name, netId = netId}
    end,
    Entity = function()
        return {state = setmetatable({set = function(_, key, value, replicated)
            assert(replicated, 'The server must publish accepted changes')
            bag[key] = value
            writes[#writes + 1] = key
        end}, {__index = bag})}
    end,
}, {__index = _G})
assert(loadfile('server/functions.lua', 't', server))()
local update = assert(events['msk_fuel:setVehicleState'])

update(101, 'fuel', 70.0)
assert(server.GetVehicleFuel(101) == 70.0)
update(101, 'fuel', 65.0)
assert(server.GetVehicleFuel(101) == 65.0)
assert(#replies == 0, 'Consumption must not send a stale correction to the owner')
update(101, 'fuel', 90.0)
assert(server.GetVehicleFuel(101) == 65.0 and replies[#replies][2] == 65.0)
server.SetVehicleFuel(101, 90.0)
assert(server.GetVehicleFuel(101) == 90.0, 'Server-authorized refills must still work')

for _, key in ipairs({'isFueling', 'nozzleAttached', 'engineFailure', 'consumFuel'}) do
    update(101, key, true)
    assert(bag[key] == true)
    update(101, key, false)
    assert(bag[key] == false)
    update(101, key, nil)
    assert(bag[key] == nil)
end
update(101, 'maxFuel', 120.0)
update(101, 'fuelType', 'diesel')
update(101, 'isFuelingType', 'gas')
update(101, 'isFuelingTypeValue', 10)
assert(bag.maxFuel == 120.0 and bag.fuelType == 'diesel' and bag.isFuelingTypeValue == 10)
update(101, 'isFuelingType', nil)
update(101, 'isFuelingTypeValue', nil)
assert(bag.isFuelingType == nil and bag.isFuelingTypeValue == nil)

local count = #writes
for _, value in ipairs({-1, math.huge, 0/0, '50', false, {}}) do
    update(101, 'fuel', value)
    update(101, 'maxFuel', value)
end
update(101, 'maxFuel', 0)
update(101, 'maxFuel', nil)
update(101, 'fuelType', 'unknown')
update(101, 'isFueling', 'true')
update(101, 'unrelatedResourceKey', true)
update(999, 'fuel', 20)
update('101', 'fuel', 20)
update(math.huge, 'fuel', 20)
assert(#writes == count, 'Invalid keys, values and entities must not publish')
owner = 8
for _, key in ipairs({'fuel', 'maxFuel', 'isFueling', 'isFuelingTypeValue'}) do update(101, key, 20) end
assert(#writes == count, 'Other clients must not change the vehicle state')

exists = false
local replyCount = #replies
update(101, 'fuel', -1)
update(101, 'unrelatedResourceKey', true)
update(65536, 'fuel', 20)
events.entityCreated(11)
assert(#replies == replyCount, 'Invalid requests must not schedule initialization')
update(101, 'fuel', 30)
update(101, 'maxFuel', 150)
assert(#writes == count and #replies == replyCount)
exists = true
events.entityCreated(0)
assert(#replies == replyCount, 'A removed entity must not trigger initialization')
events.entityCreated(11)
local request = replies[#replies]
assert(request.event == 'msk_fuel:syncVehicleState' and request[1] == owner and request.netId == 101,
    'After creation, ask the actual owner, not the earlier sender')
assert(#writes == count, 'Never replay buffered values into a newly created entity')
events.entityCreated(11)
assert(#replies == replyCount + 1, 'Pending initialization must be cleared')

local localBag, sent, handlers, nativeFuel, nativeMax = {}, {}, {}, 50.0, 100.0
local networked, controlled = true, false
local client = setmetatable({
    exports = function() end,
    Entity = function()
        return {state = setmetatable({set = function(_, key, value, replicated)
            assert(replicated == false, 'Client writes must work with strict mode enabled')
            localBag[key] = value
        end}, {__index = localBag})}
    end,
    DoesEntityExist = function() return true end,
    NetworkGetEntityIsNetworked = function() return networked end,
    NetworkHasControlOfEntity = function() return controlled end,
    NetworkGetNetworkIdFromEntity = function() return 101 end,
    NetworkGetEntityFromNetworkId = function() return 11 end,
    GetEntityFromStateBagName = function() return 11 end,
    IsEntityAVehicle = function() return true end,
    TriggerServerEvent = function(...) sent[#sent + 1] = {...} end,
    SetVehicleFuelLevel = function(_, value) nativeFuel = value end,
    GetVehicleFuelLevel = function() return nativeFuel end,
    SetVehicleHandlingFloat = function(_, _, _, value) nativeMax = value end,
    GetVehicleHandlingFloat = function() return nativeMax end,
    AddStateBagChangeHandler = function(key, _, fn) handlers[key] = fn end,
    RegisterNetEvent = function(name, fn) events[name] = fn end,
}, {__index = _G})
local state = read('client/state.lua')
assert(load(state:sub(1, assert(state:find('State.Player.Set =', 1, true)) - 1), 'state', 't', client))()
local functions = read('client/functions.lua')
assert(load(functions:sub(assert(functions:find('SetVehicleFuel = function', 1, true)),
    assert(functions:find('SetEngineFailure = function', 1, true)) - 1), 'exports', 't', client))()
local main = read('client/main.lua')
local handlerStart = assert(main:find('AddStateBagChangeHandler("fuel"', 1, true))
assert(load(main:sub(handlerStart), 'handlers', 't', client))()
local eventStart = assert(main:find("RegisterNetEvent('msk_fuel:setVehicleFuel'", 1, true))
local eventEnd = assert(main:find("RegisterNetEvent('msk_fuel:setVehicleRepaired'", eventStart, true))
assert(load(main:sub(eventStart, eventEnd - 1), 'fuel-event', 't', client))()

client.SetVehicleFuel(11, 37.5)
assert(client.GetVehicleFuel(11) == 37.5 and nativeFuel == 37.5 and #sent == 1)
client.SetVehicleMaxFuel(11, 120.0)
assert(client.GetVehicleMaxFuel(11) == 120.0 and nativeMax == 120.0 and #sent == 2)
handlers.fuel('entity:101', 'fuel', 80.0)
handlers.maxFuel('entity:101', 'maxFuel', 150.0)
assert(nativeFuel == 80.0 and nativeMax == 150.0 and #sent == 2, 'Incoming state must not echo')
handlers.fuel('entity:101', 'fuel', 0/0)
handlers.maxFuel('entity:101', 'maxFuel', math.huge)
assert(nativeFuel == 80.0 and nativeMax == 150.0)
controlled = true
nativeFuel = 79.5
handlers.fuel('entity:101', 'fuel', 80.0)
assert(nativeFuel == 79.5 and #sent == 2, 'Delayed consumption acknowledgements must not restore burned fuel')
events['msk_fuel:setVehicleFuel'](101, 60.0)
assert(client.GetVehicleFuel(11) == 60.0 and nativeFuel == 60.0 and #sent == 2)
events['msk_fuel:setVehicleFuel'](101, 100.0)
assert(nativeFuel == 100.0, 'Explicit server refills must still reach the owner')
networked = false
client.SetVehicleFuel(11, 25.0)
assert(client.GetVehicleFuel(11) == 25.0 and #sent == 2, 'Local vehicles must not send network requests')

networked = true
nativeFuel = 24.5
localBag.isFueling = false
localBag.unrelatedResourceKey = true
controlled = false
events['msk_fuel:syncVehicleState'](101)
assert(#sent == 2, 'A former owner must not send a snapshot')
controlled = true
events['msk_fuel:syncVehicleState'](101)
local snapshot = {}
for i = 3, #sent do
    assert(sent[i][1] == 'msk_fuel:setVehicleState' and sent[i][2] == 101)
    snapshot[sent[i][3]] = sent[i][4]
end
assert(#sent == 5 and snapshot.fuel == 24.5 and snapshot.maxFuel == 120.0 and snapshot.isFueling == false,
    'Initialization must preserve false, skip unset/unknown keys and report current consumption')
print('Vehicle state tests passed')
