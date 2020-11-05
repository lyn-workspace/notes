# Elasticsearch 和kibana的初体验

> 我们这里使用的是docker-compose 进行安装, 在安装之前, 首先需要服务器安装docker和docker-compose, 安装这些的过程这里就先不说了 

## 1.  安装前的准备

`docker-compose.yml`

```yaml
version: '3'
services:
    elasticsearch:
        environment:
            discovery.type: "single-node"
            ES_JAVA_OPTS: '-Xms64m -Xmx512m'
        image: "elasticsearch:7.6.2"
        restart: always
        volumes:
            - "./config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml "
            - "./data:/usr/share/elasticsearch/data"
            - "./plugins:/usr/share/elasticsearch/plugins"
        ports:
            - "9200:9200"
            - "9300:9300"
        networks:
          - es7net
    kibana:
        image: kibana:7.6.2
        container_name: kibana
        environment:
            - XPACK_GRAPH_ENABLED=true
            - TIMELION_ENABLED=true
            - XPACK_MONITORING_COLLECTION_ENABLED="true"
        ports:
            - "5601:5601"
        networks:
            - es7net
networks:
    es7net:
        driver: bridge

```

在执行`docker-compose`之前,先创建好docker 映射需要的一些目录,这里直接使用一个脚本代替

`init.sh`

```bash
echo "开始初始化es"
echo "初始化config 目录"
mkdir ./config
echo "初始化数据目录"
mkdir ./data
echo "初始化插件目录"
mkdir ./plugins
echo  "http.host: 0.0.0.0" >./config/elasticsearch.yml
echo "添加访问权限"
chmod -R  777 ../es
echo "初始化结束,可以开始直接 docker-compose up 了"

```



## 2. 安装

先执行`chmod +x init.sh` 给予`init.sh`  脚本执行的权限, 然后执行

```bash
sh init.sh
```

然后启动docker-compose 进行安装即可, 在`docker-compose`的同级目录下执行

```bash
docker-compose up -d
```

然后我们使用`docker ps` 就可以看到 `elasticsearch` 和`kibana` 的容器启动成功了



> 验证

我们可以通过访问 `http://ip:9200`端口, 可以看到

```json
{
    "name": "0adeb7852e00",
    "cluster_name": "elasticsearch",
    "cluster_uuid": "9gglpP0HTfyOTRAaSe2rIg",
    "version": {
        "number": "7.6.2",
        "build_flavor": "default",
        "build_type": "docker",
        "build_hash": "ef48eb35cf30adf4db14086e8aabd07ef6fb113f",
        "build_date": "2020-03-26T06:34:37.794943Z",
        "build_snapshot": false,
        "lucene_version": "8.4.0",
        "minimum_wire_compatibility_version": "6.8.0",
        "minimum_index_compatibility_version": "6.0.0-beta1"
    },
    "tagline": "You Know, for Search"
}
```

就说明 `elasticsearch` 已经安装成功了

访问`http://ip:5601` 出现页面,就说明`kibana` 安装成功了

## 3. 基本API

### 3.1 `_cat`

#### 3.1.1  `GET`  `_cat` 查看所有的节点

如: `http://ip:9200/_cat/nodes`, 可以看到:

```text
172.29.0.3 21 86 55 8.33 8.23 9.08 dilm * 2162cacd6d03
```

注: `*` 表示集群中的主节点

#### 3.1.2 `GET`  `_cat/health` 查看es的健康状况

访问: `http://ip:9200/_cat/health`,可以看到

```text
1604546520 03:22:00 docker-cluster green 1 1 4 4 0 0 0 0 - 100.0%
```

注意: `green` 表示健康值正常

#### 3.1.3 `GET` `_cat/master` 查看主节点

访问: `http://ip:9200/_cat/master` , 可以看到

```text
osm0iaKBT9qrxc5mOIsRDQ 172.29.0.3 172.29.0.3 2162cacd6d03
```

#### 3.1.4  `GET` `_cat/indices`  查看所有的索引,等价于`mysql` 中的`show databases`

访问:  `http://ip:9200/_cat/indices`

可以看到

```text
green open .kibana_task_manager_1       SXTHIO_4RsWZmTwMNshnsA 1 0    2  0 49.2kb 49.2kb
green open kibana_sample_data_ecommerce caFiJ4VWSDmDkQFl6HXTRw 1 0 4675  0  5.1mb  5.1mb
green open .apm-agent-configuration     HPYrwMnOTB2s2vSeSMi_bQ 1 0    0  0   283b   283b
green open .kibana_1                    dIEll9o5TJWPNr95Bfv9pw 1 0   57 49  1.8mb  1.8mb
```



