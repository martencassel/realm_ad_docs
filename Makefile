.PHONY: test-shell
test-shell:
	docker run -it -v $(PWD):/host ubuntu:22.04
