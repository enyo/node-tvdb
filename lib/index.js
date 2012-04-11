

var xmlParser = new (require("xml2js")).Parser()
  , http = require("http")
  , _ = require("underscore");



/**
 * The default options you can override by passing an options object in the constructor.
 * 
 *     - `apiKey` String
 *     - `language` String (optional) Default: 'en' You can set this later, with setLanguage(). Use
 *                         getLanguages() to get a list of languages, and use the abbreviation.
 *     - `initialHost` String (optional) Default: `thetvdb.com`
 *     - `port` Number (optional) Default: 80
 * 
 * @type {Object}
 */
var defaultOptions = {
    apiKey: null
  , language: "en"
  , initialHost: "thetvdb.com"
  , port: 80
};

/**
 * @param {Object} options
 * @api public
 */
var TVDB = function(options) {
  this.options = _.extend(_.clone(defaultOptions), options || { });
  if (!this.options.apiKey) throw new Error("You have to provide an API key.");
};


/**
 * Sets the language option.
 * 
 * @param {String} abbreviation E.g.: "fr"
 */
TVDB.prototype.setLanguage = function(abbreviation) {
  this.options.language = abbreviation;
};


/**
 * A list of thetvdb.com paths.
 * 
 * @type {Object}
 * @api private
 */
TVDB.prototype.paths = {
    mirrors: "/api/#{apiKey}/mirrors.xml"
  , languages: "/api/#{apiKey}/languages.xml"
  , serverTime: "/api/Updates.php?type=none"
  , seriesByName: "/api/GetSeries.php?seriesname="
};

/**
 * Returns the path and replaces the api key with provided key.
 * 
 * @param  {String} pathName E.g.: mirrors
 * @return {String} 
 * @api private
 */
TVDB.prototype.getPath = function(pathName) {
  return this.paths[pathName].replace("#{apiKey}", this.options.apiKey);
};


/**
 * Shortcut for http.get
 * 
 * @param  {Object} options
 * @param  {Function} callback
 * @api private
 */
TVDB.prototype.get = function(options, callback) {
  options = _.extend({ host: this.options.initialHost, port: this.options.port, parseXml: true }, options);

  if (options.pathName) {
    options.path = this.getPath(options.pathName);
    delete options.pathName;
  }
  
  if (options.arguments) {
	  options.path += options.arguments;
	  delete options.arguments;
  }
  
  http.get(options, function(res) {
    var response = '';
    if (res.statusCode < 100 || res.statusCode >= 300) {
      callback(new Error("Status: " + res.statusCode));
      return;
    }
    res.setEncoding('utf8');
    res.on('data', function (chunk) {
      response += chunk;
    });
    res.on('end', function () {
      if (options.parseXml) {
        xmlParser.parseString(response, function (err, result) {
          callback(err, result);
        });
      }
      else {
        callback(null, response);
      }
    });
  }).on("error", function(e) {
    callback(e);
  });
};


/**
 * Calls `done` with `err` if an error occured, and an array containing a list of languages.
 * 
 * A language is an object containing:
 * 
 *   - `id` String
 *   - `name` String
 *   - `abbreviation` String
 * 
 * @param {Function} done
 * @api public
 */
TVDB.prototype.getLanguages = function(done) {
  this.get({ pathName: "languages" }, function(err, response) {
    if (err) { done(err); return; }

    var languages = _.isArray(response.Language) ? response.Language : [response.Language];
    done(undefined, languages);
  });
};

/**
 * Calls `done` with `err` if an error occured, and an array containing a list of mirrors.
 * 
 * A mirror is an object containing:
 * 
 *   - `id` String
 *   - `url` String
 *   - `types` Array containing at least one of `xml`, `banner` and `zip`.
 * 
 * @param {Function} done
 * @api public
 */
TVDB.prototype.getMirrors = function(done) {
  this.get({ pathName: "mirrors" }, function(err, response) {
    if (err) { done(err); return; }

    var mirrors = _.isArray(response.Mirror) ? response.Mirror : [response.Mirror]
      , masks = { xml: 1, banner: 2, zip: 4 }
      , formattedMirrors = [];

    _.each(mirrors, function(mirror) {
      var formattedMirror = {
          id: mirror.id
        , url: mirror.mirrorpath
        , types: [ ]
      };
      _.each(masks, function(mask, type) {
        if ((mirror.typemask & mask) === mask) formattedMirror.types.push(type);
      });
      formattedMirrors.push(formattedMirror);
    });
    done(undefined, formattedMirrors);
  });
};

/**
 * Gets the server timestamp
 * 
 * @param  {Function} done 
 * @api public
 */
TVDB.prototype.getServerTime = function(done) {
  this.get({ pathName: "serverTime" }, function(err, response) {
    if (err) { done(err); return; }
    done(undefined, parseInt(response.Time));
  });
};

/**
 * Gets a list of all matching series with titles matching the given keywords
 * 
 * @param {Array} titleKeywords
 * Calls `done` with `err` if an error occured, and an array containing a list of series.
 * 
 * A series is an object containing:
 * 
 *   - `id` String
 *   - `name` String
 *   - `language` String
 *   - `banner` String
 *   - `overview` String
 *   - `firstAired` Date
 *   - `imdbId` String
 *   - `zap2itId` String
 *
 * @api public
 */
TVDB.prototype.getSeriesByName = function(titleKeywords, done) {
	if (titleKeywords) {
		this.get({ pathName: "seriesByName", arguments: titleKeywords.join('+') }, function(err, response) {
			if (err) {
				done(err);
			} else {
				var allFormattedSeries = [];
			    var allSeries = _.isArray(response.Series) ? response.Series : [response.Series];
			    _.each(allSeries, function(series) {
					if (series) {
						var formattedSeries = {
							id: series.seriesid
					        , name: series.SeriesName
					        , language: series.language
							, banner: series.banner
							, overview: series.Overview
							, firstAired: series.FirstAired
							, imdbId: series.IMDB_ID
							, zap2itId: series.zap2it_id
						};
						allFormattedSeries.push(formattedSeries);
					}
			  });
			  done(err, allFormattedSeries);
			}
		});
	} else {
		var err = new Error("Expected keywords");
		done(err);
	}
}

/**
 * Exposing TVDB
 * @type {TVDB}
 */
module.exports = TVDB;