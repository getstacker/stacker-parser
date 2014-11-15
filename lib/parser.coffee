# Load and parse .stacker template files

yaml = require 'js-yaml'
eco = require 'eco'
Promise = require 'bluebird'
readFile = Promise.promisify require('fs').readFile
path = require 'path'
_ = require 'lodash'
defaults = require('stacker-utils').object.deepDefaults

require 'stacker-globals'
config = require 'config'


loadAndParse = (filename, opts = {}) ->
  load filename, opts
  .then (contents) ->
    opts.filename = filename
    parse contents, opts


load = (filename, opts = {}) ->
  _.defaults opts, encoding: 'utf8'
  readFile path.normalize(filename), opts.encoding


###*
@return [contents, input]  Input is the config object passed to the template.
                           Contents is the parsed output.
###
parse = (contents, opts = {}) ->
  [contents, header] = parseHeader contents
  cfg = {}
  defaults cfg, header.config
  defaults cfg, opts.config or config.config
  input =
    config: cfg
    header: header
  contents = eco.render contents, input
  ext = opts.filename and path.extname opts.filename or ''
  ext = path.extname opts.filename[0...-ext.length]  if ext in ['.stack', '.stacker']
  try
    contents = if ext in ['.yml', '.yaml']
      yaml.safeLoad contents
    else if ext is '.json'
      # Strip comments
      contents = contents.replace /\s*\/\/.*/g, ''
      contents = contents.replace /\s*\/\*[^\*]*\*\//m, ''
      JSON.parse contents
    else
      contents
  catch err
    throw "Parse error [#{opts.filename}]: #{err.message}"
  [contents, input]


# @return [contents, header]
parseHeader = (contents) ->
  matches = contents.match /^#!stacker\s+"""\s+((.*\s+)+?)"""\s+((.*\s+)*)/m
  return [contents, {}]  unless matches
  [tmp, header, tmp, contents] = matches
  header = yaml.safeLoad header
  [contents, header]


module.exports =
  load: load
  parse: parse
  loadAndParse: loadAndParse
  parseHeader: parseHeader
