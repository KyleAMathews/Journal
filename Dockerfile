FROM kyma/nodejs-base
MAINTAINER Kyle Mathews "mathews.kyle@gmail.com"

RUN mkdir /var/www/; cd /var/www/; git clone https://github.com/KyleAMathews/Journal.git
RUN cd /var/www/Journal; npm install
RUN cd /var/www/Journal; brunch build
RUN cd /var/www/Journal/app/styles; compass compile

WORKDIR /var/www/Journal
ENTRYPOINT ["coffee", "/var/www/Journal/server.coffee"]
CMD ["3000"]
