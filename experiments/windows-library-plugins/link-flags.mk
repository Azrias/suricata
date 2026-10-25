.PHONY: research-libs research-rust-libs
research-libs:
	@printf '%s\n' '$(LIBS)'
research-rust-libs:
	@printf '%s\n' '$(RUST_LDADD)'
