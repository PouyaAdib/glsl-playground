http = require 'http'
path = require 'path'
mime = require 'mime'
cson = require 'cson'
fs = require 'graceful-fs'

module.exports = class Server

	constructor: () ->

		@_defineVars()

	serve: () ->

		port = if process.argv[2] isnt undefined then process.argv[2] else 9001

		@_createServer port

	_defineVars: () ->

		@_rootDir = path.resolve path.dirname(module.filename), '../../../'
		@_repPattern = /\\/g
		@_playgroundPath = process.cwd()

	_createServer: (port) ->

		http.createServer((req, res) =>

			@_serve req.url, res
			res.end()

		).listen port

		console.log "listening to localhost:#{port}"

	_serve: (uri, res) ->

		uri = uri.substr 1, uri.length

		if uri is ''

			@_writeResponse res, 'html', @_printPlaygroundList()

		else if m = uri.match /^\?getPlaygroundConfig\=([a-zA-Z0-9\_\s\-\.]+)/

			@_getPlaygroundConfig res, m[1]

		else if uri.match /^[a-zA-Z0-9\_\-\.\s]+\/$/

			@_writeResponse res, 'html', fs.readFileSync(path.join(@_rootDir, 'html/index.html'))

		else

			@_serveFile res, uri

		return

	_writeResponse: (resObject, ext = 'txt', res) ->

		resObject.writeHead 200,'Content-Type': mime.lookup(ext)
		resObject.write res

		return

	_printPlaygroundList: ->

		list = @_getPlaygroundsList()

		ret = ''

		for name in list

			ret += "<a href='/#{name}/'>#{name}</a><br>"

		ret

	_getPlaygroundsList: ->

		list = []

		for name in fs.readdirSync @_playgroundPath

			if path.extname(name) is '.cson' then list.push name.substr(0, name.length - 5)

		list

	_getPlaygroundConfig: (res, name) ->

		name += ".cson"

		file = path.resolve @_playgroundPath, name

		if fs.existsSync file

			content = fs.readFileSync file, encoding: 'utf-8'

			json = cson.parseSync content

			files = @_getFileListReq @_playgroundPath

			json.updateTime = @_getUpdateTimeForFiles files

			@_addResourcesListToJson json, @_playgroundPath, files

			@_writeResponse res, 'json', JSON.stringify(json)

		else

			res.writeHead 404

			console.log "playground #{name} doesn't exist"

			return

	_serveFile: (res, uri) ->

		uri = uri.replace /\.\./g, ''

		if uri is 'scripts/dist/page.js'

			p = path.join @_rootDir, 'scripts/dist/page.js'

		else

			p = path.join @_playgroundPath, uri

		if fs.existsSync p

			try

				@_writeResponse res, p, fs.readFileSync(p)

			catch e

				console.error uri, e

				res.writeHead 404

		else

			res.writeHead 404

		return

	_getFileListReq: (dir) ->

		list = []

		for file in fs.readdirSync dir

			p = path.resolve dir, file

			if fs.statSync(p).isDirectory()

				for item in @_getFileListReq p

					list.push item

			else

				list.push p

		list

	_getUpdateTimeForFiles: (files) ->

		biggest = 0

		for file in files

			stat = fs.statSync file

			t = stat.mtime.getTime()

			if t > biggest then biggest = t

		biggest

	_addResourcesListToJson: (json, dir, files) ->

		json.textures = textures = {}
		json.fragShaders = fragShaders = {}
		json.vertShaders = vertShaders = {}

		for file in files

			p = file.substr(dir.length + 1, file.length).replace(@_repPattern, '/')

			if p.substr(0, 8) is 'shaders/'

				filename =  p.substr(8, p.length)
				ext =  path.extname filename

				if ext is '.frag'

					fragShaders[filename.substr(0, filename.length - ext.length)] = fs.readFileSync file, encoding: 'utf-8'

				else if ext is '.vert'

					vertShaders[filename.substr(0, filename.length - ext.length)] = fs.readFileSync file, encoding: 'utf-8'

			else if p.substr(0, 9) is 'textures/'

				filename =  p.substr(9, p.length)
				ext =  path.extname filename

				if ext in ['.jpg', '.gif', '.png']

					textures[filename] = filename

		return