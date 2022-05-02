今天在使用Hadoop集群上的Hive时，结果出现以下错误：

```
FAILED: SemanticException org.apache.hadoop.hive.ql.metadata.HiveException: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient
```

使用hive启动进程`hive --service metastore `查看错误



重新安装mysql，密码没有重新初始化？？

```
[root@bigdata03 ~]# rpm -qa | grep mysql

[root@bigdata03 ~]# rpm -e --nodeps mysql-community-common-8.0.16-2.el7.aarch64
[root@bigdata03 ~]# rpm -e --nodeps mysql-community-client-8.0.16-2.el7.aarch64
[root@bigdata03 ~]# rpm -e --nodeps mysql-community-libs-8.0.16-2.el7.aarch64
[root@bigdata03 ~]# rpm -e --nodeps mysql-community-server-8.0.16-2.el7.aarch64

root@bigdata03 ~]# find / -name mysql
/etc/selinux/targeted/active/modules/100/mysql
/var/lib/mysql
/var/lib/mysql/mysql
/usr/lib64/mysql
/opt/servers/hive-2.3.7/scripts/metastore/upgrade/mysql
#删除文件
[root@bigdata03 ~]#rm -rf /etc/selinux/targeted/active/modules/100/mysql
[root@bigdata03 ~]#rm -rf /var/lib/mysql
[root@bigdata03 ~]#rm -rf /var/lib/mysql/mysql
[root@bigdata03 ~]#rm -rf /usr/lib64/mysql
```

