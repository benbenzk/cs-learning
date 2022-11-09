### MySQL安装

> **安装步骤**
> 1、环境准备(删除有冲突的依赖包、安装必须的依赖包)
> 2、安装MySQL
> 3、修改root口令(找到系统给定的随机口令、修改口令)
> 4、在数据库中创建hive用户

1. 删除mariadb

   ```shell
   # 查询是否安装了mariadb
   rpm -qa | grep mariadb
   # 删除mariadb
   rpm -e --nodeps mariadb-libs-5.5.68-1.el7.x86_64
   ```

2. 安装依赖

   ```
   yum install -y perl net-tools
   ```

3. 安装MySQL

   ```shell
   cd /opt/soft/
   tar -xvf mysql-5.7.26-1.el7.x86_64.rpm-bundle.tar
   
   # 依次运行以下命令
   rpm -ivh mysql-community-common-5.7.26-1.el7.x86_64.rpm
   rpm -ivh mysql-community-libs-5.7.26-1.el7.x86_64.rpm
   rpm -ivh mysql-community-client-5.7.26-1.el7.x86_64.rpm
   rpm -ivh mysql-community-server-5.7.26-1.el7.x86_64.rpm
   ```

4. 启动数据库

   ```shell
   #启动
   systemctl start mysqld.service
   #开机启动
   systemctl enable mysqld.service
   ```

5. 查找root密码

   ```shell
   grep password /var/log/mysqld.log
   ```

6. 修改root口令

   ```
   # 进入MySQL，使用前面查询到的口令
   mysql -u root -p
   
   # 设置口令强度;将root口令设置为123456;刷新
   set global validate_password_policy=0;
   set global validate_password_length=1;
   set password for 'root'@'localhost'=password('123456');
   flush privileges;
   ```


## MySQL 开启远程连接

登录到 MySQL，修改 root 账户的 Host

1. 切换到mysql数据库

   ```
   mysql> use mysql;
   ```

2. 查看 user 数据表当前已有的数据

   ```
   mysql> select * from user \G;
   ```

3. 修改一条 root 数据，并刷新MySQL的系统权限相关表

   ```
   mysql> update user set Host='%' where Host='localhost' and User='root';
   Query OK, 1 row affected (0.00 sec)
   Rows matched: 1  Changed: 1  Warnings: 0
   
   mysql> flush privileges;
   ```

   或者使用 grant 命令重新创建一个用户

   ```
   grant all privileges on *.* to root @"%" identified by "root";
   flush privileges;
   ```

   完成后重启mysqld服务

4. 关闭防火墙

   ```
   # systemctl stop firewalld
   # systemctl disable firewalld
   ```

**注意事项**
 当出现 10038错误时 `2003 - Can't content to MySQL server on '127.0.0.1' (10038)` ，需要 check 以下几点；
 1、记得在服务器安全组开放对应端口
 2、开放了安全组后还是连接不上，就要检查防火墙了