# Copyright(c) 2012 Matias Meno <m@tias.me>

# ### TheTVDB.com Node library
#
# It's a wrapper for [thetvdb][]s XML API, written in [CoffeeScript][] for [node][].
# You won't be in contact with any XML if you use this library.
#
# [node]: http://nodejs.org/
# [thetvdb]: http://www.thetvdb.com/
# [coffeescript]: http://coffeescript.org/
#
# Please refere to the `Readme` for a more complete documentation.

# ### Lets see the code!



# Dependencies
xmlParser = new (require "xml2js").Parser explicitRoot: no, explicitArray: no
http = require "http"
_ = require "underscore"
querystring = require "querystring"
fs = require "fs"
Zip = require "adm-zip"
keymap = require "./keymap.json"
Q = require "q"

# Class definition
class TVDB



  # The default options you can override by passing an options object in the constructor.
  #
  #   - `apiKey` String
  #   - `language` String (optional) Default: 'en' You can set this later, with setLanguage(). Use
  #                       getLanguages() to get a list of languages, and use the abbreviation.
  #   - `initialHost` String (optional) Default: `thetvdb.com`
  #   - `port` Number (optional) Default: 80
  defaultOptions =
    apiKey: null
    language: "en"
    initialHost: "thetvdb.com"
    port: 80


  # See `defaultOptions` for available options.
  constructor: (options) ->
    @options = _.extend(_.clone(defaultOptions), options || { })
    unless this.options.apiKey then throw new Error "You have to provide an API key."

  # Sets the language option.
  setLanguage: (abbreviation) ->
    @options.language = abbreviation

  # Sets the mirrorUrl option
  setMirror: (host, port) ->
    @options.initialHost = host if host?
    @options.port = port if port?


  # A list of thetvdb.com paths.
  paths:
    mirrors: '/api/#{apiKey}/mirrors.xml'
    languages: '/api/#{apiKey}/languages.xml'
    serverTime: '/api/Updates.php?type=none'
    findTvShow: '/api/GetSeries.php?seriesname=#{name}&language=#{language}'
    getInfo: '/api/#{apiKey}/series/#{seriesId}/all/#{language}.zip'
    getInfoTvShow: '/api/#{apiKey}/series/#{seriesId}/#{language}.xml'
    getInfoEpisode: '/api/#{apiKey}/episodes/#{episodesId}/#{language}.xml'
    getUpdates: '/api/#{apiKey}/updates/updates_#{period}.zip'


  # Returns the path and inserts api key and language if necessary.
  getPath: (pathName, values) ->
    path = @paths[pathName]

    _.each _.extend({ }, @options, values), (value, key) ->
      path = path.replace '#{' + key + '}', querystring.escape(value)

    return path


  # Shortcut for http.get
  get: (options) ->
    options = _.extend({ host: this.options.initialHost, port: this.options.port }, options)
    deferred = Q.defer()

    if options.pathName?
      options.path = @getPath options.pathName
      delete options.pathName

    http.get options, (res) =>
      unless 100 <= res.statusCode < 300
        deferred.reject new Error("Status: #{res.statusCode}")
        return

      contentType = res.headers['content-type'];
      if contentType.split(';').length
        contentType = contentType.split(';')[0]

      dataBuffers = [ ]
      dataLen = 0

      res.on 'data', (chunk) ->
        dataBuffers.push chunk
        dataLen += chunk.length

      res.on 'end', =>
        dataBuffer = new Buffer dataLen

        pos = 0
        for data, i in dataBuffers
          data.copy dataBuffer, pos
          pos += data.length

        switch contentType
          when "text/xml", "application/xml"
            xmlParser.parseString dataBuffer.toString(), (err, result) ->
              if err?
                deferred.reject new Error("Invalid XML: #{err.message}")
              else
                deferred.resolve result

          when "application/zip"
            @unzip dataBuffer, (err, result) ->
              if err?
                deferred.reject new Error("Invalid XML: #{err.message}")
              else
                deferred.resolve result

          else
            deferred.resolve dataBuffer.toString()

    .on "error", (e) -> deferred.reject new Error(e)

    return deferred.promise


  # Calls `done` with `err` if an error occured, and an array containing a list of languages.
  #
  # A language is an object containing:
  #
  #   - `id` String
  #   - `name` String
  #   - `abbreviation` String
  getLanguages: ->
    return @get(pathName: "languages")
    .then (response) ->
      return if _.isArray(response.Language) then response.Language else [response.Language]


  # Calls `done` with `err` if an error occured, and an array containing a list of mirrors.
  #
  # A mirror is an object containing:
  #
  #   - `id` String
  #   - `url` String
  #   - `types` Array containing at least one of `xml`, `banner` and `zip`.
  getMirrors: ->
    @get(pathName: "mirrors")
    .then (response) ->
      mirrors = if _.isArray(response.Mirror) then response.Mirror else [response.Mirror]
      masks = xml: 1, banner: 2, zip: 4
      formattedMirrors = []

      mirrors.forEach (mirror) ->
        formattedMirror =
          id: mirror.id
          url: mirror.mirrorpath
          types: [ ]

        _.each masks, (mask, type) ->
          if (mirror.typemask & mask) is mask then formattedMirror.types.push type

        formattedMirrors.push formattedMirror

      return formattedMirrors


  # Gets the server timestamp
  getServerTime: ->
    @get(pathName: "serverTime")
    .then (response) ->
      return parseInt(response.Time, 10)


  # Finds a tv show by its name.
  #
  # The callback `done` gets invoked with `err` and `tvShows`.
  #
  # `tvShows` contains:
  #
  #   - `id`
  #   - `language`
  #   - `name`
  findTvShow: (name) ->
    self = this

    @get(path: this.getPath("findTvShow", name: name))
    .then (tvShows) ->
      formattedTvShows = [ ]

      if tvShows?.Series?
        tvShows = if _.isArray tvShows.Series then tvShows.Series else [tvShows.Series]

        tvShows.forEach (tvShow) ->
          formattedTvShows.push self.formatGetTvShow tvShow

      return formattedTvShows


  # Retrieves all information for a specific TV Show.
  #
  # The callback `done` gets invoked with `err` and `info`.
  #
  # `info` contains following objects:
  #
  #   - `tvShow`
  #   - `episodes`
  #   - `actors`
  #   - `banners`
  getInfo: (tvShowId, language) ->
    options = { language: 'en', seriesId: tvShowId }
    options.language = language if language?
    self = this

    @get(path: this.getPath("getInfo", options)) 
    .then (files) ->
      formattedResult = { }

      for filename, xml of files
        xmlParser.parseString xml, (err, result) ->
          return new Error "Invalid XML: #{err.message}" if err?

          if result.Actor?
            formattedActors = []

            actors = if _.isArray result.Actor then result.Actor else [result.Actor]
            actors.forEach (actor) ->
              formattedActors.push self.formatActor actor

            formattedResult['actors'] = formattedActors

          if result.Banner?
            formattedBanners = []

            banners = if _.isArray result.Banner then result.Banner else [result.Banner]
            banners.forEach (banner) ->
              formattedBanners.push self.formatBanner banner

            formattedResult['banners'] = formattedBanners

          if result.Series?
            formattedResult['tvShow'] = self.formatTvShow result.Series

          if result.Episode?
            formattedEpisodes = []

            episodes = if _.isArray result.Episode then result.Episode else [result.Episode]
            episodes.forEach (episode) ->
              formattedEpisodes.push self.formatEpisode episode

            formattedResult['episodes'] = formattedEpisodes

      return formattedResult


  # Retrieves basic information for a specific TV Show.
  #
  # The callback `done`gets invoked with `err` and `info.
  #
  # `info` contains an object with tv show information.
  getInfoTvShow: (tvShowId, language) ->
    options = { language: 'en', seriesId: tvShowId }
    options.language = language if language?
    self = this

    @get(path: this.getPath("getInfoTvShow", options))
    .then (files) ->
      return self.formatTvShow files.Series


  # Retrieves basic information for a specific TV Show episode.
  #
  # The callback `done`gets invoked with `err` and `info.
  #
  # `info` contains an object with tv show episode information.
  getInfoEpisode: (episodeId, language) ->
    options = { language: 'en', episodesId: episodeId }
    options.language = language if language?
    self = this

    @get(path: this.getPath("getInfoEpisode", options))
    .then (files) ->
      return self.formatEpisode files.Episode

  # Unzips a zip buffer and returns an object with the filenames as keys and the data as values.
  unzip: (zipBuffer, done) ->
    zip = new Zip zipBuffer
    zipEntries = zip.getEntries()
    files = { }
    _.each zipEntries, (file, index) ->
      files[file.entryName] = file.getData().toString 'utf8'
    done null, files


  # Retrieves all updates based on parameter. Valid parameters are
  #   - `day`
  #   - `week`
  #   - `month`
  #
  # The callback `done` gets invoked with `err` and `updates`.
  #
  # `updates` contains following objects:
  #
  #   - `updateInfo`
  #   - `tvShows`
  #   - `episodes`
  #   - `banners`
  getUpdates: (period) ->
    if !(['day', 'week', 'month'].some (p) -> p == period)
      deferred = Q.defer()

      deferred.reject new Error "Invalid period #{period}"

      return deferred.promise

    options = { period: period }
    self = this

    @get(path: this.getPath("getUpdates", options))
    .then (files) ->
      formattedResult = {}

      _.each files, (xml) ->
        xmlParser.parseString xml, (err, updates) ->
          return new Error "Invalid XML: #{err.message}" if err?

          _.each updates, (update, key) ->
            if key == "$"
              formattedResult['updateInfo'] = update

            else if key == "Series"
              formattedResult['tvShows'] = []

              _.each update, (tvShow) ->
                formattedResult['tvShows'].push self.formatUpdateTvShow tvShow

            else if key == "Episode"
              formattedResult['episodes'] = []

              _.each update, (episode) ->
                formattedResult['episodes'].push self.formatUpdateEpisode episode

            else if key == "Banner"
              formattedResult['banners'] = []

              _.each update, (banner) ->
                formattedResult['banners'].push self.formatUpdateBanner banner

      return formattedResult

  format: (unformattedObject, keymap) ->
    formattedObject = {}

    for oldKey, newKey of keymap
      srcValue = unformattedObject[oldKey]
      formattedObject[newKey] = srcValue if srcValue?

    return formattedObject

  formatActor: (actor) ->
    return @format actor, keymap.actor

  formatBanner: (banner) ->
    return @format banner, keymap.banner

  formatEpisode: (episode) ->
    formatted = @format episode, keymap.episode
    formatted.firstAired = new Date(formatted.firstAired) if formatted.firstAired?

    return formatted

  formatTvShow: (tvShow) ->
    formatted = @format tvShow, keymap.series
    formatted.firstAired = new Date(formatted.firstAired) if formatted.firstAired?

    return formatted

  formatGetTvShow: (tvShow) ->
    formatted = @format tvShow, keymap.getSeries
    formatted.firstAired = new Date(formatted.firstAired) if formatted.firstAired?

    return formatted

  formatUpdateBanner: (banner) ->
    return @format banner, keymap.update.banner

  formatUpdateEpisode: (episode) ->
    return @format episode, keymap.update.episode

  formatUpdateTvShow: (tvShow) ->
    return @format tvShow, keymap.update.series

# Exposing TVDB
# @type {TVDB}
module.exports = TVDB


# Exposing the XML Parser as well
module.exports.xmlParser = xmlParser
