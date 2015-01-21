describe 'importer', ->
  importer = db = null

  it 'connects to db', (done) ->
    MongoClient = require('mongodb').MongoClient
    url = 'mongodb://localhost:27017/test'
    MongoClient.connect url, (err, testDb) ->
      return done(err) if err
      db = testDb
      importer = require('../import')(testDb)

      db.dropDatabase done

  it 'saves groups data to mongo collection', (done) ->
    data = [
      {
        _id: 'd6e2eb16-909e-11e3-99ad-bcaec58df7a4'
        name: 'SORMAT'
        parent: null
        children: ['1fef8725-9a0f-11e3-99ad-bcaec58df7a4']
      }
      {
        _id: '1fef8725-9a0f-11e3-99ad-bcaec58df7a4'
        name: 'Анкера металлические'
        parent: 'd6e2eb16-909e-11e3-99ad-bcaec58df7a4'
        children: []
      }
    ]
    importer.saveGroups data, (next) ->
      db.collection('groups').findOne _id: 'd6e2eb16-909e-11e3-99ad-bcaec58df7a4',
      (err, group) ->
        expect(err).toBe null

        expect(group).not.toBe null
        expect(group.children).toContain '1fef8725-9a0f-11e3-99ad-bcaec58df7a4'
        done()

  it 'updates products with prices', (done) ->
    products = [
      {
        _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4'
        name: 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
      }
      {
        _id: '3c586b6e-dcbd-22e3-9034-bcaec58df7a4'
        name: 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
      }
    ]

    prices = [
      {
        _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4'
        prices: [{price: '11'}]
      }
      {
        _id: '3c586b6e-dcbd-22e3-9034-bcaec58df7a4'
        prices: [{price: '12'}]
      }
    ]

    importer.saveProducts products, (prodErr) ->
      expect(prodErr).toBe null
      importer.savePrices prices, (priceErr) ->
        expect(priceErr).toBe null

        db.collection('products')
          .findOne _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4',
          (err, prod) ->
            expect(prod.name).toBe 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
            expect(prod.prices).toContain price: '11'
            done()
