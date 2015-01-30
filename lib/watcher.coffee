fs = require 'fs'
path = require 'path'
_ = require 'lodash'
walk = require 'walk'

module.exports = (importer) ->
  
  checkNewFiles = (dir) ->
    walker = walk.walk(dir)

    walker.on 'file', (root, fileStat, next) ->
      fullPath = path.resolve(root, fileStat.name)
      fs.readFile fullPath, (buffer) ->
        importer.processFile fullPath, next

  start = (dir) ->
    checkNewFiles(dir)
    setInterval checkNewFiles.bind(undefined, dir), 2 * 60 * 60 * 1000

  return start: start
