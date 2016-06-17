AdmZip = require('adm-zip')
{Promise} = require('bluebird')

create_mvrl = (node, path) ->
  video = node.option('video') or ''
  audio = node.option('audio') or ''
  thumbnail = ''

  return new Buffer([path, video, audio, thumbnail, ''].join('\n'))


insert_into_archive = (zip, node, path) ->
  if node.children?
    for name, child of node.children
      insert_into_archive(zip, child, path + '/' + name)

  else
    zip.addFile(node.name + '.mvrl', create_mvrl(node, path))


create_archive = (node, path) ->
  zip = new AdmZip()

  insert_into_archive(zip, node, path)

  return zip.toBuffer()


sideload_url = (node, path) ->


module.exports =
  create_mvrl: create_mvrl
  create_archive: create_archive
  sideload_url: sideload_url
