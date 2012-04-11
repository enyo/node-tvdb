
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

  describe("constructor", function() {
    it("should store options correctly", function() {
      var options = { apiKey: '1234', port: 8080, initialHost: 'anothertvdb', language: "fr" }
       , tvdb = new TVDB(options);
      tvdb.options.should.eql(options);
    });
    it("should throw exception if no valid apiKey has been provided", function() {
      var message = "You have to provide an API key.";
      (function() {
        new TVDB();
      }).should.throw(message);
      (function() {
        new TVDB({ apiKey: "" });
      }).should.throw(message);
      (function() {
        new TVDB({ apiKey: false });
      }).should.throw(message);
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
  
  describe("getSeriesByName()", function() {
	  it("should call the callback with error due to null keywords argument", function(done) {
		  tvdbWithError.getSeriesByName(null, function(err, mirrors) {
			  err.should.be.instanceof(Error);
			  done();
		  });
	  });
	  it("should call the callback with error due to empty keywords array", function(done) {
		  tvdbWithError.getSeriesByName([], function(err, mirrors) {
			  err.should.be.instanceof(Error);
			  done();
		  });
	  });
	  it("should return a valid list if only one series", function(done) {
		  xmlUri = __dirname + "/data/seriesByName.single.xml";
		  tvdb.getSeriesByName(["30","Rock"], function(err, series) {
			  series.should.eql([{
				   id: '79488',
				   language: 'en',
				   name: '30 Rock',
				   banner: 'graphical/79488-g11.jpg',
				   overview: "Emmy Award Winner Tina Fey writes, executive produces and stars as Liz Lemon, the head writer of a live variety programme in New York City. Liz's life is turned upside down when brash new network executive Jack Donaghy (Alec Baldwin in his Golden Globe winning role) interferes with her show, bringing the wildly unpredictable Tracy Jordan (Tracy Morgan) into the cast. Now its up to Liz to manage the mayhem and still try to have a life.",
				   firstAired: '2006-10-11',
				   imdbId: 'tt0496424',
				   zap2itId: 'SH00848357'
			   }]);
			   done();
		   });
	   });
 	  it("should return a valid list of multiple series", function(done) {
 		  xmlUri = __dirname + "/data/seriesByName.multiple.xml";
 		  tvdb.getSeriesByName(["30"], function(err, allSeries) {
	          allSeries.length.should.equal(3);
	          var ids = [];
	          _.each(allSeries, function(series) {
	            ids.push(series.id);
	            switch(series.id) {
	              case "255912":
	                series.language.should.equal("en");
	                series.name.should.eql("30 Grader i Februari");
					series.banner.should.equal("graphical/255912-g.jpg");
					series.firstAired.should.equal("2012-02-06");
					series.imdbId.should.equal("tt1677734");
	                break;
	              case "255048":
	                series.language.should.equal("en");
	                series.name.should.eql("RBO 3.0");
					series.banner.should.equal("graphical/255048-g2.jpg");
					series.firstAired.should.equal("2012-01-09");
	                break;
	              case "238461":
	                series.language.should.equal("en");
	                series.name.should.eql("30 Vies");
					series.banner.should.equal("graphical/238461-g.jpg");
					series.firstAired.should.equal("2011-01-10");
					series.imdbId.should.equal("tt1851101");
					series.overview.should.equal("In 30 lives, Marina Orsini plays the role of Gabrielle, a professor in a multiethnic high school. 30 lives, is also the story of 29 students from Gabrielle, which we will follow the stories and plots throughout the season. But 30 lives is, first and foremost, the story of lives that come together, collide, and who, day after day, will vibrate Quebec.");
	                break;
	            }
	          });
	          ids.should.eql(["255912", "255048", "238461"]);
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

});