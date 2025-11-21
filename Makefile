include .envrc

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN} -cors-trusted-origins="http://localhost:8080"

## run/client: run the cmd/client application
.PHONY: run/client
run/client:
	go run ./cmd/client

## stream/start: starts the stream on localhost
.PHONY: stream/start
stream/start:
	curl -v http://localhost:4000/v1/stream/control -H "Content-Type: application/json"  -d '{"ctrl":"start"}'

## stream/pause: starts the stream on localhost
.PHONY: stream/pause
stream/pause:
	curl -v http://localhost:4000/v1/stream/control -H "Content-Type: application/json"  -d '{"ctrl":"pause"}'

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: confirm
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## tidy: tidy module dependencies and format all .go files
.PHONY: tidy
tidy:
	@echo 'Tidying module dependencies...'
	go mod tidy
	@echo 'Verifying and vendoring module dependencies...'
	go mod verify
	go mod vendor
	@echo 'Formatting .go files...'
	go fmt ./...

## audit: run quality control checks
.PHONY: audit
audit:
	@echo 'Checking module dependencies...'
	go mod tidy -diff
	go mod verify
	@echo 'Vetting code...'
	go vet ./...
	go tool staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

# ==================================================================================== #
# BUILD
# ==================================================================================== #

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api...'
	GOGC=10 go build -ldflags='-s' -o=./bin/api ./cmd/api 
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/api ./cmd/api

## build/api: build the cmd/api application
.PHONY: build/client
build/client:
	@echo 'Building cmd/client...'
	go build -ldflags='-s' -o=./bin/streamclient ./cmd/client
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/streamclient ./cmd/client

# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh greenlight@${PRODUCTION_HOST_IP}

## production/stream/start: starts the stream on prod
.PHONY: production/stream/start
production/stream/start:
	curl -v https://${API_URL_HOST}/v1/stream/control -H "Content-Type: application/json"  -d '{"ctrl":"start"}'

## production/stream/pause: starts the stream on prod
.PHONY: production/stream/pause
production/stream/pause:
	curl -v https://${API_URL_HOST}/v1/stream/control -H "Content-Type: application/json"  -d '{"ctrl":"pause"}'

## production/deploy/api: deploy the api to production server
.PHONY: production/deploy/api
production/deploy/api:
	rsync -P ./bin/linux_amd64/api greenlight@${PRODUCTION_HOST_IP}:~
	rsync -rP --delete ./migrations greenlight@${PRODUCTION_HOST_IP}:~
	rsync -P ./remote/production/api.service greenlight@${PRODUCTION_HOST_IP}:~
	rsync -P ./remote/production/Caddyfile greenlight@${PRODUCTION_HOST_IP}:~
	ssh -t greenlight@${PRODUCTION_HOST_IP} '\
		migrate -path ~/migrations -database $$GREENLIGHT_DB_DSN up \
		&& sudo mv ~/api.service /etc/systemd/system/ \
		&& sudo systemctl enable api \
		&& sudo systemctl restart api \
		&& sudo mv ~/Caddyfile /etc/caddy/ \
		&& sudo systemctl reload caddy \
	'

## production/deploy/client: deploy the api to production server
.PHONY: production/deploy/client
production/deploy/client:
	rsync -P ./bin/linux_amd64/streamclient greenlight@${PRODUCTION_HOST_IP}:~
	rsync -P ./remote/production/streamclient.service greenlight@${PRODUCTION_HOST_IP}:~
	rsync -rP --delete ./static greenlight@${PRODUCTION_HOST_IP}:~
	ssh -t greenlight@${PRODUCTION_HOST_IP} '\
		sudo mv ~/streamclient.service /etc/systemd/system/ \
		&& sudo systemctl enable streamclient \
		&& sudo systemctl restart streamclient \
	'
