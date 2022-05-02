## Sqoop常用命令及参数

### 第1节 常用命令

<table>
  <thead>
    <tr>
      <td width="10%">序号</td>
      <td width="20%">命令</td>
      <td width="30%">类</td>
      <td>说明</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td><td>import</td><td>ImportTool</td>
      <td>将数据导入到集群</td>
    </tr>
    <tr>
      <td>2</td><td>export</td><td>ExportTool</td>
      <td>将集群数据导出</td>
    </tr>
    <tr>
      <td>3</td><td>codegen</td><td>CodeGenTool</td>
      <td>获取数据库中某张表数据生成Java并打包Jar</td>
    </tr>
    <tr>
      <td>4</td><td>create-hive-table</td><td>CreateHiveTableToo</td>
      <td>创建Hive表</td>
    </tr>
    <tr>
      <td>5</td><td>eval</td><td>EvalSqlTool</td>
      <td>查看SQL执行结果</td>
    </tr>
    <tr>
      <td>6</td><td>import-all-tables</td><td>ImportAllTablesTool</td>
      <td>入某个数据库下所有表到HDFS中</td>
    </tr>
    <tr>
      <td>7</td><td>job</td><td>JobTool</td>
      <td>用来生成一个sqoop的任务，生成后，该任务并不执行，除非使用命令执行该任务。</td>
    </tr>
    <tr>
      <td>8</td><td>list-databases</td><td>ListDatabasesTool</td>
      <td>列出所有数据库名</td>
    </tr>
    <tr>
      <td>9</td><td>list-tables</td><td>ListTablesTool</td>
      <td>列出某个数据库下所有表</td>
    </tr>
    <tr>
      <td>10</td><td>merge</td><td>MergeTool</td>
      <td>将HDFS中不同目录下面的数据合在一起，并存放在指定的目录中</td>
    </tr>
    <tr>
      <td>11</td><td>metastore</td><td>MetastoreTool</td>
      <td>记录sqoop job的元数据信息， 如果不启动metastore实例，则默认的元数据存储目录为：~/.sqoop，如果要更改存储目录，可以在配置文件sqoop- site.xml中进行更改。</td>
    </tr>
    <tr>
      <td>12</td><td>help</td><td>HelpTool</td>
      <td>打印sqoop帮助信息</td>
    </tr>
    <tr>
      <td>13</td><td>version</td><td>VersionTool</td>
      <td>打印sqoop版本信息</td>
    </tr>
  </tbody>
</table>

### 第2节 常用参数

1. 公用参数 - 数据库连接

   <table>
     <thead>
       <tr>
         <td width="10%">序号</td>
         <td width="40%">参数</td>
         <td width="50%">说明</td>
       </tr>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--connect</td>
         <td>连接关系型数据库的URL</td>
       </tr>
       <tr>
         <td>2</td><td>--connection-manager</td>
         <td>指定要使用的连接管理类</td>
       </tr>
       <tr>
         <td>3</td><td>--driver</td>
         <td>Hadoop根目录</td>
       </tr>
       <tr>
         <td>4</td><td>--help</td>
         <td>打印帮助信息</td>
       </tr>
       <tr>
         <td>5</td><td>--username</td>
         <td>连接数据库的用户名 </td>
       </tr>
       <tr>
         <td>6</td><td>--password </td>
         <td>连接数据库的密码</td>
       </tr>
       <tr>
         <td>7</td><td>--verbose</td>
         <td>在控制台打印出详细信息</td>
       </tr>
     </tbody>
   </table>

2. 公用参数 - import

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--enclosed-by</td>
         <td>给字段值前加上指定的字符</td>
       </tr>
       <tr>
         <td>2</td><td>--escaped-by</td>
         <td>对字段中的双引号加转义符</td>
       </tr>
       <tr>
         <td>3</td><td>--fields-terminated-by</td>
         <td>设定每个字段是以什么符号作为结束，默认为逗号</td>
       </tr>
       <tr>
         <td>4</td><td>-lines-terminated-by</td>
         <td>设定每行记录之间的分隔符，默认是\n</td>
       </tr>
       <tr>
         <td>5</td><td>--mysql-delimiters</td>
         <td>Mysql默认的分隔符设置，字段之间以逗号分隔，行之间 以\n分隔，默认转义符是\，字段值以单引号包裹</td>
       </tr>
       <tr>
         <td>6</td><td>--optionally-enclosed-by</td>
         <td>给带有双引号或单引号的字段值前后加上指定字符</td>
       </tr>
     </tbody>
   </table>
