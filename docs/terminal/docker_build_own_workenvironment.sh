# docker build

docker build --build-arg HOST_UID=$(id -u) --build-arg HOST_GID=$(id -g) -t tt .

# docker run

docker run -it --gpus all --name vgg -v $(pwd):/workspace -v /data/xxx:/data -v /home/shared_all:/shared --ipc=host --ulimit memlock=-1 tt

# docker exec 

docker exec -it vgg zsh 
docker exec -it -u root vgg zsh

# 如果要安装一些配置，例如安装 oh-my-zsh 到 /home/xxx/.oh-my-zsh、安装 oh-my-tmux 到 /home/xxx/.tmux
# 就应该在容器内部的/home/xxx里面，这样才是整体的镜像文件
