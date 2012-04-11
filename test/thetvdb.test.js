
var TVDB = require("../lib/index")
  , fs = require("fs")
  , _ = require("underscore")
  , xmlParser = new (require("xml2js")).Parser();

describe("tvdb", function() {
  describe("constructor", function() {
    it("should store options correctly", function() {
      var options = { apiKey: '1234', port: 8080, initialHost: 'anothertvdb', language: "fr" }
       , tvdb = new TVDB(options);
      tvdb.options.should.eql(options);
    });
  });

  describe("setLanguage()", function() {
    it("should set options.language", function() {
      var tvdb = new TVDB({ apiKey: "123" });
      tvdb.options.language.should.equal("en");
      tvdb.setLanguage("de");
      tvdb.options.language.should.equal("de");
    });
  });

  describe("get()", function() {
    it("should correctly use http to fetch the resource");
    it("should parse the XML if the parseXml option has been passed");
    it("should call the callback with error if the response was not valid");
    it("should call the callback with error if the xml was invalid");
  });

  describe("getUrl()", function() {
    it("should return all urls with API key", function() {
      var options = { apiKey: '1234abc' }
       , tvdb = new TVDB(options);
      tvdb.getPath("mirrors").should.equal("/api/1234abc/mirrors.xml");
    })
  });
  describe("getMirrors()", function() {
    var options = { apiKey: '1234abc' }
     , tvdb = new TVDB(options)
     , xmlUri;

    tvdb.get = function(opts, callback) {
      var xml = fs.readFileSync(xmlUri, "utf8");
      xmlParser.parseString(xml, callback);
    };
    
    it("should return a valid list if only one mirror", function(done) {
      xmlUri = __dirname + "/data/mirrors.single.xml";
      tvdb.getMirrors(function(err, mirrors) {
        mirrors.should.eql([{
          id: '1',
          url: 'http://thetvdb.com',
          types: [ 'xml', 'banner', 'zip' ]
        }]);
        done();
      });
    });

    it("should return a valid list if multiple mirrors", function(done) {
      xmlUri = __dirname + "/data/mirrors.multiple.xml";
      tvdb.getMirrors(function(err, mirrors) {
        mirrors.length.should.equal(7);
        var ids = [];
        _.each(mirrors, function(mirror) {
          ids.push(mirror.id);
          switch(mirror.id) {
            case "1":
              mirror.url.should.equal("xmlonly");
              mirror.types.should.eql(["xml"]);
              break;
            case "2":
              mirror.url.should.equal("bannersonly");
              mirror.types.should.eql(["banner"]);
              break;
            case "3":
              mirror.url.should.equal("ziponly");
              mirror.types.should.eql(["zip"]);
              break;
            case "4":
              mirror.url.should.equal("everything");
              mirror.types.should.eql(["xml", "banner", "zip"]);
              break;
            case "5":
              mirror.url.should.equal("xmlandbanners");
              mirror.types.should.eql(["xml", "banner"]);
              break;
            case "6":
              mirror.url.should.equal("xmlandzip");
              mirror.types.should.eql(["xml", "zip"]);
              break;
            case "7":
              mirror.url.should.equal("bannersandzip");
              mirror.types.should.eql(["banner", "zip"]);
              break;
          }
        });
        ids.should.eql(["1", "2", "3", "4", "5", "6", "7"]);
        done();
      });
    });
  });

  describe("getLanguages()", function() {
    var options = { apiKey: '1234abc' }
     , tvdb = new TVDB(options)
     , xmlUri;

    tvdb.get = function(opts, callback) {
      var xml = fs.readFileSync(xmlUri, "utf8");
      xmlParser.parseString(xml, callback);
    };
    
    it("should return a valid list if only one language", function(done) {
      // That's a crazy use case, but so am I.
      xmlUri = __dirname + "/data/languages.single.xml";
      tvdb.getLanguages(function(err, languages) {
        languages.should.eql([{
          id: '17',
          name: 'Français',
          abbreviation: 'fr'
        }]);
        done();
      });
    });

    it("should return a valid list if multiple languages", function(done) {
      xmlUri = __dirname + "/data/languages.multiple.xml";
      tvdb.getLanguages(function(err, languages) {
        languages.length.should.equal(23);
        _.each(languages, function(language) {
          language.id.should.be.a('string').and.not.be.empty;
          language.name.should.be.a('string').and.not.be.empty;
          language.abbreviation.should.be.a('string').and.not.be.empty;
        });
        done();
      });
    });

  });
});