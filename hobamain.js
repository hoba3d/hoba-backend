//
// HOBA HTTP server
// Jari Kleimola 2015
//
var http = require('http');
var MongoClient = require('mongodb').MongoClient, assert = require('assert');
var moduleName;
var exceptionsCatched = false;

http.createServer( function(req, res)
{
	// -- node.js crashes on unhandled exceptions
	// -- this listener catches and handles them
	if (!exceptionsCatched)
	{
		exceptionsCatched = true;
		process.addListener('uncaughtException', function (ex)
		{
			console.log(ex);
			res.writeHead(500, {'Content-Type': 'text/plain'});
			res.end("internal server error");
		});
	}
	
	// -- acquire full path of HTTPHandler.js from require.cache
	// -- (if not already done)
	if (!moduleName)
	{
		var keys = Object.keys(require.cache);
		for (var i=0; i<keys.length; i++)
		{
			if (keys[i].indexOf('HTTPHandler.js') > 0)
			{
				moduleName = keys[i];
				break;
			}
		}
	}
	
	// -- if HTTPHandler.js is in the cache,
	// -- delete cache entry so next require call reloads it
	if (moduleName) delete require.cache[moduleName];

	// -- reload HTTPHandler.js and call its process() method
	// -- the code in HTTPHandler.js is thereby mutable even if server is not restarted
	var options = { mongo:MongoClient };
	var handler = require('./server/HTTPHandler.js')(options);
	handler.process(req,res, function (resp)
	{
		res.end(resp);
	});
}).listen(8888);

console.log("serving HOBA at port 8888");