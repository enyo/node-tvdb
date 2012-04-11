# TheTVDB Node library Version 0.0.3-dev

It's a wrapper for [thetvdb][]s XML API, written in JavaScript for [node][].
You won't be in contact with any XML if you use this library.

> The library isn't finished yet. I'll update this README as I get along so
> you'll know what to expect.

You can check out [thetvdbs programmers API](http://thetvdb.com/wiki/index.php?title=Programmers_API)
to know what this library will be wrapping.

[node]: http://nodejs.org/
[thetvdb]: http://www.thetvdb.com/


## Usage

> First of, [get an API key from thetvdb](http://thetvdb.com/?tab=apiregister).
> Withouth an API key you won't be able to do anything with this library.


### Include and configure the library

    var TheTVDB = require("thetvdb")
      , thetvdb = new TheTVDB({ apiKey: "YOUR_KEY" });

Possible configuration options are:

  - `apiKey` {String}
  - `initialHost` {String} (optional) Default: `thetvdb.com`
  - `port` {Number} (optional) Default: 80

### Get a list of mirrors

    thetvdb.getMirrors(function(err, mirrors) {

      // err is set when either the http call to thetvdb didn't work, or the
      // XML couldn't be parsed.
      if (err) return;

      // Handle mirrors.
    });

Mirrors is an Array containing objects that are formatted like this:

    { id: "1", url: "http://thetvdb.com", types: [ "xml", "banner", "zip" ] }

`types` contains *at least* one of those types.