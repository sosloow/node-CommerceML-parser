_ = require 'lodash'

module.exports = (db) ->
  saveToCollection = (colName, data, done) ->
    unless _.isArray(data)
      return done(Error('data must be an array'))

    db.collection(colName).insert data, done

  updateCollection = (colName, data, done) ->
    unless _.isArray(data)
      return done(Error('data must be an array'))

    bulk = db.collection(colName).initializeUnorderedBulkOp()
    data.forEach (entry) ->
      bulk.find(_id: entry._id).updateOne($set: _.omit(entry, '_id'))

    bulk.execute done

  return {
    saveGroups: _.partial(saveToCollection, 'groups')
    saveProperties: _.partial(saveToCollection, 'properties')
    saveProducts: _.partial(saveToCollection, 'products')
    savePrices: _.partial(updateCollection, 'products')
  }
