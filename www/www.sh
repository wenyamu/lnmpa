#!/bin/bash

echo "####################################"
echo "### 1: 创建 nginx 分发服务端     ###"
echo "### 2: 创建 nginx 静态服务端     ###"
echo "### 3: 创建 php-fpm 动态服务端   ###"
echo "### 4: 创建 acme.sh 证书服务端   ###"
echo "### 5: 创建 mariadb 数据库服务端 ###"
echo "### 6: 创建 mysql 数据库服务端   ###"
echo "####################################"

mkdir -p /www1/nginxconf/ #创建目录结构，第一次运行时，以免执行 cp 命令时异常


# 删除容器函数
function remove_docker_container() {
    local container_name=$1
    
    if docker ps -a | grep -q "$container_name"; then
        # -f 强制删除容器(运行时的容器也可删除)
        docker rm -f "$container_name" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] 容器: $container_name 删除成功"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 容器: $container_name 不存在"
        #:  # 这里的冒号:相当于 Python 中的 pass
    fi
}

# 安全删除Docker卷
function safe_volume_rm() {
    local volume_name=$1
    
    # 检查卷是否存在且未被使用
    if docker volume inspect "$volume_name" >/dev/null 2>&1 && \
       [ -z "$(docker ps -a --filter volume="$volume_name" -q)" ]; then
        docker volume rm "$volume_name" >/dev/null 2>&1 && \
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 卷: $volume_name 删除成功" || \
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 卷: $volume_name 删除失败(可能被隐藏占用)"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 卷: $volume_name 不存在或正在使用，已跳过"
    fi
}

# 删除目录
function dir_rm() {
    local dir_name=$1
    
    if [ -d "$dir_name" ]; then
        rm -r "$dir_name"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 目录: $dir_name 删除成功"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 目录: $dir_name 不存在"
    fi
}

# 注意：定义的函数名不能含有字符"-"，可以使用"_"
### 一，创建 nginx 分发服务端容器
function nginx_forward() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 nginx_f 服务端容器 ..."
    
    remove_docker_container "nginx_f" # -f 强制删除分发服务容器(运行时的容器也可删除)
    
    cp -r ./web/ /www1/
    cp -r ./ssl/ /www1/
    cp -r ./conf_f/ /www1/
    cp -r ./nginxconf/nginx_f.conf /www1/nginxconf/nginx_f.conf
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p nginx_f_project -f nginx-forward.yml up -d
    
    #开放端口
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 nginx_f 服务端容器 完成"
}

### 二，创建 nginx 静态服务端容器
function nginx_static() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 nginx_s 服务端容器 ..."
    
    remove_docker_container "nginx_s"  # -f 强制删除静态服务容器(运行时的容器也可删除)
    
    cp -r ./web/ /www1/
    cp -r ./ssl/ /www1/
    cp -r ./conf_s/ /www1/
    cp -r ./nginxconf/nginx_s.conf /www1/nginxconf/nginx_s.conf
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p nginx_s_project -f nginx-static.yml up -d
    
    #开放端口
    iptables -I INPUT -p tcp --dport 81 -j ACCEPT
    iptables -I INPUT -p tcp --dport 444 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 nginx_s 服务端容器 完成"
}

### 三，创建 php-fpm 动态服务端容器
function php_fpm() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 phpfpm 服务端容器 ..."
    
    remove_docker_container "phpfpm"  # -f 强制删除容器(运行时的容器也可删除)
    safe_volume_rm "php7.4_fpm" # 删除容器绑定的卷(切记！不要手动删除目录)
    #docker network prune        # 清理未使用的网络,需要手动确认
    #docker volume prune         # 清理未使用的卷,需要手动确认（有时会失效）
    
    dir_rm "/www1/php/"
    mkdir -p /www1/php/7.4/fpm
    cp -r ./web/ /www1/
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p phpfpm_project -f php-fpm.yml up -d
    
    #开放端口
    iptables -I INPUT -p tcp --dport 9001 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 phpfpm 服务端容器 完成"
}

### 四，创建 acme.sh ssl证书服务端容器
function acme() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 acme 服务端容器 ..."
    
    remove_docker_container "acme"  # -f 强制删除容器(运行时的容器也可删除)
    #docker network prune  # 清理未使用的网络,需要手动确认
    #docker volume prune   # 清理未使用的卷,需要手动确认（有时会失效）
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p acme_project -f acme.sh.yml up -d
    
    #开放端口, 用于申请ssl证书(验证过了，不可行)
    #如果80端口被占用，在 --standalone 模式下要指定另外的端口 --httpport 82
    #iptables -I INPUT -p tcp --dport 82 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 acme 服务端容器 完成"
}

