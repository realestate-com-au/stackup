FROM ruby:3.1-alpine@sha256:499a310e8fab835ad47ab6251302aba1fd6ba91ebdfa22d621f495a5d0ded170 as build

WORKDIR /app
COPY bin /app/bin
COPY lib /app/lib
COPY spec /app/spec
COPY README.md /app/
COPY CHANGES.md /app/
COPY LICENSE.md /app/
COPY stackup.gemspec /app/
RUN gem build stackup.gemspec

FROM ruby:3.1-alpine@sha256:499a310e8fab835ad47ab6251302aba1fd6ba91ebdfa22d621f495a5d0ded170

MAINTAINER https://github.com/realestate-com-au/stackup

COPY --from=build /app/stackup-*.gem /tmp/

RUN apk --no-cache add diffutils \
 && gem install --no-document /tmp/stackup-*.gem \
 && rm -f /tmp/stackup-*.gem /usr/local/bundle/gems/stackup-*/*.md \
 && rm -rf /usr/local/bundle/gems/stackup-*/spec

WORKDIR /cwd
ENTRYPOINT ["stackup"]