3. 公用参数 - export
   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--input-enclosed-by</td>
         <td>对字段值前后加上指定字符</td>
       </tr>
       <tr>
         <td>2</td><td>--input-escaped-by</td>
         <td>对含有转移符的字段做转义处理</td>
       </tr>
       <tr>
         <td>3</td><td>--input-fields-terminated-by</td>
         <td>字段之间的分隔符</td>
       </tr>
       <tr>
         <td>4</td><td>--input-lines-terminated-by</td>
         <td>行之间的分隔符</td>
       </tr>
       <tr>
         <td>5</td><td>--input-optionally-enclosed-by</td>
         <td>给带有双引号或单引号的字段前后加上指定字符</td>
       </tr>
     </tbody>
   </table>

4. 公用参数 - hive

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--hive-delims-replacement</td>
         <td>用自定义的字符串替换掉数据中的\r\n和\013 \010等字符</td>
       </tr>
       <tr>
         <td>2</td><td>--hive-drop-import-delims</td>
         <td>在导入数据到hive时，去掉数据中的 \r\n\013\010这样的字符</td>
       </tr>
       <tr>
         <td>3</td><td>--map-column-hive</td>
         <td>生成hive表时，可以更改生成字段的数据类型</td>
       </tr>
       <tr>
         <td>4</td><td>--hive-partition-key</td>
         <td>创建分区，后面直接跟分区名，分区字段的默认 类型为string</td>
       </tr>
       <tr>
         <td>5</td><td>--hive-partition-value</td>
         <td>导入数据时，指定某个分区的值</td>
       </tr>
       <tr>
         <td>6</td><td>--hive-home</td>
         <td>hive的安装目录，可以通过该参数覆盖之前默认配置的目录</td>
       </tr>
       <tr>
         <td>7</td><td>--hive-import</td>
         <td>将数据从关系数据库中导入到hive表中</td>
       </tr>
       <tr>
         <td>8</td><td>--hive-overwrite</td>
         <td>覆盖掉在hive表中已经存在的数据</td>
       </tr>
       <tr>
         <td>9</td><td>--create-hive-table</td>
         <td>默认是false，即如果目标表已经存在了，那么创建任务失败</td>
       </tr>
       <tr>
         <td>10</td><td>--hive-table</td>
         <td>后面接要创建的hive表,默认使用MySQL的表名</td>
       </tr>
       <tr>
         <td>11</td><td>--table</td>
         <td>指定关系数据库的表名</td>
       </tr>
     </tbody>
   </table>

5. import参数

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--append</td>
         <td>将数据追加到HDFS中已经存在的DataSet中，如果使用该参数，sqoop会把数据先导入到临时文件目录，再合并</td>
       </tr>
       <tr>
         <td>2</td><td>--as-avrodatafile</td>
         <td>将数据导入到一个Avro数据文件中</td>
       </tr>
       <tr>
         <td>3</td><td>--as-sequencefile</td>
         <td>将数据导入到一个sequence文件中</td>
       </tr>
       <tr>
         <td>4</td><td>--as-textfile</td>
         <td>将数据导入到一个普通文本文件中</td>
       </tr>
       <tr>
         <td>5</td><td>--boundary-query</td>
         <td>边界查询，导入的数据为该参数的值(一条sql语 句)所执行的结果区间内的数据</td>
       </tr>
       <tr>
         <td>6</td><td>--columns<col1, col2, col3></td>
         <td>指定要导入的字段</td>
       </tr>
       <tr>
         <td>7</td><td>--direct</td>
         <td>直接导入模式，使用的是关系数据库自带的导入导
