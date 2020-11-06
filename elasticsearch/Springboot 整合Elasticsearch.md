#  Springboot 整合Elasticsearch



##   1. `elasticsearch-Rest-Client`

### `elasticserch` 客户端详解

1. `9300`  `tcp`

    `spring-data-elasticsearch:transport-api.jar`

   - `springboot` 版本不同,`ransport-api.jar` 不同,不能适配`es` 版本
   - `7.x` 已经不建议使用了,8以后就要废弃了

2. `9200` `HTTP`

   - `jestClient`:非官方,更新慢

   - `RestTemplate`: 模拟`HTTP`请求, `ES` 很多操作都需要自己封装

   - `HttpClient`: 同上

   - `Elasticsearch-Rest-Client`: 官方`RestClient`，封装了`ES`操作, `API`层次分明,上手简单

     最终选择Elasticsearch-Rest-Client（elasticsearch-rest-high-level-client）；
     [https://www.elastic.co/guide/en/elasticsearch/client/java-rest/current/java-rest-high.html](https:_www.elastic.co_guide_en_elasticsearch_client_java-rest_current_java-rest-high)



## 2. `SpringBoot` 整合`ElasticSearch`

###  2.1 导入依赖

这里的版本要和所安装的`es`的版本匹配

```xml
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>elasticsearch-rest-high-level-client</artifactId>
    <version>7.6.2</version>
</dependency>
```

修改 `elasticsearch`的版本, `<spring-boot-dependencies>` 中所依赖的版本为6.x,需要将版本改为安装的版本



### 2.2 编写测试类

#### 2.2.1 测试保存数据

[https://www.elastic.co/guide/en/elasticsearch/client/java-rest/current/java-rest-high-document-index.html](https:_www.elastic.co_guide_en_elasticsearch_client_java-rest_current_java-rest-high-document-index)



