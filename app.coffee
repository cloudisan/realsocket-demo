require('coffee-script') if process.env['SS_DEV']
express = require("express")
url = require('url')
qs = require('querystring')
app = express()
app.use express.static(__dirname + "/public")
ss = require('./lib/socketstream')


server = app.listen 3001
ss.start server

console.log "Express started on port 3001"