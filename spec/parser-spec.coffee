CMLparser = require '../cml-parser'

describe 'parser', ->
  importXml = offersXml = null

  it 'loads xml from file', (done) ->
    CMLparser.parseFile './spec/files/import.test.xml', (err, xmlFromFile) ->
      expect(err).toBe null
      importXml = xmlFromFile
      offersXml = CMLparser.parseFile './spec/files/offers.test.xml',
        (err, xmlFromFile) ->
          expect(err).toBe null
          offersXml = xmlFromFile
          done()

  it 'builds list of groups with name, parents, children', ->
    groupList = CMLparser.importGroups(importXml)

    expect(groupList.length).toEqual 7
    expect(groupList[1].parent).toBe 'd6e2eb16-909e-11e3-99ad-bcaec58df7a4'
    expect(groupList[2].name).toBe 'Анкерные шурупы по бетону'
    expect(groupList[4].children).toContain 'd6e2eb80-909e-11e3-99ad-bcaec58df7a4'

  it 'builds list of properties and their values, if presented', ->
    propList = CMLparser.importProps(importXml)

    expect(propList[0].type).toBe 'Число'
    expect(propList[1].values[2].value).toBe 'дюбель рамный'

  it 'builds list of products with groups and prop values', ->
    prodList = CMLparser.importProducts(importXml)
    product = prodList[0]

    expect(product.name.trim()).toBe 'Проволока стальная (вязальная)  1,8 мм'
    expect(product.groups).toContain '03cb82b2-9a11-11e3-99ad-bcaec58df7a4'
    expect(product.properties.length).toEqual 2
    expect(product.properties[1].value).toBe 'b1f93a18-77b3-11e3-b017-bcaec58df7a4'

