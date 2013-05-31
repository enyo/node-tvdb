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
Zip = require 'node-zip'


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
  get: (options, callback) ->
    options = _.extend({ host: this.options.initialHost, port: this.options.port }, options)

    if options.pathName?
      options.path = @getPath options.pathName
      delete options.pathName

    http.get options, (res) =>
      unless 100 <= res.statusCode < 300
        callback new Error("Status: #{res.statusCode}")
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
              err = new Error "Invalid XML: #{err.message}" if err?
              callback err, result

          when "application/zip"
            @unzip dataBuffer, (err, result) ->
              err = new Error "Invalid XML: #{err.message}" if err?
              callback err, result

          else
            callback null, dataBuffer.toString()

    .on "error", (e) -> callback e


  # Calls `done` with `err` if an error occured, and an array containing a list of languages.
  # 
  # A language is an object containing:
  # 
  #   - `id` String
  #   - `name` String
  #   - `abbreviation` String
  getLanguages: (done) ->
    @get pathName: "languages", (err, response) ->
      if err? then done(err); return
      languages = if _.isArray(response.Language) then response.Language else [response.Language]
      done undefined, languages


  # Calls `done` with `err` if an error occured, and an array containing a list of mirrors.
  # 
  # A mirror is an object containing:
  # 
  #   - `id` String
  #   - `url` String
  #   - `types` Array containing at least one of `xml`, `banner` and `zip`.
  getMirrors: (done) ->
    @get pathName: "mirrors", (err, response) ->
      if err? then done(err); return

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

      done undefined, formattedMirrors


  # Gets the server timestamp
  getServerTime: (done) ->
    @get pathName: "serverTime", (err, response) ->
      if err? then done(err); return
      done undefined, parseInt(response.Time, 10)


  # Finds a tv show by its name.
  # 
  # The callback `done` gets invoked with `err` and `tvShows`.
  # 
  # `tvShows` contains:
  # 
  #   - `id`
  #   - `language`
  #   - `name`
  findTvShow: (name, done) ->
    @get path: this.getPath("findTvShow", name: name), (err, tvShows) ->
      return done err if err?

      formattedTvShows = [ ]

      if tvShows?.Series?
        tvShows = if _.isArray tvShows.Series then tvShows.Series else [tvShows.Series]
        keyMapping = IMDB_ID: 'imdbId', zap2it_id: 'zap2itId', banner: 'banner', Overview: 'overview'

        tvShows.forEach (tvShow) ->
          formattedTvShow =
            id: tvShow.id
            language: tvShow.language
            name: tvShow.SeriesName

          formattedTvShow.firstAired = new Date(tvShow.FirstAired) if tvShow.FirstAired?

          _.each keyMapping, (trgKey, srcKey) ->
            srcValue = tvShow[srcKey]
            formattedTvShow[trgKey] = srcValue if srcValue

          formattedTvShows.push formattedTvShow

      done undefined, formattedTvShows


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
  getInfo: (tvShowId, done, language) ->
    options = { language: 'en', seriesId: tvShowId }
    options.language = language if language?
    self = this

    @get path: this.getPath("getInfo", options), (err, files) ->
      return done err if err?

      formattedResult = { }

      for filename, xml of files
        xmlParser.parseString xml, (err, result) ->
          return done new Error "Invalid XML: #{err.message}" if err?

          if result.Actor?
            formattedActors = []
            keyMapping = Image: 'image', Role: 'role', SortOrder: 'sortOrder'

            actors = if _.isArray result.Actor then result.Actor else [result.Actor]
            actors.forEach (actor) ->
              formattedActor =
                id: actor.id,
                name: actor.Name

              _.each keyMapping, (trgKey, srcKey) ->
                srcValue = actor[srcKey]
                formattedActor[trgKey] = srcValue if srcValue

              formattedActors.push formattedActor

            formattedResult['actors'] = formattedActors

          if result.Banner?
            formattedBanners = []
            keyMapping = Colors: 'colors', ThumbnailPath: 'thumbnailPath', VigettePath: 'vigenettePath', Season: 'season'

            banners = if _.isArray result.Banner then result.Banner else [result.Banner]
            banners.forEach (banner) ->
              formattedBanner =
                id: banner.id,
                path: banner.BannerPath,
                type: banner.BannerType,
                type2: banner.BannerType2,
                language: banner.Language,
                rating: banner.Rating,
                ratingCount: banner.RatingCount

              _.each keyMapping, (trgKey, srcKey) ->
                srcValue = banner[srcKey]
                formattedBanner[trgKey] = srcValue if srcValue

              formattedBanners.push formattedBanner

            formattedResult['banners'] = formattedBanners

          if result.Series?
            formattedResult['tvShow'] = self.formatTvShow result.Series

          if result.Episode?
            formattedEpisodes = []

            episodes = if _.isArray result.Episode then result.Episode else [result.Episode]
            episodes.forEach (episode) ->
              formattedEpisodes.push self.formatEpisode episode

            formattedResult['episodes'] = formattedEpisodes

      done undefined, formattedResult


  # Retrieves basic information for a specific TV Show.
  #
  # The callback `done`gets invoked with `err` and `info.
  #
  # `info` contains an object with tv show information.
  getInfoTvShow: (tvShowId, done, language) ->
    options = { language: 'en', seriesId: tvShowId }
    options.language = language if language?
    self = this

    @get path: this.getPath("getInfoTvShow", options), (err, files) ->
      return done err if err?

      done undefined, self.formatTvShow files.Series


  # Retrieves basic information for a specific TV Show episode.
  #
  # The callback `done`gets invoked with `err` and `info.
  #
  # `info` contains an object with tv show episode information.
  getInfoEpisode: (episodeId, done, language) ->
    options = { language: 'en', episodesId: episodeId }
    options.language = language if language?
    self = this

    @get path: this.getPath("getInfoEpisode", options), (err, files) ->
      return done err if err?

      done undefined, self.formatEpisode files.Episode

  # Unzips a zip buffer and returns an object with the filenames as keys and the data as values.
  unzip: (zipBuffer, done) ->
    zip = new Zip zipBuffer.toString("base64"), base64: true, checkCRC32: true
    files = { }
    _.each zip.files, (file, index) ->
      files[file.name] = file.data
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
  getUpdates: (period, done) ->
    if !(['day', 'week', 'month'].some (p) -> p == period)
      return done new Error "Invalid period #{period}"

    options = { period: period }

    @get path: this.getPath("getUpdates", options), (err, files) ->
      return done err if err?

      formattedResult = {}

      _.each files, (xml) ->
        xmlParser.parseString xml, (err, updates) ->
          return done new Error "Invalid XML: #{err.message}" if err?

          _.each updates, (update, key) ->
            if key == "$"
              formattedResult['updateInfo'] = update;

            else if key == "Series"
              formattedResult['tvShows'] = update;

            else if key == "Episode"
              formattedResult['episodes'] = [];

              _.each update, (episode) ->
                formattedResult['episodes'].push { id: episode.id, tvShowId: episode.Series, time: episode.time }

            else if key == "Banner"
              formattedResult['banners'] = [];

              _.each update, (banner) ->
                bannerInfo = {
                  tvShowId: banner.Series,
                  path: banner.path,
                  time: banner.time,
                  type: banner.type
                }
                bannerInfo.season = banner.SeasonNum if banner.SeasonNum?
                bannerInfo.format = banner.format if banner.format?
                bannerInfo.language = banner.language if banner.language?

                formattedResult['banners'].push bannerInfo

      done undefined, formattedResult

  formatTvShow: (tvShow) ->
    keyMapping = IMDB_ID: 'imdbId', zap2it_id: 'zap2itId', banner: 'banner', Overview: 'overview'
    formattedTvShow =
      id: tvShow.id,
      genre: tvShow.Genre,
      language: tvShow.Language,
      name: tvShow.SeriesName

    formattedTvShow.firstAired = new Date(tvShow.FirstAired) if tvShow.FirstAired?

    _.each keyMapping, (trgKey, srcKey) ->
      srcValue = tvShow[srcKey]
      formattedTvShow[trgKey] = srcValue if srcValue

    return formattedTvShow


  formatEpisode: (episode) ->
    keyMapping = Overview: 'overview', Rating: 'rating', RatingCount: 'ratingCount', Writer: 'writer'

    formattedEpisode =
      id: episode.id,
      name: episode.EpisodeName,
      number: episode.EpisodeNumber,
      language: episode.Language,
      season: episode.SeasonNumber
      seasonId: episode.seasonid,
      tvShowId: episode.seriesid,
      lastUpdated: episode.lastupdated

    formattedEpisode.firstAired = new Date(episode.FirstAired) if episode.FirstAired?

    _.each keyMapping, (trgKey, srcKey) ->
      srcValue = episode[srcKey]
      formattedEpisode[trgKey] = srcValue if srcValue

    return formattedEpisode

# Exposing TVDB
# @type {TVDB}
module.exports = TVDB


# Exposing the XML Parser as well
module.exports.xmlParser = xmlParser
