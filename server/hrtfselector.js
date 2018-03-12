var path = require('path');

var HRTFSelector = function ()
{
	function shellcmd(cmd, args, callback)
	{
		var cwd = process.cwd();
		cwd = path.join(cwd, "octave");
		var spawn = require('child_process').spawn;
		var child = spawn(cmd, args, { cwd:cwd });
		var resp = "";
		child.stdout.on('data', function (buffer) { resp += buffer.toString() });
		child.stdout.on('end', function() { callback (resp) });
	}
	
	this.findMatches = function (features, env, callback)
	{
		var pixels_per_mm = features.pinna.rect.h / features.pinna.height;
		for (var i=0; i<features.pinna.distances.length; i++)
			features.pinna.distances[i] /= pixels_per_mm;

		var fx = [];
		var c = 343.21 * 1000;
		for (var i=0; i<features.pinna.distances.length; i++)
		{
			var f = 0;
			var d = features.pinna.distances[i];
			if (d != 0) f = c / (2 * d);
			if (!isNaN(f)) fx.push(f);
		}
		
    var args = ["-qf", "hoba_hrtf_mismatch.m"];
		args = args.concat(fx);
		shellcmd(env.octave, args, function (matches)
		{
			var result = matches ? JSON.parse(matches) : null;
			callback(result);
		});
	}
}

module.exports = HRTFSelector;