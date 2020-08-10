# Spring Cloud Alibaba之naocs注册中心

## 1. 确定版本

我们先要确定下载的`nacos`的版本号, 

`spring cloud alibaba`的官网表明了各个组件的版本依赖关系和与`Spring cloud`和`Spring Boot`的依赖关系

[https://github.com/alibaba/spring-cloud-alibaba/wiki/%E7%89%88%E6%9C%AC%E8%AF%B4%E6%98%8E#%E7%BB%84%E4%BB%B6%E7%89%88%E6%9C%AC%E5%85%B3%E7%B3%BB](https://github.com/alibaba/spring-cloud-alibaba/wiki/版本说明#组件版本关系)



## 组件版本关系

| Spring Cloud Alibaba Version                    | Sentinel Version | Nacos Version | RocketMQ Version | Dubbo Version | Seata Version |
| ----------------------------------------------- | ---------------- | ------------- | ---------------- | ------------- | ------------- |
| 2.2.1.RELEASE or 2.1.2.RELEASE or 2.0.2.RELEASE | 1.7.1            | 1.2.1         | 4.4.0            | 2.7.6         | 1.2.0         |
| 2.2.0.RELEASE                                   | 1.7.1            | 1.1.4         | 4.4.0            | 2.7.4.1       | 1.0.0         |
| 2.1.1.RELEASE or 2.0.1.RELEASE or 1.5.1.RELEASE | 1.7.0            | 1.1.4         | 4.4.0            | 2.7.3         | 0.9.0         |
| 2.1.0.RELEASE or 2.0.0.RELEASE or 1.5.0.RELEASE | 1.6.3            | 1.1.1         | 4.4.0            | 2.7.3         | 0.7.1         |

## 毕业版本依赖关系(推荐使用)

| Spring Cloud Version        | Spring Cloud Alibaba Version      | Spring Boot Version |
| --------------------------- | --------------------------------- | ------------------- |
| Spring Cloud Hoxton.SR3     | 2.2.1.RELEASE                     | 2.2.5.RELEASE       |
| Spring Cloud Hoxton.RELEASE | 2.2.0.RELEASE                     | 2.2.X.RELEASE       |
| Spring Cloud Greenwich      | 2.1.2.RELEASE                     | 2.1.X.RELEASE       |
| Spring Cloud Finchley       | 2.0.2.RELEASE                     | 2.0.X.RELEASE       |
| Spring Cloud Edgware        | 1.5.1.RELEASE(停止维护，建议升级) | 1.5.X.RELEASE       |



## 2. 下载

`https://github.com/alibaba/nacos/releases` 去挑选合适的版本下载,下载. 

如果只是为了使用的话, 我们可以下载编译好的版本

![image-20200810161139368](Untitled.assets/image-20200810161139368.png)