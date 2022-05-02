# Hue整合Hadoop、Hive

配置文件`/opt/servers/hue/desktop/conf/pseudo-distributed.ini`

1. 集成HDFS、Yarn

   ```
   # 211 行。 没有安装 Solr，禁用，否则一直报错
   	app_blacklist=search
   	
   # [hadoop] -- [[hdfs_clusters]] -- [[[default]]]
   # 注意端口号。下面语句只要一个
   	# fs_defaultfs=hdfs://localhost:8020
   	fs_defaultfs=hdfs://bigdata01:9000
   	webhdfs_url=http://bigdata01:50070/webhdfs/v1
   # 211 行
   	hadoop_conf_dir=/opt/lagou/servers/hadoop-2.9.2/etc/hadoop
   	
   # [hadoop] -- [[yarn_clusters]] -- [[[default]]]
   	resourcemanager_host=bigdata03
   	resourcemanager_port=8032
   	submit_to=True
   	resourcemanager_api_url=http://bigdata03:8088
   	proxy_api_url=http://bigdata03:8088
   	history_server_api_url=http://bigdata03:19888
   ```

2. 集成Hive

   在bigdata03上需要启动Hiveserver2服务

   ```
   [beeswax]
     hive_server_host=bigdata03
     hive_server_port=10000
     hive_conf_dir=/opt/servers/hive-2.3.7/conf
   ```

3. 集成MySQL

   ```
   # [librdbms] -- [[databases]] -- [[[mysql]]];1639行
   # 注意:1639行原文: ##[[mysql]] => [[mysql]];两个##要去掉!
       [[[mysql]]]
         nice_name="My SQL DB"
         name=hue
         engine=mysql
         host=bigdata03
         port=3306
         user=hive
         password=123456
   ```

   > name是database名称