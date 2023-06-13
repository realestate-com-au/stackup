FROM ruby:3.2-alpine@sha256:1df6125b0f90e087123698e1b2df1c6a544a40033a5a14bfa3ef7067863d3474 as build

WORKDIR /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/
RUN gem build stackup.gemspec

FROM ruby:3.2-alpine@sha256:1df6125b0f90e087123698e1b2df1c6a544a40033a5a14bfa3ef7067863d3474

MAINTAINER https://github.com/realestate-com-au/stackup

COPY --from=build /app/stackup-*.gem /tmp/

RUN apk --no-cache add diffutils \
 && gem install --no-document /tmp/stackup-*.gem \
 && rm -f /tmp/stackup-*.gem /usr/local/bundle/gems/stackup-*/*.md \
 && rm -rf /usr/local/bundle/gems/stackup-*/spec

WORKDIR /cwd
ENTRYPOINT ["stackup"]