### 3.2  索引一个文档

保存一个数据,保存到哪个索引下面,指定用哪个唯一标识, 

如`PUT customer/external/1`, 表示 在`customer` 索引下的 `external` 类型下保存1号数据

```json
{
"name":"卢亚楠"
}
```

这里可以使用`POST` 请求, 也可以使用`PUT`请求,

`POST` 新增,如果不指定id, 会自动生成id, 指定id就会修改这个数据,并新增版本号

`PUT` 可以新增,也可以修改,但是`PUT` 必须指定id, 由于`PUT`必须指定id, 所以我们一般用来做更新操作,不指定`id` 就会报错

可以看到返回

```json
{
    "_index": "customer",
    "_type": "external",
    "_id": "1",
    "_version": 1,
    "result": "created",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 0,
    "_primary_term": 1
}
```

这些返回的`JSON`串的含义: 这些带有下划线开头的, 称为元数据,反映了当前的基本信息. 

`"_index": "customer"`: 表示该数据在哪个数据库下

`"_type": "external",` 表示该数据在哪个类型下

` "_id": "1",`:   说明被保存的数据的id

`"_version": 1,`:被保存的数据的版本

`"result": "created",`:  这里是创建了一条数据,如果 重新`put` 了一条数据, 该状态会变为`updated`, 并且版本号也会发生变化

###  3.3 查看文档

`GET ` `customer/external/1`

> `http://ip:9200/customer/external/1`

返回结果: 

```json
{
    "_index": "customer", // 在哪个索引中
    "_type": "external", // 在那个类型下
    "_id": "1", // 记录id
    "_version": 1, // 版本号
    "_seq_no": 0, // 并发控制字段,每次更新都会加1,用来做乐观锁
    "_primary_term": 1, // 同上,主分片重新分配,如重启,就会变化
    "found": true, 
    "_source": {
        "name": "卢亚楠"
    }
}
```

通过`if_seq_no=1&if_primary_term=1` ,当序列号匹配的时候,才进行修改,否则不修改. 

实例: 将`id=1`的数据, 修改为`name=1`,然后再次更新为`name=2`, 起始`seq_no=0`, `primary_term=1`

##### 1.  将`name`  更新为1

`http://ip:9200/customer/external/1?if_seq_no=0&if_primary_term=1`

查看返回结果

```json
{
    "_index": "customer",
    "_type": "external",
    "_id": "1",
    "_version": 2,
    "result": "updated",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 1,
    "_primary_term": 1
}
```

可以看到, `_seq_no`加1了

##### 2.  将`name` 更新为2,更新过程中使用`_seq_no=0`

再次调用 `http://ip:9200/customer/external/1?if_seq_no=0&if_primary_term=1`

将参数更新为: 

```json
{
"name":"2"
}
```



返回结果: 

```json
{
    "error": {
        "root_cause": [
            {
                "type": "version_conflict_engine_exception",
                "reason": "[1]: version conflict, required seqNo [0], primary term [1]. current document has seqNo [1] and primary term [1]",
                "index_uuid": "wnn6v2lTQD23hl6ZTc2zpw",
                "shard": "0",
                "index": "customer"
            }
        ],
        "type": "version_conflict_engine_exception",
        "reason": "[1]: version conflict, required seqNo [0], primary term [1]. current document has seqNo [1] and primary term [1]",
        "index_uuid": "wnn6v2lTQD23hl6ZTc2zpw",
        "shard": "0",
        "index": "customer"
    },
    "status": 409
}
```

 可以看到更新出现了错误

##### 3. 查看新的数据

调用 `http://ip:9200/customer/external/1`

```json
{
    "_index": "customer",
    "_type": "external",
    "_id": "1",
    "_version": 2,
    "_seq_no": 1,
    "_primary_term": 1,
    "found": true,
    "_source": {
        "name": "1"
    }
}
```

可以看到`_seq_no` 变成了1

##### 4. 再次更新,更新成功

将地址换为 `http://ip:9200/customer/external/1?if_seq_no=1&if_primary_term=1`, 

查看返回结果: 

```json
{
    "_index": "customer",
    "_type": "external",
    "_id": "1",
    "_version": 3,
    "result": "updated",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 2,
    "_primary_term": 1
}
```

可以看到数据已经更新成功了

### 3.4 更新文档

可以使用

1.  **`POST`** `customer/external/1/_update`

    ```json
   {
       "doc":{
           "name":"1"
       }
   }
   ```

2. **`POST`**   `customer/external/1`

   ```json
   {
           "name":"1"
       }
   ```

