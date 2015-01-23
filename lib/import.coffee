path = require 'path'
_ = require 'lodash'
async = require 'async'
parser = require './cml-parser'
config = require '../config'

module.exports = (db) ->
  saveToCollection = (colName, data, done) ->
    unless _.isArray(data)
      return done(Error('data must be an array'))

    splitData = (dataArray, acc) ->
      return acc.concat(dataArray) if dataArray.length < 100
      splitData(
        dataArray.slice(100, dataArray.length)
        acc.concat [dataArray.slice(0, 100)]
      )

    async.each splitData(data, []),
      ((chunk, next) ->
        db.collection(colName).insert chunk, next),
      done

  updateCollection = (colName, data, done) ->
    unless _.isArray(data)
      return done(Error('data must be an array'))

    bulk = db.collection(colName).initializeUnorderedBulkOp()
    data.forEach (entry) ->
      bulk.find(_id: entry._id).updateOne($set: _.omit(entry, '_id'))

    bulk.execute done

  processFile = (filename, done) ->
    switch filename
      when 'import.xml'
        parser.xmlFromFile path.join(config.xmlDir, 'import.xml'),
        (err, xml) ->
          return done(err) if err
          async.parallel [
            _.partial saveToCollection, 'groups', parser.parseGroups(xml)
            _.partial saveToCollection, 'properties', parser.parseProps(xml)
            _.partial saveToCollection, 'products', parser.parseProducts(xml)
          ], done
      when 'offers.xml'
        parser.xmlFromFile path.join(config.xmlDir, 'offers.xml'),
        (err, offersXml) ->
          return done(err) if err
          updateCollection 'products', parser.parsePrices(offersXml), done
      else
        done('invalid filename. Must be import.xml or offers.xml')

  return {
    saveGroups: _.partial(saveToCollection, 'groups')
    saveProperties: _.partial(saveToCollection, 'properties')
    saveProducts: _.partial(saveToCollection, 'products')
    savePrices: _.partial(updateCollection, 'products')
    processFile: processFile
  }
