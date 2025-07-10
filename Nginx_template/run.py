import shutil
import os
import json
from string import Template

'''
SITES = {
    "689.im": {
        "alias": "www.689.im",
        "root": "/etc/nginx/html/689.im",
        "port": 80,
        "sslport": 443,
        "portainer": [
            "server 1.2.3.4:9443 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ],
        "upstream_html80": "689_im_staticServer80",
        "upstream_html443": "689_im_staticServer443",
        "upstream_php": "689_im_phpfpmhost",
        "689_im_staticServer80": [
            "server 1.2.3.4:81 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:81 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ],
        "689_im_staticServer443": [
            "server 1.2.3.4:444 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:444 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ],
        "689_im_phpfpmhost": [
            "server 1.2.3.4:9001 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:9001 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ]
    },
    "ljs.im": {
        "alias": "www.ljs.im",
        "root": "/etc/nginx/html/ljs.im",
        "port": 80,
        "sslport": 443,
        "portainer": [],
        "upstream_html80": "ljs_im_staticServer80",
        "upstream_html443": "ljs_im_staticServer443",
        "upstream_php": "ljs_im_phpfpmhost",
        "ljs_im_staticServer80": [
            "server 1.2.3.4:81 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:81 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ],
        "ljs_im_staticServer443": [
            "server 1.2.3.4:444 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:444 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ],
        "ljs_im_phpfpmhost": [
            "server 1.2.3.4:9001 weight=1 max_fails=2 fail_timeout=10",
            "server 5.6.7.8:9001 weight=1 max_fails=2 fail_timeout=10",
            "check interval=3000 rise=2 fall=5 timeout=2000 type=tcp"
        ]
    }
}
'''
# 配置参数
##########################################################################
##########################################################################
##########################################################################
#portainer 在 upstream { ... } 中的配置
portainer_upstream = Template("""
upstream portainer9443 {
    #ip_hash; #让相同的客户端ip请求相同的服务器
    
    #portainer容器所在宿主机ip:宿主机端口（映射容器的9443端口）
    zone portainer9443 1m;
    
    $servers
    
}
""")

##########################################################################
##########################################################################
##########################################################################
#portainer 在 server { ... } 中的配置
portainer_conf = """
    #https://0.0.0.0:9443 访问 portainer web页面
    #portainer代理配置 https://www.abc.com/p 和 https://www.abc.com/p/ 实现访问时末尾带不带/都能正常访问
    location /p {
        rewrite ^/p$ https://{{DOMAIN}}/portainer/ redirect;
    }
    
    location /p/ {
        rewrite ^/p/$ https://{{DOMAIN}}/portainer/ redirect;
    }
    
    #portainer代理配置 https://www.abc.com/portainer/ 最后末尾/不能少
    location ~ "^/portainer(/?.*)" {
        # IP地址根据自己的改
        proxy_pass https://portainer9443$1$is_args$args;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # 开启拦截 proxy_pass 页面错误，如果有错误就转到 error_page 设置的错误页面
        proxy_intercept_errors on;
        #当 upstream 中的某个服务器发生了 错误、超时、返回500状态码等异常时，转向下一台服务器
        proxy_next_upstream error timeout http_500 http_502 http_503 http_504 http_404;
    }
"""

JSON_FILE       = "Nginx_data.json"        #nginx站点配置中的参数，比如: 域名，端口号，目录等

TEMPLATE_FILE_F = "Forward_template.conf"  #nginx转发服务的配置模板
OUTPUT_DIR_F    = "/www1/conf_f"           #nginx转发服务的配置目录

TEMPLATE_FILE_S = "Static_template.conf"   #nginx静态服务的配置模板
OUTPUT_DIR_S    = "/www1/conf_s"           #nginx静态服务的配置目录

# 读取json文件
with open(JSON_FILE, 'r', encoding='utf-8') as f:
    SITES = json.load(f)

# 读取主模板文件
with open(TEMPLATE_FILE_F, "r") as f:
    template_f = f.read()

