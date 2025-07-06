FROM ruby:3.2-alpine
RUN apk add --no-cache \
    build-base \
    sqlite-dev \
    sqlite \
    tzdata \
    && gem install bundler
WORKDIR /app
COPY . .
RUN bundle install
EXPOSE 4567
#CMD ["ruby", "app.rb", "-o", "0.0.0.0"]
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "4567"]

