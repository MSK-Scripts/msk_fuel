# MSK Fuel
Fuel System for Vehicles

## Get Vehicle Fuel Level
Returns: int
```lua
fuelLevel = exports.msk_fuel:GetVehicleFuel(vehicle)

-- You can also use:
fuelLevel = Entity(entity).state.fuel
```

## Set Vehicle Fuel Level
```lua
exports.msk_fuel:SetVehicleFuel(vehicle, fuelAmount)

-- You can also use:
Entity(entity).state.fuel = fuelAmount
```

## Get Vehicle Fuel Type
Returns: string
```lua
fuelType = exports.msk_fuel:GetVehicleFuelType(vehicle)
```

## Repair Vehicle if refueled with the wrong fuel
```lua
exports.msk_fuel:SetEngineRepaired(vehicle)
```