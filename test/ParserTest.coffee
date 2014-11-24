parser = require '../lib/parser'
expect = require('./helpers/Common').expect
path = require 'path'

yamlFile = path.resolve __dirname, '../../../.airstack.yml'
badFile = path.resolve __dirname, './.SOME_FILE_THAT_DOES_NOT_EXIST.yml'



describe 'parser', ->
  fixture = (filename) ->
    path.resolve __dirname, './fixtures', filename

  before ->
    @configIni = fixture 'config.ini.stack'
    @configYaml = fixture 'config.yaml.stack'
    @configJson = fixture 'config.json.stack'

  describe '#load', ->
    it 'loads file using promises', ->
      parser.load @configIni
      .then (contents) ->
        expect(contents).to.exist

  describe '#parseHeader', ->
    it 'extracts yaml from header', ->
      parser.load @configIni
      .then parser.parseHeader
      .spread (contents, header) ->
        expect(header.isAwesome).to.equal 'most definitely'
        expect(contents).to.contain '# Another comment'

  describe '#loadAndParse', ->
    process = (file, output) ->
      parser.loadAndParse file, config: {var3: 'hello from config'}
      .spread (contents, input) ->
        expect(input.header.output).to.equal output
        expect(contents.var1).to.equal 'abcdef'
        expect(contents.var2).to.equal 'hello from the header'
        expect(contents.var3).to.equal 'hello from config'
        expect(contents.header.output).to.equal output

    it 'parses yaml file', ->
      process @configYaml, 'tmp/config.yaml'

    it 'parses json file', ->
      process @configJson, 'tmp/config.json'

  describe '#parse', ->
    testYaml = (filename) ->
      contents = 'test: yaml'
      [results, input] = parser.parse contents, filename: filename
      expect(results.test).to.equal 'yaml'

    it 'parses yaml contents with .yaml ext', ->
      testYaml 'test.yaml'

    it 'parses yaml contents with .yml ext', ->
      testYaml 'test.yml'

    it 'parses yaml contents with .yaml.stack ext', ->
      testYaml 'test.yaml.stack'

    it 'parses yaml contents with .yaml.stacker ext', ->
      testYaml 'test.yaml.stacker'

    it 'does not parse contents', ->
      contents = 'Some <%- "arbitrary" %> content with est'
      [results, input] = parser.parse contents, parse: false
      expect(results).to.equal 'Some arbitrary content with est'

  describe '#parseContents', ->
    it 'returns contents intact for non-supported file types', ->
      contents = 'Some arbitrary content'
      expect(parser.parseContents contents).to.equal contents

    context 'yaml', ->
      it 'returns yaml', ->
        contents = "t: true\nf: false"
        yaml = parser.parseContents contents, 'yaml'
        expect(yaml.t).to.be.ok
        expect(yaml.f).to.not.be.ok

    context 'json', ->
      it 'returns standard json', ->
        contents = '{"t": true, "f": false}'
        json = parser.parseContents contents, 'json'
        expect(json.t).to.be.true
        expect(json.f).to.be.false

      it 'returns json with commends', ->
        contents = "{\"t\": true, /* comment */ \"f\": false\n // another comment\n}"
        json = parser.parseContents contents, 'json'
        expect(json.t).to.be.true
        expect(json.f).to.be.false

  describe '#fileExt', ->
    it 'strips .stack', ->
      expect(parser.fileExt 'file.yml.stack').to.equal '.yml'

    it 'strips .stacker', ->
      expect(parser.fileExt 'file.yml.stacker').to.equal '.yml'

    it 'handles multiple extensions', ->
      expect(parser.fileExt 'file.yml.something.json').to.equal '.json'

  describe '#fileType', ->
    it 'detects yaml', ->
      expect(parser.fileType '.yml').to.equal 'yaml'
      expect(parser.fileType '.yaml').to.equal 'yaml'
      expect(parser.fileType '.YML').to.equal 'yaml'
      expect(parser.fileType '.Yaml').to.equal 'yaml'

    it 'detects json', ->
      expect(parser.fileType '.json').to.equal 'json'
      expect(parser.fileType '.JSON').to.equal 'json'

    it 'strips dot for non json and yaml', ->
      expect(parser.fileType '.random').to.equal 'random'
      expect(parser.fileType '.RanDom').to.equal 'random'
