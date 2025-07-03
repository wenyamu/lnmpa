# lnmpa
linux + nginx + mysql(待补) + php + acme.sh

用法:
```
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

访问 http://abc.com 会跳转到 https://www.abc.com