出工具，以便加快导入导出过程</td>
       </tr>
       <tr>
         <td>8</td><td>--direct-split-size</td>
         <td>在使用上面direct直接导入的基础上，对导入的流 按字节分块，即达到该阈值就产生一个新的文件</td>
       </tr>
       <tr>
         <td>9</td><td>--inline-lob-limit</td>
         <td>设定大对象数据类型的最大值</td>
       </tr>
       <tr>
         <td>10</td><td>--m或–num- mappers</td>
         <td>启动N个map来并行导入数据，默认4个。</td>
       </tr>
       <tr>
         <td>11</td><td>--query或--e</td>
         <td>将查询结果的数据导入，使用时必须伴随参-- target-dir，--hive-table，如果查询中有where条 件，则条件后必须加上$CONDITIONS关键字</td>
       </tr>
       <tr>
         <td>12</td><td>--split-by</td>
         <td>按照某一列来切分表的工作单元，不能与--autoreset-to-one-mapper连用(请参考官方文 档)</td>
       </tr>
       <tr>
         <td>13</td><td>--table</td>
         <td>关系数据库的表名</td>
       </tr>
       <tr>
         <td>14</td><td>--target-dir</td>
         <td>指定HDFS路径</td>
       </tr>
       <tr>
         <td>15</td><td>--warehouse-dir</td>
         <td>与14参数不能同时使用，导入数据到HDFS时指定的目录</td>
       </tr>
       <tr>
         <td>16</td><td>--where</td>
         <td>从关系数据库导入数据时的查询条件</td>
       </tr>
       <tr>
         <td>17</td><td>--z或--compress</td>
         <td>允许压缩</td>
       </tr>
       <tr>
         <td>18</td><td>--compression-codec</td>
         <td>指定hadoop压缩编码类，默认为gzip(Use Hadoop codec default gzip)</td>
       </tr>
       <tr>
         <td>19</td><td>--null-string</td>
         <td>string类型的列如果null，替换为指定字符串</td>
       </tr>
       <tr>
         <td>20</td><td>--null-non-string</td>
         <td>非string类型的列如果null，替换为指定字符串</td>
       </tr>
       <tr>
         <td>21</td><td>--check-column</td>
         <td>作为增量导入判断的列名</td>
       </tr>
       <tr>
         <td>22</td><td>--incremental</td>
         <td>mode:append或lastmodified</td>
       </tr>
       <tr>
         <td>23</td><td>--last-value</td>
         <td>指定某一个值，用于标记增量导入的位置</td>
       </tr>
     </tbody>
   </table> 

6. export参数

   <table>
     <thead>
       <td width="10%">序号</td>
       <td width="40%">参数</td>
       <td width="50%">说明</td>
     </thead>
     <tbody>
       <tr>
         <td>1</td><td>--direct</td>
         <td>利用数据库自带的导入导出工具，以便于提高效率</td>
       </tr>
       <tr>
         <td>2</td><td>--export-dir</td>
         <td>存放数据的HDFS的源目录</td>
       </tr>
       <tr>
         <td>3</td><td>-m或--num-mappers</td>
         <td>启动N个map来并行导入数据，默认4个</td>
       </tr>
       <tr>
         <td>4</td><td>--table</td>
         <td>指定导出到哪个RDBMS中的表</td>
       </tr>
       <tr>
         <td>5</td><td>--update-key</td>
         <td>对某一列的字段进行更新操作</td>
       </tr>
       <tr>
         <td>6</td><td>--update-mode</td>
         <td>updateonly allowinsert(默认)</td>
       </tr>
       <tr>
         <td>7</td><td>--input-null-string</td>
         <td>请参考import该类似参数说明</td>
       </tr>
       <tr>
         <td>8</td><td>--input-null-non-string</td>
         <td>请参考import该类似参数说明</td>
       </tr>
       <tr>
         <td>9</td><td>--staging-table</td>
         <td>创建一张临时表，用于存放所有事务的结果，然后将所有
事务结果一次性导入到目标表中，防止错误。</td>
       </tr>
       <tr>
         <td>10</td><td>--clear- staging-table</td>
         <td>如果第9个参数非空，则可以在导出操作执行前，清空临时事务结果表</td>
       </tr>
     </tbody>
   </table>