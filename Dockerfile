FROM debian:stable-slim as linefix
RUN apt-get update && apt-get install -y dos2unix
COPY . /build
WORKDIR /build
RUN find . -type f -print0 | xargs -0 dos2unix


FROM ruby:2.7.1
ENV DATABASE_HOST=localhost \
    DATABASE_USERNAME=tracks \
    DATABASE_NAME=tracks \
    DATABASE_PASSWORD=changeme \
    DATABASE_TYPE=mysql2 \
    DATABASE_PORT=3306 \
    DATABASE_ENCODING=utf8 \
    RAILS_ENV=production
    # throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

RUN touch /etc/app-env

COPY --from=linefix /build/Gemfile* /app/
RUN gem install bundler
RUN bundle install --jobs 4

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

RUN mkdir /app/log

COPY  --from=linefix /build/ /app/
COPY config/database.docker.yml /app/config/database.yml
COPY config/site.docker.yml /app/config/site.yml

RUN bundle exec rake assets:precompile

ENTRYPOINT ["/app/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
