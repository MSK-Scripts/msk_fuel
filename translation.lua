Translate = function(locale, ...)
    if ... then
        return Translation[Config.Locale][locale]:format(...)
    end
    
    return Translation[Config.Locale][locale]
end

Translation = {
    ['de'] = {
        -- General
        ['no_permission'] = 'Du hast keine Berechtigung diesen Befehl zu nutzen!',
        ['not_inside_vehicle'] = 'Du musst in einem Fahrzeug sitzen!',
        ['not_enough_money'] = 'Du hast nicht gennug Geld dabei!',
        ['cannot_carry_petrolcan'] = 'Du hast nicht genug Platz um den Kanister zu tragen!',
        ['petrolcan_not_enough_fuel'] = 'Dein Kanister hat nicht genug Sprit!',
        
        -- Vehicle
        ['vehicle_get_fuel_type'] = 'Prüfe Spritart',
        ['vehicle_fuel_type'] = 'Dein Fahrzeug benötigt %s',
        ['fuel_vehicle'] = 'Tanke das Fahrzeug',
        ['fuel_vehicle_type'] = 'Tanke das Fahrzeug mit %s...',
        ['vehicle_tank_full'] = 'Der Tank des Fahrzeugs ist voll.',
        ['wrong_fuel'] = 'Dein Fahrzeug benötigt %s!',
        ['vehicle_fuel_success'] = 'Du hast das Fahrzeug auf %sL für $%s aufgetankt.',
        ['fuel_not_compatible'] = 'Du kannst dein Fahrzeug nicht mit Strom tanken!',
        ['fuel_electro_not_compatible'] = 'Du kannst dein Elektrofahrzeug nicht mit %s tanken!',
        
        -- Fuel Station
        ['fuel_station_blip'] = 'Tankstelle',
        ['fuel_gas'] = 'Nehme Zapfpistole - Benzin',
        ['fuel_diesel'] = 'Nehme Zapfpistole - Diesel',
        ['fuel_electro'] = 'Nehme Zapfpistole - Elektro',
        ['fuel_kerosin'] = 'Nehme Zapfpistole - Kerosin',
        ['petrolcan_refill'] = 'Kanister auffüllen',
        ['petrolcan_buy'] = 'Kanister kaufen',
        ['take_nozzle'] = 'Zapfpistole nehmen',
        ['return_nozzle'] = 'Zapfpistole zurück stecken',
        ['bought_petrolcan'] = 'Du hast einen Kanister für $%s gekauft.',
        ['refilled_petrolcan'] = 'Du hast deinen Kanister für $%s aufgefüllt.',

        -- Fuel Types
        ['gas'] = 'Benzin',
        ['diesel'] = 'Diesel',
        ['electro'] = 'Elektro',
        ['kerosin'] = 'Kerosin',
        ['petrolcan'] = 'Kanister',
    },
    ['en'] = {
        -- General
        ['no_permission'] = 'Du hast keine Berechtigung diesen Befehl zu nutzen!',
        ['not_inside_vehicle'] = 'Du musst in einem Fahrzeug sitzen!',
        ['not_enough_money'] = 'Du hast nicht gennug Geld dabei!',
        ['cannot_carry_petrolcan'] = 'Du hast nicht genug Platz um den Kanister zu tragen!',
        ['petrolcan_not_enough_fuel'] = 'Dein Kanister hat nicht genug Sprit!',
        
        -- Vehicle
        ['vehicle_get_fuel_type'] = 'Prüfe Spritart',
        ['vehicle_fuel_type'] = 'Dein Fahrzeug benötigt %s',
        ['fuel_vehicle'] = 'Tanke das Fahrzeug',
        ['fuel_vehicle_type'] = 'Tanke das Fahrzeug mit %s...',
        ['vehicle_tank_full'] = 'Der Tank des Fahrzeugs ist voll.',
        ['wrong_fuel'] = 'Dein Fahrzeug benötigt %s!',
        ['vehicle_fuel_success'] = 'Du hast das Fahrzeug auf %sL für $%s aufgetankt.',
        ['fuel_not_compatible'] = 'Du kannst dein Fahrzeug nicht mit Strom tanken!',
        ['fuel_electro_not_compatible'] = 'Du kannst dein Elektrofahrzeug nicht mit %s tanken!',
        
        -- Fuel Station
        ['fuel_station_blip'] = 'Fuel Station',
        ['fuel_gas'] = 'Take Nozzle - Gas',
        ['fuel_diesel'] = 'Take Nozzle - Diesel',
        ['fuel_electro'] = 'Take Nozzle - Electro',
        ['fuel_kerosin'] = 'Take Nozzle - Kerosin',
        ['petrolcan_refill'] = 'Refill Petrolcan',
        ['petrolcan_buy'] = 'Buy Petrolcan',
        ['take_nozzle'] = 'Take Nozzle',
        ['return_nozzle'] = 'Return Nozzle',
        ['bought_petrolcan'] = 'Du hast einen Kanister für $%s gekauft.',
        ['refilled_petrolcan'] = 'Du hast deinen Kanister für $%s aufgefüllt.',

        -- Fuel Types
        ['gas'] = 'Gas',
        ['diesel'] = 'Diesel',
        ['electro'] = 'Electro',
        ['kerosin'] = 'Kerosin',
        ['petrolcan'] = 'Petrolcan',
    },
}