## Hive命令

1. hive命令

   ```
   [root@bigdata03 ~]# hive -help
   usage: hive
    -d,--define <key=value>          Variable substitution to apply to Hive
                                     commands. e.g. -d A=B or --define A=B
       --database <databasename>     Specify the database to use
    -e <quoted-query-string>         SQL from command line
    -f <filename>                    SQL from files
    -H,--help                        Print help information
       --hiveconf <property=value>   Use value for given property
       --hivevar <key=value>         Variable substitution to apply to Hive
                                     commands. e.g. --hivevar A=B
    -i <filename>                    Initialization SQL file
    -S,--silent                      Silent mode in interactive shell
    -v,--verbose                     Verbose mode (echo executed SQL to the
   ```

   -e：不进入hive交互窗口，执行sql语句

   ```
   [root@bigdata03 ~]# hive -e "select * from users"
   ```

   -f：执行脚本中sql语句

   ```
   # 创建文件hqlfile1.sql，内容:select * from users
   # 执行文件中的sql语句
   [root@bigdata03 ~]# hive -f hqlfile1.sql
   ```

2. 退出hive命令行

   ```
   hive (default)> exit;
   -- 或
   hive (default)> quit;
   ```

3. 在命令行中执行shell命令

   ```
   -- 显示文件列表
   hive (default)> !ls -l;
   anaconda-ks.cfg
   hqlfile1.sql
   -- 清空屏幕
   hive (default)> !clear;
   ```

4. 在命令行中执行dfs命令

   ```
   -- 显示hdfs文件根目录文件列表
   hive (default)> dfs -ls /;
   ```