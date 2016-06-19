fs = require('fs')
{basename,join} = require('path')
require('./polyfill')

extensions = [
  '.mp4'
  '.webm'
  '.3gp'
  '.mkv'
  '.m4v'
]

hints = {
  audio: [
    "_5.1"
    "quadraphonic"
    "_binaural"
  ]
  video: [
    "_2dp"
    "_3dpv"
    "_3dph"
    "180x180"
    "180x101"
    "180x101_3dh"
    "_mono360"
    "3dv"
    "_tb"
    "3dh"
    "_lr"
    "_cubemap"
    "_cubemap_tb"
    "_cubemap_lr"
    "_octahedron"
    "_icosahedron"
    "180x180_3dv"
    "180x180_3dh"
    "180x180_squished_3dh"
    "180x160_3dv"
    "180hemispheres"
    "180-hemispheres"
    "cylinder_slice_2x25_3dv"
    "cylinder_slice_16x9_3dv"
    "sib3d"
    "_planetarium"
    "_fulldome"
    "_v360"
    "_rtxp"
  ]
}

class TreeNode

  constructor: (@path, @parent, leaf) ->
    @name = basename(@path)
    @options = {}

    if leaf
      @children = null
    else
      @children = {}


  option: (type) ->
    if @options[type]?
      return @options[type]
    else if @parent?
      return @parent.option(type)
    else
      return null


load_options = (fn, node) ->
  # does it even exist?

  if not fs.existsSync(fn)
    return

  # parse

  data = fs.readFileSync(fn, {encoding: 'utf8'})
  entries = data.split('\n')

  # first line is video hint

  video = entries[0]?.trim()

  if video
    node.options.video = video

  # second line is audio hint

  audio = entries[1]?.trim()

  if video
    node.options.audio = audio


filename_hints = (node) ->
  # TODO: should we be able to deduct audio and video at same time?

  dot_index = node.name.lastIndexOf('.')
  name = node.name.substr(0, dot_index)

  for type, list of hints
    for hint in list
      if hint[0] == '_'
        hint_match = hint
      else
        hint_match = '_' + hint

      if name.endsWith(hint_match)
        node.options[type] = hint


find_thumbnail = (node) ->
  match_bases = [
    node.path
    # TODO: integrate replacing extension
    # TODO: integrate thumbnail folder ... how does it work?
  ]

  for match_base in match_bases
    for ext in ['.jpg', '.png']
      match = match_base + ext

      if fs.existsSync(match)
        node.options['thumbnail'] = match
        return

find_files = (fn, parent) ->
  stat = fs.statSync(fn)

  if stat.isDirectory()
    root = new TreeNode(fn, parent, false)

    # find children

    empty = true

    for file in fs.readdirSync(fn)
      child = find_files(join(fn, file), root)

      if child?
        root.children[child.name] = child
        empty = false

    # do not add empty

    if empty
      return null

    # read options

    load_options(join(fn, '.mvrlhint'), root)

    # done

    return root

  else if stat.isFile()
    for extension in extensions
      if fn.toLowerCase().endsWith(extension)
        node = new TreeNode(fn, parent, true)
        filename_hints(node)
        find_thumbnail(node)
        return node

  else
    return null


module.exports =
  find_files: find_files
