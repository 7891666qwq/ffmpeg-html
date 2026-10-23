@echo off
echo 正在打开localhost:3000
ping null -a 4 >> null
start http://localhost:3000
echo 完成
echo 如果有显示拒绝连接请等一会在重新连接
npx serve .