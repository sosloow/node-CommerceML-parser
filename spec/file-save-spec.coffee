fs = require 'fs-extra'

describe 'file saver', ->
  beforeEach (done) ->
    fs.unlink './spec/files/xml/test.xml', done

  it 'saves xml files into configured xmlDir', (done) ->
    saveFile = require('../lib/file-save')(
      xmlDir: './spec/files/xml'
      imagesDir: './spec/files/images')

    fs.readFile './spec/files/import.test.done', 'utf8', (err, data) ->
      saveFile 'test.xml', data, (err) ->
        expect(fs.existsSync('./spec/files/xml/test.xml'))
          .toBeTruthy()

          done()
