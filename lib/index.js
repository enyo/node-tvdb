

var xmlParser = new (require("xml2js")).Parser()
  , http = require("http")
  , _ = require("underscore");

/**
 * The configuration options are:
 * 
 *     - `apiKey` String
 *     - `initialHost` String (optional) Default: `thetvdb.com`
 *     - `port` Number (optional) Default: 80
 * 
 * @param {Object} options
 * @api public
 */
var TheTVDB = function(options) {
  this.options = _.extend({ initialHost: "thetvdb.com", port: 80 }, options || { });
  if (!this.options.apiKey) throw new Error("You have to provide an API key.");
};



/**
 * A list of thetvdb.com paths.
 * 
 * @type {Object}
 * @api private
 */
TheTVDB.prototype.paths = {
    mirrors: "/api/#{apiKey}/mirrors.xml"
  , languages: "/api/#{apiKey}/languages.xml"
};

/**
 * Returns the path and replaces the api key with provided key.
 * 
 * @param  {String} pathName E.g.: mirrors
 * @return {String} 
 * @api private
 */
TheTVDB.prototype.getPath = function(pathName) {
  return this.paths[pathName].replace("#{apiKey}", this.options.apiKey);
};


/**
 * Shortcut for http.get
 * 
 * @param  {Object} options
 * @param  {Function} callback
 * @api private
 */
TheTVDB.prototype.get = function(options, callback) {
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
TheTVDB.prototype.getLanguages = function(done) {
  this.get({ pathName: "languages" }, function(err, response) {
    var languages = _.isArray(response.Language) ? response.Language : [response.Language];
    done(err, languages);
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
TheTVDB.prototype.getMirrors = function(done) {
  this.get({ pathName: "mirrors" }, function(err, response) {
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
    done(err, formattedMirrors);
  });
};


/**
 * Exposing TheTVDB
 * @type {TheTVDB}
 */
module.exports = TheTVDB;