# 第10节：商品模块 - 数据库设计

## 学习目标

- 掌握电商商品模块的数据库设计思路
- 理解无限级分类的实现方式
- 学会设计冗余字段提高查询性能
- 理解SKU（库存量单位）的设计原理

## 1. 商品模块功能概览

电商系统的商品模块是整个平台的核心，主要包括：

```
┌─────────────────────────────────────────────────────────────┐
│                      商品模块功能结构                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  商品分类   │  │  商品品牌   │  │  商品属性   │         │
│  │  管理      │  │  管理      │  │  管理      │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                │
│         └────────────────┴────────────────┘                │
│                          │                                  │
│                   ┌──────┴──────┐                          │
│                   │  商品信息   │                          │
│                   │  管理      │                          │
│                   └──────┬──────┘                          │
│                          │                                  │
│                   ┌──────┴──────┐                          │
│                   │  SKU库存   │                          │
│                   │  管理      │                          │
│                   └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## 2. 数据库表设计

### 2.1 商品分类表 (pms_product_category)

**设计目标**：支持无限级分类，如：手机数码 > 手机通讯 > 智能手机

```sql
CREATE TABLE `pms_product_category` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `parent_id` bigint(20) DEFAULT '0' COMMENT '上级分类的编号：0表示一级分类',
  `name` varchar(64) DEFAULT NULL COMMENT '分类名称',
  `level` int(1) DEFAULT '0' COMMENT '分类级别：0->1级；1->2级；2->3级',
  `product_count` int(11) DEFAULT '0' COMMENT '商品数量',
  `product_unit` varchar(64) DEFAULT NULL COMMENT '商品单位',
  `nav_status` int(1) DEFAULT '0' COMMENT '是否显示在导航栏：0->不显示；1->显示',
  `show_status` int(1) DEFAULT '0' COMMENT '显示状态：0->不显示；1->显示',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `icon` varchar(255) DEFAULT NULL COMMENT '图标',
  `keywords` varchar(255) DEFAULT NULL COMMENT '关键字',
  `description` text COMMENT '描述',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品分类表';
```

**核心设计要点**：

1. **parent_id 自关联**：实现无限级分类
   - parent_id = 0 表示一级分类
   - parent_id = 其他分类ID 表示子分类

2. **level 字段**：快速判断分类层级
   - 避免递归查询层级
   - 便于按层级筛选

3. **冗余字段 product_count**：
   - 缓存该分类下的商品数量
   - 避免频繁COUNT查询

### 2.2 商品品牌表 (pms_brand)

```sql
CREATE TABLE `pms_brand` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT '品牌名称',
  `first_letter` varchar(8) DEFAULT NULL COMMENT '首字母',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `factory_status` int(1) DEFAULT '0' COMMENT '是否为品牌制造商',
  `show_status` int(1) DEFAULT '0' COMMENT '是否显示',
  `product_count` int(11) DEFAULT '0' COMMENT '产品数量',
  `product_comment_count` int(11) DEFAULT '0' COMMENT '产品评论数量',
  `logo` varchar(255) DEFAULT NULL COMMENT '品牌logo',
  `big_pic` varchar(255) DEFAULT NULL COMMENT '专区大图',
  `brand_story` text COMMENT '品牌故事',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品品牌表';
```

### 2.3 分类与品牌关联表

**为什么需要关联表？**

```
场景：
- 手机分类下有：苹果、华为、小米等品牌
- 苹果品牌下有：手机、平板、笔记本等产品

结论：分类和品牌是多对多关系
```

```sql
CREATE TABLE `pms_product_category_brand_relation` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `brand_id` bigint(20) DEFAULT NULL COMMENT '品牌ID',
  `product_category_id` bigint(20) DEFAULT NULL COMMENT '分类ID',
  `brand_name` varchar(64) DEFAULT NULL COMMENT '品牌名称（冗余）',
  `product_category_name` varchar(64) DEFAULT NULL COMMENT '分类名称（冗余）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品分类与品牌关联表';
```

**冗余字段的作用**：
- 列表展示时无需关联查询品牌表和分类表
- 提高查询性能
- 代价：数据更新时需要同步维护

### 2.4 商品属性设计

**属性分类 vs 属性**：

```
pms_product_attribute_category（属性分类）
├── 手机
│   ├── 屏幕尺寸（属性）
│   ├── 运行内存（属性）
│   └── 存储容量（属性）
├── 电脑
│   ├── 处理器（属性）
│   ├── 内存容量（属性）
│   └── 显卡（属性）
```

```sql
-- 属性分类表
CREATE TABLE `pms_product_attribute_category` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT '类型名称（如：手机、电脑）',
  `attribute_count` int(11) DEFAULT '0' COMMENT '属性数量',
  `param_count` int(11) DEFAULT '0' COMMENT '参数数量',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品属性分类表';

-- 属性表
CREATE TABLE `pms_product_attribute` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `product_attribute_category_id` bigint(20) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL COMMENT '属性名称',
  `select_type` int(1) DEFAULT '0' COMMENT '选择类型：0->唯一；1->单选；2->多选',
  `input_type` int(1) DEFAULT '0' COMMENT '录入方式：0->手工录入；1->从列表选取',
  `input_list` varchar(255) DEFAULT NULL COMMENT '可选值列表，逗号分隔',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `filter_type` int(1) DEFAULT '0' COMMENT '分类筛选样式：1->普通；2->颜色',
  `type` int(1) DEFAULT '0' COMMENT '0->规格参数；1->销售属性',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品属性表';
