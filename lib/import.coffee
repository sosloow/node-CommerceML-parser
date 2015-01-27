path = require 'path'
_ = require 'lodash'
async = require 'async'
parser = require './cml-parser'
config = require '../config'

module.exports = (db) ->
  saveToCollection = (colName, data, options, done) ->
    if arguments.length == 3 && typeof options == 'function'
      done = options
      options = upsert: true
    unless _.isArray(data)
      return done(Error('data must be an array'))

    # split long arrays into smaller chunks
    splitData = (dataArray, acc) ->
      return acc.concat([dataArray]) if dataArray.length < 100
      splitData(
        dataArray.slice(100, dataArray.length)
        acc.concat [dataArray.slice(0, 100)])

    # map records in each chunk
    # into Bulk of mongo upsert operations,
    # inserted separatedly
    if options.upsert
      async.each splitData(data, []), ((chunk, next) ->
        bulk = db.collection(colName).initializeUnorderedBulkOp()
        chunk.forEach (entry) ->
          bulk.find(_id: entry._id).upsert()
            .updateOne $set: _.omit(entry, '_id')
        bulk.execute next), done
    else
      # if not upserting drop collection
      # and re-insert each chunk
      db.collection(colName).remove ->
        async.each splitData(data, []), ((chunk, next) ->
          db.collection(colName).insert chunk, next), done

  updateCollection = (colName, data, done) ->
    unless _.isArray(data)
      return done(Error('data must be an array'))

    # send update operations in bulk
    bulk = db.collection(colName).initializeUnorderedBulkOp()
    data.forEach (entry) ->
      bulk.find(_id: entry._id).updateOne($set: _.omit(entry, '_id'))

    bulk.execute done

  # xml files get parsed, images skipped for now
  processFile = (filename, done) ->
    switch filename
      when 'import.xml'
        parser.xmlFromFile path.join(config.xmlDir, 'import.xml'),
        (err, xml) ->
          return done(err) if err
          options = upsert: parser.parseUpdateReinsertFlag(xml)
          async.parallel [
            _.partial saveToCollection, 'groups', parser.parseGroups(xml), options
            _.partial saveToCollection, 'properties', parser.parseProps(xml), options
            _.partial saveToCollection, 'products', parser.parseProducts(xml), options
          ], done

      when 'offers.xml'
        parser.xmlFromFile path.join(config.xmlDir, 'offers.xml'),
        (err, offersXml) ->
          return done(err) if err
          updateCollection 'products', parser.parsePrices(offersXml), done

      else
        if filename.match /\.(jpg|png|jpeg|gif)$/
          console.log 'processing image...'
          done(null)
        else
          done message: 'cant import invalid file'

  return {
    saveGroups: _.partial(saveToCollection, 'groups')
    saveProperties: _.partial(saveToCollection, 'properties')
    saveProducts: _.partial(saveToCollection, 'products')
    savePrices: _.partial(updateCollection, 'products')
    processFile: processFile
  }
