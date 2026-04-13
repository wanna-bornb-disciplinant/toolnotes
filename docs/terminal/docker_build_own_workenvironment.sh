# docker build

docker build --build-arg HOST_UID=$(id -u) --build-arg HOST_GID=$(id -g) -t tt .

# docker run

docker run -it --gpus all --name vgg -v $(pwd):/workspace -v /data/ethan:/data -v /home/shared_all:/shared --ipc=host --ulimit memlock=-1 tt

# docker exec 

docker exec -it vgg zsh 
docker exec -it -u root vgg zsh
