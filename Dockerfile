FROM kyma/docker-nodejs-base
MAINTAINER Kyle Mathews "mathews.kyle@gmail.com"

# Install Graphicsmagick
RUN apt-get install -y graphicsmagick

WORKDIR /app
ADD package.json /app/package.json
RUN npm install
ADD bower.json /app/bower.json
RUN bower install --allow-root
ADD . /app
RUN brunch build
RUN cd app/styles; compass compile

CMD ["coffee", "server.coffee", "3000"]
