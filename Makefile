.PHONY: all clean

all: clean
	@echo "Running soupault ..." >&2
	soupault --debug --config soupault.toml
	@echo "Running tailwind ..." >&2
	ln -sfn $(NODE_PATH) build/css/node_modules
	tailwindcss -i build/css/style.in.css -o build/css/style.css
	rm -f build/css/style.in.css build/css/node_modules
	@echo "Running syntax highlighter ..." >&2
	@tmp=$$(mktemp) && \
		echo '$$highlighting-css$$' > "$$tmp" && \
		echo '`test`{.c}' | pandoc --highlight-style=zenburn --template="$$tmp" > build/css/syntax.css

clean:
	rm -rf build/
