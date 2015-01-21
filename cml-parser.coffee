fs = require 'fs'
parser = require 'libxmljs'
_ = require 'lodash'

parseGroups = (xml) ->
  groups = xml.find('/КоммерческаяИнформация/Классификатор/Группы/Группа')

  aux = (groupXml, parent_Id) ->  
    children = groupXml.find('./Группы/Группа')
    _id = groupXml.get('./Ид').text()
    currentGroup =
      name: groupXml.get('./Наименование').text()
      parent: parent_Id
      children: children.map (child) -> child.get('./Ид').text()

    return [currentGroup] unless children.length > 0
    [currentGroup].concat children.reduce ((result, child) ->
      result.concat(aux(child, _id))), []

  groups.reduce ((result, group) ->
    result.concat(aux(group, null))), []

parseProps = (xml) ->
  xml.find('/КоммерческаяИнформация/Классификатор/Свойства/Свойство')
    .map (propNode) ->
      _id: propNode.get('./Ид').text()
      name: propNode.get('./Наименование').text()
      type: propNode.get('./ТипЗначений').text()
      values: propNode.find('./ВариантыЗначений/Справочник')
        .map (valueNode) ->
          _id: valueNode.get('./ИдЗначения').text()
          value: valueNode.get('./Значение').text()

parseProducts = (xml) ->
  xml.find('/КоммерческаяИнформация/Каталог/Товары/Товар')
    .map (prodNode) ->
      _id: prodNode.get('./Ид').text()
      name: prodNode.get('./Наименование').text()
      baseUnit: prodNode.get('./БазоваяЕдиница').text()
      groups: prodNode.find('./Группы/Ид').map (_id) -> _id.text()
      properties: prodNode.find('./ЗначенияСвойств/ЗначенияСвойства')
        .map (propNode) ->
          _id: propNode.get('./Ид').text()
          value: propNode.get('./Значение').text()

parsePrices = (xml) ->
  priceTypes = xml.find('/КоммерческаяИнформация/ПакетПредложений/ТипыЦен/ТипЦены')
    .map (priceTypeNode) ->
      _id: priceTypeNode.get('./Ид').text()
      name: priceTypeNode.get('./Наименование').text()
  xml.find('/КоммерческаяИнформация/ПакетПредложений/Предложения/Предложение')
    .map (offerNode) ->
      _id: offerNode.get('./Ид').text()
      prices: offerNode.find('./Цены/Цена').map (priceNode) ->
        price: priceNode.get('./ЦенаЗаЕдиницу').text()
        currency: priceNode.get('./Валюта').text()
        unit: priceNode.get('./Единица').text()
        coef: priceNode.get('./Коэффициент').text()
        type:
          _id: priceNode.get('./ИдТипаЦены').text()
          name: _.find(priceTypes, (pt) ->
            pt._id == priceNode.get('./ИдТипаЦены').text()).name

xmlFromFile = (path, done) ->
  fs.readFile path, 'utf8', (err, data) ->
    return done(err) if err
    done(null, parser.parseXml(data))

module.exports =
  xmlFromFile: xmlFromFile
  parseGroups: parseGroups
  parseProps: parseProps
  parseProducts: parseProducts
  parsePrices: parsePrices
