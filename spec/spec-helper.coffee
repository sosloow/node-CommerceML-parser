process.env.NODE_ENV = 'test'
request = require 'request'

class Requester
  buildUrl: (path) ->
    "http://localhost:7665#{path}"

  get: (path, callback) ->
    request @buildUrl(path), callback

  post: (path, data, callback) ->
    request.post @buildUrl(path), body: data, callback

  put: (path, body, callback) ->
    request
      method: 'PUT'
      url: @buildUrl(path)
      json: body,
      callback

  delete: (path, callback) ->
    request.del @buildUrl(path), callback

exports.withServer = (callback) ->
  jasmine.asyncSpecWait()

  app = require("../lib/api.coffee")

  server = app.listen 7665

  stopServer = ->
    server.close()
    jasmine.asyncSpecDone()

  callback new Requester, stopServer
