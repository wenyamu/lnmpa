#!/bin/bash

#echo "内核版本"
#uname -r

#echo "linux版本"
#centos 系统用 cat /etc/redhat-release 
#debian 或 ubuntu 系统用 cat /etc/os-release

#echo "系统类型"
#uname -s

#echo "更新yum"
#yum update

#使用方法
#wget -N --no-check-certificate https://www.xxx.com/test/docker3.sh
#chmod +x ./docker.sh && ./docker.sh

echo "#############################"
echo "### 安装 docker-ce        ###"
echo "### CentOS 7              ###"
echo "### CentOS Stream 8       ###"
echo "### CentOS Stream 9       ###"
echo "### Debian 12 (Bookworm)  ###"
echo "### Debian 11 (Bullseye)  ###"
echo "### Ubuntu 23.10 (Mantic) ###"
echo "### Ubuntu 22.04 (Jammy)  ###"
echo "### Ubuntu 20.04 (Focal)  ###"
echo "#############################"

# 注意：定义的函数名不能含有字符"-"
### 一，在 centos 上安装 docker-ce
#https://docs.docker.com/engine/install/centos/
function install_docker_ce_centos() {
    echo "卸载旧版本"
    sudo yum remove -y docker \
             docker-client \
             docker-client-latest \
             docker-common \
             docker-latest \
             docker-latest-logrotate \
             docker-logrotate \
             docker-engine \
             docker-selinux

    echo "安装需要的软件包"
    # 安装需要的软件包,yum-util 提供 yum-config-manager 功能，另外两个是 device mapper 驱动依赖的
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2

    echo "设置yum源"
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    #echo "查看docker版本列表"
    # 可以查看所有仓库中所有docker版本
    #yum list docker-ce --showduplicates | sort -r
    # 安装上面查询到的指定docker版本
    #VERSION_STRING="23.0.6"
    #sudo yum install -y docker-ce-${VERSION_STRING} docker-ce-cli-${VERSION_STRING} containerd.io docker-buildx-plugin docker-compose-plugin

    echo "安装docker ..."
    # 安装 docker 到最新版
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "启动docker-ce服务并将其加入开机自启"
    # 启动
    sudo systemctl start docker

    # 加入开机自启
    sudo systemctl enable docker

    echo "查看 docker-ce 版本 ..."
    docker version
}

### 二，在 debian 上安装 docker-ce
#https://docs.docker.com/engine/install/debian/
function install_docker_ce_debian() {
    echo "卸载以避免与 Docker Engine 版本冲突 ..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    #设置存储库
    echo "更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库"
    sudo apt-get -y update
    sudo apt-get -y install ca-certificates curl gnupg
    
    echo "添加Docker官方GPG密钥"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    echo "将存储库添加到 Apt 源"
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

    #安装 Docker 引擎
    echo "更新apt包索引"
    sudo apt-get -y update

    #echo "查看docker版本列表"
    # 可以查看所有仓库中所有docker版本
    #apt list -a docker-ce
    # 安装上面查询到的指定docker版本
    #VERSION_STRING="5:25.0.5-1~debian.11~bullseye"
    #sudo apt-get install -y docker-ce=${VERSION_STRING} docker-ce-cli=${VERSION_STRING} containerd.io docker-buildx-plugin docker-compose-plugin

    echo "安装 Docker 引擎、containerd 和 Docker Compose 最新版"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo "查看 docker-ce 版本 ..."
    docker version

}

### 三，在 ubuntu 上安装 docker-ce
#https://docs.docker.com/engine/install/ubuntu/
function install_docker_ce_ubuntu() {
    echo "卸载以避免与 Docker Engine 版本冲突 ..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    #设置存储库
    echo "更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库"
    sudo apt-get -y update
    sudo apt-get -y install ca-certificates curl
    
    echo "添加Docker官方GPG密钥"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    echo "将存储库添加到 Apt 源"
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    #安装 Docker 引擎
    echo "更新apt包索引"
    sudo apt-get -y update
    echo "安装 Docker 引擎、containerd 和 Docker Compose 最新版"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "查看 docker-ce 版本 ..."
    docker version

}

echo "确认系统版本并安装对应 docker"
check_sys(){
    #如果存在 /etc/redhat-release 文件，则为 centos
    if [[ -f /etc/redhat-release ]]; then
        install_docker_ce_centos
    elif cat /etc/issue | grep -q -E -i "debian|bullseye|bookworm"; then
        install_docker_ce_debian
    elif cat /etc/issue | grep -q -E -i "ubuntu|focal|jammy|mantic"; then
        install_docker_ce_ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        install_docker_ce_centos
    #elif cat /proc/version | grep -q -E -i "debian"; then
    #    install_docker_ce_debian
    #elif cat /proc/version | grep -q -E -i "ubuntu"; then
    #    install_docker_ce_ubuntu
    #elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    #    install_docker_ce_centos
    fi
}

check_sys