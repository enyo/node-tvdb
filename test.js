var TheTVDB = require("./lib/index");




var thetvdb = new TheTVDB({ apiKey: "7DE1E72A16C0B072" });

thetvdb.getMirrors(function(err, mirrors) { console.log(err, mirrors); });
