path = require 'path'
fs = require 'fs'
_ = require 'lodash'
async = require 'async'
walk = require 'walk'
parser = require './cml-parser'

module.exports = (db, config) ->
  config ?= require '../config'

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

  listImageFiles = (done) ->
    fs.readdir config.imagesDir, (err, files) ->
      return done() unless files
      done null, _.compact files.map (file) ->
        return unless path.extname(file).match(/(jpe?g|png|gif)/)
        id = file.match(/^(.+)\..+?$/)[1]
        webPath = path.join(config.imagesWebDir, file)
        return unless id.match(/^[0-9a-f\-]+$/)
        return {
          _id: id
          images: [webPath]
        }

  # parse freshly uploaded xml, link images to
  # the product docs in mongo, and resize them
  processFile = (filename, done) ->
    return message: 'provide filename param' unless filename

    basename = path.basename(filename)
    switch basename
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
          fs.rename filename, path.join(config.imagesDir, basename), done
        else
          done message: 'cant import invalid file'

  return {
    listImageFiles: listImageFiles
    processFile: processFile
    saveGroups: _.partial(saveToCollection, 'groups')
    saveProperties: _.partial(saveToCollection, 'properties')
    saveProducts: _.partial(saveToCollection, 'products')
    savePrices: _.partial(updateCollection, 'products')
    saveImages: (done) ->
      listImageFiles (err, images) ->
        updateCollection 'products', images, done
  }
