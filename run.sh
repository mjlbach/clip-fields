docker run --gpus all \
	--ipc host \
	--network host \
	--privileged \
	-v $HOME:$HOME \
	-it clip-field
