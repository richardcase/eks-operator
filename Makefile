TARGETS := $(shell ls scripts)

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-`uname -s`-`uname -m` > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	./.dapper $@

clean:
	rm -rf build bin dist

.PHONY: $(TARGETS)

.PHONY: generate
generate:
	$(MAKE) generate-go
	$(MAKE) generate-crd

.PHONY: generate-crd
generate-crd: $(MOCKGEN)
	go generate main.go

.PHONY: generate-go
generate-go: $(MOCKGEN)
	go generate ./pkg/apis/...
