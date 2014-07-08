FROM kyma/docker-nodejs-base
MAINTAINER Kyle Mathews "mathews.kyle@gmail.com"

# Install Graphicsmagick
RUN apt-get install -y graphicsmagick \
  fontforge ttfautohint unzip

WORKDIR /app
ENV DOCKER true
ENV NODE_ENV production
EXPOSE 8081

# Install woff-code for fontcustom
RUN curl -L http://people.mozilla.com/~jkew/woff/woff-code-latest.zip > woff-code-latest.zip
RUN unzip woff-code-latest.zip -d sfnt2woff && cd sfnt2woff && make && sudo mv sfnt2woff /usr/local/bin/

# Install Gems
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

# Install Gulp for building assets
RUN npm install -g cult gulp

# Install node.js modules.
ADD package.json /app/package.json
RUN npm install

ADD . /app

# Build web application assets.
RUN cult build

CMD ["node_modules/.bin/coffee", "hapijs.coffee"]
