fs = require 'fs'
parser = require 'libxmljs'
_ = require 'lodash'

textNode = (parent, name) ->
  node = parent.get("./#{name}")
  return '' unless node
  node.text()

parseGroups = (xml) ->
  groups = xml.find('/КоммерческаяИнформация/Классификатор/Группы/Группа')

  aux = (groupXml, parent_Id) ->  
    children = groupXml.find('./Группы/Группа')
    _id = textNode(groupXml, 'Ид')
    currentGroup =
      _id: _id
      name: textNode(groupXml, 'Наименование')
      parent: parent_Id
      children: children.map (child) -> textNode(child, 'Ид')

    return [currentGroup] unless children.length > 0
    [currentGroup].concat children.reduce ((result, child) ->
      result.concat(aux(child, _id))), []

  groups.reduce ((result, group) ->
    result.concat(aux(group, null))), []

parseProps = (xml) ->
  xml.find('/КоммерческаяИнформация/Классификатор/Свойства/Свойство')
    .map (propNode) ->
      _id: textNode(propNode, 'Ид')
      name: textNode(propNode, 'Наименование')
      type: textNode(propNode, 'ТипЗначений')
      values: propNode.find('./ВариантыЗначений/Справочник')
        .map (valueNode) ->
          _id: textNode(valueNode, 'ИдЗначения')
          value: textNode(valueNode, 'Значение')

parseProducts = (xml) ->
  xml.find('/КоммерческаяИнформация/Каталог/Товары/Товар')
    .map (prodNode) ->
      _id: textNode(prodNode, 'Ид')
      name: textNode(prodNode, 'Наименование')
      baseUnit: textNode(prodNode, 'БазоваяЕдиница')
      groups: prodNode.find('./Группы/Ид').map (_id) -> _id.text()
      properties: prodNode.find('./ЗначенияСвойств/ЗначенияСвойства')
        .map (propNode) ->
          _id: textNode(propNode, 'Ид')
          value: textNode(propNode, 'Значение')

parsePrices = (xml) ->
  priceTypes = xml.find('/КоммерческаяИнформация/ПакетПредложений/ТипыЦен/ТипЦены')
    .map (priceTypeNode) ->
      _id: textNode(priceTypeNode, 'Ид')
      name: textNode(priceTypeNode, 'Наименование')
  xml.find('/КоммерческаяИнформация/ПакетПредложений/Предложения/Предложение')
    .map (offerNode) ->
      _id: textNode(offerNode, 'Ид')
      prices: offerNode.find('./Цены/Цена').map (priceNode) ->
        price: textNode(priceNode, 'ЦенаЗаЕдиницу')
        currency: textNode(priceNode, 'Валюта')
        unit: textNode(priceNode, 'Единица')
        coef: textNode(priceNode, 'Коэффициент')
        type:
          _id: textNode(priceNode, 'ИдТипаЦены')
          name: _.find(priceTypes, (pt) ->
            pt._id == textNode(priceNode, 'ИдТипаЦены')).name

xmlFromFile = (path, done) ->
  fs.readFile path, 'utf8', (err, data) ->
    return done(err) if err
    try
      xml = parser.parseXml(data)
      fs.rename path, path.replace(/\.xml$/, '.done'), (err) ->
        return done(err) if err
        done(null, xml)
    catch err
      done(err)

module.exports =
  xmlFromFile: xmlFromFile
  parseGroups: parseGroups
  parseProps: parseProps
  parseProducts: parseProducts
  parsePrices: parsePrices
