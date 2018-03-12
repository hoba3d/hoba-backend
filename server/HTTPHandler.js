//
// handler for HOBA HTTP server
// Jari Kleimola 2015
//
var fs = require('fs');
var url = require('url');
var path = require('path');
var http = require('http');
var mime = require("mime");
var multiparty = require('multiparty');
var requireNew = require('require-new');


function HTTPHandler (options)
{	
	var self = this;
	var args = {};
	
	// -- handle GET requests
	function onGET (req,res)
	{
		// -- let's deal this annoying thing first out of the way
		if (req.url === '/favicon.ico')
		{
			res.writeHead(200, {'Content-Type': 'image/x-icon'} );
			end();
			return;
		}
		
		// -- avoid directory traversal attacks
		// -- and redirect to ./client/ folder
		var cwd = process.cwd();
		var uri = url.parse(req.url).pathname;
		cwd = path.join(cwd, "client");
		var filename = path.join(cwd, uri);
		if (filename.indexOf(cwd) !== 0)
		{
			reply(res, 404, "404 Not Found");
			return;
		}
		
		fs.exists(filename, function(exists)
		{
			if (exists)
			{
				if (req.url === "/") filename = path.join(cwd, "index.html");
				fs.readFile(filename, "binary", function(err, data)
				{
					if (!err)
					{
						res.writeHead(200, {'Content-Type':mime.lookup(filename), 'Content-Length':data.length});
						res.write(data);
						end();
						
						// -- note: to get WAVH, we need to set CORS header correctly (see below)
						// var wavh = fs.readFileSync("path/to/wavh/file");
						// res.writeHead(200, {'Content-Type': 'audio/wav', 'Access-Control-Allow-Origin':'*'});
						// res.write(wavh, 'binary');
						// end();
					}
					else
					{
						console.log(err);
						reply(res, 500, "internal server error");
						return;
					}
				});
			}
			else reply(res, 404, "404 Not Found");
		});
	}
	
	// -- handle POST requests
	function onPOST (req,res)
	{
		if (req.url === '/upload')
		{
			var form = new multiparty.Form();
			form.parse(req, function(err, fields, files)
			{
				var Backend = requireNew('./backend.js');
				var backend = new Backend(options.mongo);
				backend.process(fields, files, function (idHRTF)
				{
					end(idHRTF);
					return;
				});
			});
		}
		else
		{
			res.writeHead(404, {'Content-Type': 'text/plain'});
			end("unsupported URL");
		}
	}

	// -- helper method to reply with an error message
	function reply(res, code, text)
	{
		res.writeHead(code, {"Content-Type": "text/plain"});
		res.write(text);
		end();
	}
	
	// -- entry point
	this.process = function (req,res, callback)
	{
		args = { req:req, res:res, callback:callback };
		
		if (req.method === 'GET') onGET(req,res);
		else if (req.method === 'POST') onPOST(req,res);
		else
		{
			res.writeHead(405, {'Content-Type': 'text/plain'});
			end("unsupported request");
		}
	}

	// -- exit point
	var end = function (resp)
	{
		args.callback(resp);
	}
}

module.exports = function (options)
{
	return new HTTPHandler(options);
}
