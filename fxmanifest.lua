fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_fuel'
description 'Fuel System for Vehicle'
version '1.2.0-beta.1'
license 'LGPL-3.0-or-later'

lua54 'yes'

ui_page 'html/index.html'

shared_script {
	'@msk_core/import.lua',
	'translation.lua',
	'config.lua',
	'config.*.lua',
	'shared/*.lua',
}

-- Written out instead of globbed: boot.lua depends on every other admin file
-- and has to load last, and the business modules have to exist before
-- server/main.lua uses them. A glob would order them alphabetically, which is
-- not the order they need. New files have to be added here or they never load.
client_scripts {
	'client/state.lua',
	'client/functions.lua',
	'client/business/sync.lua',
	'client/business/dashboard.lua',
	'client/business/delivery.lua',
	'client/fuel.lua',
	'client/target.lua',
	'client/main.lua',
	'client/admin/main.lua',
	'client/admin/nui.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/utils.lua',
	'server/functions.lua',
	'server/business/stations.lua',
	'server/business/pricing.lua',
	'server/business/stock.lua',
	'server/business/account.lua',
	'server/business/employees.lua',
	'server/business/ownership.lua',
	'server/business/payroll.lua',
	'server/business/supply.lua',
	'server/business/delivery.lua',
	'server/business/maintenance.lua',
	'server/business/owner_api.lua',
	'server/main.lua',
	'server/commands.lua',
	'server/versionchecker.lua',
	'server/admin/store.lua',
	'server/admin/permissions.lua',
	'server/admin/seed.lua',
	'server/admin/api.lua',
	'server/admin/command.lua',
	'server/admin/boot.lua',
}

files {
	'html/**/*.*',
}

dependencies {
	'msk_core',
	'ox_target',
	'ox_inventory',
	'oxmysql',
}
