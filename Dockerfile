FROM ruby:2.7.1

#USER root

RUN curl https://deb.nodesource.com/setup_12.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client yarn

RUN mkdir /bbb-lti-broker
WORKDIR /bbb-lti-broker

# Setting env up
ENV RAILS_ENV='production'
ENV RACK_ENV='production'

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install
RUN yarn install --check-files
COPY . /bbb-lti-broker
# RUN rake db:create db:migrate db:seed

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Precompile assets
#   The assets are precompiled in runtime because RELATIVE_URL_ROOT can be set up through .env

# Run startup command
CMD ["scripts/start.sh"]
