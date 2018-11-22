# README

## Running on docker

```
# build the image
docker build -t bbb-recording-api .

# create a database
docker run --rm -ti -v $(pwd)/db:/usr/src/app/db -e RAILS_MASTER_KEY=abcdefghijklmnopqrstuvx123 -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bbb-recording-api bundle exec rake db:reset

# run the server
docker run --rm -ti -p 3000:80 -v $(pwd)/db:/usr/src/app/db -e RAILS_MASTER_KEY=abcdefghijklmnopqrstuvx123 -e BBB_SECRET=8cd8ef52e8e101574e400365b55e11a6 bbb-recording-api
```

If you don't have a master key, create it with:

```
 docker run --rm -ti -v $(pwd)/config:/usr/src/app/config -e EDITOR=vim bbb-recording-api bundle exec rails credentials:edit
```

### Running `redis-subscriber` on docker

```
docker run --rm -ti -v $(pwd)/db:/usr/src/app/db -e RAILS_MASTER_KEY=abcdefghijklmnopqrstuvx123 -e BBB_REDIS_HOST=localhost -e BBB_REDIS_PORT=6379 bbb-recording-api bundle exec ruby scripts/redis-subscriber.rb
```

### Importing recordings

The importer reads the recordings from `/var/bigbluebutton/` and publishes their information to redis, so that `redis-subscriber` can update the database. So before importing you need to have `redis-subscriber` running.

```
docker run --rm -ti -v /var/bigbluebutton:/var/bigbluebutton -e RAILS_MASTER_KEY=abcdefghijklmnopqrstuvx123 -e BBB_REDIS_HOST=localhost -e BBB_REDIS_PORT=6379 bbb-recording-api bundle exec ruby scripts/import.rb
```
