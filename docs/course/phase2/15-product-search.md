# 第15节：商品搜索与筛选

## 本节目标

- 实现商品多条件搜索
- 掌握分页查询优化技巧
- 实现按属性筛选商品
- 理解搜索排序策略

## 15.1 搜索需求分析

### 15.1.1 用户搜索场景

| 场景 | 示例 | 技术需求 |
|:---|:---|:---|
| **关键词搜索** | "iPhone" | 模糊匹配、分词 |
| **分类筛选** | 手机分类下的商品 | 精确匹配 |
| **品牌筛选** | 苹果品牌 | 精确匹配 |
| **价格区间** | 1000-5000元 | 范围查询 |
| **属性筛选** | 颜色=黑色, 内存=128GB | 多值匹配 |
| **排序** | 价格从低到高 | 排序算法 |

### 15.1.2 搜索接口设计

```java
@GetMapping("/search")
public CommonResult<CommonPage<PmsProduct>> search(
        @RequestParam(required = false) String keyword,      // 关键词
        @RequestParam(required = false) Long categoryId,     // 分类ID
        @RequestParam(required = false) Long brandId,        // 品牌ID
        @RequestParam(required = false) BigDecimal minPrice, // 最低价格
        @RequestParam(required = false) BigDecimal maxPrice, // 最高价格
        @RequestParam(required = false) String sort,         // 排序方式
        @RequestParam(defaultValue = "1") Integer pageNum,   // 页码
        @RequestParam(defaultValue = "10") Integer pageSize  // 每页数量
)
```

## 15.2 数据库搜索实现

### 15.2.1 动态SQL构建

```java
@Service
public class PmsProductSearchService {

    @Autowired
    private PmsProductMapper productMapper;

    /**
     * 商品搜索
     */
    public Page<PmsProduct> search(ProductSearchParam param) {
        Page<PmsProduct> page = new Page<>(param.getPageNum(), param.getPageSize());
        
        LambdaQueryWrapper<PmsProduct> wrapper = new LambdaQueryWrapper<>();
        
        // 1. 关键词搜索（名称、副标题、关键词）
        if (StrUtil.isNotBlank(param.getKeyword())) {
            wrapper.and(w -> w.like(PmsProduct::getName, param.getKeyword())
                    .or()
                    .like(PmsProduct::getSubTitle, param.getKeyword())
                    .or()
                    .like(PmsProduct::getKeywords, param.getKeyword()));
        }
        
        // 2. 分类筛选
        if (param.getCategoryId() != null) {
            wrapper.eq(PmsProduct::getProductCategoryId, param.getCategoryId());
        }
        
        // 3. 品牌筛选
        if (param.getBrandId() != null) {
            wrapper.eq(PmsProduct::getBrandId, param.getBrandId());
        }
        
        // 4. 价格区间
        if (param.getMinPrice() != null) {
            wrapper.ge(PmsProduct::getPrice, param.getMinPrice());
        }
        if (param.getMaxPrice() != null) {
            wrapper.le(PmsProduct::getPrice, param.getMaxPrice());
        }
        
        // 5. 只查询上架商品
        wrapper.eq(PmsProduct::getPublishStatus, 1);
        wrapper.eq(PmsProduct::getDeleteStatus, 0);
        
        // 6. 排序
        applySort(wrapper, param.getSort());
        
        return productMapper.selectPage(page, wrapper);
    }
    
    private void applySort(LambdaQueryWrapper<PmsProduct> wrapper, String sort) {
        if (StrUtil.isBlank(sort)) {
            // 默认按创建时间倒序
            wrapper.orderByDesc(PmsProduct::getCreateTime);
            return;
        }
        
        switch (sort) {
            case "price_asc":
                wrapper.orderByAsc(PmsProduct::getPrice);
                break;
            case "price_desc":
                wrapper.orderByDesc(PmsProduct::getPrice);
                break;
            case "sale_desc":
                wrapper.orderByDesc(PmsProduct::getSale);
                break;
            case "new":
                wrapper.orderByDesc(PmsProduct::getCreateTime);
                break;
            default:
                wrapper.orderByDesc(PmsProduct::getCreateTime);
        }
    }
}
```

### 15.2.2 搜索参数DTO

