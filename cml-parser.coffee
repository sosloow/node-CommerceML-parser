parser = require 'libxmljs'
fs = require 'fs'

importGroups = (xml) ->
  groups = xml.find('/КоммерческаяИнформация/Классификатор/Группы/Группа')

  aux = (groupXml, parentId) ->  
    children = groupXml.find('./Группы/Группа')
    id = groupXml.get('./Ид').text()
    currentGroup =
      name: groupXml.get('./Наименование').text()
      parent: parentId
      children: children.map (child) -> child.get('./Ид').text()

    return [currentGroup] unless children.length > 0
    [currentGroup].concat children.reduce ((result, child) ->
      result.concat(aux(child, id))), []

  groups.reduce ((result, group) ->
    result.concat(aux(group, null))), []

importProps = (xml) ->
  xml.find('/КоммерческаяИнформация/Классификатор/Свойства/Свойство')
    .map (propNode) ->
      id: propNode.get('./Ид').text()
      name: propNode.get('./Наименование').text()
      type: propNode.get('./ТипЗначений').text()
      values: propNode.find('./ВариантыЗначений/Справочник')
        .map (valueNode) ->
          id: valueNode.get('./ИдЗначения').text()
          value: valueNode.get('./Значение').text()

importProducts = (xml) ->
  xml.find('/КоммерческаяИнформация/Каталог/Товары/Товар')
    .map (prodNode) ->
      id: prodNode.get('./Ид').text()
      name: prodNode.get('./Наименование').text()
      baseUnit: prodNode.get('./БазоваяЕдиница').text()
      groups: prodNode.find('./Группы/Ид').map (id) -> id.text()
      properties: prodNode.find('./ЗначенияСвойств/ЗначенияСвойства')
        .map (propNode) ->
          id: propNode.get('./Ид').text()
          value: propNode.get('./Значение').text()

parseFile = (path, done) ->
  fs.readFile path, 'utf8', (err, data) ->
    return done(err) if err
    done(null, parser.parseXml(data))

module.exports =
  parseFile: parseFile
  importGroups: importGroups
  importProps: importProps
  importProducts: importProducts
