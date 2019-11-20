FROM httpd:2.4.39

# vim for debug
# git is widly used for this app
# ca-certificates is used for https git clonning stuff and https api call
# jq is used to read JSON config file and parse github and gitlab API responses
# curl is used to query github and gitlab API
# ssh is used to generate and use key for git push to gitlab through SSH
RUN apt-get update && apt-get install -yq --no-install-recommends vim git ca-certificates jq curl ssh


# nodejs/npm used for versionning and debuging helpers
# jquery and material-components-web used in index.html at the root of the local git web server
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y build-essential nodejs
COPY index.html   /usr/local/apache2/htdocs/
COPY index2.html  /usr/local/apache2/htdocs/
COPY index.css    /usr/local/apache2/htdocs/
COPY package.json /usr/local/apache2/htdocs/
RUN cd /usr/local/apache2/htdocs/ && npm install

# ezmasterization of ezmaster-globs
# see https://github.com/Inist-CNRS/ezmaster
COPY config.json /
RUN echo '{ \
  "httpPort": 80, \
  "configPath": "/config.json", \
  "configType": "json", \
  "dataPath": "/usr/local/apache2/htdocs" \
}' > /etc/ezmaster.json

# source code of this app and docker stuff for running it
COPY entrypoint.sh /
COPY dump-github.periodically.sh /
COPY github-functions.sh /
COPY gitlab-functions.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "httpd-foreground" ]
EXPOSE 80