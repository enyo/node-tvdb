
TVDB = require "../src/index"
fs = require "fs"
_ = require "underscore"
xmlParser = TVDB.xmlParser
http = require "http"


describe "tvdb", ->
 
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

  describe "setMirror()", ->
    it "should set options.initialHost", ->
      tvdb = new TVDB apiKey: "123"
      tvdb.options.initialHost.should.equal "thetvdb.com"
      tvdb.options.port.should.equal 80
      tvdb.setMirror "thetvdbtest.com", 8080
      tvdb.options.initialHost.should.equal "thetvdbtest.com"
      tvdb.options.port.should.equal 8080
      tvdb = new TVDB apiKey: "123"

  describe "get()", ->
    httpGet = null
    httpData = "some data"
    statusCode = 200
    contentType = "text/plain"
    httpOptionsInterceptor = null
    beforeEach ->
      statusCode = 200
      httpOptionsInterceptor = ->
      httpGet = http.get
      http.get = (options, callback) ->
        httpOptionsInterceptor options
        callback
          statusCode: statusCode
          headers: {'content-type': contentType}
          setEncoding: (encoding) -> return null
          on: (event, callback) ->
            switch event
              when "data"
                buffer = if httpData instanceof Buffer then httpData else new Buffer httpData 
                setTimeout (-> callback(buffer)), 5
              when "end"
                setTimeout callback, 10
        { on: (event, callback) -> }

    afterEach ->
      http.get = httpGet

    it "should correctly use http to fetch the resource", (done) ->
      httpData = "blabla"
      tvdb.get { }, (err, data) ->
        data.should.eql "blabla"
        done()
        
    it "should parse the XML if the contentType was application/xml", (done) ->
      httpData = "<some><xml>test</xml></some>"
      contentType = "application/xml"
      tvdb.get { }, (err, data) ->
        data.should.eql { xml: "test" }
        done()

    it "should parse the XML if the contentType was text/xml", (done) ->
      httpData = "<some><xml>test</xml></some>"
      contentType = "text/xml"
      tvdb.get { }, (err, data) ->
        data.should.eql { xml: "test" }
        done()

    it "should forward the options provided", (done) ->
      httpOptionsInterceptor = (options) ->
        options.should.eql host: 'thetvdb.com', port: 80, path: '/some/path'
        done()
      tvdb.get { path: "/some/path" }, (err, data) ->

    it "should use pathName to translate it to a valid path", (done) ->
      httpOptionsInterceptor = (options) ->
        options.should.eql host: 'thetvdb.com', port: 80, path: '/api/123/mirrors.xml'
        done()
      tvdb.get { pathName: "mirrors" }, (err, data) ->

    it "should call the callback with error if the response was not valid", (done) ->
      statusCode = 404
      tvdb.get { }, (err, data) ->
        err.should.be.instanceof Error
        err.message.should.eql "Status: 404"
        done()

    it "should call the callback with error if the xml was invalid", (done) ->
      httpData = "invalid xml"
      contentType = "application/xml"
      tvdb.get { }, (err, data) ->
        err.should.be.instanceof Error
        err.message.indexOf("Invalid XML").should.equal 0
        done()
      
    it "should unzip zip files directly", (done) ->
      httpData = fs.readFileSync "#{__dirname}/data/test.zip"
      contentType = "application/zip"
      tvdb.get { }, (err, data) ->
        data.should.not.be.instanceof Buffer
        data["test.txt"].should.eql "test content"
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




