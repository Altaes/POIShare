## POIShare
An adapted project allowing users to pin POIs (Points of Interests) and storing those locations in a database. Credits to Michael Katz at http://www.raywenderlich.com
This project includes the iOS App itself and also the server written in Node.js. The current project works with the most up to date tools in the package.json file:
```
{
  "name": "envite-server",
  "version": "0.0.1",
  "private": true,
  "dependencies": {
    "express": "4.*",
    "jade": "1.*",
    "mongodb": "2.*",
    "body-parser": "1.*"
  }
}
```

# Dependencies/Tools needed:
* Node.js (https://nodejs.org/download/)
* MongoDB 
> `ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"`
> `brew update` first then `brew install mongodb`

# Set-up
1. Clone the repository/Download as a zip
2. Download/Install Node.js and MongoDB
3. cd to the `POIShare/server` and type in terminal `npm update`
4. MongoDB is on port 27017, and to start MongoDB type `cd /usr/local/opt/mongodb; sudo mongod`
  a. Alternatively, you could add: `alias [Name of alias]='cd /usr/local/opt/mongodb; sudo mongod'` in ~/.bash_profile
5. Once you have MongoDB started up, navigate with a new terminal window to `POIShare/server/` and run `node index.js`; This will start the server that communicates to the MongoDB
6. After you have the server and the MongoDB up and running, open the Xcode project and run the app.
