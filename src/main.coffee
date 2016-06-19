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


get_node = (coll, path) ->
  cur = nodes[coll]?[1]

  for step, i in path.split('/')
    if not cur?
      return null

    cur = cur.children[step]

  return cur


path_to_url_gen = (req, coll) ->
  url_base = req.protocol + '://' + req.get('host') + '/download/' + coll
  base_length = nodes[coll][1].path.length
  return (path) -> return url_base + path.substr(base_length)



app = express()

app.engine 'haml', require('haml-coffee').__express
app.set('views', './views')

app.get '/', (req, res) ->
  res.render('index.haml', {files: nodes})

# mvrl creation

app.get '/mvrl/:id/*', (req, res) ->
  coll = req.params.id
  route = req.params[0]

  node = get_node(coll, route)
  path_to_url = path_to_url_gen(req, coll)

  res.send(milkvr.create_mvrl(node, path_to_url))

app.get '/archive/:id/*', (req, res) ->
  coll = req.params.id
  route = req.params[0]

  node = get_node(coll, route)
  path_to_url = path_to_url_gen(req, coll)

  res.setHeader('Content-Disposition', contentDisposition(path.basename(node.path) + '.zip'))

  res.send(milkvr.create_archive(node, path_to_url))

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