3.  **`PUT`**  `customer/external/1`

   ```json
   {
           "name":"1"
       }
   ```

- 不同: `POST`操作会对比源文档数据,如果相同不会有什么操作,文档`Version 不增加,`PUT` 操作总会将数据重新保存并且增加`version` 版本

   带`_update` 对比元数据, 如果一样,则不进行任何操作. 

  使用场景: 

  - 对于大并发更新,不带`update`
  - 对于大并发查询偶尔更新,带`update`, 对比更新,重新计算分配规则

- 更新同时增加属性 **`POST`** `/customer/external/1_update`

   ```json
  {
      "doc":{
          "name":"2",
          "age":"22"
      }
  }
  ```

  

  

###  3.5 删除文档或者索引

  ```text
  DELETE customer/external/1
  DELETE customer
  ```

  注:  `elasticsearch` 并没有提供删除类型的操作, 只提供了删除索引和文档的操作,

  #### 3.5.1 根据id删除

  例:  删除`id=1`的数据,删除后继续查询`

  **`DELETE`**  `http://ip:9200/customer/external/1`

   返回结果: 

  ```json
  {
      "_index": "customer",
      "_type": "external",
      "_id": "1",
      "_version": 4,
      "result": "deleted",
      "_shards": {
          "total": 2,
          "successful": 1,
          "failed": 0
      },
      "_seq_no": 3,
      "_primary_term": 1
  }
  ```

  然后再查询, 可以看到返回

  ```josn
  {
      "_index": "customer",
      "_type": "external",
      "_id": "1",
      "found": false
  }
  ```

  

#### 3.5.2 删除整个索引

**`DELETE`** `http://ip:9200/customer`

返回结果: 

```json
{
    "acknowledged": true
}
```



### 3.6  批量操作 `bulk`

语法格式: 

```text
{action:{metadata}}\n
{request body  }\n
{action:{metadata}}\n
{request body  }\n
```

这里的批量操作,当发生某一条执行发生失败的时候,其他的数据仍然是可以继续执行,也就是说彼此之间是独立的,

`bulk api`依次按顺序执行所有的`action`(动作), 如果一个单个的动作因为任何原因失败,它将继续处理后面剩余的动作,当`bulk api`  返回的时候,它将提供每个动作的状态(与发送的顺序相同) , 通过这个可以检查一个指定的动作是否失败了. 

**例子**

1.  执行多条数据

    ```text
   POST customer/external/_bulk
   {"index":{"_id":"1"}}
   {"name":"John Doe"}
   {"index":{"_id":"2"}}
   {"name":"John Doe"}
   ```

   

    执行结果: 

   ```json
   #! Deprecation: [types removal] Specifying types in bulk requests is deprecated.
   {
     "took" : 491,
     "errors" : false,
     "items" : [
       {
         "index" : {
           "_index" : "customer",
           "_type" : "external",
           "_id" : "1",
           "_version" : 1,
           "result" : "created",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 0,
           "_primary_term" : 1,
           "status" : 201
         }
       },
       {
         "index" : {
           "_index" : "customer",
           "_type" : "external",
           "_id" : "2",
           "_version" : 1,
           "result" : "created",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 1,
           "_primary_term" : 1,
           "status" : 201
         }
       }
     ]
   }
   ```

2. 对于整个索引执行批量操作

   ```text
   POST /_bulk
   {"delete":{"_index":"website","_type":"blog","_id":"123"}}
   {"create":{"_index":"website","_type":"blog","_id":"123"}}
   {"title":"my first blog post"}
   {"index":{"_index":"website","_type":"blog"}}
   {"title":"my second blog post"}
   {"update":{"_index":"website","_type":"blog","_id":"123"}}
   {"doc":{"title":"my updated blog post"}}
   ```

   运行结果: 

   ```json
   #! Deprecation: [types removal] Specifying types in bulk requests is deprecated.
   {
     "took" : 608,
     "errors" : false,
     "items" : [
       {
         "delete" : {
           "_index" : "website",
           "_type" : "blog",
           "_id" : "123",
           "_version" : 1,
           "result" : "not_found",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 0,
           "_primary_term" : 1,
           "status" : 404
         }
       },
       {
         "create" : {
           "_index" : "website",
           "_type" : "blog",
           "_id" : "123",
           "_version" : 2,
           "result" : "created",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 1,
           "_primary_term" : 1,
           "status" : 201
         }
       },
       {
         "index" : {
           "_index" : "website",
           "_type" : "blog",
           "_id" : "MCOs0HEBHYK_MJXUyYIz",
           "_version" : 1,
           "result" : "created",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 2,
           "_primary_term" : 1,
           "status" : 201
         }
       },
       {
         "update" : {
           "_index" : "website",
           "_type" : "blog",
           "_id" : "123",
           "_version" : 3,
           "result" : "updated",
           "_shards" : {
             "total" : 2,
             "successful" : 1,
             "failed" : 0
           },
           "_seq_no" : 3,
           "_primary_term" : 1,
           "status" : 200
         }
       }
     ]
   }
   ```

   



