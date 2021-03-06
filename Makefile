SHELL= /bin/bash
GO ?= go
BUILD_DIR := ./bin
BIN_DIR := /usr/local/bin
NAME := psgo
PROJECT := github.com/vrothberg/psgo

GO_SRC=$(shell find . -name \*.go)

all: validate build

.PHONY: build
build: $(GO_SRC)
	 $(GO) build -buildmode=pie -o $(BUILD_DIR)/$(NAME)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: vendor
vendor: vendor.conf
	@echo "*** Sorting vendor.conf ***"
	sort vendor.conf -o vendor.conf
	vndr

.PHONY: validate
validate: $(GO_SRC)
	@which gofmt >/dev/null 2>/dev/null || (echo "ERROR: gofmt not found." && false)
	test -z "$$(gofmt -s -l . | grep -vE 'vendor/' | tee /dev/stderr)"
	@which golint >/dev/null 2>/dev/null|| (echo "ERROR: golint not found." && false)
	test -z "$$(golint $(PROJECT)/...  | grep -vE 'vendor/' | tee /dev/stderr)"
	@go doc cmd/vet >/dev/null 2>/dev/null|| (echo "ERROR: go vet not found." && false)
	test -z "$$($(GO) vet $$($(GO) list $(PROJECT)/...) 2>&1 | tee /dev/stderr)"

.PHONY: test
TESTCONTAINER := psgo-test
test: build
	$(BUILD_DIR)/$(NAME) > /dev/null

	$(BUILD_DIR)/$(NAME) -format "pid,user" > /dev/null

	sudo docker run --name $(TESTCONTAINER) -d alpine sleep 100
	sudo docker inspect --format '{{.State.Pid}}' $(TESTCONTAINER) | xargs sudo $(BUILD_DIR)/$(NAME) -pid | grep "sleep"
	sudo docker rm -f $(TESTCONTAINER)

.PHONY: install
install:
	sudo install -D -m755 $(BUILD_DIR)/$(NAME) $(BIN_DIR)

.PHONY: uninstall
uninstall:
	sudo rm $(BIN_DIR)/$(NAME)
