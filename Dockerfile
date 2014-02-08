# Node.js env for madtalk
# VERSION       1.0

FROM ubuntu:precise
MAINTAINER Wilson Young <yyfearth@gmail.com>

# upgrade packages and install build-essential + node.js
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe\ndeb http://ppa.launchpad.net/chris-lea/node.js/ubuntu precise main" > /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7917B12 && \
	apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y build-essential nodejs

# deploy
RUN mkdir /app
ADD package.json /app/package.json
ADD app.js /app/app.js
ADD cache.dat /app/cache.dat
RUN cd /app; npm install

EXPOSE 8008
CMD ["/usr/bin/nodejs", "/app/app.js"]