## 4. 检索

### 4.1 样本测试数据

准备一份顾客银行账户信息的虚构的`JSON`  文档样本,每个文档下面都用下列的`schema`(模式)

```json
{
	"account_number": 1,
	"balance": 39225,
	"firstname": "Amber",
	"lastname": "Duke",
	"age": 32,
	"gender": "M",
	"address": "880 Holmes Lane",
	"employer": "Pyrami",
	"email": "amberduke@pyrami.com",
	"city": "Brogan",
	"state": "IL"
}
```



从 `[https://github.com/elastic/elasticsearch/blob/master/docs/src/test/resources/accounts.json] `  导入测试数据

`POST bank/account/_bulk`



### 4.2 检索

#### 4.2.1 `search api`

`ES` 支持两种基本方式检索

- 通过`REST request uri`发送搜索参数(uri+搜索参数)
- 通过`REST request body`  来发送参数(uri+请求体)

信息检索

>  一切检索从`_search`开始

- `GET /bank/_search`    

  > 检索`bank` 下所有信息,包括`type`和`docs`

- `GET` `bank/_search?q=*&sort=account_number:asc` 

  >  请求参数方式检索

  返回结果: 

  ```json
  {
    "took" : 887,
    "timed_out" : false,
    "_shards" : {
      "total" : 1,
      "successful" : 1,
      "skipped" : 0,
      "failed" : 0
    },
    "hits" : {
      "total" : {
        "value" : 1000,
        "relation" : "eq"
      },
      "max_score" : null,
      "hits" : [
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "0",
          "_score" : null,
          "_source" : {
            "account_number" : 0,
            "balance" : 16623,
            "firstname" : "Bradshaw",
            "lastname" : "Mckenzie",
            "age" : 29,
            "gender" : "F",
            "address" : "244 Columbus Place",
            "employer" : "Euron",
            "email" : "bradshawmckenzie@euron.com",
            "city" : "Hobucken",
            "state" : "CO"
          },
          "sort" : [
            0
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "1",
          "_score" : null,
          "_source" : {
            "account_number" : 1,
            "balance" : 39225,
            "firstname" : "Amber",
            "lastname" : "Duke",
            "age" : 32,
            "gender" : "M",
            "address" : "880 Holmes Lane",
            "employer" : "Pyrami",
            "email" : "amberduke@pyrami.com",
            "city" : "Brogan",
            "state" : "IL"
          },
          "sort" : [
            1
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "2",
          "_score" : null,
          "_source" : {
            "account_number" : 2,
            "balance" : 28838,
            "firstname" : "Roberta",
            "lastname" : "Bender",
            "age" : 22,
            "gender" : "F",
            "address" : "560 Kingsway Place",
            "employer" : "Chillium",
            "email" : "robertabender@chillium.com",
            "city" : "Bennett",
            "state" : "LA"
          },
          "sort" : [
            2
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "3",
          "_score" : null,
          "_source" : {
            "account_number" : 3,
            "balance" : 44947,
            "firstname" : "Levine",
            "lastname" : "Burks",
            "age" : 26,
            "gender" : "F",
            "address" : "328 Wilson Avenue",
            "employer" : "Amtap",
            "email" : "levineburks@amtap.com",
            "city" : "Cochranville",
            "state" : "HI"
          },
          "sort" : [
            3
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "4",
          "_score" : null,
          "_source" : {
            "account_number" : 4,
            "balance" : 27658,
            "firstname" : "Rodriquez",
            "lastname" : "Flores",
            "age" : 31,
            "gender" : "F",
            "address" : "986 Wyckoff Avenue",
            "employer" : "Tourmania",
            "email" : "rodriquezflores@tourmania.com",
            "city" : "Eastvale",
            "state" : "HI"
          },
          "sort" : [
            4
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "5",
          "_score" : null,
          "_source" : {
            "account_number" : 5,
            "balance" : 29342,
            "firstname" : "Leola",
            "lastname" : "Stewart",
            "age" : 30,
            "gender" : "F",
            "address" : "311 Elm Place",
            "employer" : "Diginetic",
            "email" : "leolastewart@diginetic.com",
            "city" : "Fairview",
            "state" : "NJ"
          },
          "sort" : [
            5
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "6",
          "_score" : null,
          "_source" : {
            "account_number" : 6,
            "balance" : 5686,
            "firstname" : "Hattie",
            "lastname" : "Bond",
            "age" : 36,
            "gender" : "M",
            "address" : "671 Bristol Street",
            "employer" : "Netagy",
            "email" : "hattiebond@netagy.com",
            "city" : "Dante",
            "state" : "TN"
          },
          "sort" : [
            6
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "7",
          "_score" : null,
          "_source" : {
            "account_number" : 7,
            "balance" : 39121,
            "firstname" : "Levy",
            "lastname" : "Richard",
            "age" : 22,
            "gender" : "M",
            "address" : "820 Logan Street",
            "employer" : "Teraprene",
            "email" : "levyrichard@teraprene.com",
            "city" : "Shrewsbury",
            "state" : "MO"
          },
          "sort" : [
            7
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "8",
          "_score" : null,
          "_source" : {
            "account_number" : 8,
            "balance" : 48868,
            "firstname" : "Jan",
            "lastname" : "Burns",
            "age" : 35,
            "gender" : "M",
            "address" : "699 Visitation Place",
            "employer" : "Glasstep",
            "email" : "janburns@glasstep.com",
            "city" : "Wakulla",
            "state" : "AZ"
          },
          "sort" : [
            8
          ]
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "9",
          "_score" : null,
          "_source" : {
            "account_number" : 9,
            "balance" : 24776,
            "firstname" : "Opal",
            "lastname" : "Meadows",
            "age" : 39,
            "gender" : "M",
            "address" : "963 Neptune Avenue",
            "employer" : "Cedward",
            "email" : "opalmeadows@cedward.com",
            "city" : "Olney",
            "state" : "OH"
          },
          "sort" : [
            9
          ]
        }
      ]
    }
  }
  
  ```

  响应结果解释: 

  - `took`: `es` 执行搜索的时间(毫秒)
  - `time_out`: 告诉我们搜索是否超时
  - `_shards`: 告诉我们多少个分片被搜索了,以及统计了成功/失败的搜索分片
  - `hits`: 搜索结果
  - `hits.total`: 搜索结果总条数
  - `hits.hits`: 实际的搜索结果(数组), 默认为前10 的文档 
  - `sort`: 结果的排序key(键), 没有则按照 `scort` 排序
  - `score` 和`max_score` : 相关性得分和最高得分(全文检索用)

  详细的字段信息，参照： [https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-search.html](https:_www.elastic.co_guide_en_elasticsearch_reference_current_getting-started-search)



