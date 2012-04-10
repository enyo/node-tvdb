
var TheTVDB = require("../lib/index")
  , fs = require("fs")
  , _ = require("underscore")
  , xmlParser = new (require("xml2js")).Parser();

describe("thetvdb", function() {
  describe("constructor", function() {
    it("should store options correctly", function() {
      var options = { apiKey: '1234', port: 8080, initialHost: 'anothertvdb' }
       , thetvdb = new TheTVDB(options);
      thetvdb.options.should.eql(options);
    });
  });
  describe("getUrl()", function() {
    it("should return all urls with API key", function() {
      var options = { apiKey: '1234abc' }
       , thetvdb = new TheTVDB(options);
      thetvdb.getPath("mirrors").should.equal("/api/1234abc/mirrors.xml");
    })
  });
  describe("getMirrors()", function() {
    var options = { apiKey: '1234abc' }
     , thetvdb = new TheTVDB(options)
     , xmlUri;

    thetvdb.get = function(opts, callback) {
      var xml = fs.readFileSync(xmlUri, "utf8");
      xmlParser.parseString(xml, callback);
    };
    
    it("should return a valid list if only one mirror", function(done) {
      xmlUri = __dirname + "/data/mirrors.single.xml";
      thetvdb.getMirrors(function(err, mirrors) {
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
      thetvdb.getMirrors(function(err, mirrors) {
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
});