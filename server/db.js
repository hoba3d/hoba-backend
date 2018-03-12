// ----------------------------------------------------------------------------
// -- DB methods: open/close, insert/update/replace, remove/drop, find
// 
var DB = function (mongoclient)
{
	var db;
	var self = this;
	var dbpath = "mongodb://localhost:27017/";
	var MongoDB = require('mongodb');

	// -- modify this to update the user DB
	// -- you can see the contents of 'data' argument in backend.process() function
	// -- use eg. sessionstorage to persist currently logged userID
	this.storeAcquisitionData (data)
	{
		return;
		db.open("test", function (err)
		{
			if (err) { console.log(err); return; }		
			db.drop("user");
			db.insert("user", data).then(
				function (res)
				{
					var c = db.find("user");
					c.each(function (err,d) { if (d) console.log(d); if (err || !d) { db.close(); } });
				},
				function (err) { console.log(err); });
		});
	}

	this.open = function (url, callback)
	{
		mongoclient.connect(dbpath + url, {native_parser:true}, function(err, db_)
		{
			if (!err) { db = db_; if (callback) callback(null); }
			else if (callback) callback(err);
		});
	}
	
	this.close = function () { db.close(); };
	
	this.insert = function (coll, doc)
	{
		if (Array.isArray(doc)) return db.collection(coll).insertMany(doc);
		else return db.collection(coll).insertOne(doc);
	}
	
	this.update = function (coll, query, data, many)
	{
		if (many) return db.collection(coll).updateMany(query, data);
		else		 return db.collection(coll).updateOne(query, data);
	}
	
	this.replace = function (coll, query, data)
	{
		return db.collection(coll).replaceOne(query, data);
	}
	
	this.remove = function (coll, query, all)
	{
		if (all) return db.collection(coll).deleteAll(query);
		else		return db.collection(coll).deleteOne(query);
	}
	
	this.drop = function (coll)
	{
		return db.collection(coll).drop();
	}
	
	// -- returns an iterable async cursor: eg. cursor.each(function (err,doc) { ... });
	this.find = function (coll, query)
	{
		return db.collection(coll).find(query);
	}
	
	this.asBinary = function (data)
	{
		return new MongoDB.Binary(data);
	}
}

module.exports = DB;