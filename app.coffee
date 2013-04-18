require('coffee-script') if process.env['SS_DEV']
express = require("express")
url = require('url')
qs = require('querystring')
app = express()
app.use express.static(__dirname + "/public")
ss = require('./lib/socketstream')
config = undefined
if (ss.env == 'production')
  config = require('./server/config/production')
else
  config = require('./server/config/dev')


ss.ws.transport.use "engineio",
  client:
    transports: [ "websocket", "htmlfile", "xhr-polling", "jsonp-polling" ]
  server: (io) ->
    io.set "log level", 4
    
ss.session.store.use "redis",
  host: config.redisSrv
  port: config.redisPort
  db: config.redisDb

ss.publish.transport.use "redis",
  host: config.redisSrv
  port: config.redisPort
  db: config.redisDb
  
server = app.listen 3001
ss.start server

console.log "Express started on port 3001"