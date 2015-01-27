http = require 'http'
config = require '../config'
MongoClient = require('mongodb').MongoClient

module.exports =
  init: (options) ->
    unless options.path
      throw Error('options.path not present')
    MongoClient.connect config.dbUri, (err, db) ->
      throw err if err

      importer = require('./import')(db)
      api = require('./api')(importer)

      http.createServer(api).listen api.get('port'), ->
        console.log "Express server listening on port #{api.get('port')}"

      watcher = require('./watcher')(importer)

      watcher.start(options.path)

module.exports.init(path: './files')
