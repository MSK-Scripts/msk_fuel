Translate = function(key, ...)
    -- Fall back to english, then to the raw key, so a missing entry never errors out.
    local str = (Translation[Config.Locale] and Translation[Config.Locale][key])
        or (Translation['en'] and Translation['en'][key])

    if not str then
        return key
    end

    if ... then
        return str:format(...)
    end

    return str
end

Translation = {
    ['de'] = {
        -- General
        ['no_permission'] = 'Du hast keine Berechtigung diesen Befehl zu nutzen!',
        ['not_inside_vehicle'] = 'Du musst in einem Fahrzeug sitzen!',
        ['not_enough_money'] = 'Du hast nicht genug Geld dabei!',
        ['cannot_carry_petrolcan'] = 'Du hast nicht genug Platz um den Kanister zu tragen!',
        ['petrolcan_not_equipped'] = 'Du musst einen Kanister in der Hand halten!',
        ['petrolcan_not_enough_fuel'] = 'Dein Kanister hat nicht genug Sprit!',

        -- Main Thread
        ['vehicle_does_not_exist'] = 'Das Fahrzeug existiert nicht mehr, tanken wurde abgebrochen.',
        ['vehicle_too_far_away_from_station'] = 'Das Fahrzeug ist zu weit von der Zapfsäule entfernt, tanken wurde abgebrochen.',
        ['too_far_away_from_vehicle'] = 'Du bist zu weit vom Fahrzeug entfernt, tanken wurde abgebrochen.',
        ['too_far_away_from_station'] = 'Du bist zu weit von der Zapfsäule entfernt, tanken wurde abgebrochen.',

        -- Vehicle
        ['vehicle_get_fuel_type'] = 'Prüfe Spritart',
        ['vehicle_fuel_type'] = 'Dein Fahrzeug benötigt %s',
        ['fuel_vehicle'] = 'Tanke das Fahrzeug',
        ['fuel_vehicle_type'] = 'Tanke das Fahrzeug mit %s...',
        ['vehicle_tank_full'] = 'Der Tank des Fahrzeugs ist voll.',
        ['wrong_fuel'] = 'Dein Fahrzeug benötigt %s!',
        ['vehicle_fuel_success'] = 'Du hast das Fahrzeug auf %sL für $%s aufgetankt.',
        ['fuel_not_compatible'] = 'Du kannst dein Fahrzeug nicht mit Strom tanken!',
        ['fuel_electric_not_compatible'] = 'Du kannst dein Elektrofahrzeug nicht mit %s tanken!',

        -- Fuel Station
        ['fuel_station_blip'] = 'Tankstelle',
        ['fuel_gas'] = 'Zapfpistole - Benzin',
        ['fuel_diesel'] = 'Zapfpistole - Diesel',
        ['fuel_electric'] = 'Zapfpistole - Elektro',
        ['fuel_kerosin'] = 'Zapfpistole - Kerosin',
        ['petrolcan_refill'] = 'Kanister auffüllen',
        ['petrolcan_buy'] = 'Kanister kaufen',
        ['take_nozzle'] = 'Zapfpistole nehmen',
        ['return_nozzle'] = 'Zapfpistole zurück stecken',
        ['bought_petrolcan'] = 'Du hast einen Kanister für $%s gekauft.',
        ['refilled_petrolcan'] = 'Du hast deinen Kanister für $%s aufgefüllt.',

        -- Fuel Types
        ['gas'] = 'Benzin',
        ['diesel'] = 'Diesel',
        ['electric'] = 'Elektro',
        ['kerosin'] = 'Kerosin',
        ['petrolcan'] = 'Kanister',
    },
    ['en'] = {
        -- General
        ['no_permission'] = 'You do not have permission to use this command!',
        ['not_inside_vehicle'] = 'You must be sitting in a vehicle!',
        ['not_enough_money'] = 'You do not have enough money on you!',
        ['cannot_carry_petrolcan'] = 'You do not have enough space to carry the petrolcan!',
        ['petrolcan_not_equipped'] = 'You must be holding a petrolcan in your hand!',
        ['petrolcan_not_enough_fuel'] = 'Your petrolcan does not have enough fuel!',

        -- Main Thread
        ['vehicle_does_not_exist'] = 'The vehicle no longer exists, refueling has been cancelled.',
        ['vehicle_too_far_away_from_station'] = 'The vehicle is too far away from the fuel pump, refueling has been cancelled.',
        ['too_far_away_from_vehicle'] = 'You are too far away from the vehicle, refueling has been cancelled.',
        ['too_far_away_from_station'] = 'You are too far away from the fuel pump, refueling has been cancelled.',

        -- Vehicle
        ['vehicle_get_fuel_type'] = 'Check fuel type',
        ['vehicle_fuel_type'] = 'Your vehicle requires %s',
        ['fuel_vehicle'] = 'Refuel the vehicle',
        ['fuel_vehicle_type'] = 'Refueling the vehicle with %s...',
        ['vehicle_tank_full'] = 'The vehicle\'s tank is full.',
        ['wrong_fuel'] = 'Your vehicle requires %s!',
        ['vehicle_fuel_success'] = 'You refueled the vehicle to %sL for $%s.',
        ['fuel_not_compatible'] = 'You cannot refuel your vehicle with electricity!',
        ['fuel_electric_not_compatible'] = 'You cannot charge your electric vehicle with %s!',

        -- Fuel Station
        ['fuel_station_blip'] = 'Fuel Station',
        ['fuel_gas'] = 'Nozzle - Gas',
        ['fuel_diesel'] = 'Nozzle - Diesel',
        ['fuel_electric'] = 'Nozzle - Electric',
        ['fuel_kerosin'] = 'Nozzle - Kerosin',
        ['petrolcan_refill'] = 'Refill Petrolcan',
        ['petrolcan_buy'] = 'Buy Petrolcan',
        ['take_nozzle'] = 'Take Nozzle',
        ['return_nozzle'] = 'Return Nozzle',
        ['bought_petrolcan'] = 'You bought a petrolcan for $%s.',
        ['refilled_petrolcan'] = 'You refilled your petrolcan for $%s.',

        -- Fuel Types
        ['gas'] = 'Gas',
        ['diesel'] = 'Diesel',
        ['electric'] = 'Electric',
        ['kerosin'] = 'Kerosin',
        ['petrolcan'] = 'Petrolcan',
    },
}
