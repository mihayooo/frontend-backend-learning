# 第二阶段：商品模块数据库ER图

## 实体关系概览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           商品模块数据库关系图                                │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  pms_product     │         │ pms_product_     │         │  pms_brand       │
│  商品信息表       │◄───────►│ category         │◄───────►│  品牌表          │
│                  │    N:1  │ 商品分类表        │   N:M   │                  │
└────────┬─────────┘         └────────┬─────────┘         └──────────────────┘
         │                            │
         │ N:1                        │ 1:N
         ▼                            ▼
┌──────────────────┐         ┌──────────────────┐
│ pms_product_     │         │ pms_product_     │
│ attribute_value  │         │ category_brand_  │
│ 商品属性值表      │         │ relation         │
│                  │         │ 分类品牌关联表    │
└────────┬─────────┘         └──────────────────┘
         │ N:1
         ▼
┌──────────────────┐         ┌──────────────────┐
│ pms_product_     │◄───────►│ pms_product_     │
│ attribute        │   N:1   │ attribute_       │
│ 商品属性表        │         │ category         │
│                  │         │ 属性分类表        │
└──────────────────┘         └──────────────────┘

┌──────────────────┐
│  pms_sku_stock   │
│  SKU库存表        │
│                  │
└──────────────────┘
         ▲
         │ N:1
         │
