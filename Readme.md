# TheTVDB.com Node library Version 0.0.6

It's a wrapper for [thetvdb][]s XML API, written in JavaScript for [node][].
You won't be in contact with any XML if you use this library.

> The library isn't finished yet. I'll update this README as I get along so
> you'll know what to expect.

You can check out [thetvdbs programmers API](http://thetvdb.com/wiki/index.php?title=Programmers_API)
to know what this library will be wrapping.

[node]: http://nodejs.org/
[thetvdb]: http://www.thetvdb.com/


This project uses [semantic versioning](http://semver.org/) and uses this [tag script](https://github.com/enyo/tag) to tag the versions.

I use the great [mocha testing framework](http://visionmedia.github.com/mocha/) with the (also great) [should assertion library](https://github.com/visionmedia/should.js) for testing.  
If you contribute to this project, please write a test, and make sure all existing tests pass.

## Usage

> First off, [get an API key from thetvdb](http://thetvdb.com/?tab=apiregister).
> Withouth an API key you won't be able to do anything with this library.


### Include and configure the library

    var TVDB = require("tvdb")
      , tvdb = new TVDB({ apiKey: "YOUR_KEY" });

Possible configuration options are:

  - `apiKey` {String}
  - `initialHost` {String} (optional) Default: `thetvdb.com`
  - `port` {Number} (optional) Default: 80

### Get available languages

    tvdb.getLanguages(function(err), languages) {
      if (err) return;

      // Handle languages.
    };

TVDB uses `"en"` (english) as default when it fetches data. If you want another language, use this function, get the language
you want (or let the user decide which language s/he wants) and use the `abbreviation` as new language.

To set the language as new default, simply call:

    tvdb.setLanguage(language.abbreviation);

### Get a list of mirrors

    tvdb.getMirrors(function(err, mirrors) {

      // err is set when either the http call to thetvdb didn't work, or the
      // XML couldn't be parsed.
      if (err) return;

      // Handle mirrors.
    });

Mirrors is an Array containing objects that are formatted like this:

    { id: "1", url: "http://thetvdb.com", types: [ "xml", "banner", "zip" ] }

`types` contains *at least* one of `"xml"`, `"banner"` and `"zip"`.



### Get server time

    tvdb.getServerTime(function(err), time) {
      if (err) return;

      // Handle time.
    };

Time is an integer.

### Get a list of series by name

	tvdb.getSeriesByName(['My', 'Favorite', 'Sitcom'], function(err, allSeries) {
		// err is set when either the http call to thetvdb didn't work, the
		// XML couldn't be parsed, or the list of keywords to search for was
		// not set.
		if (err) return;
		
		// Handle list of matching series
	});

Series is an Array containing objects that are formatted like this:

	{ id: "987654321", name: 'My Favorite Sitcom', language: 'en', banner: 'path/to/banner.jpg', overview: 'My Favorite Sitcom stars Bla McBlaberson in dual roles as both a high-strung criminal lawyer, and his lazy twin brother.', firstAired: '2009-09-09', imdbId: 't1234567', zap2itId: 'S666' }
	
Not all fields are set for all series. This depends on how much information about the series has been contributed to The TVDB.