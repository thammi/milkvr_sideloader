AdmZip = require('adm-zip')
{Promise} = require('bluebird')

create_mvrl = (node, path_to_url) ->
  video = node.option('video') or ''
  audio = node.option('audio') or ''

  thumbnail = node.option('thumbnail') or ''

  if thumbnail
    thumbnail = path_to_url(thumbnail)

  return new Buffer([path_to_url(node.path), video, audio, thumbnail, ''].join('\n'))


insert_into_archive = (zip, node, path_to_url) ->
  if node.children?
    for name, child of node.children
      insert_into_archive(zip, child, path_to_url)

  else
    zip.addFile(node.name + '.mvrl', create_mvrl(node, path_to_url))


create_archive = (node, path_to_url) ->
  zip = new AdmZip()

  insert_into_archive(zip, node, path_to_url)

  return zip.toBuffer()


sideload_url = (node, path) ->


module.exports =
  create_mvrl: create_mvrl
  create_archive: create_archive
  sideload_url: sideload_url
