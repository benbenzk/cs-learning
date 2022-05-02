#!/bin/bash
if [ $# -lt 2 ]
then
echo '用法：install_jdk.sh PACKAGE_FILE SERVER_PATH'
echo '样例：install_jdk.sh /opt/soft/jdk.tar.gz /opt/server'
exit 100
fi

# 判断传递的软件包是否存在
package_file=$1
if [ ! -f $package_file ]
then
  echo "$package_file not exist!!!"
  exit 101
fi
server_path=$2
echo "package file:$package_file"
echo "server  path:$server_path"

java_home=$server_path/jdk1.8
if [ ! -d $java_home ]
then
  echo "$java_home not exist, creating .........."
  mkdir -p $java_home
  echo "done."
fi

echo "uncompressed $package_file > $java_home .........."
# 解压不显示文件内容
tar -zxf $package_file --strip-components=1 -C $java_home
echo "done."

echo "JAVA_HOME=$java_home"

profile_path='/etc/profile'
# 备份/etc/profile
bak_file=`dirname $0`/profile-`date +"%Y%m%d%H%M%S"`.bak
cp $profile_path $bak_file

# 查找JAVA_HOME注释并删除
sed -i '/# JAVA/d' $profile_path
# 查找带有关键词JAVA_HOME的行并删除
sed -i '/JAVA_HOME/d' $profile_path

# 将java环境变量写入到profile文件中
echo 'writing to '${profile_path}' ..........'
sed -i '$a\# JAVA' $profile_path
sed -i '$a\export JAVA_HOME='$java_home $profile_path
sed -i '$a\export PATH=$PATH:$JAVA_HOME/bin' $profile_path
source $profile_path
echo done.

java -version
echo success.
exit