```java
@Data
public class ProductSearchParam {
    private String keyword;       // 关键词
    private Long categoryId;      // 分类ID
    private Long brandId;         // 品牌ID
    private BigDecimal minPrice;  // 最低价格
    private BigDecimal maxPrice;  // 最高价格
    private String sort;          // 排序方式
    private Integer pageNum = 1;  // 页码
    private Integer pageSize = 10;// 每页数量
}
```

## 15.3 属性筛选实现

### 15.3.1 属性筛选表设计

```sql
-- 商品分类与属性关系表
CREATE TABLE pms_product_category_attribute_relation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_category_id BIGINT COMMENT '商品分类ID',
    product_attribute_category_id BIGINT COMMENT '属性分类ID'
);
```

### 15.3.2 属性筛选逻辑

```java
/**
 * 根据属性筛选商品
 */
public List<Long> searchByAttributes(Map<Long, String> attributeMap) {
    if (attributeMap == null || attributeMap.isEmpty()) {
        return Collections.emptyList();
    }
    
    // 构建子查询
    StringBuilder sql = new StringBuilder();
    sql.append("SELECT DISTINCT product_id FROM pms_product_attribute_value WHERE ");
    
    List<String> conditions = new ArrayList<>();
    for (Map.Entry<Long, String> entry : attributeMap.entrySet()) {
        conditions.add("(product_attribute_id = " + entry.getKey() + 
                      " AND value = '" + entry.getValue() + "')");
    }
    
    sql.append(String.join(" OR ", conditions));
    
    // 执行查询
    return baseMapper.selectProductIdsByAttributes(sql.toString());
}
```

### 15.3.3 组合搜索

```java
/**
 * 综合搜索（包含属性筛选）
 */
public Page<PmsProduct> complexSearch(ProductComplexSearchParam param) {
    // 1. 先根据属性筛选出商品ID列表
    List<Long> productIds = Collections.emptyList();
    if (param.getAttributes() != null && !param.getAttributes().isEmpty()) {
        productIds = searchByAttributes(param.getAttributes());
        if (productIds.isEmpty()) {
            // 没有匹配的商品，返回空结果
            return new Page<>();
        }
    }
    
    // 2. 构建基础查询条件
    Page<PmsProduct> page = new Page<>(param.getPageNum(), param.getPageSize());
    LambdaQueryWrapper<PmsProduct> wrapper = buildWrapper(param);
    
    // 3. 添加属性筛选条件
    if (!productIds.isEmpty()) {
        wrapper.in(PmsProduct::getId, productIds);
    }
    
    return productMapper.selectPage(page, wrapper);
}
```

## 15.4 搜索优化

### 15.4.1 数据库索引优化

```sql
-- 商品表索引
CREATE INDEX idx_product_name ON pms_product(name);           -- 名称搜索
CREATE INDEX idx_product_category ON pms_product(product_category_id);  -- 分类筛选
CREATE INDEX idx_product_brand ON pms_product(brand_id);      -- 品牌筛选
CREATE INDEX idx_product_price ON pms_product(price);         -- 价格排序
CREATE INDEX idx_product_publish ON pms_product(publish_status, delete_status); -- 状态筛选

-- 复合索引（最左前缀原则）
CREATE INDEX idx_product_search ON pms_product(
    publish_status, 
    delete_status, 
    product_category_id, 
    brand_id
);
```

### 15.4.2 分页优化

```java
/**
 * 深度分页优化
 */
public List<PmsProduct> searchWithOffsetLimit(int offset, int limit) {
    // 方式1：使用子查询优化（适用于大数据量）
    // SELECT * FROM pms_product 
    // WHERE id >= (SELECT id FROM pms_product ORDER BY id LIMIT 100000, 1)
    // LIMIT 10
    
    // 方式2：使用覆盖索引
    // 先查询ID列表，再关联查询完整数据
    List<Long> ids = productMapper.selectIdsWithCondition(offset, limit);
    if (ids.isEmpty()) {
        return Collections.emptyList();
    }
    return productMapper.selectBatchIds(ids);
}
```

### 15.4.3 缓存优化

