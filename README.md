To reproduce

```
bundle install
rake db:create db:migrate # (see .env for env vars)
bin/server
```

```
curl localhost:9292/repro
```
