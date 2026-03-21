#!/bin/bash
# 项目初始化脚本

echo "Setting up Game_Autochess..."

# 创建必要的目录
mkdir -p Assets/Scripts/{Core,Entities,Systems,UI,Utils}
mkdir -p Assets/{Prefabs,Scenes}
mkdir -p Assets/Art/{Sprites,Models,Materials}
mkdir -p Assets/Audio/{BGM,SFX}
mkdir -p Assets/Resources/Data

echo "Done!"
