# lnmpa
linux + nginx + mysql/mariadb + php + acme.sh

# 注意：
> nginx 分发容器、nginx 静态容器、 php 动态容器，三者中的 web文件 要完全一致，不然访问时会找不到页面

用法:
```
pip install docker && \
apt install -y git && \
curl -L https://github.com/wenyamu/docker/releases/download/v1.0.0/docker-ce.sh | bash && \
git clone https://github.com/wenyamu/lnmpa.git /root/lnmpa && \
cd /root/lnmpa && \
bash ./demo.sh
```
1, 绑定邮箱
```
docker exec acme acme.sh --register-account -m abc@qq.com
```

2，修改 `www/conf_f/upstream.conf` 中的ip, 然后重启分发容器
```
docker restart nginx_f
```

3，生成ssl证书
```
docker exec acme acme.sh --issue \
-d abc.com \
-d www.abc.com \
-w /web/abc.com \
--keylength ec-256
```

4，安装证书
```
docker exec acme acme.sh --install-cert \
-d abc.com \
--key-file       /ssl/abc.com/key.pem \
--fullchain-file /ssl/abc.com/fullchain.pem \
--cert-file      /ssl/abc.com/cert.pem \
--ca-file        /ssl/abc.com/ca.pem
```

5, 最后再重启分发容器
```
docker restart nginx_f
```
6, 重载nginx配置文件
`Nginx_template/Nginx_data.json` 修改这个文件，然后再执行重载
重载时已经加入了 `nginx -s reload` 命令，不需要重启容器。

访问 http://abc.com 会跳转到 https://www.abc.com

# 如果php使用curl无法返回数据时
```
#‌跳过证书验证（开发环境）
$curl = curl_init();
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
```
