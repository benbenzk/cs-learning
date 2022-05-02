## Flume基础应用

Flume支持的数据源种类有很多，可以来自directory、http、kafka等。Flume提供 了**Source组件**用来采集数据源；**Channel组件**用来缓存数据；**Sink组件**用来保存数据。

**常见Source**

1. Avro Source

   监听Avro端口来接收外部Avro客户端的事件流。Avro Source接收到的是经过Avro序列化后的数据，然后反序列化数据继续传输。如果是Avro Source的话，源数据必须是经过Avro序列化后的数据。利用Avro Source可以实现多级流动、扇出流、扇入流等效果。接收通过Flume提供的Avro客户端发送的日 志信息。

   > Avro是Hadoop的一个数据序列化系统，由Hadoop的创始人Doug Cutting开发，设计用于支持大批量数据交换的应用。它的主要特点: 
   >
   > 1. 支持二进制序列化方式，可以便捷，快速地处理大量数据；
   > 2. 动态语言友好，Avro提供的机制使动态语言可以方便地处理Avro数据；

   ![flume-avro-source](./imgs/flume-avro-source.png)

2. Exec Source

   可以将命令产生的输出作为source。如`ping 192.168.218.101`、`tail -f hive.log`。 

3. NetCat Source

   一个NetCat Source用来监听一个指定端口，并接收监听到的数据。 

4. Spooling Directory Source

   将指定的文件加入到“自动搜集”目录中。Flume会持续监听这个目录，把文件当做Source来处理。

   注意：一旦文件被放到目录中后， 便不能修改，如果修改，Flume会报错。此外，也不能有重名的文件。 

5. Taildir Source(1.7)

   监控指定的多个文件，一旦文件内有新写入的数据， 就会将其写入到指定的Sink内，本来源可靠性高，不会丢失数据。其不会对于跟踪的文件有任何处理，不会重命名也不会删除，不会做任何修改。目前不支持Windows 系统，不支持读取二进制文件，支持一行一行的读取文本文件。 

**常见Channel**

1. Memory Channel 缓存到内存中(最常用) 
2. File Channel 缓存到文件中
3. JDBC Channel 通过JDBC缓存到关系型数据库中
4. Kafka Channel 缓存到Kafka中

**常见Sink**

1. Logger Sink

   将信息显示在标准输出上，主要用于测试

2. Avro Sink

   Flume Events发送到Sink，转换为Avro Events，并发送到配置好的hostname/port。从配置好的Channel按照配置好的批量大小批量获取Events
   
3. Null Sink

   将接收到events全部丢弃

4. HDFS Sink

   将 Events写进HDFS。支持创建文本和序列文件，支持两种文件类型压缩。文件可以基于数据的经过时间、大小、事件的数量周期性地滚动

5. Hive Sink

   该Sink Streams 将包含分割文本或者JSON数据的Events直接传送到Hive表或分区中。使用Hive事务写Events。当一系列Events提交到Hive时，它们马上可以被Hive查询到

6. HBase Sink

   保存到HBase

7. Kafka Sink

   保存到kafka

日志采集就是根据业务需求选择合适的Source、Channel、Sink，并将其组合在一起。

### 第1节 入门案例

中文帮助文档 https://flume.liyifeng.org

业务需求

- 监听本机8888端口，Flume将监听的数据实时显示在控制台

需求分析

- 使用telnet工具可以向8888端口发送数据
- 监听端口数据，选择Netcat Source
- Channel选择Memory
- 数据实时显示，选择Logger Sink

实现步骤

1. 安装telnet工具

   ```
   yum install telnet
   ```

2. 检查8888端口是否被占用。如果该端口被占用，可以选择使用其他端口完成任务

   ```
   lsof -i:8888
   ```

3. 创建Flume Agent配置文件flume-netcat-logger.conf

    ```
    # a1是agent的名称。source、channel、sink的名称分别为:r1 c1 k1
    a1.sources = r1
    a1.channels = c1
    a1.sinks = k1
    
    # source
    a1.sources.r1.type = netcat
    a1.sources.r1.bind = bigdata03
    a1.sources.r1.port = 8888
    # channel
    a1.channels.c1.type = memory
    a1.channels.c1.capacity = 10000
    a1.channels.c1.transactionCapacity = 100
    
    # sink
    a1.sinks.k1.type = logger
    
    # source、channel、sink之间的关系
    a1.sources.r1.channels = c1
    a1.sinks.k1.channel = c1
    ```
    
    Memory Channel是使用内存缓冲Event的Channel实现。速度比较快速，容量会受到jvm内存大小的限制，可靠性不够高。适用于允许丢失数据，但对性能要求较高的日志采集业务
    
