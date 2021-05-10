# /bin/bash

# 生成本地镜像 test，通过当前目录下的 Dockerfile，. 为当期目录下寻找Dockerfile
docker build -t test .

# 启动 test 镜像，生成 test 容器；-e APP_ROOT=http://www.baidu.com/ 为定义的环境变量及值
docker run -it -e APP_ROOT=http://www.baidu.com/ --name test -p 3000:80 -d test

# 查看 test 容器是否在运行中，若能看到则是在后台运行，否则为运行后随即退出（脚本中最后的 sh 命令解决的便是容器启动后随即退出问题）
docker ps

# 查看容器 log
docker logs test

# 测试：执行以下命令应输出 http://www.baidu.com/ 为成功，也就是刚才启动镜像时 APP_ROOT 设置的值
curl http://localhost:3000 

# 测试：执行以下命令会输出百度的html文本文档
curl http://localhost:3000/test
