describe 'importer', ->
  importer = db = null

  it 'connects to db', (done) ->
    MongoClient = require('mongodb').MongoClient
    url = 'mongodb://localhost:27017/test'
    MongoClient.connect url, (err, testDb) ->
      return done(err) if err
      db = testDb
      importer = require('../lib/import')(testDb,
        imagesDir: './spec/files/images',
        imagesWebDir: 'images')

      products = [
        {
          _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4'
          name: 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
        }
        {
          _id: '1413801911001'
          name: 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
        }
      ]

      db.dropDatabase (err) ->
        db.collection('products').insert products, done

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
    prices = [
      {
        _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4'
        prices: [{price: '11'}]
      }
      {
        _id: '1413801911001'
        prices: [{price: '12'}]
      }
    ]

    importer.savePrices prices, (priceErr) ->
      expect(priceErr).toBeFalsy()

      db.collection('products')
        .findOne _id: '3c586b6e-dcbd-11e3-9034-bcaec58df7a4',
        (err, prod) ->
          expect(prod.name).toBe 'Скоба металлич.с одним отверст.Ф48-50мм(50шт)'
          expect(prod.prices).toContain price: '11'
          done()

  it 'returns a list of image files with ids', (done) ->
    importer.listImageFiles (err, images) ->
      expect(err).toBeFalsy()
      expect(images[0].images).toContain 'images/1413801911001.jpeg'
      done()

  it 'updates products with images', (done) ->
    importer.saveImages (err) ->
      expect(err).toBeFalsy()
      db.collection('products')
        .findOne _id: '1413801911001', (err, prod) ->
          expect(prod).toBeTruthy()

          done()
