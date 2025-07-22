import shutil
import os
import sys
import json
from string import Template
import docker
import subprocess
from datetime import datetime

##########################################################################
##########################################################################
##########################################################################

JSON_FILE = "Syncthing_data.json" #设备及共享文件夹配置信息


#获取设备id
def get_device_id(container_name="syncthing"):
    
    command = ["docker", "exec", container_name, "syncthing", "--device-id"]
    
    result = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    output = result.stdout.strip()
    return output


#删除共享文件配置信息
def del_folder(folder_id, container_name="syncthing"):
    
    command = ["docker", "exec", container_name, "syncthing", "cli", "config", "folders", folder_id, "delete"]
    
    subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

#为共享文件夹添加设备
def add_folder_devices(folder_id, device_id,container_name="syncthing"):
    
    command = ["docker", "exec", container_name, "syncthing", "cli", "config", "folders", folder_id, "devices", "add", "--device-id", device_id]
    
    subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

#添加设备
def add_devices(item,container_name="syncthing"):
    
    #添加设备，命令重复执行不会提示错误，也不会重复添加，所以这里就不用判断设备是否已经存在
    command_base = ["docker", "exec", container_name, "syncthing", "cli", "config"]
    
    command_device = [
        "devices", "add", 
        "--device-id", item["device-id"],
        "--name",      item["name"],
        "--addresses", item["addresses"],
        "--auto-accept-folders"
    ]
    
    command = command_base+command_device
    
    subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

#添加共享文件夹
def add_folders(folder_id,item,container_name="syncthing"):
    #配置共享文件夹
    command_base = ["docker", "exec", container_name, "syncthing", "cli", "config"]
    
    command_folder = [
        "folders", "add", 
        "--id",    folder_id,
        "--label", item["label"],
        "--path",  item["path"],
        "--type",  item["type"],
        "--rescan-intervals", str(item["rescan-intervals"])
    ]
    
    command = command_base+command_folder
    
    subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

#syncthing文件同步配置
def syncthing(JSON_FILE,container_name="syncthing"):
    
    # 读取json文件
    with open(JSON_FILE, 'r', encoding='utf-8') as js:
        SITES = json.load(js)
    
    # 循环读取json配置
    for folder_id, devices in SITES.items():
        #print(folder_id)
        #print(devices)
        
        for device in devices:
            #添加设备，命令重复执行不会提示错误，也不会重复添加，所以这里就不用判断设备是否已经存在
            add_devices(device)
            
            #配置共享文件夹
            #如果当前当前容器的设备id与列表中的一致，则按此设置配置共享文件夹
            if device["device-id"] == get_device_id():
                #print(device)
                ''''''
                #删除共享文件配置信息
                #这里是为了方便修改配置，简便的方法就是先删除然后再设置一次
                del_folder(folder_id)
                
                add_folders(folder_id, device)
            
            add_folder_devices(folder_id, device["device-id"])

if __name__ == "__main__":
    syncthing(JSON_FILE)
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] syncthing 配置文件修改完成")

##########################################################################
##########################################################################
##########################################################################
