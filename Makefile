include .envrc
SHELL := powershell.exe
.SHELLFLAGS := -Command

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== 
.PHONY: run/api
confirm:
	@powershell -Command "Write-Host -NoNewline 'Are you sure? [y/N] '; if ((Read-Host) -ne 'y') {exit 1}"

.PHONY: run/api
run/api:
	@go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}

.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

.PHONY: db/migrations/new
db/migrations/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

.PHONY: db/migrations/up
db/migrations/up: confirm
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

.PHONY: audit
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...
## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

# ==================================================================================== #
# BUILD
# ==================================================================================== #

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api...'
	# Build for Windows (64-bit)
	set-item env:GOOS 'windows'
	set-item env:GOARCH 'amd64'
	go build -ldflags='-s' -o="./bin/windows_amd64/api.exe" "./cmd/api" 

	# Build for Linux (64-bit)
	set-item env:GOOS 'linux'
	set-item env:GOARCH 'amd64'
	go build -ldflags='-s' -o="./bin/linux_amd64/api" "./cmd/api" 