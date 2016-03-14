FROM ruby:2.3-alpine
MAINTAINER https://github.com/realestate-com-au/stackup

COPY pkg/stackup-*.gem /app/
WORKDIR /app
RUN gem install stackup-*.gem

ENTRYPOINT ["stackup"]
