# 通过配置环境变量使web docker + nginx 部署，在启动容器时可传入参数修改proxy_pass的值，避免将代理路径写成固定值，在后端服务地址修改时，拉取的docker镜像不可用
## 思路

 1. 通过[nginx set](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html#set) 指令定义nginx conf 变量，将变量放到proxy_pass
 2. 通过[nginx include](http://nginx.org/en/docs/ngx_core_module.html#include) 指令引入定义变量的environment variable 文件
 3. 写一个shell 脚本，使用 [echo -e](https://www.runoob.com/linux/linux-shell-echo.html) 命令将要定义的环境变量写入environment variable 文件，随后启动nginx 应用（此脚本在容器启动时执行）
 4. docker 生成容器，启动容器时添加 [-e](https://www.runoob.com/docker/docker-run-command.html) 参数设置容器内环境变量
 ## 实现
 
 1. 编写 [nginx](http://nginx.org/en/docs/) 配置文件，使用预定义的变量
 
```perl
# 处理 proxy_pass 的值为域名时，域名解析产生的问题
resolver 114.114.114.114;
server {
    listen    80;
    server_name localhost;
    # 引入定义变量指令的文件
    include /etc/nginx/conf.d/*.variable;

    root   /usr/share/nginx/html;

    charset utf-8;

    location / {
      # 变量使用
      return 200 $APP_ROOT;
    }

    location /test {
      # 变量使用
      proxy_pass         $APP_ROOT;
      # proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    }
}
```
2. 编写[shell](https://www.runoob.com/linux/linux-shell.html)

```powershell
# /bin/bash

# 设置多个环境变量到 environment variable
# echo -e "set \$variable1 $PATH;
# set \$variable2 $PATH;
# set \$variable3 $PATH;" > /opt/aaa/env.variable; 

# 设置单个环境变量到 environment variable
echo set \$APP_ROOT $APP_ROOT\; > /etc/nginx/conf.d/env.variable 
# 启动 nginx 应用
nginx
# 防止容器启动后进程退出，导致容器退出；实现容器后台运行
sh
```
此处的 `echo` 是将 `set \$APP_ROOT $APP_ROOT\;` 这个字符串写入到 `/etc/nginx/conf.d/env.variable ` 这个文件中，供nginx conf include。

3.  编写 [Dockerfile](http://www.dockerinfo.net/dockerfile%E4%BB%8B%E7%BB%8D)

```yaml
FROM nginx:alpine
LABEL maintainer=fullsee

# 将 nginx 配置文件 copy 到容器内配置文件的目录下
COPY ./default.conf /etc/nginx/conf.d

# 将 shell copy 到 workdir 目录，此处为 /opt
COPY ./main.sh /opt

# 给环境变量设置初始值
ENV APP_ROOT=default

# workdir
WORKDIR /opt

# 容器内给shell文件添加所有用户可执行权限
RUN chmod a+x ./main.sh

# 容器应用端口
EXPOSE 80

# 每次容器启动时执行 main.sh shell 文件
CMD ["sh", "main.sh"]
```
4. [生成镜像，启动容器，测试：逐条执行以下命令](https://www.runoob.com/docker/docker-tutorial.html)

```powershell
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
```
# [Github源码](https://github.com/JCMZZ/Docker_Nginx_Variable)