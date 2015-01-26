fs = require 'fs-extra'

describe 'file saver', ->
  saveFile = require('../lib/file-save')(
    xmlDir: './spec/files/xml'
    imagesDir: './spec/files/images')

  beforeEach ->
    try
      fs.unlinkSync './spec/files/xml/test.xml'
      fs.unlinkSync './spec/files/images/test.jpeg'
    catch

  afterEach ->
    try
      fs.unlinkSync './spec/files/xml/test.xml'
      fs.unlinkSync './spec/files/images/test.jpeg'
    catch

  it 'saves xml files into configured xmlDir', (done) ->
    fs.readFile './spec/files/import.test.done', 'utf8', (err, data) ->
      saveFile 'test.xml', data, (err) ->
        expect(fs.existsSync('./spec/files/xml/test.xml'))
          .toBeTruthy()

          done()

  it 'saves images into image dir', (done) ->
    fs.readFile './spec/files/', (err, data) ->
      saveFile 'test.jpeg', data, (err) ->
        expect(fs.existsSync('./spec/files/images/test.jpeg'))
          .toBeTruthy()

          done()
