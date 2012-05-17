TVDB = require "../lib/index"
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
        getHeader: (which) ->
          return contentType if which == "content-type"
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
        tvShows.length.should.equal 0
        done()

  describe "getInfo()", ->
    it "should call the callback with error", (done) ->
      tvdbWithError.getInfo "mirrorurl.com", "id", (err, mirrors) ->
        err.should.be.instanceof Error
        err.message.should.equal "test error"
        done()
    it "should return a valid object containing Json objects", (done) ->
      contentType = "application/zip"
      dataFileUri = __dirname + "/data/dexter.en.zip"
      tvdb.getInfo "mirrorurl.com", "id", (err, info) ->
        done()