4. 启动Flume Agent 

   ```
   flume-ng agent --name a1 --conf-file $FLUME_HOME/conf/flume-netcat-logger.conf -Dflume.root.logger=INFO,console
   ```

   - name。定义agent的名字，要与参数文件一致
   - conf-file。指定参数文件位置
   - -D表示flume运行时动态修改flume.root.logger参数属性值，并将控制台日志打印级别设置为INFO级别。日志级别包括：log、info、warn、error 

5. 使用telnet向本机的8888端口发送消息hello

   ```
   telnet bigdata03 8888
   ```

6. 在Flume监听页面查看数据接收情况

   ```
   INFO sink.LoggerSink: Event: { headers:{} body: 68 65 6C 6C 6F 0D                               hello. }
   ```

### 第2节 监控日志文件信息到HDFS

业务需求

- 监控本地日志文件，收集内容实时上传到HDFS 

需求分析

- 使用 tail -F 命令即可找到本地日志文件产生的信息
- Source选择Exec。Exec监听一个指定的命令，获取命令的结果作为数据源。Source组件从这个命令的结果中取数据。当agent进程挂掉重启后，可能存在数据丢失;
- Channel选择Memory
- Sink选择HDFS 

> tail -f 
>
> 等同于--follow=descriptor，根据文件描述符进行追踪，当文件改名或被删除，追 
>
> 踪停止 
>
> tail -F 
>
> 等同于--follow=name --retry，根据文件名进行追踪，并保持重试，即该文件被 
>
> 删除或改名后，如果再次创建相同的文件名，会继续追踪 

实现步骤

1. 环境准备

   Flume要想将数据输出到HDFS，必须持有Hadoop相关jar包。将 

   commons-configuration-1.6.jar hadoop-auth-2.9.2.jar hadoop-common- 2.9.2.jar hadoop-hdfs-2.9.2.jar commons-io-2.4.jar htrace-core4-4.1.0-incubating.jar 

   拷贝到 $FLUME_HOME/lib 文件夹下，目前验证此步骤没必要

   ```
   cd $HADOOP_HOME/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib
   cp commons-configuration-1.6.jar $FLUME_HOME/lib
   cp hadoop-auth-2.9.2.jar $FLUME_HOME/lib
   cp hadoop-common-2.9.2.jar $FLUME_HOME/lib
   cp hadoop-hdfs-2.9.2.jar $FLUME_HOME/lib
   cp commons-io-2.4.jar $FLUME_HOME/lib
   cp htrace-core4-4.1.0-incubating.jar $FLUME_HOME/lib
   ```

2. 创建配置文件flume-exec-hdfs.conf

   ```
   # Name the components on this agent
   a2.sources = r2
   a2.sinks = k2
   a2.channels = c2
   
   # Describe/configure the source
   a2.sources.r2.type = exec
   a2.sources.r2.command = tail -F /opt/servers/hive-2.3.7/logs/hive.log
   
   # Use a channel which buffers events in memory
   a2.channels.c2.type = memory
   a2.channels.c2.capacity = 10000
   a2.channels.c2.transactionCapacity = 500
   
   # Describe the sink
   a2.sinks.k2.type = hdfs
   a2.sinks.k2.hdfs.path = hdfs://bigdata01:9000/flume/%Y%m%d/%H%M
   # 上传文件的前缀
   a2.sinks.k2.hdfs.filePrefix = logs-
   # 是否使用本地时间戳
   a2.sinks.k2.hdfs.useLocalTimeStamp = true
   # 积攒500个Event才flush到HDFS一次
   a2.sinks.k2.hdfs.batchSize = 500
   # 设置文件类型，支持压缩。DataStream没启用压缩
   a2.sinks.k2.hdfs.fileType = DataStream
   # 1分钟滚动一次
   a2.sinks.k2.hdfs.rollInterval = 60
   # 128M滚动一次
   a2.sinks.k2.hdfs.rollSize = 134217700
   # 文件的滚动与Event数量无关
   a2.sinks.k2.hdfs.rollCount = 0
   # 最小冗余数
   a2.sinks.k2.hdfs.minBlockReplicas = 1
   
   # Bind the source and sink to the channel
   a2.sources.r2.channels = c2
   a2.sinks.k2.channel = c2
   ```

3. 启动agent

   ```
   flume-ng agent --name a2 --conf-file ./flume-exec-hdfs.conf -Dflume.root.logger=INFO,console
   ```

4. 启动hadoop和hive，操作hive产生日志

   ```
   start-dfs.sh start-yarn.sh
   # 在命令行多次执行
   hive -e "show databases"
   ```

