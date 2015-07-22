var ObjectID = require('mongodb').ObjectID,
    fs = require('fs');

FileDriver = function(db) {
  this.db = db;
};

FileDriver.prototype.getCollection = function(callback) {
  this.db.collection('files', function(error, file_collection) {
    if (error) callback(error);
    else callback(null, file_collection);
  });
};

FileDriver.prototype.get = function(id, callback) {
  
  //Fetches the files collection from the database
  this.getCollection(function(error, file_collection) {
    if (error) callback(error)
    else {

      //Used to check for valid hex string
      var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$");
      if (!checkForHexRegExp.test(id)) callback({error: "invalid id"});

      //If hex string test passes, the id is converted to Binary JSON
      //with ObjectID(id), and findOne will find a single entity that
      //matches that Binary JSON ObjectID
      else file_collection.findOne({'_id':ObjectID(id)}, function(error, doc) {
        if (error) callback(error);
        else callback(null, doc);
      });
    }
  });
};

//Request Handler used by Express router
FileDriver.prototype.handleGet = function(req, res) {
  var fileId = req.params.id;
  if (fileId) {
    
    //Fetches the file entity from the database with the supplied fileId
    this.get(fileId, function(error, thisFile) {
      if (error) { res.status(400).send(error); }
      else {
        if (thisFile) {

          //Adds the fileId with the file extension to create a fileName
          var fileName = fileId + thisFile.ext;

          //Sets the filePath to the uploads directory /uploads/fileId+ext
          var filePath = './uploads/' + fileName;

          //Calls sendfile on the response object (res), method handles
          //transfering of the file and appropriate response headers
          res.sendfile(filePath);
        } else {
          res.status(404).send('file not found');
        }
      }
    });
  } else {
    res.status(404).send('file not found');
  }
};

FileDriver.prototype.save = function(obj, callback) {
  
  //Retrieves the file collection
  this.getCollection(function(error, the_collection) {
    if (error) callback(error);
    else {

      //sets the date of the object that is to be inserted
      obj.created_at = new Date();

      //Inserts the object in the file collection
      the_collection.insert(obj, function() {
        callback(null, obj);
      });
    }
  });
};

//A wrapper for FileDriver.prototype.save, and its purpose is to create a
//new file entity and return its id
FileDriver.prototype.getNewFileId = function(newobj, callback) {

  //Creates a new file entity (newobj)
  this.save(newobj, function(error, obj) {
    if (error) { callback(error); }

    //returns the object's id
    else { callback(null, obj._id); }
  });
};

FileDriver.prototype.handleUploadRequest = function(req, res) {
  
  //Gets the content header that is set by the mobile app
  var ctype = req.get("content-type");

  //Tries to guess the file extension
  var ext = ctype.substr(ctype.indexOf('/')+1);

  if (ext) { 
    ext = '.' + ext; 
  } else { 
    ext = ''; 
  }

  //Creates a new file entity of the content-type and extension
  this.getNewFileId({'content-type': ctype, 'ext': ext}, function(error, id) {
    if (error) { res.status(400).send(error); }
    else {

      //Creates a filename with the id + extension
      var fileName = id + ext;

      //Assigns the filepath with the directory name + uploads + fileName
      filePath = __dirname + '/uploads/' + fileName;

      //Creates a file system to write to the system
      var writable = fs.createWriteStream(filePath);

      //Request is a readStream, so we pipe it to the writable
      req.pipe(writable);

      //Associates writeStream with a callback, the readStream's 'end' event
      //occurs when the pipe operation is finished. Then a response with the
      //new id is sent back
      req.on('end', function() {
        res.status(201).send({'_id': id});
      });

      //If the writeStream raises an error event, then there's an error
      //with writing the file. Server sends a response with 500 + fs error
      writable.on('error', function(error) {
        res.status(500).send(error);
      });
    }
  });
};

exports.FileDriver = FileDriver;
