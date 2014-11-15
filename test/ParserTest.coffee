parser = require '../lib/parser'
expect = require('./helpers/Common').expect
path = require 'path'

yamlFile = path.resolve __dirname, '../../../.airstack.yml'
badFile = path.resolve __dirname, './.SOME_FILE_THAT_DOES_NOT_EXIST.yml'


getMockFile = (filename) ->
  path.resolve __dirname, './mocks', filename

describe 'parser', ->
  before ->
    @configIni = getMockFile 'config.ini.stack'

  describe 'load', ->
    it 'loads file using promises', (done) ->
      parser.load @configIni
      .then (contents) ->
        expect(contents).to.exist
        done()
      .catch (err) ->
        done err

  describe 'parseHeader', ->
    it 'extracts yaml from header', (done) ->
      parser.load @configIni
      .then parser.parseHeader
      .spread (cfg, contents) ->
        expect(cfg.isAwesome).to.equal 'most definitely'
        expect(contents).to.contain '# Another comment'
        done()
      .catch (err) ->
        done err


  # TODO: test loadAndParse with config -> header -> eco templating
