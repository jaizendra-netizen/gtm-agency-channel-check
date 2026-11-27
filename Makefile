SWIFTC ?= swiftc

channel-check: Sources/Core.swift Sources/main.swift
	$(SWIFTC) -O Sources/Core.swift Sources/main.swift -o channel-check

.build-tests: Sources/Core.swift Tests/main.swift
	$(SWIFTC) Sources/Core.swift Tests/main.swift -o .build-tests

test: .build-tests
	./.build-tests

clean:
	rm -f channel-check .build-tests
