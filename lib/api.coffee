express = require 'express'
basicAuth = require 'basic-auth'
getRawBody = require 'raw-body'
logger = require 'morgan'

module.exports = (importer, config) ->
  config ?= require '../config'
  saveFile = require('./file-save')(config)

  api = express()

  api.set 'port', process.env.PORT || config.port || 3010
  api.set 'env', process.env.NODE_ENV || 'development'
  if api.get('env') == 'development'
    api.use logger('dev')

  handlers =
    bodyParser: (req, res, next) ->
      getRawBody req,
        length: req.headers['content-length']
        limit: '500mb'
        encoding: 'utf8',
        (err, string) ->
          return next(err) if (err)

          req.rawBody = string
          next()

    basicAuth: (req, res, next) ->
      user = basicAuth(req)

      if user && user.name == config.auth.user && user.pass == config.auth.pass
      return next()

      res
        .status(401)
        .set('WWW-Authenticate', 'Basic realm="1cexchange"')
        .end()

    # Обмен заказами начинается с того, что 1С посылает http-запрос
    # вместе с http-авторизацией следующего вида:
    # 1c_exchange.php?type=sale&mode=checkauth
    # На этот запрос система 1С-Битрикс отвечает тремя
    # строками (используется разделитель строк "\n"):
    # слово "success";
    # имя Cookie;
    # значение Cookie.
    # Примечание:
    # все последующие запросы к 1С-Битрикс сопровождаются выставлением
    # со стороны 1С имени и значения Cookie, полученными по команде "checkauth".
    checkAuth: (req, res) -> res.send 'success\n'

    # Далее следует запрос 1С вида:
    # 1c_exchange.php?type=sale&mode=init
    # В ответ 1С-Битрикс выдает две строчки:
    # zip=yes, если сервер поддерживает обмен в zip-формате.
    # В этом случае файлы на следующем шаге должны быть упакованы в zip-формате
    # или zip=no, в таком случае файлы не должны быть упакованы,
    # а передаются каждый по отдельности.
    # file_limit=<число>, где <число> - максимально допустимый размер
    # файла в байтах для передачи за один запрос. Если размер файла больше,
    # то он должен быть порезан на части.
    init: (req, res) -> res.send 'zip=no\nfile_limit=5000000\n'

    # Идет файл для импорта, надо его сохранить
    # http://../1c_exchange.pl?type=sale&mode=file&filename=<имя файла>
    file: (req, res) ->
      return res.status(400).send('failure\n') unless req.rawBody
      saveFile req.query.filename, req.rawBody, (err) ->
        console.log err.stack if err
        return res.status(400).send('failure\n') if err
        res.send 'success\n'

    # На последнем шаге по запросу из 1С проводится пошаговая загрузка каталога:
    # 1c_exchange.php?type=catalog&mode=import&filename=<имя файла>
    # Во время загрузки система «1С-Битрикс: Управление сайтом» может
    # отвечатьв одном из следующих форматов:
    # Если в первой строке содержится слово "progress" - это означает
    # необходимостьпослать тот же запрос повторно. В этом случае во
    # второй строке будет возвращен текущий статус обработки, объем
    # загруженных данных, статус импорта и т.д.
    # Если в строке содержится слово "success", то это сообщает об
    # успешном окончании обработки файла <имя файла>.
    # Примечание:
    # Если в ходе какого-либо запроса произошла ошибка,то ответ
    # системы 1С-Битрикс будет иметь вид: в первой строке слово
    # "failure", а на следующих - описание ошибки, произошедшей
    # в процессе обработки запроса.
    # Если произошла необрабатываемая ошибка уровня ядра продукта
    # или sql-запроса, то в таком случае будет возвращен html-код.
    processFiles: (req, res) ->
      importer.processFile req.query.filename, (err) ->
        if err
          console.log err.stack
          return res.status(400).send "failure\n#{err.message}"

        res.send('success\nxml processed\n')

  api.use handlers.bodyParser
  unless api.get('env') == 'test'
    api.all '/api/1cexchange', handlers.basicAuth

  api.get '/api/1cexchange', (req, res) ->
    switch req.query.mode
      when 'checkauth'
        handlers.checkAuth(req, res)
      when 'init'
        handlers.init(req, res)
      when 'import'
        handlers.processFiles(req, res)
      else
        res.status(404).end()

  api.post '/api/1cexchange', (req, res) ->
    switch req.query.mode
      when 'file'
        handlers.file(req, res)
      else
        res.status(404).end()

  return api
