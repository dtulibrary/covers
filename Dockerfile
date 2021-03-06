FROM debian:8.6

RUN apt-get update -qq && apt-get install -y \
  ruby \
  build-essential \
  libpq-dev \
  git \
  libxml2-dev \
  libxslt1-dev \
  libsqlite3-dev \
  imagemagick \
  libmagickcore-dev \
  libmagickwand-dev \
  bundler

RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock

#RUN useradd -ms /bin/bash dtuuser
#USER dtuuser

RUN bundle install
ADD . /myapp

CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
