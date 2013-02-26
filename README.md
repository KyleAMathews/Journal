# Journal

Muli-user journal web app with decent (and improving) off-line support, full-text search, and responsive design.

Backend is node.js and frontend uses Backbone.js and Sass/Compass.

Only interesting right now if you want to hack on it.

## How to install

### Dependencies

* [Node.js](http://nodejs.org/) 0.8.x or above
* [MongoDB](http://www.mongodb.org/)
* [Redis](http://redis.io/)
* [ElasticSearch](http://www.elasticsearch.org/)
* [GraphicsMagick](http://www.graphicsmagick.org/)
* [Brunch](http://brunch.io/)
* [Compass](http://compass-style.org/)

#### Installing Compass
This app depends on the latest alpha version of Compass. To install run `gem install compass --pre`

You'll also need to install three other Compass dependencies, `susy`, `compass-normalize`, `sassy-buttons`.

#### Clone repo and compile Coffescript and SCSS files

After installing all of the above, clone this repository. Then run `npm install` to install the various node.js dependencies.

Then to compile the Javascript and CSS, go first to the root directory and run `brunch build` and then to the `app/styles` directory and run `compass compile`
