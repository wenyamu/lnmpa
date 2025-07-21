# lnmpa
> linux(debian 11) + nginx1.24 + mariadb10.11 / mysql5.7 + php7.4 + acme.sh

# 注意：
> nginx 分发容器、nginx 静态容器、 php 动态容器，三者中的 web文件 要完全一致，不然访问时会找不到页面

## 一键部署
```
pip install docker && \
apt install -y git && \
curl -L https://github.com/wenyamu/docker/releases/download/v1.0.0/docker-ce.sh | bash && \
git clone https://github.com/wenyamu/lnmpa.git /root/lnmpa && \
cd /root/lnmpa && \
bash ./demo.sh
```

## 修改nginx配置
`Nginx_template/Nginx_data.json` 修改这个文件，然后再执行重载
> 重载时已经加入了 `nginx -s reload` 命令，不需要重启容器。
```
bash ./demo.sh
```

## 生成和安装ssl证书
1, 绑定邮箱
```
docker exec acme acme.sh --register-account -m abc@qq.com
```
2, 生成证书
```
docker exec acme acme.sh --issue \
-d abc.com \
-d www.abc.com \
-w /web/abc.com \
--keylength ec-256
```
3，安装证书
```
docker exec acme acme.sh --install-cert \
-d abc.com \
--key-file       /ssl/abc.com/key.pem \
--fullchain-file /ssl/abc.com/fullchain.pem \
--cert-file      /ssl/abc.com/cert.pem \
--ca-file        /ssl/abc.com/ca.pem
```

访问 http://abc.com 会跳转到 https://www.abc.com

# 如果php使用curl无法返回数据时
```
#‌跳过证书验证（开发环境）
$curl = curl_init();
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
```

# 关于使用 syncthing 进行文件同步
> 文件的所有者要一致，不然有可能只可以A-B同步，B-A不能同步的现象。

> 你可以使用 chown 修改所有权
```
#直接修改宿主机中文件或目录的所有权，以下是修改目录及目录下所有文件及子目录的所有权
chown -R 1000:1000 /www1/web
#或者修改容器中的文件或目录的所有权
docker exec -it syncthing sh -c "chown -R 1000:1000 /syncthing"
```
