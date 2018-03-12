var fs = require('fs');

var HRTFBuilder = function ()
{
	function shellcmd(cmd, args, callback)
	{
		var spawn = require('child_process').spawn;
		var child = spawn(cmd, args);
		var resp = "";
		child.stdout.on('data', function (buffer) { resp += buffer.toString() });
		child.stdout.on('end', function() { callback (resp) });
	}
	
	this.build = function (matches)
	{
		var octave = "/usr/local/octave/3.8.0/bin/octave";
    var args = ["-q", "hoba_sofa2wavh.m"];
		var sofafile = "../wavh/CIPIC_subject_003_hrir.sofa";
		var wavhfile = "../wavh/CIPIC_subject_003_hrir.wavh";
		args.push(sofafile);
		args.push(wavhfile);
		shellcmd(octave, args, function () {});
	}
}

module.exports = HRTFBuilder;

var b = new HRTFBuilder();
b.build();
