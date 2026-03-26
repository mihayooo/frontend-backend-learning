# 第七节：代码生成器使用

> **学习目标**：掌握 MyBatis-Plus Generator 的使用，自动生成 CRUD 代码

---

## 7.1 本节概述

MyBatis-Plus Generator 是 MyBatis-Plus 的代码生成器，可以根据数据库表结构自动生成：
- Entity（实体类）
- Mapper（数据访问层）
- Service（业务层）
- Controller（控制层）
- Mapper XML 文件

本节将学习如何使用代码生成器快速开发。

**预计学习时间**：20 分钟

---

## 7.2 代码生成器位置

mall-tiny 已集成代码生成器，位于：
```
src/main/java/com/macro/mall/tiny/generator/MyBatisPlusGenerator.java
```

---

## 7.3 使用步骤

### 7.3.1 创建业务表

假设我们要创建商品品牌表 `pms_brand`：

```sql
CREATE TABLE `pms_brand` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT '品牌名称',
  `logo` varchar(255) DEFAULT NULL COMMENT '品牌logo',
  `description` varchar(255) DEFAULT NULL COMMENT '品牌描述',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `show_status` int(1) DEFAULT '1' COMMENT '显示状态：0->不显示；1->显示',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品品牌表';
```

### 7.3.2 运行代码生成器

1. 打开 `MyBatisPlusGenerator.java`
2. 右键运行 `main` 方法
3. 按提示输入：
   - 模块名：`pms`
   - 表名：`pms_brand`（或 `pms_*` 生成整个模块）

### 7.3.3 查看生成的代码

生成的代码位于：
```
src/main/java/com/macro/mall/tiny/modules/pms/
├── controller/PmsBrandController.java
├── dto/
├── mapper/PmsBrandMapper.java
├── model/PmsBrand.java
└── service/
    ├── PmsBrandService.java
    └── impl/PmsBrandServiceImpl.java
```

---

## 7.4 生成代码说明

### 7.4.1 Entity（实体类）

```java
@Data
@EqualsAndHashCode(callSuper = false)
@TableName("pms_brand")
public class PmsBrand implements Serializable {
    private Long id;
    private String name;
    private String logo;
    private String description;
    private Integer sort;
    private Integer showStatus;
    private Date createTime;
}
```

### 7.4.2 Controller（控制器）

```java
@RestController
@Api(tags = "PmsBrandController", description = "商品品牌管理")
@RequestMapping("/brand")
public class PmsBrandController {
    
    @Autowired
    private PmsBrandService brandService;
    
    @ApiOperation("添加品牌")
    @RequestMapping(value = "/create", method = RequestMethod.POST)
    public CommonResult create(@RequestBody PmsBrand brand) {
        boolean success = brandService.save(brand);
        return success ? CommonResult.success(null) : CommonResult.failed();
    }
    
    // ... 其他方法
}
```

---

## 7.5 本节小结

✅ 了解了 MyBatis-Plus Generator 的功能  
✅ 学会了使用代码生成器自动生成代码  
✅ 理解了生成代码的结构

---

## 7.6 下节预告

**第八节：Spring Security 认证流程解析**

深入了解 mall-tiny 的权限认证机制。

---

## 参考资源

- [MyBatis-Plus Generator 文档](https://baomidou.com/pages/779a6e/)
