FROM kyma/docker-nodejs-base
MAINTAINER Kyle Mathews "mathews.kyle@gmail.com"

# Install Graphicsmagick
RUN apt-get install -y graphicsmagick

WORKDIR /app
ADD package.json /app/package.json
RUN npm install
ADD bower.json /app/bower.json
RUN bower install --allow-root
ADD app /app/app
ADD config.coffee /app/config.coffee
RUN brunch build
RUN cd app/styles; compass compile
ADD . /app

CMD ["coffee", "server.coffee", "3000"]