5. 在HDFS查看文件
  

### 第3节 监控目录采集信息到HDFS

业务需求

- 监控指定目录，收集信息实时上传到HDFS

需求分析

- Source选择Spooling Directory。Spooling Directory能够保证数据不丢失，且能够实现断点续传， 但延迟较高，不能实时监控
- Channel选择Memory
- Sink选择HDFS 

Spooling Directory Source监听一个指定的目录，即只要向指定目录**添加新的文件**，Source组件就可以获取到该信息，并解析该文件的内容，写入到Channel。Sink处理完之后， 标记该文件已完成处理，文件名添加`.completed`后缀。虽然是自动监控整个目录， 但是只能监控文件，如果以追加的方式向已被处理的文件中添加内容，Source并不能识别。

> 注意
>
> - 拷贝到spool目录下的文件不可以再打开编辑
> - 无法监控子目录的文件夹变动
> - 被监控文件夹每500毫秒扫描一次文件变动
> - 适合用于同步新文件，但不适合对实时追加日志的文件进行监听并同步

实现步骤

1. 创建配置文件`flume-spooldir-hdfs.conf`

   ```
   # Name the components on this agent
   a3.sources = r3
   a3.channels = c3
   a3.sinks = k3
   
   # Describe/configure the source
   a3.sources.r3.type = spooldir
   a3.sources.r3.spoolDir = /root/upload
   a3.sources.r3.fileSuffix = .COMPLETED
   a3.sources.r3.fileHeader = true
   
   # 忽略以.tmp结尾的文件，不上传
   a3.sources.r3.ignorePattern = ([^ ]*\.tmp)
   
   # Use a channel which buffers events in memory
   a3.channels.c3.type = memory
   a3.channels.c3.capacity = 10000
   a3.channels.c3.transactionCapacity = 500
   
   # Describe the sink
   a3.sinks.k3.type = hdfs
   a3.sinks.k3.hdfs.path = hdfs://bigdata01:9000/flume/upload/%Y%m%d/%H%M
   a3.sinks.k3.hdfs.filePrefix = upload-
   # 是否使用本地时间戳
   a3.sinks.k3.hdfs.useLocalTimeStamp = true
   # 积攒500个Event，flush到HDFS一次
   a3.sinks.k3.hdfs.batchSize = 500
   # 设置文件类型
   a3.sinks.k3.hdfs.fileType = DataStream
   # 60秒滚动一次
   a3.sinks.k3.hdfs.rollInterval = 60
   # 128M滚动一次
   a3.sinks.k3.hdfs.rollSize = 134217700
   # 文件滚动与event数量无关
   a3.sinks.k3.hdfs.rollCount = 0
   # 最小冗余数
   a3.sinks.k3.hdfs.minBlockReplicas = 1
   
   # Bind the source and sink to the channel
   a3.sources.r3.channels = c3
   a3.sinks.k3.channel = c3
   ```

2. 启动agent

   ```
   flume-ng agent --name a3 --conf-file /opt/servers/flume-1.9.0/conf/flume-spooldir-hdfs.conf -Dflume.root.logger=INFO,console
   ```

3. 向`/root/upload`文件夹中添加文件

4. 查看HDFS上的数据

### 第4节 监控日志文件采集数据到HDFS、本地文件系统

业务需求

- 监控日志文件，收集信息上传到HDFS和本地文件系统 

需求分析

- 需要多个Agent级联实现

- Source选择Taildir

  Taildir Source。Flume 1.7.0加入的新Source，相当于 Spooling Directory Source + Exec Source。可以监控多个目录，并且使用正则表达式匹配该目录中的文件名进行实时收集。实时监控一批文件，并记录每个文件最新消费位置，agent进程重启后不会有数据丢失的问题。目前不适用于Windows系统；其不会对于跟踪的文件有任何处理，不会重命名也不会删除，不会做任何修改。不支持读取二进制文件，支持一行一行的读取文本文件。 

- Channel选择Memory

- 最终的Sink分别选择HDFS、File Roll 

![flume监控日志文件采集到HDFS及本地文件系统](./imgs/flume监控日志文件采集到HDFS及本地文件系统.png)

实现步

