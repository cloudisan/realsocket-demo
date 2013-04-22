# System Assets
# -------------
# Loads system libraries and modules for the client. Also exposes an internal API
# which other modules can use to send system assets to the client

fs = require('fs')
pathlib = require('path')
uglifyjs = require('uglify-js')
coffee = require('coffee-script') if process.env['SS_DEV']

wrap = require('./wrap')
fsUtils = require('../utils/file')

# Allow internal modules to deliver assets to the browser
assets =
  libs:       []
  modules:    {}
  initCode:   []


# API to add new System Library or Module
exports.send = send = (type, name, content, options = {}) ->
  content = coffee.compile(content) if coffee && options.coffee
  switch type
    when 'code'
      assets.initCode.push(content)
    when 'lib', 'library'
      assets.libs.push({name: name, content: content, options: options})
    when 'mod', 'module'
      if assets.modules[name]
        #throw new Error("System module name '#{name}' already exists")
      else
        assets.modules[name] = {content: content, options: options}


# Load all system libs and modules
exports.load = ->
  # Load essential libs for backwards compatibility with all browsers
  # and to enable module loading. Note with libs, order is important!
  ['json.min.js', 'browserify.js', 'hogan.js'].forEach (fileName) ->
    path = pathlib.join(__dirname,fileName)
    code = fs.readFileSync(path, 'utf8')
    preMinified = fileName.indexOf('.min') >= 0
    send('lib', fileName, code, {minified: preMinified})

  # System Modules. Including main SocketStream client code
  # Load order is not important
  modDir = pathlib.join(__dirname, '/modules')
  fsUtils.readDirSync(modDir).files.forEach (fileName) ->
    code = fs.readFileSync(fileName, 'utf8')
    sp = fileName.split('.')
    extension = sp[sp.length-1]
    modName = fileName.substr(modDir.length + 1)
    send('mod', modName, code, {coffee: extension == 'coffee'})

  loadResponders('events', 'events-responder')
  loadResponders('rpc', 'socketstream-rpc')
  loadEngineIO()

###
# Load rpc && events
loadEvents ->
  # Serve client code
  filePath = '../request/responders/events/client.' + (process.env['SS_DEV'] && 'coffee' || 'js')
  filePath = pathlib.resolve(__dirname, filePath)
  code = fs.readFileSync(filePath, 'utf8')
  send('mod', 'events-responder', code, {coffee: process.env['SS_DEV']})

loadRPC ->
  filePath = '../request/responders/rpc/client.' + (process.env['SS_DEV'] && 'coffee' || 'js')
  filePath = pathlib.resolve(__dirname, filePath)
  code = fs.readFileSync(filePath, 'utf8')
  send('mod', 'socketstream-rpc', code, {coffee: process.env['SS_DEV']})
###

loadEngineIO = ->
  dir = "../websocket/transports/engineio/"
  loadFile('lib', "#{dir}client.js" , 'engine.io-client')
  loadFile('mod', "#{dir}wrapper.js" , 'socketstream-transport')

###
loadWrapper = ->
  ["wrapper", "client"].forEach(fileName) ->
    filePath = "../websocket/transports/engineio/#{fileName}.js"
    filePath = pathlib.resolve(__dirname, filePath)
    code = fs.readFileSync(filePath, 'utf8')
    send('mod', 'socketstream-transport', code)
###

loadResponders = (dir, name) ->
  file = "../request/responders/#{dir}/client." + (process.env['SS_DEV'] && 'coffee' || 'js')
  loadFile('mod', file, name)
  ###
  filePath = pathlib.resolve(__dirname, filePath)
  code = fs.readFileSync(filePath, 'utf8')
  send('mod', name, code, {coffee: process.env['SS_DEV']})
###

#load some file
loadFile = (type, file, name) ->
  config = {coffee: process.env['SS_DEV']} if pathlib.extname(file) is '.coffee'
  file = pathlib.resolve(__dirname, file)
  code = fs.readFileSync(file, 'utf8')
  send(type, name, code, config)

# Serve system assets
exports.serve =

  js: (options = {}) ->
    # Libs
    output = assets.libs.map (code) ->
      options.compress && !code.options.minified && minifyJS(code.content) || code.content

    # Modules
    for name, mod of assets.modules
      code = wrap.module(name, mod.content)
      code = minifyJS(code) if options.compress && !mod.options.minified
      output.push(code)

    output.join("\n")

  initCode: ->
    assets.initCode.join(" ")


# Private

minifyJS = (originalCode) ->
  jsp = uglifyjs.parser
  pro = uglifyjs.uglify
  ast = jsp.parse(originalCode)
  ast = pro.ast_mangle(ast)
  ast = pro.ast_squeeze(ast)
  pro.gen_code(ast) + ';'