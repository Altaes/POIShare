var ObjectID = require('mongodb').ObjectID;

CollectionDriver = function(db) {
  this.db = db;
};

CollectionDriver.prototype.getCollection = function(collectionName, callback) {
  this.db.collection(collectionName, function(error, the_collection) {
    if (error) callback(error);
    else callback(null, the_collection);
  });
};

CollectionDriver.prototype.findAll = function(collectionName, callback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error);
    else {
      the_collection.find().toArray(function(error, results) {
        if (error) callback(error);
        else callback(null, results);
      });
    }
  });
};

CollectionDriver.prototype.get = function(collectionName, id, calback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error);
    else {
      //Creates a Hex check for the id
      var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$");

      //Checks if the id is a hex string (must be a hex string to qualify for matching)
      if (!checkForHexRegExp.test(id)) callback({error: "invalid id"});

      //Matches the id against the '_id' in the database
      //Object(id) creates a Binary JSON ObjectID to match against '_id'
      else the_collection.findOne({'_id':ObjectID(id)}, function(error, doc) {
        if (error) callback(error);
        else callback(null, doc);
      });
    }
  });
};

CollectionDriver.prototype.save = function(collectionName, obj, callback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error)
    else {
      obj.created_at = new Date();
      the_collection.insert(obj, function() {
        callback(null, obj);
      });
    }
  });
};

CollectionDriver.prototype.update = function(collectionName, obj, entityId, callback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error)
    else {
      //Convert to a real objectId thats binary JSON
      obj._id = ObjectID(entityId);
      obj.update_at = new Date();
      the_collection.save(obj, function(error, doc) {
        if (error) callback(error);
        else callback(null, obj);
      });
    }
  });
};

CollectionDriver.prototype.delete = function(collectionName, entityId, callback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error);
    else {
      the_collection.remove({'_id':ObjectID(entityId)}, function(error, doc) {
        if (error) callback(error);
        else callback(null, doc);
      });
    }
  });
};

CollectionDriver.prototype.query = function(collectionName, query, callback) {
  this.getCollection(collectionName, function(error, the_collection) {
    if (error) callback(error)
    else {
      the_collection.find(query).toArray(function(error, results) {
        if (error) callback(error)
        else  callback(null, results)
      });
    }
  });
};
//Declares the exposed, or exported, entities to other applications that list
//collectionDriver.js as a required module
exports.CollectionDriver = CollectionDriver;