1. 创建agent1配置文件`flume-taildir-avro.conf`

   - 1个 Taildir Source
   - 2个 Memory Channel
   - 2个 Avro Sink 

   ```
   # Name the components on this agent
   a1.sources = r1
   a1.sinks = k1 k2
   a1.channels = c1 c2
   
   # 将数据流复制给所有channel
   a1.sources.r1.selector.type = replicating
   
   # source type
   a1.sources.r1.type = taildir
   # 记录每个文件最新消费位置
   a1.sources.r1.positionFile = /root/flume/taildir_position.json
   a1.sources.r1.filegroups = f1
   # 备注:.*log 是正则表达式;这里写成 *.log 是错误的
   a1.sources.r1.filegroups.f1 = /opt/servers/hive-2.3.7/logs/.*log
   
   # sink
   a1.sinks.k1.type = avro
   a1.sinks.k1.hostname = bigdata03
   a1.sinks.k1.port = 9091
   a1.sinks.k2.type = avro
   a1.sinks.k2.hostname = bigdata03
   a1.sinks.k2.port = 9092
   
   # channel
   a1.channels.c1.type = memory
   a1.channels.c1.capacity = 10000
   a1.channels.c1.transactionCapacity = 500
   
   a1.channels.c2.type = memory
   a1.channels.c2.capacity = 10000
   a1.channels.c2.transactionCapacity = 500
   
   # Bind the source and sink to the channel
   a1.sources.r1.channels = c1 c2
   a1.sinks.k1.channel = c1
   a1.sinks.k2.channel = c2
   ```

2. 创建agent2配置文件`flume-avro-hdfs.conf`

   - 1个Avro Source
   - 1个Memory Channel
   - 1个HDFS Sink

   ```
   # Name the components on this agent
   a2.sources = r1
   a2.sinks = k1
   a2.channels = c1
   
   # Describe/configure the source
   a2.sources.r1.type = avro
   a2.sources.r1.bind = bigdata03
   a2.sources.r1.port = 9091
   
   # Describe the channel
   a2.channels.c1.type = memory
   a2.channels.c1.capacity = 10000
   a2.channels.c1.transactionCapacity = 500
   
   # Describe the sink
   a2.sinks.k1.type = hdfs
   a2.sinks.k1.hdfs.path = hdfs://bigdata01:9000/flume2/%Y%m%d/%H
   # 上传文件的前缀
   a2.sinks.k1.hdfs.filePrefix = flume2-
   # 是否使用本地时间戳
   a2.sinks.k1.hdfs.useLocalTimeStamp = true
   # 500个Event才flush到HDFS一次
   a2.sinks.k1.hdfs.batchSize = 500
   # 设置文件类型，可支持压缩
   a2.sinks.k1.hdfs.fileType = DataStream
   # 60秒生成一个新的文件
   a2.sinks.k1.hdfs.rollInterval = 60
   a2.sinks.k1.hdfs.rollSize = 0
   a2.sinks.k1.hdfs.rollCount = 0
   a2.sinks.k1.hdfs.minBlockReplicas = 1
   
   # Bind the source and sink to the channel
   a2.sources.r1.channels = c1
   a2.sinks.k1.channel = c1
   ```

3. 创建agent3配置文件`flume-avro-file.conf`

   - 1个Avro Source
   - 1个Memory Channel
   - 1个File Roll Sink

   ```
   # Name the components on this agent
   a3.sources = r1
   a3.sinks = k1
   a3.channels = c2
   
   # Describe/configure the source
   a3.sources.r1.type = avro
   a3.sources.r1.bind = bigdata03
   a3.sources.r1.port = 9092
   
   # Describe the sink
   a3.sinks.k1.type = file_roll
   # 目录需要提前创建好
   a3.sinks.k1.sink.directory = /root/flume/output
   
   # Describe the channel
   a3.channels.c2.type = memory
   a3.channels.c2.capacity = 10000
   a3.channels.c2.transactionCapacity = 500
   
   # Bind the source and sink to the channel
   a3.sources.r1.channels = c2
   a3.sinks.k1.channel = c2
   ```

4. 分别启动3个Agent

   先启动agent2、agent3，最后启动agent1

   ```
   cd $FLUME_HOME/conf
   flume-ng agent --name a2 --conf-file ./flume-avro-hdfs.conf -Dflume.root.logger=INFO,console
   flume-ng agent --name a3 --conf-file ./flume-avro-file.conf -Dflume.root.logger=INFO,console
   flume-ng agent --name a1 --conf-file ./flume-taildir-avro.conf -Dflume.root.logger=INFO,console
   ```

5. 执行hive命令产生日志

   ```
   hive -e "show databases"
   ```

6. 分别检查HDFS文件、文帝文件以及消费位置文件

三种监控日志文件Source对比

- Exec Source：适用于监控一个实时追加的文件，但不能保证数据不丢失;
- Spooling Directory Source：能够保证数据不丢失，且能够实现断点续传，但延迟较高，不能实时监控
- Taildir Source：既能够实现断点续传，又可以保证数据不丢失，还能够进行实时监控。