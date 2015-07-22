var http = require('http'),
    express = require('express'),
    path = require('path'),
    MongoClient = require('mongodb').MongoClient,
    assert = require('assert'),
    Server = require('mongodb').Server,
    CollectionDriver = require('./collectionDriver').CollectionDriver,
    bodyParser = require('body-parser'),
    FileDriver = require('./fileDriver').FileDriver;


var app = express();
app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(bodyParser.json());

//Change the host to the server elsewhere
var mongoHost = 'localHost';
var mongoPort = 27017;

var fileDriver;
var collectionDriver;

var url = 'mongodb://localhost:27017';

MongoClient.connect(url, function(error, db) {
  assert.equal(null, error);
  console.log("Connected correctly to MongoDB server");

  fileDriver = new FileDriver(db);
  collectionDriver = new CollectionDriver(db);
});
//Creates a new MongoClient
//var mongoClient = new MongoClient(new Server(mongoHost, mongoPort));

//Tries to connect the MongoClient to connect to the MongoDB server

/*
mongoClient.open(function(err, mongoClient) {

  //Fails if the MongoDB server hasn't been started yet (i.e. `mongodb` in terminal)
  if (!mongoClient) {
    console.error("Error! Exiting... Must start MongoDB first");
    process.exit(1);
  }

  //Upon successful connection, opens the EnviteDatabase
  var db = mongoClient.db("EnviteDatabase");

  //Passes the MongoClient database to the collection drier
  collectionDriver = new CollectionDriver(db);
});
*/

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function(req, res) {
  res.status(200).send('<html><body><h1>Hello World</h1></body></html>');
});

//Files are treated first, and differently than generic collection obj
app.post('/files', function(req, res) {
  fileDriver.handleUploadRequest(req, res);
});

app.get('/files/:id', function(req, res) {
  fileDriver.handleGet(req, res);
});

app.get('/:collection', function(req, res) {
  var params = req.params;
  var query = req.query.query;
  if (query) {
    query = JSON.parse(query);
    collectionDriver.query(req.params.collection, query, returnCollectionResults(req, res));
  } else {
    collectionDriver.findAll(req.params.collection, returnCollectionResults(req, res));
  }
});

function returnCollectionResults(req, res) {
  return function(error, objs) {
    if (error) { res.status(400).send(error); }
    else {
      if (req.accepts('html')) {
        res.render('data', {objects: objs, collection: req.params.collection});
      } else {
        res.set('Content-Type', 'application/json');
        res.status(200).send(objs);
      }
    }
  };
};

app.get('/:collection/:entity', function(req, res) {
  var params = req.params;
  var entity = params.entity;
  var collection = params.collection;
  if (entity) {
    collectionDriver.get(collection, entity, function(error, objs) {
      if (error) { res.status(400).send(error); }

      //If entity is found, return as a JSON document
      else { res.status(200).send(objs); }
    });
  } else {
    res.status(400).send( {error: 'bad url', url: req.url});
  }
});

app.post('/:collection', function(req, res) {
  var object = req.body;
  var collection = req.params.collection;
  collectionDriver.save(collection, object, function(error, docs) {
    if (error) { res.status(400).send(error); }
    else { res.status(201).send(docs); }
  });
});

app.put('/:collection/:entity', function(req, res) {
  var params = req.params;
  var entity = params.entity;
  var collection = params.collection;
  if (entity) {
    collectionDriver.update(collection, req.body, entity, function(error, objs) {
      if (error) { res.status(400).send(error); }
      else { res.status(200).send(objs); }
    });
  } else {
    var error = { "message" : "Cannot PUT a whole collection" };
    res.status(400).send(error);
  }
});

app.delete('/:collection/:entity', function(req, res) {
  var params = req.params;
  var entity = params.entity;
  var collection = params.collection;
  if (entity) {
    collectionDriver.delete(collection, entity, function(error, objs) {
      if (error) { res.status(400).send(error); }
      else { res.status(200).send(objs); }
    });
  } else {
    var error = { "message" : "Cannot DELETE a whole collection" };
    res.status(400).send(error);
  }
});

//Catch all for 404 errors if res.send() wasn't previously called
app.use(function (req,res) {
  res.render('404', {url:req.url});
});

http.createServer(app).listen(app.get('port'), function() {
  console.log('Express server listening on port ' + app.get('port'));
});
