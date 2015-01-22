helper = require './spec-helper'

describe 'exchange API', ->
  it 'authenticates requests with basic auth', ->
    helper.withServer (r, done) ->
      r.post '/api/1cexchange',
        mode: 'checkauth',
        (err, res, body) ->
          expect(res.statusCode).toEqual 200
          expect(body).toBe 'success\n'

          done()

  it 'ensures xmlDir exists and writes >> file if its xml', ->
    helper.withServer (r, done) ->
      r.post '/api/1cexchange',
        mode: 'file'
        filename: 'test.xml'
        POSTDATA: '<?xml><body></body>',
        (err, res, body) ->
          expect(res.statusCode).toEqual 200
          expect(body).toBe 'success\n'

          done()
