FROM httpd:2.4.29

# vim for debug
# git is widly used for this app
# jq is used to read JSON config file
# curl is used to query github API
RUN apt-get update && apt-get install -yq --no-install-recommends vim git ca-certificates jq curl

COPY entrypoint.sh /
COPY dump-github.periodically.sh /
COPY config.json /

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "httpd-foreground" ]
EXPOSE 80