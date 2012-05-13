
TVDB = require "../lib/index"
fs = require "fs"
_ = require "underscore"
xmlParser = new (require "xml2js").Parser();
http = require "http"


describe "tvdb", ->
  tvdbWithError = new TVDB { apiKey: "12" }

  tvdbWithError.get = (opts, callback) ->
    callback new Error "test error"
  
  options = { apiKey: '1234abc' }
  tvdb = new TVDB options
  xmlUri = null

  tvdb.get = (opts, callback) ->
    xml = fs.readFileSync xmlUri, "utf8"
    xmlParser.parseString xml, callback

  describe "constructor", ->
    it "should store options correctly", ->
      options =
        apiKey: '1234'
        port: 8080
        initialHost: 'anothertvdb'
        language: "fr"

      tvdb = new TVDB options
      tvdb.options.should.eql options

    it "should throw exception if no valid apiKey has been provided", ->
      message = "You have to provide an API key."

      (-> new TVDB ).should.throw message
      (-> new TVDB apiKey: "").should.throw message
      (-> new TVDB apiKey: false).should.throw message

  describe "setLanguage()", ->
    it "should set options.language", ->
      tvdb = new TVDB apiKey: "123"
      tvdb.options.language.should.equal "en"
      tvdb.setLanguage "de"
      tvdb.options.language.should.equal "de"

  describe "get()", ->
    httpGet = null
    httpData = "some data"
    statusCode = 200
    httpOptionsInterceptor = null
    beforeEach ->
      statusCode = 200
      httpOptionsInterceptor = ->
      httpGet = http.get
      http.get = (options, callback) ->
        httpOptionsInterceptor options
        callback
          statusCode: statusCode
          setEncoding: (encoding) -> return null
          on: (event, callback) ->
            switch event
              when "data"
                setTimeout (-> callback(httpData)), 5
              when "end"
                setTimeout callback, 10

        { on: (event, callback) -> }
    afterEach ->
      http.get = httpGet

    it "should correctly use http to fetch the resource", (done) ->
      httpData = "blabla"
      tvdb.get { parseXml: false }, (err, data) ->
        data.should.eql "blabla"
        done()
        
    it "should parse the XML if the parseXml option has been passed", (done) ->
      httpData = "<some><xml>test</xml></some>"
      tvdb.get { parseXml: true }, (err, data) ->
        data.should.eql { xml: "test" }
        done()

    it "should forward the options provided", (done) ->
      httpOptionsInterceptor = (options) ->
        options.should.eql host: 'thetvdb.com', port: 80, parseXml: false, path: '/some/path'
        done()
      tvdb.get { path: "/some/path", parseXml: false }, (err, data) ->

    it "should use pathName to translate it to a valid path", (done) ->
      httpOptionsInterceptor = (options) ->
        options.should.eql host: 'thetvdb.com', port: 80, parseXml: false, path: '/api/123/mirrors.xml'
        done()
      tvdb.get { pathName: "mirrors", parseXml: false }, (err, data) ->

    it "should call the callback with error if the response was not valid", (done) ->
      statusCode = 404
      tvdb.get { parseXml: false }, (err, data) ->
        err.should.be.instanceof Error
        err.message.should.eql "Status: 404"
        done()
    it "should call the callback with error if the xml was invalid", (done) ->
      httpData = "invalid xml"
      tvdb.get { parseXml: true }, (err, data) ->
        err.should.be.instanceof Error
        err.message.indexOf("Invalid XML").should.equal 0
        done()
      

  describe "getUrl()", ->
    it "should return all urls with API key", ->
      options = apiKey: '1234abc'
      tvdb = new TVDB options
      tvdb.getPath("mirrors").should.equal("/api/1234abc/mirrors.xml");

    it "should return all urls with language", ->
      options = apiKey: '1234abc', language: "de"
      tvdb = new TVDB options
      tvdb.getPath("findTvShow").should.equal '/api/GetSeries.php?seriesname=#{name}&language=de'

    it "should additionally replace all values passed in the values object and escape them", ->
      options = apiKey: '1234abc', language: "de"
      tvdb = new TVDB options
      tvdb.getPath("findTvShow", { name: "bestname" }).should.equal "/api/GetSeries.php?seriesname=bestname&language=de"
      tvdb.getPath("findTvShow", { name: "weird  & name" }).should.equal "/api/GetSeries.php?seriesname=weird%20%20%26%20name&language=de"

  describe "unzip()", ->
    it "should properly unzip a single file, and call done", (done) ->
      tvdb.unzip fs.readFileSync(__dirname + "/data/dexter.en.zip"), (err, file) ->
        content = fs.readFileSync __dirname + "/data/dexter.en.zip.deflated/actors.xml", "utf-8"
        file["actors.xml"].should.eql content
        done()




