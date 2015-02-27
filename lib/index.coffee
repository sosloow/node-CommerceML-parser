http = require 'http'
MongoClient = require('mongodb').MongoClient

module.exports =
  init: (options) ->
    options ?= require '../config'

    unless options.path
      throw Error('options.path not present')
    MongoClient.connect options.dbUri, (err, db) ->
      throw err if err

      importer = require('./import')(db, options)
      api = require('./api')(importer, options)

      http.createServer(api).listen api.get('port'), ->
        console.log "Express server listening on port #{api.get('port')}"

      watcher = require('./watcher')(importer)

      watcher.start(options.path)

module.exports.init
  path: './files'
  dbUri: 'mongodb://localhost:27017/import'
  imagesDir: './files/images'
  xmlDir: './files/xml'
