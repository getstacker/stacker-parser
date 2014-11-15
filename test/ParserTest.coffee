parser = require '../lib/parser'
expect = require('./helpers/Common').expect
path = require 'path'

yamlFile = path.resolve __dirname, '../../../.airstack.yml'
badFile = path.resolve __dirname, './.SOME_FILE_THAT_DOES_NOT_EXIST.yml'



describe 'parser', ->
  getMockFile = (filename) ->
    path.resolve __dirname, './mocks', filename

  before ->
    @configIni = getMockFile 'config.ini.stack'
    @configYaml = getMockFile 'config.yaml.stack'
    @configJson = getMockFile 'config.json.stack'

  describe 'load', ->
    it 'loads file using promises', ->
      parser.load @configIni
      .then (contents) ->
        expect(contents).to.exist

  describe 'parseHeader', ->
    it 'extracts yaml from header', ->
      parser.load @configIni
      .then parser.parseHeader
      .spread (header, contents) ->
        expect(header.isAwesome).to.equal 'most definitely'
        expect(contents).to.contain '# Another comment'

  describe 'loadAndParse', ->
    process = (file, output) ->
      parser.loadAndParse file, config: {var3: 'hello from config'}
      .spread (input, yaml) ->
        expect(input.header.output).to.equal output
        expect(yaml.var1).to.equal 'abcdef'
        expect(yaml.var2).to.equal 'hello from the header'
        expect(yaml.var3).to.equal 'hello from config'
        expect(yaml.header.output).to.equal output

    it 'parses yaml file', ->
      process @configYaml, 'tmp/config.yaml'

    it 'parses json file', ->
      process @configJson, 'tmp/config.json'

