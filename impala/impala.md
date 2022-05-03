## Impala概述

### 1.1 Impala是什么 

Impala是Cloudera提供的⼀款开源的针对HDFS和HBASE中的PB级别数据进⾏交互式实时查询(Impala速度快)，Impala是参照谷歌的新三篇论文当中的Dremel实现⽽来，其中旧三篇论⽂分别是 (BigTable，GFS，MapReduce)分别对应我们即将学的HBase和已经学过的HDFS以及MapReduce。 

Impala最大卖点和最大特点就是**快速**，Impala中文翻译是⾼角羚⽺。 

### 1.2 Impala优势 

回顾前面⼤数据课程路线其实就是⼀个大数据从业者面对的大数据相关技术发展的过程，

- 技术发展以及更新换代的原因就是老的技术架构遇到新的问题，有些问题可以通过不断优化代码优化设计得以解决，有一些问题就不再是简简单单修改代码就能解决，需要从框架本身架构设计上改变，以至于需要推倒重建。
- 在大数据领域主要解决的问题是数据的存储和分析，但是其实一个完整的大数据分析任务如果细分会有非常多具体的场景，⾮常多的环节；并没有一个类似Java Web的Spring框架实现大一统的局面。 

⽐如我们按照阶段划分一个大数据开发任务，会有：数据采集(日志文件，关系型数据库中)，数据清洗 (数据格式整理，脏数据过滤等)，数据预处理(为了后续分析所做的工作)，数据分析：离线处理(T+1分析)，实时处理(数据到来即分析)，数据可视化，机器学习，深度学习等 

面对如此众多的阶段再加上大数据天生的大数据量问题没有任何一个框架可以完美cover以上每个阶段。所以大数据领域有⾮常多框架，每个框架都有最适合⾃己的具体场景。⽐如：HDFS负责大数据量存储，MapReduce(Hive)负责大数据量的分析计算， 

**Impala的诞⽣**

之前学习的Hive以及MR适合离线批处理，但是对交互式查询的场景⽆能为力要求快速响应)，所以为了解决查询速度的问题，Cloudera公司依据Google的Dremel开发了Impala,Impala抛弃了**MapReduce** 使⽤了类似于传统的**MPP**数据库技术，⼤大提⾼了查询的速度。 

**MPP是什么?** 

MPP (Massively Parallel Processing)，就是大规模并⾏处理，在MPP集群中，每个节点资源都是独⽴享有也就是有独⽴的磁盘和内存，每个节点通过网络互相连接，彼此协同计算，作为整体提供数据服 务。 

简单来说，MPP是将任务并行的分散到多个服务器和节点上，在每个节点上计算完成后，将各自部分的结果汇总在一起得到最终的结果 

对于MPP架构的软件来说聚合操作比如计算某张表的总条数，则先进⾏局部聚合(每个节点并⾏计算)， 然后把局部汇总结果进⾏全局聚合(与Hadoop相似)。 

**Impala与Hive对⽐**

Impala的技术优势

- Impala没有采取MapReduce作为计算引擎，MR是非常好的分布式并⾏计算框架，但MR引擎更多的是⾯向批处理模式，⽽不是⾯向交互式的SQL执⾏。与 Hive相⽐：Impala把整个查询任务转为一棵执⾏计划树，⽽不是一连串的MR任务，在分发执⾏计划后，Impala使⽤拉取的⽅式获取上个阶段的执⾏行结果，把结果数据、按执⾏树流式传递汇集，减少的了把中间结果写入磁盘的步骤，再从磁盘读取数据的开销。Impala使⽤服务的⽅式避免每次执⾏查询都需要启动的开销，即相⽐Hive没了MR启动时间。 

- 使⽤用LLVM(C++编写的编译器器)产⽣运⾏代码，针对特定查询⽣成特定代码。 

- 优秀的IO调度，Impala⽀持直接数据块读取和本地代码计算。