```java
@Service
public class ProductSearchCacheService {
    
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    private static final String SEARCH_CACHE_KEY = "product:search:";
    private static final long CACHE_TTL = 5; // 5分钟
    
    /**
     * 带缓存的搜索
     */
    public Page<PmsProduct> searchWithCache(ProductSearchParam param) {
        // 生成缓存key
        String cacheKey = generateCacheKey(param);
        
        // 尝试从缓存获取
        String cached = redisTemplate.opsForValue().get(cacheKey);
        if (StrUtil.isNotBlank(cached)) {
            return JSONUtil.toBean(cached, Page.class);
        }
        
        // 查询数据库
        Page<PmsProduct> result = search(param);
        
        // 写入缓存
        redisTemplate.opsForValue().set(
            cacheKey, 
            JSONUtil.toJsonStr(result), 
            CACHE_TTL, 
            TimeUnit.MINUTES
        );
        
        return result;
    }
    
    private String generateCacheKey(ProductSearchParam param) {
        return SEARCH_CACHE_KEY + DigestUtil.md5Hex(JSONUtil.toJsonStr(param));
    }
}
```

## 15.5 搜索Controller

```java
@RestController
@Api(tags = "PmsProductSearchController", description = "商品搜索")
@RequestMapping("/product")
public class PmsProductSearchController {

    @Autowired
    private PmsProductSearchService searchService;

    @ApiOperation("商品搜索")
    @GetMapping("/search")
    public CommonResult<CommonPage<PmsProduct>> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long brandId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) String sort,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        
        ProductSearchParam param = new ProductSearchParam();
        param.setKeyword(keyword);
        param.setCategoryId(categoryId);
        param.setBrandId(brandId);
        param.setMinPrice(minPrice);
        param.setMaxPrice(maxPrice);
        param.setSort(sort);
        param.setPageNum(pageNum);
        param.setPageSize(pageSize);
        
        Page<PmsProduct> page = searchService.search(param);
        return CommonResult.success(CommonPage.restPage(page));
    }

    @ApiOperation("获取筛选条件")
    @GetMapping("/search/filter")
    public CommonResult<Map<String, Object>> getFilterConditions(
            @RequestParam(required = false) Long categoryId) {
        
        Map<String, Object> result = searchService.getFilterConditions(categoryId);
        return CommonResult.success(result);
    }
}
```

## 15.6 实战练习

### 练习1：实现关键词搜索

```bash
curl "http://localhost:8080/product/search?keyword=iPhone&pageNum=1&pageSize=10"
```

### 练习2：组合条件搜索

```bash
curl "http://localhost:8080/product/search?categoryId=2&brandId=1&minPrice=5000&maxPrice=10000&sort=price_asc"
```

### 练习3：性能测试

```java
@Test
public void testSearchPerformance() {
    long start = System.currentTimeMillis();
    
    for (int i = 0; i < 100; i++) {
        ProductSearchParam param = new ProductSearchParam();
        param.setKeyword("手机");
        param.setPageNum(i % 10 + 1);
        searchService.search(param);
    }
    
    long end = System.currentTimeMillis();
    System.out.println("100次搜索耗时：" + (end - start) + "ms");
    System.out.println("平均每次：" + (end - start) / 100 + "ms");
}
```

## 15.7 常见问题

### Q1: 搜索慢怎么优化？

**答**：
1. **添加索引**：对搜索字段添加索引
2. **分页优化**：避免深度分页
3. **缓存**：热点数据缓存
4. **搜索引擎**：引入Elasticsearch

### Q2: 如何实现全文搜索？

**答**：
- MySQL：使用FULLTEXT索引
- Elasticsearch：专业的全文搜索引擎
- 分词：IK Analyzer、jieba

### Q3: 多属性筛选如何实现？

**答**：
- 方案1：多表JOIN（简单但性能差）
- 方案2：子查询IN（推荐）
- 方案3：倒排索引（Elasticsearch）

## 15.8 本节小结

本节我们学习了：
1. **搜索接口设计**：多条件组合搜索
2. **动态SQL**：MyBatis-Plus条件构造器
3. **属性筛选**：多属性组合查询
4. **性能优化**：索引、缓存、分页优化

至此，第二阶段商品模块全部完成！

---

**第二阶段总结**：
- ✅ 第10节：商品模块数据库设计
- ✅ 第11节：商品分类管理
- ✅ 第12节：商品属性管理
- ✅ 第13节：商品发布功能
- ✅ 第14节：SKU管理与库存
- ✅ 第15节：商品搜索与筛选

**下阶段预告**：第三阶段订单模块 - 购物车、订单创建、支付、物流跟踪。