### 4.3 `Query DSL`

#### 4.3.1 基本语法格式

`Elasticsearch`  提供了一个可以执行查询的`json` 风格的`DSL`, 这个被称为`Query DSL`, 该查询语句非常全面,一个查询语句的典型结构: 

```json
QUERY_NAME:{
   ARGUMENT:VALUE,
   ARGUMENT:VALUE,...
}
```

如果针对某个字段,那么它的结构如下: 

```json
{
  QUERY_NAME:{
     FIELD_NAME:{
       ARGUMENT:VALUE,
       ARGUMENT:VALUE,...
      }   
   }
}
```

```json
GET bank/_search
{
  "query": {
    "match_all": {}
  },
  "from": 0,
  "size": 5,
  "sort": [
    {
      "account_number": {
        "order": "desc"
      }
    }
  ]
}
```

`query` 定义了如何查询

- `match_all` : 查询类型(代表查询所有的数据), `es`中可以在`query` 中组合非常多的查询类型来完成复杂查询
- 除 了`query` 参数之后,我们也可以传递其他的参数以改变查询的结果,比如`sort`,`size`
- `form`+`szie` 限定, 完成分页功能
- `sort`排序,多字段排序,会在前序字段相等时后续字段内部排序,否则以前序为准



#### 4.3.2  返回部分字段

```json
GET bank/_search
{
  "query": {
    "match_all": {}
  },
  "from": 0,
  "size": 5,
  "sort": [
    {
      "account_number": {
        "order": "desc"
      }
    }
  ],
  "_source": ["balance","firstname"]
  
}
```

返回结果: 

```json
{
  "took" : 221,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1000,
      "relation" : "eq"
    },
    "max_score" : null,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "999",
        "_score" : null,
        "_source" : {
          "firstname" : "Dorothy",
          "balance" : 6087
        },
        "sort" : [
          999
        ]
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "998",
        "_score" : null,
        "_source" : {
          "firstname" : "Letha",
          "balance" : 16869
        },
        "sort" : [
          998
        ]
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "997",
        "_score" : null,
        "_source" : {
          "firstname" : "Combs",
          "balance" : 25311
        },
        "sort" : [
          997
        ]
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "996",
        "_score" : null,
        "_source" : {
          "firstname" : "Andrews",
          "balance" : 17541
        },
        "sort" : [
          996
        ]
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "995",
        "_score" : null,
        "_source" : {
          "firstname" : "Phelps",
          "balance" : 21153
        },
        "sort" : [
          995
        ]
      }
    ]
  }
}

```



