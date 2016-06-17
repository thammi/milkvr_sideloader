express = require('express')
path = require('path')
os = require('os')
contentDisposition = require('content-disposition')

PORT = process.env.PORT or 8080

tree = require('./tree')
milkvr = require('./milkvr')

nodes = []

for arg in process.argv.slice(2)
  fn = path.resolve(arg)
  node = tree.find_files(fn)
  nodes.push([fn, node])


get_node = (path) ->
  cur = nodes

  for step, i in path.split('/')
    if i == 0
      cur = cur[step][1]
    else
      cur = cur.children[step]

    if not cur?
      return null

  return cur


download_url = (req, path) ->
  return req.protocol + '://' + req.get('host') + '/download/' + path


app = express()

app.engine 'haml', require('haml-coffee').__express
app.set('views', './views')

app.get '/', (req, res) ->
  res.render('index.haml', {files: nodes})

# mvrl creation

app.get '/mvrl/*', (req, res) ->
  route = req.params[0]
  node = get_node(route)
  download = download_url(req, route)
  res.send(milkvr.create_mvrl(node, download))

app.get '/archive/*', (req, res) ->
  route = req.params[0]
  node = get_node(route)
  download = download_url(req, route)

  res.setHeader('Content-Disposition', contentDisposition(path.basename(node.path) + '.zip'))

  res.send(milkvr.create_archive(node, download))

# download routes

for [name, node], index in nodes
  if node?
    app.use('/download/' + index, express.static(node.path))

# start listening

app.listen PORT, () ->
  console.log('Listening on port ' + PORT)
  console.log()
  console.log('Connect using one of the following URLs:')

  for name, entries of os.networkInterfaces()
    for entry in entries
      if entry.family == 'IPv6'
        address = '[' + entry.address + ']'
      else if entry.family == 'IPv4'
        address = entry.address

      console.log('- http://' + address + ':' + PORT + '/ (' + name + ')')

