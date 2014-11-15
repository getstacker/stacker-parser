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
Parse contents for stacker header, eco templates, yaml, and json.

@param opts  All opts are optional.
       opts.filename: {String} filename used for parsing contents by file extension
       opts.parse:    {Bool} set to false to disable parsing of file contents by parseContents
@return [contents, input]  Input is the config object passed to the template.
                           Contents is the parsed output.
###
parse = (contents, opts = {}) ->
  [contents, header] = parseHeader contents
  cfg = {}
  defaults cfg, header.config
  defaults cfg, opts.config or config.config
  ext = fileExt opts.filename
  type = fileType ext
  input =
    config: cfg
    header: header
    file:
      name: opts.filename
      ext: ext
      type: type
  # Process eco template code, if any
  contents = eco.render contents, input
  # By default, parse contents for supported file types
  unless opts.parse == false
    try
      contents = parseContents contents, type
    catch err
      throw "Parse contents error [#{opts.filename}]: #{err.message}"
  [contents, input]


# @return [contents, header]
parseHeader = (contents) ->
  matches = contents.match /^#!stacker\s+"""\s+((.*\s+)+?)"""\s+((.*\s+)*)/m
  return [contents, {}]  unless matches
  [tmp, header, tmp, contents] = matches
  header = yaml.safeLoad header
  [contents, header]


# @throws parse error
parseContents = (contents, type) ->
  if type is 'yaml'
    yaml.safeLoad contents
  else if type is 'json'
    # Strip comments
    contents = contents.replace /\s*\/\/.*/g, ''
    contents = contents.replace /\s*\/\*[^\*]*\*\//m, ''
    JSON.parse contents
  else
    contents


# Get file extension without .stack or .stacker
fileExt = (filename) ->
  return null  unless filename
  ext = filename and path.extname filename or ''
  if ext in ['.stack', '.stacker']
    # Strip .stacker extension
    path.extname filename[0...-ext.length]
  else
    ext


fileType = (ext) ->
  return null  unless ext
  ext = ext.toLowerCase()
  if ext in ['.yml', '.yaml']
    'yaml'
  else if ext is '.json'
    'json'
  else
    ext.replace '.', ''


module.exports =
  load: load
  parse: parse
  loadAndParse: loadAndParse
  parseHeader: parseHeader
  parseContents: parseContents
  fileExt: fileExt
  fileType: fileType
