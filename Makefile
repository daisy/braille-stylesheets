# npm install -D sass postcss postcss-cli

bana/bana.css : %.css : %.scss
	npx sass --no-source-map $< $@

bana/bana.ebraille.css : %.ebraille.css : %.css
	npx postcss $< --no-map --use $(CURDIR)/filter-media.js -o $@
