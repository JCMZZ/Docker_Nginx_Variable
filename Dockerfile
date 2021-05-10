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
