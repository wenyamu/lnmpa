#!/bin/bash

# 注意：定义的函数名不能含有字符"-"，可以使用"_"

# 检测Docker是否已安装
function check_docker_installed() {
    if command -v docker &> /dev/null; then
        echo "✅  Docker已安装, 版本: $(docker --version | awk '{print $3}' | tr -d ',')"
        return 0
    else
        echo "❌  Docker未安装"
        return 1
    fi
}

# 检查Docker服务状态
function check_docker_service() {
    if systemctl is-active --quiet docker; then
        echo "🟢 Docker服务正在运行"
        return 0
    else
        echo "🔴 Docker服务未运行"
        return 1
    fi
}

# 安装 docker-ce
function install_docker_ce() {
    echo "安装 docker-ce"
    cd ./docker-ce/
    chmod +x ./docker-ce.sh && ./docker-ce.sh
    cd ..
}

# 检测是否安装，是否启动；在部署 docker 容器前执行
function pre_install_docker_ce() {
    if check_docker_installed; then
        check_docker_service || sudo systemctl start docker
    else
        install_docker_ce
        check_docker_service || sudo systemctl start docker
    fi
}

### 一，部署 web 服务
function web() {
    echo "部署 web 服务"
    cd ./www/
    chmod +x ./www.sh && ./www.sh
}

### 二，创建 portainer-ce 容器，管理宿主机的容器，也可以管理安装了 portainer_agent 的容器
function portainer() {
    echo "安装 portainer-ce"
    #docker rm -f portainer      # -f 强制删除容器(运行时的容器也可删除)
    docker compose -f portainer-ce/portainer.yml up -d
    #开放端口
    iptables -I INPUT -p tcp --dport 9000 -j ACCEPT
    iptables -I INPUT -p tcp --dport 9443 -j ACCEPT
}

### 三，创建 portainer_agent 容器，安装了 portainer_agent 的容器可以由 portainer-ce 统一管理
function agent() {
    echo "安装 portainer_agent"
    #docker rm -f agent      # -f 强制删除容器(运行时的容器也可删除)
    docker compose -f portainer-ce/portainer_agent.yml up -d
}

### 四，创建 syncthing 容器，同于数据同步
function syncthing() {
    echo "安装 syncthing"
    #docker rm -f syncthing      # -f 强制删除容器(运行时的容器也可删除)
    mkdir -p /www1/web
    docker compose -f syncthing/syncthing.yml up -d
    docker exec -it syncthing sh -c "chown -R 1000:1000 /syncthing"
    docker exec syncthing syncthing --device-id #输出syncthing容器的设备id
}

### 五，重置 nginx 配置
function reset_nginx() {
    echo "重置 nginx 配置"
    cd ./Nginx_template/
    chmod +x ./run.py && python3 ./run.py
}

# 执行
pre_install_docker_ce

echo "###############################"
echo "### 1: 部署 web 服务        ###"
echo "### 2: 安装 portainer-ce    ###"
echo "### 3: 安装 portainer_agent ###"
echo "### 4: 安装 syncthing       ###"
echo "### 5: 重载 nginx 配置文件  ###"
echo "###############################"

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

filter_num=`echo ${SOFT_NUM} | tr -cd "[1-5]" | sed 's/./& /g' | tr ' ' '\n' | sort -nu | tr '\n' ' ' | sed s/[[:space:]]//g`

#此case必须放置在定义的函数后面，不然会提示找不到函数，无法执行
case $filter_num in
 1)
    web
 ;;
 2)
    portainer
 ;;
 3)
    agent
 ;;
 4)
    syncthing
 ;;
 5)
    reset_nginx
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
