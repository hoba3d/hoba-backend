//
// backend logic for HOBA HTTP server
// Jari Kleimola 2015
//
var fs = require('fs');
var requireNew = require('require-new');
var DB = requireNew('./db');
var HRTFSelector = requireNew('./hrtfselector');

var Environment = 
{
	wavhPath_44100: "wavh/",
	wavhPath_48000: "wavh/",
	octave: "/usr/local/octave/3.8.0/bin/octave"
};

var Backend = function (mongo)
{
	var db,hrtfSelector,hrtfBuilder;
	
	function init()
	{
		db = new DB(mongo);
		hrtfSelector = new HRTFSelector();
	}
	init();
		
	// -- entry point
	this.process = function (fields, files, callback)
	{
		var pinna = files.pinna[0];	
		var data  = {};
		data.img  = db.asBinary(fs.readFileSync(pinna.path));
		data.type = pinna.headers['content-type'];
		data.features = {
			pinna: {
				height: parseInt(fields.height[0]),
				rect: JSON.parse(fields.pinnarect[0]),
				distances: [],
				c1: JSON.parse(fields.c1[0]) }};
			var dists = fields.distances[0].split(",");
			for (var i=0; i<dists.length; i++)
				data.features.pinna.distances.push(parseInt(dists[i]));
		data.hrtf = {};
		
		hrtfSelector.findMatches(data.features, Environment, function (result)
		{
			var id;
			if (result)
			{
				var bestMatch = result.matches.ids[0];
				data.hrtf.id = id = result.ids[bestMatch-1];
				data.hrtf.matches = result;
			}
			db.storeAcquisitionData(data);
			
			// -- exit point
			callback(id);
		});
	}
}

module.exports = Backend;