#### 4.3.3 `match` 匹配查询

- 基本类型(非字符串), 精切控制

```json
GET bank/_search
{
  "query": {
    "match": {
      "account_number": "20"
    }
  }
}
```

`match` 返回 account_number=20的数据

返回结果; 

```json
{
  "took" : 774,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "20",
        "_score" : 1.0,
        "_source" : {
          "account_number" : 20,
          "balance" : 16418,
          "firstname" : "Elinor",
          "lastname" : "Ratliff",
          "age" : 36,
          "gender" : "M",
          "address" : "282 Kings Place",
          "employer" : "Scentric",
          "email" : "elinorratliff@scentric.com",
          "city" : "Ribera",
          "state" : "WA"
        }
      }
    ]
  }
}

```

- 字符串: 全文检索

  ```json
  GET bank/_search
  {
    "query": {
      "match": {
        "address": "kings"
      }
    }
  }
  ```

  全文检索,最后会按照评分进行排序,会对检索条件进行分词匹配

  查询结果:

  ```json
  {
    "took" : 790,
    "timed_out" : false,
    "_shards" : {
      "total" : 1,
      "successful" : 1,
      "skipped" : 0,
      "failed" : 0
    },
    "hits" : {
      "total" : {
        "value" : 2,
        "relation" : "eq"
      },
      "max_score" : 6.095661,
      "hits" : [
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "20",
          "_score" : 6.095661,
          "_source" : {
            "account_number" : 20,
            "balance" : 16418,
            "firstname" : "Elinor",
            "lastname" : "Ratliff",
            "age" : 36,
            "gender" : "M",
            "address" : "282 Kings Place",
            "employer" : "Scentric",
            "email" : "elinorratliff@scentric.com",
            "city" : "Ribera",
            "state" : "WA"
          }
        },
        {
          "_index" : "bank",
          "_type" : "account",
          "_id" : "722",
          "_score" : 6.095661,
          "_source" : {
            "account_number" : 722,
            "balance" : 27256,
            "firstname" : "Roberts",
            "lastname" : "Beasley",
            "age" : 34,
            "gender" : "F",
            "address" : "305 Kings Hwy",
            "employer" : "Quintity",
            "email" : "robertsbeasley@quintity.com",
            "city" : "Hayden",
            "state" : "PA"
          }
        }
      ]
    }
  }
  
  ```

#### 4.3.4 `match_phrase` 短句匹配

将需要匹配的值当成一整个单词(不分词) 进行检索

```json
GET bank/_search
{
  "query": {
    "match_phrase": {
      "address": "mill road"
    }
  }
}
```

查看 `address` 中包含 `mill road`的所有记录, 并且给出相关性得分.

返回结果: 

```json
{
  "took" : 6278,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 8.991257,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 8.991257,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      }
    ]
  }
}

```

`match`  和`match_phrase` 的区别,观察如下例子: 

```json
GET bank/_search
{
  "query": {
    "match_phrase": {
      "address": "990 Mill"
    }
  }
}
```

返回结果:

```json
{
  "took" : 48,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 10.919691,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 10.919691,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      }
    ]
  }
}

```

使用`match` 的`keyword`

```json
GET bank/_search
{
  "query": {
    "match": {
      "address.keyword": "990 Mill"
    }
  }
}
```

查看结果, 一条也没有匹配到

```json
{
  "took" : 34,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 0,
      "relation" : "eq"
    },
    "max_score" : null,
    "hits" : [ ]
  }
}

```

修改匹配条件为: `990 Mill Road`

```json
GET bank/_search
{
  "query": {
    "match": {
      "address.keyword": "990 Mill Road"
    }
  }
}
```

查询出来一条数据

```json
{
  "took" : 133,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 6.685111,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 6.685111,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      }
    ]
  }
}

```



文本字段的匹配,使用`keyword`, 匹配的条件就是要显示字段的全部值,要进行精确匹配,`match_phrase` 是做短语匹配的,只要是文本中包含匹配条件,就能匹配到. 



#### 4.3.5 `multi_math` 多字段匹配

```json
GET bank/_search
{
  "query": {
    "multi_match": {
      "query": "mill",
      "fields": [
        "state",
        "address"
      ]
    }
  }
}
```

