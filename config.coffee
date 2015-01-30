path = require 'path'

module.exports =
  xmlDir: path.join(__dirname, 'files/xml')
  imagesDir: path.join(__dirname, 'files/images')
  imagesWebDir: 'images'
  dbUri: 'mongodb://localhost:27017/import'
  auth:
    user: 'sn'
    pass: 'lady8ug'
