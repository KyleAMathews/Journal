# Journal

Muli-user journal web app with decent (and improving) off-line support, full-text search, and responsive design.

Backend is node.js and frontend uses Backbone.js and Sass/Compass.

Only interesting right now if you want to hack on it.

## How to install

### Dependencies

* [Node.js](http://nodejs.org/) 0.8.x or above
* [MongoDB](http://www.mongodb.org/)
* [ElasticSearch](http://www.elasticsearch.org/)
* [GraphicsMagick](http://www.graphicsmagick.org/)
* [Brunch](http://brunch.io/)
* [Compass](http://compass-style.org/)

The app assumes all of the above is installed on one machine. It is possible to run your ElasticSearch instance on a seperate machine. To do this, edit the app_config.coffee file to add the IP address of the server ElasticSearch is running on.

After installing all of the above, clone this repository. Then run `npm install` to install the various node.js dependencies.

Then to compile the Javascript and CSS, go first to the `/app` directory and run `brunch build` and then to the `app/styles` directory and run `compass compile`
