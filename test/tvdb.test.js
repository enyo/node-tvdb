
var TVDB = require("../lib/index")
  , fs = require("fs")
  , _ = require("underscore")
  , xmlParser = new (require("xml2js")).Parser();

describe("tvdb", function() {
  var tvdbWithError = new TVDB({ apiKey: "12" });
  tvdbWithError.get = function(opts, callback) {
    callback(new Error("test error"));
  };
  
  var options = { apiKey: '1234abc' }
   , tvdb = new TVDB(options)
   , xmlUri;

  tvdb.get = function(opts, callback) {
    var xml = fs.readFileSync(xmlUri, "utf8");
    xmlParser.parseString(xml, callback);
  };


  describe("getMirrors()", function() {
    it("should call the callback with error", function(done) {
      tvdbWithError.getMirrors(function(err, mirrors) {
        err.should.be.instanceof(Error);
        err.message.should.equal("test error");
        done();
      });
    });

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
    it("should call the callback with error", function(done) {
      tvdbWithError.getMirrors(function(err, mirrors) {
        err.should.be.instanceof(Error);
        err.message.should.equal("test error");
        done();
      });
    });
    
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

  describe("getServerTime()", function() {
    it("should call the callback with error", function(done) {
      tvdbWithError.getServerTime(function(err, mirrors) {
        err.should.be.instanceof(Error);
        err.message.should.equal("test error");
        done();
      });
    });

    it("should return the server time correctly", function(done) {
      xmlUri = __dirname + "/data/server_time.xml";
      tvdb.getServerTime(function(err, time) {
        time.should.be.a("number").and.equal(1334162822);
        done();
      });
    });
  });



  describe("findTvShow()", function() {
    it("should call the callback with error", function(done) {
      tvdbWithError.findTvShow("test name", function(err, mirrors) {
        err.should.be.instanceof(Error);
        err.message.should.equal("test error");
        done();
      });
    });

    it("should use the right path", function(done) {
      var tvdb = new TVDB({ apiKey: '1234abc' });

      tvdb.get = function(opts, callback) {
        opts.path.indexOf("seriesname=abc%26%20c").should.not.equal(-1);
        done();
      };

      tvdb.findTvShow("abc& c", function(err, time) {
      });
    });

    it("should return a valid list if only one tv show", function(done) {
      xmlUri = __dirname + "/data/find_tv_show.single.xml";
      tvdb.findTvShow("dexter", function(err, tvShows) {
        var data = { id: '79349', language: 'en', name: 'Dexter', imdbId: 'tt0773262', zap2itId: 'SH859795', banner: 'graphical/79349-g6.jpg', overview: 'Overview text.' };

        tvShows.length.should.equal(1);
        var tvShow = tvShows[0];

        tvShow.firstAired.getTime().should.equal(new Date("2006-10-01").getTime());

        _.each(data, function(value, key) {
          tvShow[key].should.equal(value);
        });

        done();
      });
    });

    it("should return a valid list if only one tv show with very little information", function(done) {
      xmlUri = __dirname + "/data/find_tv_show.naked.xml";
      tvdb.findTvShow("dexter", function(err, tvShows) {
        tvShows.length.should.equal(1);
        tvShows[0].should.eql({ id: '79349', language: 'en', name: 'Dexter' });
        done();
      });
    });

    it("should return a valid list if multiple tv shows", function(done) {
      xmlUri = __dirname + "/data/find_tv_show.multiple.xml";
      tvdb.findTvShow("dexter", function(err, tvShows) {
        tvShows.length.should.equal(2);
        tvShows[0].name.should.equal("Dexter");
        tvShows[0].id.should.equal("79349");
        tvShows[1].name.should.equal("Cliff Dexter");
        tvShows[1].id.should.equal("159611");
        done();
      });
    });

    it("should return a valid list if no tv show was found", function(done) {
      xmlUri = __dirname + "/data/no_data.xml";
      tvdb.findTvShow("dexter", function(err, tvShows) {
        tvShows.length.should.equal(0);
        done();
      });
    });

  });

  describe("unzip()", function() {
    it("should properly unzip a single file, and call done.", function(done) {
      tvdb.unzip(fs.readFileSync(__dirname + "/data/dexter.en.zip"), "actors.xml", function(err, file) {
        file.readAsText("actors.xml").should.eql(fs.readFileSync(__dirname + "/data/dexter.en.zip.deflated/actors.xml", "utf-8"));
        done();
      })
    });
  });
});