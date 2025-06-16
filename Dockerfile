FROM ruby:3.4.1-alpine

RUN apk add build-base

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set --local without rubocop && bundle install

COPY . .

CMD ["./bin/bitshell"] 
