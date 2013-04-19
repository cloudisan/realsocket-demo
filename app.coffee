require('coffee-script')
{spawn, exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
express = require("express")
url = require('url')
qs = require('querystring')
app = express()
app.use express.static(__dirname + "/public")
ss = require('./lib/socketstream')
config = undefined
config = require('./server/config/dev')


ss.ws.transport.use "engineio",
  client:
    transports: [ "websocket", "htmlfile", "xhr-polling", "jsonp-polling" ]
  server: (io) ->
    io.set "log level", 4

###
ss.session.store.use "redis",
  host: config.redisSrv
  port: config.redisPort
  db: config.redisDb
###

ss.session.store.use 'mongo',
  host: config.mongoSrv,
  port: config.mongoPort,
  db: config.mongoDbName

ss.publish.transport.use "redis",
  host: config.redisSrv
  port: config.redisPort
  db: config.redisDb
  
# ## *launch*
#
# **given** string as a cmd
# **and** optional array and option flags
# **and** optional callback
# **then** spawn cmd with options
# **and** pipe to process stdout and stderr respectively
# **and** on child process exit emit callback if set and status is 0
launch = (cmd, options=[], callback) ->
  app = spawn cmd, options
  app.stdout.pipe(process.stdout)
  app.stderr.pipe(process.stderr)
  app.on 'exit', (status) -> callback?() if status is 0
  
app.post '/auto_deploy', (req, res) =>
  exec 'git pull origin develop && npm update && /etc/init.d/realsocket-demo stop && /etc/init.d/realsocket-demo start', (err) ->
    res.send err if err
    res.send 'the realsocket demo app has been deployed successfully...'
  
server = app.listen 3005
ss.start server

console.log "Express started on port 3005"