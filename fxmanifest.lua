fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_fuel'
description 'Fuel System for Vehicle'
version '1.0.0'

lua54 'yes'

shared_script {
	'@msk_core/import.lua',
	'translation.lua',
    'config.lua',
	'config.*.lua',
}

client_scripts {
	'client/**/*.*'
}

server_scripts {
	'server/**/*.*'
}

dependencies {
	'msk_core',
	'ox_target',
	'ox_inventory',
}