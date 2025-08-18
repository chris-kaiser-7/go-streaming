# Go Streaming example with greenlight and pion
This is created from the base templete from https://github.com/DataDavD/greenlight.

## For Development:
create .envrc file in project root folder and add:
```
GREENLIGHT_DB_DSN=<your_database_connection_string>
```

Controls for development, building, and production are in the Makefile.

To run the application do "make run/api" and "make run/client"
To start the stream you can do "make stream/start"
To pause the stream you can do "make stream/pause"

you can control the stream thru curl as well
```
curl -v http://localhost:4000/v1/stream/control -H "Content-Type: application/json" -d '{"ctrl":"start"}'
```

## For production on target debian based server. (I used Ubuntu 22.04):
create .envrc file in project root folder and add:
```
PRODUCTION_HOST_IP=<your_server_ip>
API_URL_HOST=<example.com>
```
update the caddy file in remote/production/Caddyfile to change reverse proxy to desired host/path

To initialize the server scp the scripts 01.sh and 02.sh found in remote/production/setup/ to the prod server and run them.

To build the binaries you can run "make build/api" and "make build/client"

To deploy binaries to production you can run "make production/deploy/api" and "make production/deploy/client"

You can start the stream with "make production/stream/start" and pause the stream with "make production/stream/pause"

you can control the stream thru curl as well
```
curl -v https://API_URL_HOST/v1/stream/control -H "Content-Type: application/json" -d '{"ctrl":"start"}'
```
