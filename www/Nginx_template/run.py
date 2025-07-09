import os
import json

# 配置参数
'''
SITES = {
    "689.im": {
        "alias": "www.689.im",
        "root": "/etc/nginx/html/689.im",
        "port": 80,
        "sslport": 443,
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
JSON_FILE       = "Nginx_data.json"

TEMPLATE_FILE_F = "Forward_template.conf"
OUTPUT_DIR_F    = "/www1/conf_f"

TEMPLATE_FILE_S = "Static_template.conf"
OUTPUT_DIR_S    = "/www1/conf_s"

# 读取json文件
with open(JSON_FILE, 'r', encoding='utf-8') as f:
    SITES = json.load(f)

# 读取主模板文件
with open(TEMPLATE_FILE_F, "r") as f:
    template_f = f.read()

# 读取副模板文件
with open(TEMPLATE_FILE_S, "r") as s:
    template_s = s.read()

# 生成各站点配置
for domain, config in SITES.items():
    
    # 生成 upstream servers 部分
    servers_html80  = "\n    ".join([f"{s};" for s in config[config["upstream_html80"]]])
    servers_html443 = "\n    ".join([f"{s};" for s in config[config["upstream_html443"]]])
    servers_php     = "\n    ".join([f"{s};" for s in config[config["upstream_php"]]])
    
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
    
    output_path_f = os.path.join(OUTPUT_DIR_F, f"{domain}_f.conf")
    with open(output_path_f, "w") as f:
        f.write(content_f)
    
    content_s = template_s.replace("{{DOMAIN}}",  domain) \
                          .replace("{{ALIAS}}",   config["alias"]) \
                          .replace("{{ROOT}}",    config["root"]) \
                          .replace("{{PORT}}",    str(config["port"])) \
                          .replace("{{SSLPORT}}", str(config["sslport"]))
    
    output_path_s = os.path.join(OUTPUT_DIR_S, f"{domain}_s.conf")
    with open(output_path_s, "w") as f:
        f.write(content_s)
    
    print(f"Generated config for {domain}")

##########################################################################
##########################################################################
##########################################################################

'''
from string import Template

upstream_template = Template("""
upstream backend {
    #ip_hash; #让相同的客户端ip请求相同的服务器
    
    #nginx容器所在宿主机ip:宿主机端口（映射容器的80端口）
    zone backend 1m;
    $servers
    # 开启健康检查功能 需要编译安装 nginx_upstream_check_module 模块
    check interval=3000 rise=2 fall=5 timeout=2000 type=tcp;
}
""")

OUTPUT_DIR = "/www1/conf_s"

# 新服务器列表配置
new_servers = [
    "192.168.1.10 weight=5",
    "192.168.1.11:8080 weight=3",
    "192.168.1.12 backup"
]

# 生成servers部分
servers_content = "\n    ".join([f"server {s};" for s in new_servers])

# 替换模板
new_config = upstream_template.substitute(servers=servers_content)

output_path = os.path.join(OUTPUT_DIR, f"upstream.conf")
with open(output_path, "w") as f:
    f.write(new_config)
'''