- 选择适合的数据存储格式可以得到最好的性能(Impala⽀支持多种存储格式)。

- 尽可能使用内存，中间结果不写磁盘，及时通过网络以stream的⽅式传递。

Impala与Hive对比分析

查询过程

- Hive：在Hive中，每个查询都有一个“冷启动”的常见问题。(map,reduce每次都要启动关闭，申请资源，释放资源。。。)

- Impala：Impala避免了任何可能的启动开销，这是⼀种本地查询语⾔。 因为要始终处理查询，则 Impala守护程序进程总是在集群启动之后就准备就绪。守护进程在集群启动之后可以接收查询任务并执行查询任务。

中间结果

- Hive：Hive通过MR引擎实现所有中间结果，中间结果需要落盘，这对降低数据处理速度有不利影响。

- Impala：在执⾏程序之间使⽤流的⽅式传输中间结果，避免数据落盘。尽可能使用内存避免磁盘开销

交互查询

- Hive：对于交互式计算，Hive不是理想的选择。
- Impala：对于交互式计算，Impala非常适合。(数据量量级PB级)

计算引擎

- Hive：是基于批处理的Hadoop MapReduce
- Impala：更像是MPP数据库

容错

- Hive：Hive是容错的(通过MR&Yarn实现) 

- Impala：Impala没有容错，由于良好的查询性能，Impala遇到错误会重新执行⼀次查询

查询速度 

​	Impala：Impala比Hive快3-90倍。

**Impala优势总结**

1. Impala最大优点就是查询速度快，在一定数据量下;
2. 速度快的原因：避免了MR引擎的弊端，采⽤了MPP数据库技术

### 1.3 Impala的缺点

1. Impala属于MPP架构，只能做到百节点级，一般并发查询个数达到20左右时，整个系统的吞吐已经达到满负荷状态，在扩容节点也提升不了吞吐量，处理数据量在PB级别最佳。 
2. 资源不能通过YARN统⼀资源管理调度，所以Hadoop集群⽆法实现Impala、Spark、Hive等组件的动态资源共享。 

### 1.4 适⽤用场景

 **Hive**：复杂的批处理理查询任务，数据转换任务，对实时性要求不⾼同时数据量⼜很⼤的场景。 

**Impala**：实时数据分析，与Hive配合使用，对Hive的结果数据集进⾏实时分析。impala不能完全取代hive，impala可以直接处理hive表中的数据。 



## Impala安装与入⻔案例 

### 2.1 集群准备 

1. 安装**Hadoop,Hive** 
   - Impala的安装需要提前装好Hadoop，Hive这两个框架
   - hive需要在所有的Impala安装的节点上面都要有，因为Impala需要引用Hive的依赖包
   - hadoop的框架需要支持C程序访问接⼝，查看下图，如果该路径有.so结尾⽂文件，就证明支持C接口。 

2. 准备Impala的所有依赖包

   Cloudera公司对于Impala的安装只提供了rpm包没有提供tar包；所以我们选择使用Cloudera的rpm包进⾏Impala的安装，但是另外一个问题，Impala的rpm包依赖⾮常多的其他的rpm包，我们可以⼀个个的将依赖找出来，但是这种⽅式实在是浪费时间。 

   Linux系统中对于rpm包的依赖管理提供了⼀个非常好的管理工具叫做Yum，类似于Java工程中的包管理工具Maven，Maven可以自动搜寻指定Jar所需的其它依赖并⾃动下载来。Yum同理可以⾮常⽅便的让我们进⾏rpm包的安装⽆需关系当前rpm所需的依赖。但是与Maven下载其它依赖需要到中央仓库⼀样 Yum下载依赖所需的源也是在放置在国外服务器并且其中没有安装Impala所需要的rpm包，所以默认的这种Yum源可能下载依赖失败。所以我们可以指定Yum去哪里下载所需依赖。 

   rpm⽅式安装：需要⾃己管理rpm包的依赖关系，⾮常麻烦，解决依赖关系使⽤yum；默认Yum源是没有Impala的rpm安装包，所以我们⾃己准备好所有的Impala安装所需的rpm包，制作Yum本地源，配置 Yum命令去到我们准备的Yun源中下载Impala的rpm包进⾏安装。 