`state` 或者`address` 中包含`mill`, 并且在查询的过程中 , 会对于查询条件进行分词. 

查询结果:

```json
{
  "took" : 121,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 4,
      "relation" : "eq"
    },
    "max_score" : 5.4598455,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 5.4598455,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "136",
        "_score" : 5.4598455,
        "_source" : {
          "account_number" : 136,
          "balance" : 45801,
          "firstname" : "Winnie",
          "lastname" : "Holland",
          "age" : 38,
          "gender" : "M",
          "address" : "198 Mill Lane",
          "employer" : "Neteria",
          "email" : "winnieholland@neteria.com",
          "city" : "Urie",
          "state" : "IL"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "345",
        "_score" : 5.4598455,
        "_source" : {
          "account_number" : 345,
          "balance" : 9812,
          "firstname" : "Parker",
          "lastname" : "Hines",
          "age" : 38,
          "gender" : "M",
          "address" : "715 Mill Avenue",
          "employer" : "Baluba",
          "email" : "parkerhines@baluba.com",
          "city" : "Blackgum",
          "state" : "KY"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "472",
        "_score" : 5.4598455,
        "_source" : {
          "account_number" : 472,
          "balance" : 25571,
          "firstname" : "Lee",
          "lastname" : "Long",
          "age" : 32,
          "gender" : "F",
          "address" : "288 Mill Street",
          "employer" : "Comverges",
          "email" : "leelong@comverges.com",
          "city" : "Movico",
          "state" : "MT"
        }
      }
    ]
  }
}

```



#### 4.3.6  `bool`  用来做复合查询

复合语句可以合并,任何其他查询语句,包括复合语句,这也就是意味着复合语句之间可以互相嵌套,可以表达非常复杂的逻辑. 

##### `must`:  必须达到`must` 所列举的所有条件

```json

GET bank/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "address": "mill"
          }
        },
        {
          "match": {
            "gender": "M"
          }
        }
      ]
    }
  }
}
```

 查看`address=mill` 和`gender=M`的数据

返回结果:

```json
{
  "took" : 21,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 6.1390967,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "136",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 136,
          "balance" : 45801,
          "firstname" : "Winnie",
          "lastname" : "Holland",
          "age" : 38,
          "gender" : "M",
          "address" : "198 Mill Lane",
          "employer" : "Neteria",
          "email" : "winnieholland@neteria.com",
          "city" : "Urie",
          "state" : "IL"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "345",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 345,
          "balance" : 9812,
          "firstname" : "Parker",
          "lastname" : "Hines",
          "age" : 38,
          "gender" : "M",
          "address" : "715 Mill Avenue",
          "employer" : "Baluba",
          "email" : "parkerhines@baluba.com",
          "city" : "Blackgum",
          "state" : "KY"
        }
      }
    ]
  }
}

```



#####  `must not` 必须不匹配`must not` 所列举的所有条件

查询`gender=M` 并且`address =mill`的,但是`age!=38`的数据

```json

GET bank/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "address": "mill"
          }
        },
        {
          "match": {
            "gender": "M"
          }
        }
      ],
      "must_not": [
        {
          "match": {
            "age": "30"
          }
        }
      ]
    }
  }
}
```

返回结果: 

```json
{
  "took" : 90,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 6.1390967,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "136",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 136,
          "balance" : 45801,
          "firstname" : "Winnie",
          "lastname" : "Holland",
          "age" : 38,
          "gender" : "M",
          "address" : "198 Mill Lane",
          "employer" : "Neteria",
          "email" : "winnieholland@neteria.com",
          "city" : "Urie",
          "state" : "IL"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "345",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 345,
          "balance" : 9812,
          "firstname" : "Parker",
          "lastname" : "Hines",
          "age" : 38,
          "gender" : "M",
          "address" : "715 Mill Avenue",
          "employer" : "Baluba",
          "email" : "parkerhines@baluba.com",
          "city" : "Blackgum",
          "state" : "KY"
        }
      }
    ]
  }
}

```



#####  `should`  应该达到`should`   列举的条件,如果达到就会增加相关文档的评分, 并不会改变查询的结果, 如果`query` 中只有`should`   且只有一种匹配规则,那么`should`  的条件就会被作为默认匹配条件去改变查询结果

例子: 匹配`lastName` 应该等于`Wallace`的数据

```json

GET bank/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "address": "mill"
          }
        },
        {
          "match": {
            "gender": "M"
          }
        }
      ],
      "must_not": [
        {
          "match": {
            "age": "30"
          }
        }
      ],
      "should": [
        {
          "match": {
            "lastname": "Wallace"
          }
        }
      ]
    }
  }
}

```



