NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m

NAME=nginx-config-renderer

VERSION ?= "dev"
REPO=github.com/bghellofresh/${NAME}
BUILD_DIR ?= build
GO_LINKER_FLAGS=-ldflags="-s -w -X main.version=$(VERSION)"
BINARY=${NAME}
BINARY_SRC=$(REPO)/cmd/nginx-config-renderer

# Space separated patterns of packages to skip in list, test, format.
IGNORED_PACKAGES := /vendor/

.PHONY: all clean deps build

all: clean deps build

deps:
	@git config --global --add http.https://gopkg.in.followRedirects true
# Setting up GitHub token to download internal dependencies
ifdef GITHUB_TOKEN
	@git config --global --add url."https://${GITHUB_TOKEN}@github.com/bghellofresh/".insteadOf "https://github.com/hellofresh/"
endif

	@echo "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)"
	@go get -u github.com/golang/dep/cmd/dep
	@dep ensure -vendor-only

build:
	@printf "$(OK_COLOR)==> Building Binary $(NO_COLOR)\n"
	@go build -o ${BUILD_DIR}/${BINARY} ${GO_LINKER_FLAGS} ${BINARY_SRC}

build-dev:
	@echo "$(OK_COLOR)==> Building Development Environment... $(NO_COLOR)"
	@docker-compose up -d

test-unit:
	@/bin/sh -c "./build/test.sh $(allpackages)"

clean:
	@echo "$(OK_COLOR)==> Cleaning project$(NO_COLOR)"
	@go clean
	@rm -rf build

# cd into the GOPATH to workaround ./... not following symlinks
_allpackages = $(shell ( go list ./... 2>&1 1>&3 | \
    grep -v -e "^$$" $(addprefix -e ,$(IGNORED_PACKAGES)) 1>&2 ) 3>&1 | \
    grep -v -e "^$$" $(addprefix -e ,$(IGNORED_PACKAGES)))

# memoize allpackages, so that it's executed only once and only if used
allpackages = $(if $(__allpackages),,$(eval __allpackages := $$(_allpackages)))$(__allpackages)