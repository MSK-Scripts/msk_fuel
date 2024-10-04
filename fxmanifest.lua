fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_fuel'
description 'Fuel System for Vehicle'
version '0.0.1'

lua54 'yes'

shared_script {
	'@msk_core/import.lua',
	'@ox_lib/init.lua',
    'config.lua',
	'translation.lua'
}

client_scripts {
	'client/**/*.*'
}

server_scripts {
	'server/**/*.*'
}

dependencies {
	'ox_lib',
	'msk_core',
}