┌────────┴─────────┐
│  pms_product     │
│  商品信息表       │
└──────────────────┘
```

## 详细表结构说明

### 1. 商品分类表 (pms_product_category)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键，自增 |
| parent_id | bigint | 上级分类ID，0表示一级分类 |
| name | varchar(64) | 分类名称 |
| level | int | 分类级别：0->1级；1->2级；2->3级 |
| product_count | int | 该分类下的商品数量 |
| product_unit | varchar(64) | 商品单位 |
| nav_status | int | 是否显示在导航栏 |
| show_status | int | 显示状态 |
| sort | int | 排序 |
| icon | varchar(255) | 分类图标 |
| keywords | varchar(255) | 关键字 |
| description | text | 描述 |

**设计要点**：
- 使用 `parent_id` 实现无限级分类（树形结构）
- `level` 字段用于快速判断分类层级
- `product_count` 冗余字段，避免频繁统计

### 2. 商品品牌表 (pms_brand)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键，自增 |
| name | varchar(64) | 品牌名称 |
| first_letter | varchar(8) | 首字母（用于字母索引） |
| sort | int | 排序 |
| factory_status | int | 是否为品牌制造商 |
| show_status | int | 是否显示 |
| product_count | int | 产品数量 |
| product_comment_count | int | 产品评论数量 |
| logo | varchar(255) | 品牌logo URL |
| big_pic | varchar(255) | 专区大图 |
| brand_story | text | 品牌故事 |

### 3. 商品分类与品牌关联表 (pms_product_category_brand_relation)

**设计原因**：
- 一个分类下可以有多个品牌（如：手机分类下有苹果、华为、小米）
- 一个品牌可以属于多个分类（如：小米品牌有手机、电视、笔记本）
- 因此是多对多关系，需要关联表

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| brand_id | bigint | 品牌ID |
| product_category_id | bigint | 分类ID |
| brand_name | varchar(64) | 品牌名称（冗余） |
| product_category_name | varchar(64) | 分类名称（冗余） |

### 4. 商品属性分类表 (pms_product_attribute_category)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| name | varchar(64) | 类型名称（如：手机、电脑） |
| attribute_count | int | 属性数量 |
| param_count | int | 参数数量 |

**说明**：
- 不同类型的商品有不同的属性集合
- 例如：手机有"屏幕尺寸"、"运行内存"等属性
- 电脑有"处理器"、"显卡"等属性

### 5. 商品属性表 (pms_product_attribute)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| product_attribute_category_id | bigint | 属性分类ID |
| name | varchar(64) | 属性名称 |
| select_type | int | 选择类型：0->唯一；1->单选；2->多选 |
| input_type | int | 录入方式：0->手工录入；1->从列表选取 |
| input_list | varchar(255) | 可选值列表，逗号分隔 |
| sort | int | 排序 |
| filter_type | int | 筛选样式：1->普通；2->颜色 |
| search_type | int | 检索类型 |
| related_status | int | 相同属性产品是否关联 |
| hand_add_status | int | 是否支持手动新增 |
| **type** | **int** | **重要：0->规格参数；1->销售属性** |

**关键区分**：
- **规格参数 (type=0)**：描述商品特性，如屏幕尺寸、处理器型号
- **销售属性 (type=1)**：影响价格和库存，如颜色、存储容量（用于生成SKU）

### 6. 商品信息表 (pms_product)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| brand_id | bigint | 品牌ID |
| product_category_id | bigint | 分类ID |
| product_attribute_category_id | bigint | 属性分类ID |
| name | varchar(200) | 商品名称 |
| pic | varchar(255) | 商品主图 |
| product_sn | varchar(64) | 货号（唯一） |
| delete_status | int | 删除状态（软删除） |
| publish_status | int | 上架状态 |
| new_status | int | 新品状态 |
| recommand_status | int | 推荐状态 |
| verify_status | int | 审核状态 |
| price | decimal(10,2) | 价格 |
| promotion_price | decimal(10,2) | 促销价格 |
| stock | int | 库存（总库存） |
| album_pics | varchar(255) | 画册图片，逗号分隔 |
| detail_html | text | 详情HTML内容 |
| **brand_name** | **varchar** | **品牌名称（冗余）** |
| **product_category_name** | **varchar** | **分类名称（冗余）** |

**冗余字段设计**：
- `brand_name` 和 `product_category_name` 是冗余字段
- 目的：避免列表查询时的多表关联，提高性能
- 代价：数据一致性维护成本增加

### 7. SKU库存表 (pms_sku_stock)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| product_id | bigint | 商品ID |
| sku_code | varchar(64) | SKU编码（唯一） |
| price | decimal(10,2) | SKU价格 |
| stock | int | 库存 |
| low_stock | int | 预警库存 |
| pic | varchar(255) | SKU图片 |
| sale | int | 销量 |
| promotion_price | decimal(10,2) | 促销价 |
| lock_stock | int | 锁定库存（下单未支付） |
| **sp_data** | **varchar(500)** | **销售属性JSON** |

**sp_data 示例**：
```json
{
  "颜色": "黑色钛金属",
  "存储容量": "256GB"
}
```

### 8. 商品属性值表 (pms_product_attribute_value)

| 字段名 | 类型 | 说明 |
|:---|:---|:---|
| id | bigint | 主键 |
| product_id | bigint | 商品ID |
| product_attribute_id | bigint | 属性ID |
| value | varchar(255) | 属性值 |

**说明**：
- 关联商品和属性，存储具体的属性值
- 规格参数：单值（如屏幕尺寸：6.1英寸）
- 销售属性：多值逗号分隔（如颜色：黑色,白色,金色）

## 核心关系说明

### 1. 商品与分类（N:1）
```
一个商品属于一个分类
一个分类下有多个商品
```

### 2. 商品与品牌（N:1）
```
一个商品属于一个品牌
一个品牌下有多个商品
```

### 3. 分类与品牌（N:M）
```
一个分类可以有多个品牌
一个品牌可以属于多个分类
通过 pms_product_category_brand_relation 关联
```

### 4. 商品与SKU（1:N）
```
一个商品有多个SKU（不同规格组合）
一个SKU属于一个商品
例如：iPhone 15 Pro 有 黑色256GB、白色256GB、蓝色512GB 等多个SKU
```

### 5. 商品与属性（N:M）
```
一个商品有多个属性
一个属性可以被多个商品使用
通过 pms_product_attribute_value 关联
```

## 设计亮点

1. **无限级分类**：使用 parent_id 自关联，支持任意层级
2. **冗余字段**：适当冗余（品牌名、分类名）提高查询性能
3. **软删除**：使用 delete_status 代替物理删除
4. **SKU设计**：灵活的销售属性JSON，支持任意规格组合
5. **属性分离**：规格参数 vs 销售属性，职责清晰

## 索引建议

```sql
-- 商品表常用查询索引
CREATE INDEX idx_product_category ON pms_product(product_category_id);
CREATE INDEX idx_product_brand ON pms_product(brand_id);
CREATE INDEX idx_product_publish ON pms_product(publish_status);
CREATE INDEX idx_product_name ON pms_product(name);

-- SKU表索引
CREATE INDEX idx_sku_product ON pms_sku_stock(product_id);
CREATE UNIQUE INDEX idx_sku_code ON pms_sku_stock(sku_code);

-- 分类表索引
CREATE INDEX idx_category_parent ON pms_product_category(parent_id);
CREATE INDEX idx_category_level ON pms_product_category(level);
```
