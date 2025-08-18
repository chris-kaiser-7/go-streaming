This is created from the base templete from https://github.com/DataDavD/greenlight.

##For Development:

create .envrc file in root and add:
```
set export GREENLIGHT_DB_DSN=<your database connection string>
```

Controls for development, building, and production are the the Makefile.

To run the application do "make run/api" and "make run/client"
To start the stream you can do "make stream/start"
To pause the stream you can do "make stream/pause"

you can control the stream thru curl as well
```
curl -v http://localhost:4000/v1/stream/control -H "Content-Type: application/json"  -d '{"ctrl":"start"}'
```

For production on target debian based server. (I used Ubuntu 22.04):
update the caddy file in remote/production/Caddyfile to change reverse proxy to desired host/path

run setup scripts 01.sh then 02.sh found in remote/production/setup/ 
do "make build/api" and "make build/client"
then "make production/deploy/api" and "make production/deploy/client"
you can start the 

