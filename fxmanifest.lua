fx_version 'cerulean'
game 'gta5'

description 'Alpha Dispatch System for Boss'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/movable.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/sounds/*.wav'
}

lua54 'yes'