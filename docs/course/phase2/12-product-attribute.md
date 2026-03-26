# 第12节：商品属性管理

## 本节目标

- 理解商品属性分类的设计
- 掌握规格与参数的区别
- 实现属性分类、属性、属性值的完整CRUD
- 理解属性与商品的关联关系

## 12.1 属性管理概述

### 12.1.1 为什么需要属性管理

商品属性是电商平台的核心数据，它决定了：
- **商品筛选**：用户可以通过属性筛选商品
- **商品对比**：相同属性的商品可以对比
- **SKU生成**：销售属性组合生成SKU
- **搜索优化**：属性参与搜索排序

### 12.1.2 规格 vs 参数

| 维度 | 规格（Specification） | 参数（Parameter） |
|:---|:---|:---|
| **用途** | 生成SKU，影响价格库存 | 描述商品特性，展示用 |
| **示例** | 颜色、尺码、内存 | 屏幕尺寸、电池容量 |
| **是否必填** | 是 | 否 |
| **用户选择** | 购买时必须选择 | 仅展示 |
| **影响价格** | 是 | 否 |

**示例**：iPhone 15 Pro
- **规格**：颜色（黑色/白色/蓝色）、存储（128GB/256GB/512GB）
- **参数**：屏幕尺寸6.1英寸、重量187g、A17 Pro芯片

## 12.2 数据库设计

### 12.2.1 属性相关表

```sql
-- 属性分类表
CREATE TABLE pms_product_attribute_category (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL COMMENT '属性分类名称',
    attribute_count INT DEFAULT 0 COMMENT '属性数量',
    param_count INT DEFAULT 0 COMMENT '参数数量',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 属性表
CREATE TABLE pms_product_attribute (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_attribute_category_id BIGINT COMMENT '属性分类ID',
    name VARCHAR(64) NOT NULL COMMENT '属性名称',
    select_type INT DEFAULT 0 COMMENT '选择类型：0->唯一；1->单选；2->多选',
    input_type INT DEFAULT 0 COMMENT '录入方式：0->手工录入；1->从列表选取',
    input_list VARCHAR(255) COMMENT '可选值列表，逗号分隔',
    sort INT DEFAULT 0 COMMENT '排序',
    filter_type INT DEFAULT 0 COMMENT '筛选样式：1->普通；2->颜色',
    search_type INT DEFAULT 0 COMMENT '检索类型：0->不检索；1->关键字；2->范围',
    related_status INT DEFAULT 0 COMMENT '是否关联：0->不关联；1->关联',
    hand_add_status INT DEFAULT 0 COMMENT '是否支持手动新增：0->不支持；1->支持',
    type INT DEFAULT 0 COMMENT '类型：0->规格；1->参数',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 属性值表
CREATE TABLE pms_product_attribute_value (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT COMMENT '商品ID',
    product_attribute_id BIGINT COMMENT '属性ID',
    value VARCHAR(255) COMMENT '属性值，规格多值逗号分隔'
);
```

### 12.2.2 表关系说明

```
pms_product_attribute_category (属性分类)
    ├── 1:N → pms_product_attribute (属性)
    │           └── 通过 N:M 关联 pms_product
    │
    └── pms_product_attribute_value (属性值)
                └── 关联具体商品和属性
```

## 12.3 核心代码实现

### 12.3.1 属性分类实体

```java
@Data
@TableName("pms_product_attribute_category")
public class PmsProductAttributeCategory {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    private String name;
    private Integer attributeCount;  // 规格数量
    private Integer paramCount;      // 参数数量
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
```

### 12.3.2 属性实体

```java
@Data
@TableName("pms_product_attribute")
public class PmsProductAttribute {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    private Long productAttributeCategoryId;
    private String name;
    
    // 选择类型：0->唯一；1->单选；2->多选
    private Integer selectType;
    
    // 录入方式：0->手工录入；1->从列表选取
    private Integer inputType;
    
    // 可选值列表，逗号分隔
    private String inputList;
    
    // 检索类型：0->不检索；1->关键字；2->范围
    private Integer searchType;
    
    // 类型：0->规格；1->参数
    private Integer type;
    
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
```

### 12.3.3 属性值实体

```java
@Data
@TableName("pms_product_attribute_value")
public class PmsProductAttributeValue {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    private Long productId;           // 商品ID
    private Long productAttributeId;  // 属性ID
    private String value;             // 属性值
}
```

