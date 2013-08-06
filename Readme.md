# TheTVDB.com Node library Version 0.0.13


![Build status](https://travis-ci.org/enyo/node-tvdb.png?branch=master) (Master)  
![Build status](https://travis-ci.org/enyo/node-tvdb.png) (Development)


It's a wrapper for [thetvdb][]s XML API, written in [CoffeeScript][] for [node][].
You won't be in contact with any XML if you use this library.

> The library isn't finished yet. I'll update this README as I get along so
> you'll know what to expect.

You can check out [thetvdbs programmers API](http://thetvdb.com/wiki/index.php?title=Programmers_API)
to know what this library will be wrapping.

[node]: http://nodejs.org/
[thetvdb]: http://www.thetvdb.com/
[coffeescript]: http://coffeescript.org/


This project uses [semantic versioning](http://semver.org/) and uses this [tag script](https://github.com/enyo/tag) to tag the versions.

I use the great [mocha testing framework](http://visionmedia.github.com/mocha/) with the (also great) [should assertion library](https://github.com/visionmedia/should.js) for testing.  
If you contribute to this project, please write a test, and make sure all existing tests pass.

## Usage

> First off, [get an API key from thetvdb](http://thetvdb.com/?tab=apiregister).
> Withouth an API key you won't be able to do anything with this library.


All code samples are presented in both, Javascript and CoffeScript.

### Include and configure the library

    // JS
    var TVDB = require("tvdb")
      , tvdb = new TVDB({ apiKey: "YOUR_KEY" });

    # Coffee
    TVDB = require("tvdb")
    tvdb = new TVDB apiKey: "YOUR_KEY"

Possible configuration options are:

  - `apiKey` {String}
  - `language` {String} (optional) Default: `"en"`. Use getLanguages() if you want another language.
  - `initialHost` {String} (optional) Default: `"thetvdb.com"`
  - `port` {Number} (optional) Default: 80

### Get available languages

    // JS
    tvdb.getLanguages(function(err, languages) {
      if (err) return;
      // Handle languages.
    };

    # Coffee
    tvdb.getLanguages (err, languages) ->
      if err? then return
      # Handle languages

TVDB uses `"en"` (english) as default when it fetches data. If you want another language, use this function, get the language
you want (or let the user decide which language s/he wants) and use the `abbreviation` as new language.

To set the language as new default, simply call:

    // JS
    tvdb.setLanguage(language.abbreviation);
    
    # Coffee
    tvdb.setLanguage language.abbreviation

### Get a list of mirrors

    // JS
    tvdb.getMirrors(function(err, mirrors) {
      if (err) return;
      // Handle mirrors.
    });

    # Coffee
    tvdb.getMirrors (err, mirrors) ->
      if err? then return
      # Handle mirrors

Mirrors is an Array containing objects that are formatted like this:

    { id: "1", url: "http://thetvdb.com", types: [ "xml", "banner", "zip" ] }

`types` contains *at least* one of `"xml"`, `"banner"` and `"zip"`.



### Get server time

    // JS
    tvdb.getServerTime(function(err, time) {
      if (err) return;
      // Handle time.
    };

    // Coffee
    tvdb.getServerTime (err, time) ->
      if err? then return
      # Handle time

`time` is an integer.


### Find a TV Show

    // JS
    tvdb.findTvShow("Mad Men", function(err, tvShows) {
      if (err) return;
      // Handle tvShows.
    };

    # Coffee
    tvdb.findTvShow "Mad Men", (err, tvShows) ->
      if err? then return
      # Handle tvShows

`tvShows` is an array of `tvShow` objects which contain following obligatory values:

  - `id` {String}
  - `language` {String}
  - `name` {String}

and following optional values:

  - `firstAired` {Date}
  - `imdbId` {String}
  - `zap2itId` {String}
  - `banner` {String}
  - `overview` {String}



