FROM ruby:2.5-alpine@sha256:2938785389aaa30e1b6d7683f52ec0a86af1a5af915698a102598e56e2313640

MAINTAINER https://github.com/realestate-com-au/stackup

RUN apk --no-cache add diffutils

WORKDIR /app

COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY stackup.gemspec /app/

RUN gem build stackup.gemspec
RUN gem install stackup-*.gem

WORKDIR /cwd

ENTRYPOINT ["stackup"]