# 读取副模板文件
with open(TEMPLATE_FILE_S, "r") as s:
    template_s = s.read()

#复制旧目录中文件到新的目录中
def batch_copy(src_dir, dst_dir):
    #新目录不存在就创建
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)
    #循环旧目录中的文件复制到新目录
    for filename in os.listdir(src_dir):
        src_path = os.path.join(src_dir, filename)
        if os.path.isfile(src_path):
            shutil.copy2(src_path, dst_dir)

# 生成各站点配置
for domain, config in SITES.items():
    
    # 生成 upstream servers 部分
    servers_html80  = "\n    ".join([f"{s};" for s in config[config["upstream_html80"]]])
    servers_html443 = "\n    ".join([f"{s};" for s in config[config["upstream_html443"]]])
    servers_php     = "\n    ".join([f"{s};" for s in config[config["upstream_php"]]])
    
    #配置 转发服务器
    content_f = template_f.replace("{{DOMAIN}}",            domain) \
                          .replace("{{ALIAS}}",             config["alias"]) \
                          .replace("{{ROOT}}",              config["root"]) \
                          .replace("{{PORT}}",              str(config["port"])) \
                          .replace("{{SSLPORT}}",           str(config["sslport"])) \
                          .replace("{{UPSTREAM_HTML80}}",   config["upstream_html80"]) \
                          .replace("{{UPSTREAM_HTML443}}",  config["upstream_html443"]) \
                          .replace("{{UPSTREAM_PHP}}",      config["upstream_php"]) \
                          .replace("{{SERVERS_HTML80}}",    servers_html80) \
                          .replace("{{SERVERS_HTML443}}",   servers_html443) \
                          .replace("{{SERVERS_PHP}}",       servers_php)
    
    #如果需要配置 portainer
    if config["portainer"]:
        # 新服务器列表配置
        portainer_servers = config["portainer"]
        
        # 生成servers部分
        servers_content = "\n    ".join([f"{s};" for s in portainer_servers])
        
        # 替换模板, 把模板 portainer_upstream 中的变量名 $servers 替换为 servers_content 
        portainer_upstream = portainer_upstream.substitute(servers=servers_content)
        
        portainer_conf = portainer_conf.replace("{{DOMAIN}}", domain)
        
        content_f = content_f.replace("#{{PORTAINER_CONF}}",  portainer_conf) \
                             .replace("#{{PORTAINER_UPSTREAM}}",  portainer_upstream)
    
    output_path_f = os.path.join(OUTPUT_DIR_F, f"{domain}_f.conf")
    if not os.path.exists(OUTPUT_DIR_F):
        os.makedirs(OUTPUT_DIR_F)
    with open(output_path_f, "w") as f:
        f.write(content_f)
    
    #配置 静态服务器
    content_s = template_s.replace("{{DOMAIN}}",  domain) \
                          .replace("{{ALIAS}}",   config["alias"]) \
                          .replace("{{ROOT}}",    config["root"]) \
                          .replace("{{PORT}}",    str(config["port"])) \
                          .replace("{{SSLPORT}}", str(config["sslport"]))
    
    output_path_s = os.path.join(OUTPUT_DIR_S, f"{domain}_s.conf")
    if not os.path.exists(OUTPUT_DIR_S):
        os.makedirs(OUTPUT_DIR_S)
    with open(output_path_s, "w") as f:
        f.write(content_s)
    
    # 复制域名临时证书文件，只是为了避免 nginx 容器无法启动，后续还需要替换成有效的证书文件
    # 如果 fullchain.pem 证书已经存在(用于判断证书是否已经使用 acme.sh 生成，避免执行后覆盖掉有效的证书文件)，就跳过
    if os.path.exists(f"/www1/ssl/{domain}/fullchain.pem"):
        pass
    else:
        batch_copy("./base_ssl", f"/www1/ssl/{domain}")
    
    print(f"Generated config for {domain}")

##########################################################################
##########################################################################
##########################################################################
