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
        ['petrolcan_already_full'] = 'Dein Kanister ist bereits voll.',

        -- Fuel Business
        ['fuel_price_info'] = '%s kostet hier $%s pro Liter (%s).',
        ['station_sold_out'] = 'Diese Tankstelle hat kein %s mehr auf Lager.',
        ['station_no_petrolcan'] = 'Hier gibt es kein Benzin für Kanister.',
        ['no_dashboard_permission'] = 'Du hast keine Berechtigung für das Admin Dashboard.',
        ['station_buy'] = 'Tankstelle kaufen',
        ['station_manage'] = 'Tankstelle verwalten',
        ['station_bought'] = 'Du hast die Tankstelle %s gekauft.',
        ['station_sold'] = 'Du hast %s verkauft und $%s erhalten.',
        ['station_buy_failed'] = 'Diese Tankstelle steht nicht zum Verkauf.',
        ['station_no_access'] = 'Du hast keinen Zugriff auf diese Tankstelle.',
        ['hired_at_station'] = 'Du wurdest bei %s eingestellt.',
        ['fired_from_station'] = 'Du wurdest bei %s entlassen.',
        ['payroll_paid'] = 'Du hast $%s Gehalt von %s bekommen.',
        ['payroll_no_funds'] = 'Das Firmenkonto von %s reicht nicht für die Gehälter.',

        -- Supply
        ['restock_done'] = 'Du hast %s Liter für $%s nachbestellt.',
        ['delivery_depot'] = 'Sprit-Depot',
        ['delivery_public_take'] = 'Liefer-Auftrag annehmen',
        ['delivery_started'] = 'Fahr zum Depot: %s',
        ['delivery_loading'] = 'Sprit wird geladen...',
        ['delivery_loaded'] = '%s Liter geladen. Bring sie zu %s.',
        ['delivery_unloading'] = 'Sprit wird abgeladen...',
        ['delivery_done'] = 'Du hast %s Liter an %s geliefert.',
        ['delivery_done_public'] = 'Du hast %s Liter geliefert und $%s bekommen.',
        ['delivery_aborted'] = 'Der Liefer-Auftrag wurde abgebrochen.',
        ['delivery_timeout'] = 'Der Liefer-Auftrag hat zu lange gedauert und wurde abgebrochen.',
        ['delivery_vehicle_lost'] = 'Dein Lieferfahrzeug ist verschwunden.',
        ['delivery_vehicle_destroyed'] = 'Dein Lieferfahrzeug ist nicht mehr fahrbereit.',
        ['delivery_trailer_lost'] = 'Dein Anhänger ist verschwunden.',
        ['delivery_spawn_blocked'] = 'Hier ist kein Platz für das Lieferfahrzeug.',
        ['delivery_already_running'] = 'Du hast bereits einen Liefer-Auftrag.',
        ['delivery_public_failed'] = 'Dieser Auftrag ist gerade nicht verfügbar.',

        -- Maintenance
        ['pump_broken'] = 'Diese Zapfsäule ist defekt und muss repariert werden.',
        ['pump_repaired'] = 'Die Zapfsäule wurde für $%s repariert.',

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
        ['petrolcan_already_full'] = 'Your petrolcan is already full.',

        -- Fuel Business
        ['fuel_price_info'] = '%s costs $%s per liter here (%s).',
        ['station_sold_out'] = 'This fuel station has run out of %s.',
        ['station_no_petrolcan'] = 'There is no petrol for cans here.',
        ['no_dashboard_permission'] = 'You do not have permission to open the admin dashboard.',
        ['station_buy'] = 'Buy this fuel station',
        ['station_manage'] = 'Manage this fuel station',
        ['station_bought'] = 'You bought the fuel station %s.',
        ['station_sold'] = 'You sold %s and received $%s.',
        ['station_buy_failed'] = 'This fuel station is not for sale.',
        ['station_no_access'] = 'You have no access to this fuel station.',
        ['hired_at_station'] = 'You were hired at %s.',
        ['fired_from_station'] = 'You were let go from %s.',
        ['payroll_paid'] = 'You received $%s in wages from %s.',
        ['payroll_no_funds'] = 'The company account of %s cannot cover its wages.',

        -- Supply
        ['restock_done'] = 'You restocked %s liters for $%s.',
        ['delivery_depot'] = 'Fuel depot',
        ['delivery_public_take'] = 'Take a delivery job',
        ['delivery_started'] = 'Drive to the depot: %s',
        ['delivery_loading'] = 'Loading fuel...',
        ['delivery_loaded'] = 'Loaded %s liters. Take them to %s.',
        ['delivery_unloading'] = 'Unloading fuel...',
        ['delivery_done'] = 'You delivered %s liters to %s.',
        ['delivery_done_public'] = 'You delivered %s liters and earned $%s.',
        ['delivery_aborted'] = 'The delivery run was cancelled.',
        ['delivery_timeout'] = 'The delivery run took too long and was cancelled.',
        ['delivery_vehicle_lost'] = 'Your delivery vehicle is gone.',
        ['delivery_vehicle_destroyed'] = 'Your delivery vehicle is no longer driveable.',
        ['delivery_trailer_lost'] = 'Your trailer is gone.',
        ['delivery_spawn_blocked'] = 'There is no room for the delivery vehicle here.',
        ['delivery_already_running'] = 'You already have a delivery job.',
        ['delivery_public_failed'] = 'That job is not available right now.',

        -- Maintenance
        ['pump_broken'] = 'This pump is broken and has to be repaired.',
        ['pump_repaired'] = 'The pump was repaired for $%s.',

        -- Fuel Types
        ['gas'] = 'Gas',
        ['diesel'] = 'Diesel',
        ['electric'] = 'Electric',
        ['kerosin'] = 'Kerosin',
        ['petrolcan'] = 'Petrolcan',
    },
}
