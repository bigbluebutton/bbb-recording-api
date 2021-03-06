FROM ruby:2.5

# Install app dependencies.
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Set an environment variable for the install location.
ENV RAILS_ROOT /usr/src/app

# Make the directory and set as working.
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

# Set environment variables.
ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT 1
ENV PORT 80

# Install gems.
ENV BUNDLE_PATH /usr/src/bundle
COPY Gemfile* $app/
RUN bundle install --without development test --deployment --clean --path /usr/src/bundle --jobs 4

# Adding project files.
COPY . .

# Expose port 80.
EXPOSE 80

# Start the application.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
