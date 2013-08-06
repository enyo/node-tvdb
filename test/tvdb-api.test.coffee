TVDB = require "../src/index"
fs = require "fs"
_ = require "underscore"
xmlParser = new (require("xml2js")).Parser()
http = require "http"

describe "tvdb", ->
  tvdbWithError = new TVDB apiKey: "12"
  tvdbWithError.get = (opts, callback) ->
    callback new Error "test error"

  options = apiKey: "1234abc"

  tvdb = new TVDB options
  dataFileUri = undefined

  httpGet = null
  statusCode = 200
  contentType = "text/xml"
  beforeEach ->
    statusCode = 200
    httpGet = http.get
    http.get = (options, callback) ->
      callback
        statusCode: statusCode
        headers: {'content-type': contentType}
        setEncoding: (encoding) -> return null
        on: (event, callback) ->
          switch event
            when "data"
              setTimeout (-> callback(fs.readFileSync(dataFileUri))), 5
            when "end"
              setTimeout callback, 10
      { on: (event, callback) -> }


  afterEach ->
    http.get = httpGet
    dataFileUri = undefined

  describe "getMirrors()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getMirrors (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()

    it "should return a valid list if only one mirror", (done) ->
      dataFileUri = __dirname + "/data/mirrors.single.xml"
      tvdb.getMirrors (err, mirrors) ->
        mirrors.should.eql [
          id: "1"
          url: "http://thetvdb.com"
          types: [ "xml", "banner", "zip" ]
        ]
        done()

    it "should return a valid list if multiple mirrors", (done) ->
      dataFileUri = __dirname + "/data/mirrors.multiple.xml"
      tvdb.getMirrors (err, mirrors) ->
        mirrors.length.should.equal 7
        ids = []
        _.each mirrors, (mirror) ->
          ids.push mirror.id
          switch mirror.id
            when "1"
              mirror.url.should.equal "xmlonly"
              mirror.types.should.eql [ "xml" ]
            when "2"
              mirror.url.should.equal "bannersonly"
              mirror.types.should.eql [ "banner" ]
            when "3"
              mirror.url.should.equal "ziponly"
              mirror.types.should.eql [ "zip" ]
            when "4"
              mirror.url.should.equal "everything"
              mirror.types.should.eql [ "xml", "banner", "zip" ]
            when "5"
              mirror.url.should.equal "xmlandbanners"
              mirror.types.should.eql [ "xml", "banner" ]
            when "6"
              mirror.url.should.equal "xmlandzip"
              mirror.types.should.eql [ "xml", "zip" ]
            when "7"
              mirror.url.should.equal "bannersandzip"
              mirror.types.should.eql [ "banner", "zip" ]

        ids.should.eql [ "1", "2", "3", "4", "5", "6", "7" ]
        done()

  describe "getLanguages()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getMirrors (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()

    it "should return a valid list if only one language", (done) ->
      dataFileUri = __dirname + "/data/languages.single.xml"
      tvdb.getLanguages (err, languages) ->
        languages.should.eql [
          id: "17"
          name: "Français"
          abbreviation: "fr"
        ]
        done()

    it "should return a valid list if multiple languages", (done) ->
      dataFileUri = __dirname + "/data/languages.multiple.xml"
      tvdb.getLanguages (err, languages) ->
        languages.length.should.equal 23
        _.each languages, (language) ->
          language.id.should.be.a("string").and.not.be.empty
          language.name.should.be.a("string").and.not.be.empty
          language.abbreviation.should.be.a("string").and.not.be.empty

        done()

  describe "getServerTime()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getServerTime (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()

    it "should return the server time correctly", (done) ->
      dataFileUri = __dirname + "/data/server_time.xml"
      tvdb.getServerTime (err, time) ->
        time.should.be.a("number").and.equal 1334162822
        done()

  describe "findTvShow()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.findTvShow "test name", (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()

    it "should use the right path", (done) ->
      localTvdb = new TVDB apiKey: "1234abc"
      localTvdb.get = (opts, callback) ->
        opts.path.indexOf("seriesname=abc%26%20c").should.not.equal -1
        done()

      localTvdb.findTvShow "abc& c", (err, time) ->

    it "should return a valid list if only one tv show", (done) ->
      dataFileUri = __dirname + "/data/find_tv_show.single.xml"

      tvdb.findTvShow "dexter", (err, tvShows) ->
        data =
          id: "79349"
          language: "en"
          name: "Dexter"
          imdbId: "tt0773262"
          zap2itId: "SH859795"
          banner: "graphical/79349-g6.jpg"
          overview: "Overview text."

        tvShows.length.should.equal 1
        tvShow = tvShows[0]
        tvShow.firstAired.getTime().should.equal new Date("2006-10-01").getTime()
        _.each data, (value, key) ->
          tvShow[key].should.equal value

        done()

    it "should return a valid list if only one tv show with very little information", (done) ->
      dataFileUri = __dirname + "/data/find_tv_show.naked.xml"
      tvdb.findTvShow "dexter", (err, tvShows) ->
        tvShows.length.should.equal 1
        tvShows[0].should.eql
          id: "79349"
          language: "en"
          name: "Dexter"

        done()

    it "should return a valid list if multiple tv shows", (done) ->
      dataFileUri = __dirname + "/data/find_tv_show.multiple.xml"
      tvdb.findTvShow "dexter", (err, tvShows) ->
        tvShows.length.should.equal 2
        tvShows[0].name.should.equal "Dexter"
        tvShows[0].id.should.equal "79349"
        tvShows[1].name.should.equal "Cliff Dexter"
        tvShows[1].id.should.equal "159611"
        done()

    it "should return a valid list if no tv show was found", (done) ->
      dataFileUri = __dirname + "/data/no_data.xml"
      tvdb.findTvShow "dexter", (err, tvShows) ->
        (err == undefined).should.be.ok
        tvShows.length.should.equal 0
        done()

  describe "getInfo()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getInfo "id", (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()
    it "should return a valid object containing Json objects", (done) ->
      contentType = "application/zip"
      dataFileUri = __dirname + "/data/dexter.en.zip"
      tvdb.getInfo "id", (err, info) ->
        info.tvShow.should.exist
        info.episodes.should.exist
        info.banners.should.exist
        info.actors.should.exist
        info.tvShow.name.should.equal "Dexter"
        info.tvShow.id.should.equal "79349"
        info.episodes[0].name.should.equal "Early Cuts: Alex Timmons (Chapter 1)"
        info.episodes[0].id.should.equal "1285811"
        info.banners[0].id.should.equal "30362"
        info.actors[0].name.should.equal "Michael C. Hall"
        info.actors[0].id.should.equal "70947"
        done()

  describe "getInfoTvShow()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getInfoTvShow "id", (err, tvShow) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()
    it "should return a valid object containing Json data", (done) ->
      contentType = "text/xml"
      dataFileUri = __dirname + "/data/series.single.xml"
      tvdb.getInfoTvShow "id", (err, tvShow) ->
        tvShow.id.should.equal "70327"
        Object.getOwnPropertyNames(tvShow).length.should.equal 9
        done()

  describe "getInfoEpisode()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getInfoEpisode "id", (err, episode) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()
    it "should return a valid object containing Json data", (done) ->
      dataFileUri = __dirname + "/data/episodes.single.xml"
      tvdb.getInfoEpisode "id", (err, episode) ->
        episode.id.should.equal "3954591"
        Object.getOwnPropertyNames(episode).length.should.equal 12
        done()

  describe "getUpdates()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getUpdates 'day', (err, files) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()
    it "should return a valid object containing Json objects", (done) ->
      contentType = "application/zip"
      dataFileUri = __dirname + "/data/updates_day.zip"
      tvdb.getUpdates 'day', (err, updates) ->
        updates.updateInfo.should.exist
        updates.tvShows.should.exist
        updates.episodes.should.exist
        updates.banners.should.exist
        updates.updateInfo.time.should.equal "1362426001"
        updates.tvShows[0].id.should.equal "70327"
        updates.episodes[0].time.should.equal "1362402840"
        updates.banners[0].path.should.equal "posters/266443-1.jpg"
        done()
    it "should not allow a non-valid period", (done) ->
      tvdb.getUpdates "weekly", (err, updates) ->
        err.should.be.instanceof Error
        err.message.should.equal "Invalid period weekly"
        done()
    it "should use different path depending on period", (done) ->
      localTvdb = new TVDB apiKey: "12"
      localTvdb.get = (opts) ->
        opts.path.should.equal "/api/12/updates/updates_day.zip"
      localTvdb.getUpdates 'day', (err, updates) ->
      localTvdb.get = (opts) ->
        opts.path.should.equal "/api/12/updates/updates_week.zip"
      localTvdb.getUpdates 'week', (err, updates) ->
      localTvdb.get = (opts) ->
        opts.path.should.equal "/api/12/updates/updates_month.zip"
        done()
      localTvdb.getUpdates 'month', (err, updates) ->
