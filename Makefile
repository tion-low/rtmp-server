KEY?=
IP?=


serve:
	node app.js

player:
	ffplay -fflags nobuffer -i rtmp://$(IP)/live/$(KEY)

player-demo:
	ffplay -fflags nobuffer -i rtmp://localhost/live/testdayo

player-demo-show1:
	ffplay -showmode 1 -fflags nobuffer -i rtmp://localhost/live/testdayo
