
exec = require('child_process').exec
fs = require 'fs'
sysPath = require 'path'

task 'compile:coffee', ->

	unless fs.existsSync './scripts/js'

		fs.mkdirSync './scripts/js'

	exec 'node ./node_modules/coffee-script/bin/coffee -bco ./scripts/js ./scripts/coffee',

		(error) ->

			if fs.existsSync '-p'

				fs.rmdirSync '-p'

			if error?

				console.log 'Compile failed: ' + error

			else

				invoke 'browserify'

			return

task 'browserify', ->

	unless fs.existsSync './scripts/dist'

		fs.mkdirSync './scripts/dist'

	exec 'node ./node_modules/browserify/bin/cmd.js ./scripts/js/pages/page.js --path js --noparse=FILE --dg false -o ./scripts/dist/page.js',

		(error) ->

			if fs.existsSync '-p'

				fs.rmdirSync '-p'

			if error?

				console.log 'Compile failed: ' + error

			return

task 'build', ->

	invoke 'compile:coffee'