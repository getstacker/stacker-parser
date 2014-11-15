# Load and parse .stacker template files

yaml = require 'js-yaml'
eco = require 'eco'
Promise = require 'bluebird'
readFile = Promise.promisify require('fs').readFile
path = require 'path'
_ = require 'lodash'

require 'stacker-globals'
config = require 'config'


loadAndParse = (filename, opts = {}) ->
  opts.filename = filename
  load filename, opts
  .then (contents) ->
    parse contents, opts


load = (filename, opts = {}) ->
  _.defaults opts, encoding: 'utf8'
  readFile path.normalize(filename), opts.encoding


parse = (contents, opts = {}) ->
  [cfg, contents] = parseHeader contents
  cfg.config ?= {}
  defaults cfg.config, config.config
  contents = eco.render contents, config
  ext = opts.filename and path.extname opts.filename or ''
  ext = path.extname opts.filename[0...-ext.length]  if ext in ['.stack', '.stacker']
  if ext in ['.yml', '.yaml']
    yaml.safeLoad contents
  else if ext is '.json'
    JSON.parse contents
  else
    contents


parseHeader = (contents) ->
  matches = contents.match /^#!stacker\s+"""\s+((.*\s+)+?)"""\s+((.*\s+)*)/m
  return [{}, contents]  unless matches
  [tmp, cfg, tmp, contents] = matches
  cfg = yaml.safeLoad cfg
  [cfg, contents]


module.exports =
  load: load
  parse: parse
  loadAndParse: loadAndParse
  parseHeader: parseHeader
