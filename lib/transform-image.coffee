path = require 'path'
_ = require 'lodash'
gm = require('gm').subClass
  imageMagick: true

options =
  outputDir: './spec/files'
  watermarkFile: '/home/stepan/projects/1c-import/spec/files/images/watermark.png'
  width: 300
  height: 200

# @options: outputDir, watermarkFile, width, height,
# watermarkPos
init = (opts, done) ->
  opts ?= {}
  _.each opts, (name, val) ->
    options[name] = val

  gm(options.watermarkFile).size (err, value) ->
    options.waterWidth = value.width
    options.waterHeight = value.height
    done(err)

processImage = (imagePath, done) ->
  coords =
    x: 0
    y: 0
    x2: options.width
    y2: options.height
  output = path.join options.outputDir, path.basename(imagePath)
  gm(imagePath)
    .resize(options.width, options.height)
    .draw("image Over
      #{coords.x},#{coords.y} #{coords.x2},#{coords.y2}
      '#{options.watermarkFile}'")
    .write output, (err) ->
      console.log err || 'alright'
      done(err)

init {}, ->
  processImage('./spec/files/images/1413801911001.jpeg', (->))
module.exports =
  init: init
  processImage: processImage
