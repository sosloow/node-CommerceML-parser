fs = require 'fs-extra'
path = require 'path'

module.exports = (config) ->
  config ?= require '../config'

  saveXml = (filePath, data, done) ->
    fs.ensureDir config.xmlDir, (err) ->
      return done(err) if err
      fullPath = path.join(config.xmlDir, filePath)
      fs.appendFile fullPath, data, done

  saveImage = (filePath, data, done) ->
    dirPath = path.join config.imagesDir, path.dirname(filePath)
    fs.ensureDir dirPath, (err) ->
      return done(err) if err
      fullPath = path.join(dirPath, filePath)
      fs.appendFile fullPath, data, done

  saveFile = (filePath, data, done) ->
    return done(message: 'filename must be provided') unless filePath
    if filePath.match(/\.xml$/)
      saveXml(filePath, data, done)
    else if filePath.match(/\.(png|jpg|jpeg|gif)$/)
      saveImage(filePath, data, done)
    else
      done message: 'file extension is not accepted'

  return saveFile
