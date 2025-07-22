
# 获取设备A的ID 
> 5SLZXEE-7574VYD-MZUL6YT-QQKEGTN-FZPH6XY-4ADPNRN-6GPSRW7-6IQEBQJ
```
DEVICE_A_ID=$(docker exec syncthing syncthing --device-id)
echo "设备A ID: $DEVICE_A_ID"
```

# 获取设备B的ID 
> VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX
```
DEVICE_B_ID=$(docker exec syncthing syncthing --device-id)
echo "设备B ID: $DEVICE_B_ID"
```

# json文件格式
```
{
    "shared-data":[
        {
            "device-id":"5SLZXEE-7574VYD-MZUL6YT-QQKEGTN-FZPH6XY-4ADPNRN-6GPSRW7-6IQEBQJ",
            "name":"DeviceA",
            "addresses":"dynamic",
            "type": "sendonly",
            "path": "/syncthing",
            "label":"只发送",
            "rescan-intervals":3
        },
        {
            "device-id":"VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX",
            "name":"DeviceB",
            "addresses":"dynamic",
            "type": "receiveonly",
            "path": "/syncthing",
            "label":"只接收",
            "rescan-intervals":3
        }
    ]
}
```
#########################
#########################
#########################

# 在设备 A 上添加设备 B
```
docker exec syncthing syncthing cli config devices add \
  --device-id VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX \
  --name "DeviceB" \
  --addresses "dynamic" \
  --auto-accept-folders
```
# 在设备 B 上添加设备 A
```
docker exec syncthing syncthing cli config devices add \
  --device-id 5SLZXEE-7574VYD-MZUL6YT-QQKEGTN-FZPH6XY-4ADPNRN-6GPSRW7-6IQEBQJ \
  --name "DeviceA" \
  --addresses "dynamic" \
  --auto-accept-folders
```
# 在设备 A 创建共享文件夹
```
docker exec syncthing syncthing cli config folders add \
  --id "shared-data" \
  --label "123-data" \
  --path "/syncthing" \
  --type "sendreceive" \
  --rescan-intervals 3

# 再单独添加设备关联：使用完整路径格式（v1.30+）
docker exec syncthing syncthing cli config \
  folders shared-data \
  devices add --device-id VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX
```

# 在设备 B 创建接收文件夹（ID必须与A一致）
```
docker exec syncthing syncthing cli config folders add \
  --id "shared-data" \
  --label "123-data" \
  --path "/syncthing" \
  --type "sendreceive" \
  --rescan-intervals 3

# 再单独添加设备关联：使用完整路径格式（v1.30+）
docker exec syncthing syncthing cli config \
  folders shared-data \
  devices add --device-id 5SLZXEE-7574VYD-MZUL6YT-QQKEGTN-FZPH6XY-4ADPNRN-6GPSRW7-6IQEBQJ
```
# 其他命令行
```
# 查看设备A的同步状态
docker exec syncthing syncthing cli show system

# 查看设备B的同步状态
docker exec syncthing syncthing cli show system


# 重载服务
docker exec syncthing syncthing cli config save
docker restart syncthing


# 检查syncthing版本
docker exec syncthing syncthing --version


# 检查设备列表
docker exec syncthing syncthing cli config devices list

#修改设备的的参数, 一次只能修改一个参数
docker exec syncthing syncthing cli config devices 5SLZXEE-7574VYD-MZUL6YT-QQKEGTN-FZPH6XY-4ADPNRN-6GPSRW7-6IQEBQJ name set ljs

#删除设备（共享文件夹下的关联设备也会一起删除）
docker exec syncthing syncthing cli config devices VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX delete

# 检查文件夹配置
docker exec syncthing syncthing cli config folders list

#删除共享文件夹
docker exec syncthing syncthing cli config folders shared-data delete

# 检查文件夹关联设备
docker exec syncthing syncthing cli config folders shared-data devices list

# 移除共享文件夹的指定关联设备
docker exec syncthing syncthing cli config folders shared-data devices VM3ALPT-KAUHYUT-GQLOKI7-HKDRR2N-RN2RNTG-SXFLQCK-HQHGY76-AG6PTAX delete

#修改共享文件夹的参数, 一次只能修改一个参数
docker exec syncthing syncthing cli config folders shared-data rescan-intervals set 3 && \
docker exec syncthing syncthing cli config folders shared-data type set sendreceive
```




#未测试
docker exec syncthing chown -R 1000:1000 /var/syncthing

