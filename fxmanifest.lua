fx_version 'cerulean'
game 'gta5'

description 'mrc-template'
version '1.0.0'

shared_scripts {
	'shared/*.lua',
}

server_scripts {
    'server/*.lua',
}

client_scripts {
    'client/*.lua',
}

ui_page "html/index.html"

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
}

data_file 'DLC_ITYP_REQUEST' 'stream/mrc-cave.ytyp'

lua54 'yes'