## 12.4 关键业务逻辑

### 12.4.1 属性分类统计

```java
@Select("SELECT pac.*, " +
        "(SELECT COUNT(*) FROM pms_product_attribute pa " +
        " WHERE pa.product_attribute_category_id = pac.id AND pa.type = 0) as attribute_count, " +
        "(SELECT COUNT(*) FROM pms_product_attribute pa " +
        " WHERE pa.product_attribute_category_id = pac.id AND pa.type = 1) as param_count " +
        "FROM pms_product_attribute_category pac")
List<Map<String, Object>> selectListWithAttrCount();
```

### 12.4.2 根据分类获取属性

```java
public List<PmsProductAttribute> listByCategoryIdAndType(Long categoryId, Integer type) {
    return baseMapper.selectByCategoryIdAndType(categoryId, type);
}
```

### 12.4.3 保存商品属性值

```java
@Transactional
public boolean saveBatch(Long productId, List<PmsProductAttributeValue> valueList) {
    // 1. 删除旧的属性值
    remove(new LambdaQueryWrapper<PmsProductAttributeValue>()
            .eq(PmsProductAttributeValue::getProductId, productId));
    
    // 2. 保存新的属性值
    if (valueList != null && !valueList.isEmpty()) {
        for (PmsProductAttributeValue value : valueList) {
            value.setProductId(productId);
        }
        return saveBatch(valueList);
    }
    return true;
}
```

## 12.5 API接口

### 12.5.1 属性分类接口

| 接口 | 方法 | 说明 |
|:---|:---|:---|
| `/productAttribute/category/list` | GET | 分页查询属性分类 |
| `/productAttribute/category/list/withAttr` | GET | 获取分类及属性数量 |
| `/productAttribute/category/create` | POST | 创建属性分类 |
| `/productAttribute/category/update/{id}` | POST | 修改属性分类 |
| `/productAttribute/category/delete/{id}` | GET | 删除属性分类 |

### 12.5.2 属性接口

| 接口 | 方法 | 说明 |
|:---|:---|:---|
| `/productAttribute/list/{categoryId}` | GET | 分页查询属性列表 |
| `/productAttribute/attrList/{categoryId}` | GET | 根据分类和类型获取属性 |
| `/productAttribute/create` | POST | 创建属性 |
| `/productAttribute/update/{id}` | POST | 修改属性 |
| `/productAttribute/{id}` | GET | 查询单个属性 |
| `/productAttribute/delete` | POST | 批量删除属性 |

## 12.6 实战练习

### 练习1：创建手机属性分类

1. 创建属性分类"手机属性"
2. 添加规格：颜色（单选）、存储容量（单选）、网络类型（单选）
3. 添加参数：屏幕尺寸、电池容量、处理器、后置摄像头

### 练习2：为iPhone添加属性值

```json
{
  "productId": 1,
  "attributeValues": [
    {"productAttributeId": 1, "value": "黑色钛金属,白色钛金属,蓝色钛金属"},
    {"productAttributeId": 2, "value": "128GB,256GB,512GB,1TB"},
    {"productAttributeId": 5, "value": "6.1英寸"},
    {"productAttributeId": 6, "value": "3274mAh"}
  ]
}
```

## 12.7 常见问题

### Q1: 规格和参数如何区分？

**答**：
- **规格**：影响SKU生成和价格，用户购买时必须选择
- **参数**：仅用于展示商品特性，不参与SKU生成

### Q2: 属性值为什么用逗号分隔？

**答**：对于多选规格（如颜色有多个选项），一个属性可能对应多个值，用逗号分隔便于存储和解析。

### Q3: 如何根据规格生成SKU？

**答**：使用笛卡尔积算法，将所有规格的可选值组合，生成所有可能的SKU组合。详见第14节。

## 12.8 本节小结

本节我们学习了：
1. **属性分类**：组织管理属性的容器
2. **规格**：影响SKU和价格的销售属性
3. **参数**：描述商品特性的展示属性
4. **属性值**：具体商品与属性的关联数据

下节预告：**第13节：商品发布功能实现** - 完整的商品发布流程，包括基本信息、图片、属性、SKU的保存。

---

**课后作业**：
1. 为"电脑整机"分类创建属性分类和属性
2. 实现属性分类的CRUD接口测试
3. 思考：如何实现属性的级联删除？
