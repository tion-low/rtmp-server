KEY?=
IP?=


serve:
	node app.js

player:
	ffplay -fflags nobuffer -i rtmp://$(IP)/live/$(KEY)