**本地Yum原制作步骤**

Yum源是Centos当中下载软件rpm包的地址，因此通过制作本地Yum源并指定Yum命令使⽤本地Yum源，为了使Yum命令(本机，跨⽹网络节点)可以通过网络访问到本地源，我们使⽤Httpd这种静态资源服务器来开放我们下载所有的rpm包。

1. 在bigdata01上安装httpd服务器

   ```shell
   #安装
   yum install -y httpd
   #启动服务
   systemctl start httpd
   ```

   验证httpd工作是否正常，默认端口是80，可以省略，访问地址：http://bigdata01

   ![httpd](./imgs/httpd.png)

2. 新建一个测试页面

   httpd默认存放页面路径`/var/www/html`

   新建一个test.html

   ```html
   <html>
     <body>
       <div>this is a new page!!</div>
     </body>
   </html>
   ```

   访问：http://bigdata01/test.html

   后续可以把下载的rpm包解压房知道此处便可下载

3. 下载Impala安装所需rpm包

   impala所需安装包下载：http://archive.cloudera.com/cdh5/repo-as-tarball/5.7.6/cdh5.7.6-centos7.tar.gz

   注意：该tar.gz包是包含了Cloudera所提供的⼏乎所有rpm包，但是为了方便我们不再去梳理其中依赖关系，全部下载来，整个⽂件⽐较⼤，有3.8G。选择一个磁盘空间够的节点，后续还要把压缩包解压所以磁盘空间要剩余10G以上。

   下载完成后将安装包上传到bigdata01的/opt/software目录中

4. 使用httpd浏览安装包文件

   解压缩安装包

   ```shell
   tar -zxvf /opt/software/impala-cdh5.7.6-centos7.tar.gz -C /opt/servers/
   ```

   创建软链接到 /var/www/html目录下

   ```shell
   ln -s /opt/servers/cdh/5.7.6 /var/www/html/cdh57
   ```

   验证：http://bigdata01/cdh57

   > 注意：如果提示403 forbidden，修改/etc/selinux/config配置SELINUX=disabled，然后重启机器

5. 修改yum源配置文件

   ```
   cd /etc/yum.repos.d/
   #创建一个新配置文件
   vi local.repo
   #添加内容
   [local]
   name=local
   baseurl=http://bigdata01/cdh57/
   gpgcheck=0
   enabled=1
   ```

   说明

   - name：对于当前源的描述；
   - baseurl：访问当前源的地址信息；
   - gpgcheck：1/0，gpg校验；
   - enabled：1/0，是否使⽤用当前源；

6. 分发local.repo文件到其它节点

### 2.2 安装Impala

#### 集群规划

| 服务               | Bigdata01 | Bigdata02 | Bigdata03 |
| ------------------ | --------- | --------- | --------- |
| Impala-catalogd    | ✘         | ✘         | ✔︎         |
| impala-statestored | ✘         | ✘         | ✔︎         |
| impala-server      | ✔︎         | ✔︎         | ✔︎         |

impala-server：这个进程是Impala真正工作的进程，官⽅建议把impala-server安装在datanode节点， 更更靠近数据(短路路读取)，进程名impalad；

impala-statestored：健康监控⻆色，主要监控impala-server，impala-server出现异常时告知给其它impala-server，进程名叫做statestored；

impala-catalogd：管理和维护元数据(Hive)，impala更新操作，把impala-server更新的元数据通知给其它impala-server，进程名catalogd；

官方建议statestore与catalog安装在同一节点上!! 

#### 安装步骤

bigdata03

```shell
yum install -y impala
yum install -y impala-server
yum install -y impala-state-store
yum install -y impala-catalog
yum install -y impala-shell
```

