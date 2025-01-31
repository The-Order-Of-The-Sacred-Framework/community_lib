fx_version 'cerulean'
game 'gta5'

description 'mrc-template'
version '1.0.0'

shared_scripts {
	'init.lua',
	'shared/*.lua',
}

server_scripts {
    'server/*.lua',
	'init.lua'
}

client_scripts {
    'client/*.lua',
	'init.lua'
}

ui_page "html/index.html"

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'shared/*.lua',
	'client/*.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/mrc-cave.ytyp'

lua54 'yes'

