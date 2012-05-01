

var xmlParser = new (require("xml2js")).Parser()
  , http = require("http")
  , _ = require("underscore")
  , querystring = require("querystring")
  , fs = require("fs")
  , NodeZip = require('node-zip')
  ;



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
  , findTvShow: "/api/GetSeries.php?seriesname=#{name}&language=#{language}"
  , getInfo: "/api/#{apiKey}/series/#{seriesId}/all/#{language}.zip"
};

/**
 * Returns the path and inserts api key and language if necessary.
 * 
 * @param  {String} pathName E.g.: mirrors
 * @param  {Object} values an optional hashmap object with values to replace in the path.
 * @return {String} 
 * @api private
 */
TVDB.prototype.getPath = function(pathName, values) {
  var path = this.paths[pathName];

  _.each(_.extend({ }, this.options, values), function(value, key) {
    path = path.replace("#{" + key + "}", querystring.escape(value));
  });

  return path;
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
          // if (_.isString(result) && !err) {
          //   err = new Error(result);
          //   result = null;
          // }
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
 * Finds a tv show by its name.
 * 
 * The callback `done` gets invoked with `err` and `tvShows`.
 * 
 * `tvShows` contains:
 * 
 *   - `id`
 *   - `language`
 *   - `name`
 * 
 * @param  {String} name 
 * @param  {Function} done 
 * @api public
 */
TVDB.prototype.findTvShow = function(name, done) {
  this.get({ path: this.getPath("findTvShow", { name: name }) }, function(err, tvShows) {
    if (err) { done(err); return; }

    var formattedTvShows = [ ];

    if (!_.isEmpty(tvShows)) {
      var tvShows = _.isArray(tvShows.Series) ? tvShows.Series : [tvShows.Series]
        , keyMapping = { IMDB_ID: 'imdbId', zap2it_id: 'zap2itId', banner: 'banner', Overview: 'overview',  };

      _.each(tvShows, function(tvShow) {
        var formattedTvShow = {
            id: tvShow.id
          , language: tvShow.language
          , name: tvShow.SeriesName
        };
        if (tvShow.FirstAired) formattedTvShow.firstAired = new Date(tvShow.FirstAired);
        _.each(keyMapping, function(trgKey, srcKey) {
          var srcValue = tvShow[srcKey];
          if (srcValue) formattedTvShow[trgKey] = srcValue;
        });
        formattedTvShows.push(formattedTvShow);
      });
    }

    done(undefined, formattedTvShows);
  });
};



/**
 * Unzips a zip buffer and returns the provided file.
 * 
 * @param  {Buffer} zipBuffer
 * @param  {String} fileToExtract
 * @param  {Function} done called with `err`, `extractedFile`
 * @api private
 */
TVDB.prototype.unzip = function(zipBuffer, fileToExtract, done) {
  var zip = new NodeZip(zipBuffer.toString("base64"), { base64: true });
  var unzipped = zip.files[fileToExtract].data;
  done(null, unzipped);
};



/**
 * Retrieves all information for a specific TV Show.
 * 
 * The callback `done` gets invoked with `err` and `info`.
 * 
 * `info` contains:
 * 
 * @param  {String} name 
 * @param  {Function} done 
 * @api public
 */
TVDB.prototype.getInfo = function(mirrorUrl, tvShowId, done, language) {
  var options = { parseXml: false };
  if (language) options.language = language;
  this.get({ path: this.getPath("getInfo", options) }, function(err, zip) {
    if (err) { done(err); return; }


    var formattedTvShows = [ ];

    if (!_.isEmpty(tvShows)) {
      var tvShows = _.isArray(tvShows.Series) ? tvShows.Series : [tvShows.Series]
        , keyMapping = { IMDB_ID: 'imdbId', zap2it_id: 'zap2itId', banner: 'banner', Overview: 'overview',  };

      _.each(tvShows, function(tvShow) {
        var formattedTvShow = {
            id: tvShow.id
          , language: tvShow.language
          , name: tvShow.SeriesName
        };
        if (tvShow.FirstAired) formattedTvShow.firstAired = new Date(tvShow.FirstAired);
        _.each(keyMapping, function(trgKey, srcKey) {
          var srcValue = tvShow[srcKey];
          if (srcValue) formattedTvShow[trgKey] = srcValue;
        });
        formattedTvShows.push(formattedTvShow);
      });
    }

    done(undefined, formattedTvShows);
  });
};




/**
 * Exposing TVDB
 * @type {TVDB}
 */
module.exports = TVDB;