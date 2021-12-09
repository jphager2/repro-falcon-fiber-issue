To reproduce

```
bundle install
rake db:create db:migrate # (set .env for env vars)
bin/server
```

```
curl localhost:9292/repro
```