返回结果: 

```json
{
  "took" : 18145,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 12.824207,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 12.824207,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "136",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 136,
          "balance" : 45801,
          "firstname" : "Winnie",
          "lastname" : "Holland",
          "age" : 38,
          "gender" : "M",
          "address" : "198 Mill Lane",
          "employer" : "Neteria",
          "email" : "winnieholland@neteria.com",
          "city" : "Urie",
          "state" : "IL"
        }
      },
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "345",
        "_score" : 6.1390967,
        "_source" : {
          "account_number" : 345,
          "balance" : 9812,
          "firstname" : "Parker",
          "lastname" : "Hines",
          "age" : 38,
          "gender" : "M",
          "address" : "715 Mill Avenue",
          "employer" : "Baluba",
          "email" : "parkerhines@baluba.com",
          "city" : "Blackgum",
          "state" : "KY"
        }
      }
    ]
  }
}

```

能够看到相关度越高,得分也就越高

#### 4.3.7 `Filter`  结果过滤

并不是所有的查询都需要产生分数,特别是哪些仅用于`filter` 过滤的文档 . 为了不计算分数,`es` 会自动检查场景并且优化查询的执行

```json

GET bank/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "address": "mill"
          }
        }
      ],
      "filter": [
        {
          "range": {
            "balance": {
              "gte": 10000,
              "lte": 20000
            }
          }
        }
      ]
    }
  }
}

```

这里先查询所有匹配`address=mill`的文档,然后再根据`10000<=balance<=20000`进行结果查询, 查询结果:

```json
{
  "took" : 66,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 5.4598455,
    "hits" : [
      {
        "_index" : "bank",
        "_type" : "account",
        "_id" : "970",
        "_score" : 5.4598455,
        "_source" : {
          "account_number" : 970,
          "balance" : 19648,
          "firstname" : "Forbes",
          "lastname" : "Wallace",
          "age" : 28,
          "gender" : "M",
          "address" : "990 Mill Road",
          "employer" : "Pheast",
          "email" : "forbeswallace@pheast.com",
          "city" : "Lopezo",
          "state" : "AK"
        }
      }
    ]
  }
}

```

Each `must`, `should`, and `must_not` element in a Boolean query is referred to as a query clause. How well a document meets the criteria in each `must` or `should` clause contributes to the document’s _relevance score_. The higher the score, the better the document matches your search criteria. By default, Elasticsearch returns documents ranked by these relevance scores.
在boolean查询中，`must`, `should` 和`must_not` 元素都被称为查询子句 。 文档是否符合每个“must”或“should”子句中的标准，决定了文档的“相关性得分”。  得分越高，文档越符合您的搜索条件。  默认情况下，Elasticsearch返回根据这些相关性得分排序的文档。
The criteria in a `must_not` clause is treated as a _filter_. It affects whether or not the document is included in the results, but does not contribute to how documents are scored. You can also explicitly specify arbitrary filters to include or exclude documents based on structured data.

`“must_not”子句中的条件被视为“过滤器”。` 它影响文档是否包含在结果中，  但不影响文档的评分方式。  还可以显式地指定任意过滤器来包含或排除基于结构化数据的文档。

`filter` 在使用过程中,并不会计算相关性得分

#### 4.3.8 `term`

和`match` 一样,匹配某个属性的值,全文检索字段用`match`, 其他非`text`字段匹配用`term`

> Avoid using the `term` query for [`text`](https:_www.elastic.co_guide_en_elasticsearch_reference_7.6_text) fields.
> 避免对文本字段使用“term”查询
> By default, Elasticsearch changes the values of `text` fields as part of [analysis](). This can make finding exact matches for `text` field values difficult.
> 默认情况下，Elasticsearch作为[analysis]()的一部分更改' text '字段的值。这使得为“text”字段值寻找精确匹配变得困难。
> To search `text` field values, use the match.
> 要搜索“text”字段值，请使用匹配。
> [https://www.elastic.co/guide/en/elasticsearch/reference/7.6/query-dsl-term-query.html](

使用`term` 匹配查询

```json

GET bank/_search
{
  "query": {
    "term": {
      "address": {
        "value": "mill Road"
      }
    }
  }
}
```

返回结果: 

```json
{
  "took" : 26,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 0,
      "relation" : "eq"
    },
    "max_score" : null,
    "hits" : [ ]
  }
}

```

一条也没有匹配到, 更换为`match`后, 就可以匹配到32个

也就是说, 全文检索字段用`match`, 其他非`text` 字段匹配用`match`

#### 4.3.9 `Aggregation` 执行聚合