### 五，创建 mariadb 数据库服务端容器
function mariadb() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 mariadb 服务端容器 ..."
    
    remove_docker_container "mariadb"  # -f 强制删除容器(运行时的容器也可删除)
    #docker network prune  # 清理未使用的网络,需要手动确认
    #docker volume prune   # 清理未使用的卷,需要手动确认（有时会失效）
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p mariadb_project -f mariadb10.yml up -d
    
    #开放端口
    iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 mariadb 服务端容器 完成"
}

### 六，创建 mysql 数据库服务端容器
function mysql() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 mysql 服务端容器 ..."
    
    remove_docker_container "mysql"  # -f 强制删除容器(运行时的容器也可删除)
    #docker network prune  # 清理未使用的网络,需要手动确认
    #docker volume prune   # 清理未使用的卷,需要手动确认（有时会失效）
    
    # 使用 -p 自定义项目名，避免目录名冲突(会出现 orphan containers 孤儿容器)
    docker compose -p mysql_project -f mysql5.7.yml up -d
    
    #开放端口
    iptables -I INPUT -p tcp --dport 3307 -j ACCEPT
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 创建 mysql 服务端容器 完成"
}

# 注意：定义变量时，=号前后不能有空格
read -p "继续请输入对应编号或编号组合, 退出Ctrl+C : " SOFT_NUM
#如果 ${SOFT_NUM} 字符串为空，则默认为0
if [ -z "${SOFT_NUM}" ];then
	SOFT_NUM=0
fi

#过滤输入的字符（具体命令释义见文末）
#1，提取其中的数字1-3，因为软件就三个，1-3对应三个软件
#2，为每个数字前加上空格，为第三步做准备
#3，替换空格为换行，为第四步做好准备
#4，按从小到大进行排序，并删除重复数字，只保留一个
#5，再把换行替换成空格，为第六步做好准备
#6，去掉字符串中的所有空格
#7，最后得到的软件编号和组合编号就只有7种形式：1,2,3,12,23,13,123

filter_num=`echo ${SOFT_NUM} | tr -cd "[1-6]" | sed 's/./& /g' | tr ' ' '\n' | sort -nu | tr '\n' ' ' | sed s/[[:space:]]//g`

#此case必须放置在定义的函数后面，不然会提示找不到函数，无法执行
case $filter_num in
 1)
    nginx_forward
 ;;
 2)
    nginx_static
 ;;
 3)
    php_fpm
 ;;
 4)
    acme
 ;;
 5)
    mariadb
 ;;
 6)
    mysql
 ;;
 12)
    nginx_forward
    nginx_static
 ;;
 13)
    nginx_forward
    php_fpm
 ;;
 23)
    nginx_static
    php_fpm
 ;;
 123)
    nginx_forward
    nginx_static
    php_fpm
 ;;
 1235)
    nginx_forward
    nginx_static
    php_fpm
    mariadb
 ;;
 *)
    echo "请重新输入编号或编号组合"
 ;;
esac


#num="1, 3 2 1-01  - 2345 231 4224533115"
#echo ${num} | tr -cd "[0-9]" | sed 's/./& /g' | tr ' ' '\n' | sort -nu | tr '\n' ' ' | sed s/[[:space:]]//g

#释义tr -cd "[0-9]"

#tr是translate的缩写，主要用于删除文件中的控制字符，或者进行字符转换
#-d表示删除，[0-9]表示所有数字，-c表示对条件取反
#tr -cd "[0-9]" #剔除非数字的字符

#释义tr ' ' '\n' | sort -nu

#tr ' ' '\n' 把空格替换成换行
#sort -nu    -n 表示把字符串按数字进行从小到大排序 -u 去除重复数字，只保留一个
# 注意：此两个命令结合才能起到排序的作用（因为sort是默认处理文件，加上换行欺骗它这是文件，哈哈）

#释义sed命令
# str='bbc123uu789'
# echo $str
#bbc123uu789

#在每个字符前加上+号
# echo $str|sed 's/./&\+/g'
#b+b+c+1+2+3+u+u+7+8+9+

#在每个字符前加上空格
# echo $str|sed 's/./& /g'
#b b c 1 2 3 u u 7 8 9 

#以固定长度分隔,三个.表示每三个字符分隔一次
# echo $str|sed 's/.../& /g'
#bbc 123 uu7 89

#去除字符串中的所有空格
#sed s/[[:space:]]//g
