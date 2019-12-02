# README

## Setup


```
docker-compose build dev
docker-compose run -e EDITOR=vim dev bundle exec rails credentials:edit
docker-compose run -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 dev bundle exec rake db:create db:reset
```

Edit `.env` and set the variables accordingly.

## Run

```
docker-compose up dev
```

### Running only the `redis-subscriber`

```
docker-compose up subscriber
```

### Importing recordings

The importer reads the recordings from `/var/bigbluebutton/` and publishes their information to redis, so that `redis-subscriber` can update the database. So before importing you need to have `redis-subscriber` running.

```
docker-compose up import
```
