#!/bin/bash

#1 获取输入参数个数，如果个数为0，直接退出
param_num=$#
echo $param_num
if [ $param_num -eq 0 ]
then
echo no params
exit
fi
#2 根据传入参数获取文件名称
p1=$1
fname=`basename $p1`
echo ${fname}
#3 获取输入参数的绝对路径
pdir=`cd -P $(dirname $p1); pwd`
echo pdir=$pdir
#4 获取用户名称
user=`whoami`
#5 循环执行rsync
for((host=1; host<4; host++))
do
echo ****** bigdata$host ******
hostname=bigdata0$host
rsync -rvl $pdir/$fname $user@$hostname:$pdir
done