```

**重要区分：规格参数 vs 销售属性**

| 类型 | type值 | 作用 | 示例 |
|:---|:---|:---|:---|
| 规格参数 | 0 | 描述商品特性 | 屏幕尺寸、处理器型号 |
| 销售属性 | 1 | 影响价格和库存 | 颜色、存储容量 |

### 2.5 SKU设计（核心难点）

**什么是SKU？**

```
SKU = Stock Keeping Unit（库存量单位）

示例：iPhone 15 Pro
├── SKU1: 黑色 + 256GB = ¥7999
├── SKU2: 白色 + 256GB = ¥7999
├── SKU3: 蓝色 + 512GB = ¥8999
└── SKU4: 黑色 + 1TB = ¥9999

同一商品，不同规格组合 = 不同SKU
```

```sql
CREATE TABLE `pms_sku_stock` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) DEFAULT NULL COMMENT '商品ID',
  `sku_code` varchar(64) NOT NULL COMMENT 'sku编码',
  `price` decimal(10,2) DEFAULT NULL COMMENT '价格',
  `stock` int(11) DEFAULT '0' COMMENT '库存',
  `low_stock` int(11) DEFAULT '0' COMMENT '预警库存',
  `pic` varchar(255) DEFAULT NULL COMMENT '展示图片',
  `sale` int(11) DEFAULT '0' COMMENT '销量',
  `promotion_price` decimal(10,2) DEFAULT NULL COMMENT '单品促销价格',
  `lock_stock` int(11) DEFAULT '0' COMMENT '锁定库存（下单未支付）',
  `sp_data` varchar(500) DEFAULT NULL COMMENT '商品销售属性，json格式',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品SKU库存表';
```

**sp_data JSON示例**：

```json
{
  "颜色": "黑色钛金属",
  "存储容量": "256GB"
}
```

**为什么用JSON存储销售属性？**
- 不同商品的属性组合不同
- JSON灵活，无需为每种商品创建不同表结构
- 查询时可以通过JSON函数解析

### 2.6 商品主表

```sql
CREATE TABLE `pms_product` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `brand_id` bigint(20) DEFAULT NULL COMMENT '品牌ID',
  `product_category_id` bigint(20) DEFAULT NULL COMMENT '分类ID',
  `product_attribute_category_id` bigint(20) DEFAULT NULL COMMENT '属性分类ID',
  `name` varchar(200) NOT NULL COMMENT '商品名称',
  `pic` varchar(255) DEFAULT NULL COMMENT '商品图片',
  `product_sn` varchar(64) NOT NULL COMMENT '货号',
  `delete_status` int(1) DEFAULT '0' COMMENT '删除状态：0->未删除；1->已删除',
  `publish_status` int(1) DEFAULT '0' COMMENT '上架状态：0->下架；1->上架',
  `new_status` int(1) DEFAULT '0' COMMENT '新品状态',
  `recommand_status` int(1) DEFAULT '0' COMMENT '推荐状态',
  `verify_status` int(1) DEFAULT '0' COMMENT '审核状态',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `sale` int(11) DEFAULT '0' COMMENT '销量',
  `price` decimal(10,2) DEFAULT NULL COMMENT '价格',
  `promotion_price` decimal(10,2) DEFAULT NULL COMMENT '促销价格',
  `stock` int(11) DEFAULT '0' COMMENT '库存',
  `low_stock` int(11) DEFAULT '0' COMMENT '库存预警值',
  `album_pics` varchar(255) DEFAULT NULL COMMENT '画册图片，逗号分隔',
  `detail_html` text COMMENT '产品详情网页内容',
  `brand_name` varchar(255) DEFAULT NULL COMMENT '品牌名称（冗余）',
  `product_category_name` varchar(255) DEFAULT NULL COMMENT '分类名称（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商品信息表';
```

## 3. 数据库关系图

```
┌────────────────────────────────────────────────────────────────┐
│                      实体关系图                                 │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   ┌──────────────┐         ┌──────────────┐                   │
│   │ pms_product  │         │ pms_product  │                   │
│   │   商品表     │◄───N:1──│   category   │                   │
│   │              │         │   分类表     │                   │
│   └──────┬───────┘         └──────┬───────┘                   │
│          │                        │                            │
│          │ N:1                    │ 1:N                        │
│          ▼                        ▼                            │
│   ┌──────────────┐         ┌──────────────┐                   │
│   │  pms_brand   │◄──N:M──►│ pms_product  │                   │
│   │   品牌表     │  关联表  │category_brand│                   │
│   └──────────────┘         │  _relation   │                   │
│                            └──────────────┘                   │
│                                                                │
│   ┌──────────────┐         ┌──────────────┐                   │
│   │ pms_product  │         │ pms_sku_     │                   │
│   │              │◄──1:N──►│   stock      │                   │
│   │              │         │  SKU库存表   │                   │
│   └──────────────┘         └──────────────┘                   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## 4. 索引设计建议

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

## 5. 设计亮点总结

| 设计 | 优点 | 代价 |
|:---|:---|:---|
| parent_id自关联 | 支持无限级分类 | 查询子树需要递归 |
| 冗余字段 | 提高列表查询性能 | 维护一致性成本 |
| 软删除 | 数据可恢复，有审计 | 增加delete_status条件 |
| SKU JSON属性 | 灵活支持任意规格组合 | JSON查询性能略低 |
| 属性分离 | 规格参数vs销售属性职责清晰 | 需要维护两套逻辑 |

## 6. 课后练习

1. **思考题**：如果要支持四级分类，当前设计是否需要修改？
2. **实践题**：为分类表添加一个`path`字段（如：`0,1,5,10`），存储从根到当前节点的路径，这样有什么好处？
3. **挑战题**：设计一个SQL查询，获取某个分类下的所有子分类ID（包括间接子分类）

## 参考文件

- 完整SQL：`mall-tiny/sql/phase2_product.sql`
- ER图文档：`docs/course/phase2/database-er-product.md`
