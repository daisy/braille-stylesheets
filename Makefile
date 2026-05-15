# npm install -D sass
bana/bana.css : %.css : %.scss
	npx sass --no-source-map $< $@
