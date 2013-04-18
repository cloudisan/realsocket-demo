express = require("express")
url = require('url')
qs = require('querystring')
app = express()
utils = require('./lib/client/serve/utils')
system = require('./lib/client/system')
app.use express.static(__dirname + "/public")
ss = require('./lib/socketstream')

#asset = require('./lib/client/asset')(ss, options)

ss.client.define('main',
  view: 'app.html',
  css:  ['libs/reset.css', 'app.styl'],
  code: ['libs/jquery.min.js', 'app'],
  tmpl: '*'
);


# Serve system libraries and modules
app.get '/_serveDev/system?*', (request, response) ->
  utils.serve.js(system.serve.js(), response)

# Listen for requests for application client code
app.get '/_serveDev/code?*', (request, response) ->
  thisUrl = url.parse(request.url)
  params = qs.parse(thisUrl.query)
  path = utils.parseUrl(request.url)
  asset.js path, {pathPrefix: params.pathPrefix}, (output) ->
    utils.serve.js(output, response)

app.get '/_serveDev/start?*', (request, response) ->
  utils.serve.js(system.serve.initCode(), response)

# CSS

# Listen for requests for CSS files
###
app.get '/_serveDev/css?*', (request, response) ->
  path = utils.parseUrl(request.url)
  asset.css path, {}, (output) ->
    utils.serve.css(output, response)
###

server = app.listen 3001
ss.start server

console.log "Express started on port 3000"