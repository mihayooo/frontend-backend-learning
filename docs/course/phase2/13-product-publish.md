# 第13节：商品发布功能实现

## 本节目标

- 理解商品发布的完整流程
- 掌握DTO（数据传输对象）的设计
- 实现商品信息的批量保存
- 理解事务在商品发布中的应用

## 13.1 商品发布流程

### 13.1.1 完整流程图

```
┌─────────────────────────────────────────────────────────────┐
│                      商品发布流程                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 填写基本信息 ──→ 商品名称、副标题、描述、价格             │
│         │                                                   │
│         ▼                                                   │
│  2. 选择分类 ────→ 商品分类、品牌、属性分类                   │
│         │                                                   │
│         ▼                                                   │
│  3. 上传图片 ────→ 主图、相册图、详情图                       │
│         │                                                   │
│         ▼                                                   │
│  4. 设置属性 ────→ 规格、参数                               │
│         │                                                   │
│         ▼                                                   │
│  5. 生成SKU ────→ 根据规格组合生成SKU                       │
│         │                                                   │
│         ▼                                                   │
│  6. 保存商品 ────→ 事务保证数据一致性                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 13.1.2 涉及的数据表

| 步骤 | 涉及表 | 说明 |
|:---|:---|:---|
| 基本信息 | pms_product | 商品主表 |
| 分类品牌 | pms_product | category_id, brand_id |
| 图片 | pms_product | pic, album_pics |
| 规格 | pms_product_attribute_value | 规格属性值 |
| 参数 | pms_product_attribute_value | 参数属性值 |
| SKU | pms_sku_stock | SKU库存信息 |
| 分类属性关系 | pms_product_category_attribute_relation | 分类与属性分类关联 |

## 13.2 DTO设计

### 13.2.1 商品发布DTO

```java
@Data
public class PmsProductPublishDto {
    // ========== 基本信息 ==========
    private Long id;                          // 商品ID（更新时使用）
    private Long brandId;                     // 品牌ID
    private Long productCategoryId;           // 商品分类ID
    private Long productAttributeCategoryId;  // 属性分类ID
    
    private String name;                      // 商品名称
    private String subTitle;                  // 副标题
    private String description;               // 商品描述
    private String detailHtml;                // 详情HTML
    private String detailMobileHtml;          // 移动端详情
    
    // ========== 价格库存 ==========
    private BigDecimal price;                 // 售价
    private BigDecimal originalPrice;         // 原价
    private BigDecimal promotionPrice;        // 促销价
    private Integer stock;                    // 库存
    private Integer lowStock;                 // 预警库存
    
    // ========== 图片 ==========
    private String pic;                       // 主图
    private String albumPics;                 // 相册图，逗号分隔
    
    // ========== 属性 ==========
    private List<ProductAttributeValueDto> productAttributeValueList;  // 属性值列表
    
    // ========== SKU ==========
    private List<PmsSkuStock> skuStockList;   // SKU列表
    
    // ========== 其他设置 ==========
    private Integer sort;                     // 排序
    private Integer newStatus;                // 新品状态
    private Integer recommandStatus;          // 推荐状态
    private Integer publishStatus;            // 上架状态
}

@Data
public class ProductAttributeValueDto {
    private Long productAttributeId;  // 属性ID
    private String value;             // 属性值
}
```

### 13.2.2 DTO设计原则

1. **聚合相关数据**：将分散的表数据聚合到一个DTO
2. **扁平化结构**：简化前端传参
3. **便于验证**：集中参数校验
4. **减少请求次数**：一次请求完成所有操作

## 13.3 核心代码实现

### 13.3.1 商品发布Service

```java
@Service
public class PmsProductPublishService {

    @Autowired
    private PmsProductService productService;
    @Autowired
    private PmsProductAttributeValueService attributeValueService;
    @Autowired
    private PmsSkuStockService skuStockService;
    
    /**
     * 发布商品（带事务）
     */
    @Transactional(rollbackFor = Exception.class)
    public boolean publish(PmsProductPublishDto publishDto) {
        // 1. 保存商品基本信息
        PmsProduct product = convertToProduct(publishDto);
        boolean success = productService.save(product);
        if (!success) {
            throw new RuntimeException("保存商品基本信息失败");
        }
        
        Long productId = product.getId();
        
        // 2. 保存商品属性值
        if (publishDto.getProductAttributeValueList() != null) {
            List<PmsProductAttributeValue> valueList = publishDto.getProductAttributeValueList()
                    .stream()
                    .map(dto -> {
                        PmsProductAttributeValue value = new PmsProductAttributeValue();
                        value.setProductId(productId);
                        value.setProductAttributeId(dto.getProductAttributeId());
                        value.setValue(dto.getValue());
                        return value;
                    })
                    .collect(Collectors.toList());
            attributeValueService.saveBatch(productId, valueList);
        }
        
        // 3. 保存SKU信息
        if (publishDto.getSkuStockList() != null) {
            skuStockService.updateBatch(productId, publishDto.getSkuStockList());
        }
        
        return true;
    }
    
    /**
     * 更新商品（带事务）
     */
    @Transactional(rollbackFor = Exception.class)
    public boolean update(Long id, PmsProductPublishDto publishDto) {
        // 1. 更新商品基本信息
        PmsProduct product = convertToProduct(publishDto);
        product.setId(id);
        boolean success = productService.updateById(product);
        if (!success) {
            throw new RuntimeException("更新商品基本信息失败");
        }
        
        // 2. 更新商品属性值
        if (publishDto.getProductAttributeValueList() != null) {
            List<PmsProductAttributeValue> valueList = publishDto.getProductAttributeValueList()
                    .stream()
                    .map(dto -> {
                        PmsProductAttributeValue value = new PmsProductAttributeValue();
                        value.setProductId(id);
                        value.setProductAttributeId(dto.getProductAttributeId());
                        value.setValue(dto.getValue());
                        return value;
                    })
                    .collect(Collectors.toList());
            attributeValueService.saveBatch(id, valueList);
        }
        
        // 3. 更新SKU信息
        if (publishDto.getSkuStockList() != null) {
            skuStockService.updateBatch(id, publishDto.getSkuStockList());
        }
        
        return true;
    }
    
    private PmsProduct convertToProduct(PmsProductPublishDto dto) {
        PmsProduct product = new PmsProduct();
        BeanUtils.copyProperties(dto, product);
        product.setCreateTime(LocalDateTime.now());
        product.setUpdateTime(LocalDateTime.now());
        product.setDeleteStatus(0);  // 未删除
        product.setVerifyStatus(1);  // 已审核
        return product;
    }
}
```

### 13.3.2 商品发布Controller

```java
@RestController
@Api(tags = "PmsProductPublishController", description = "商品发布管理")
@RequestMapping("/product")
public class PmsProductPublishController {

    @Autowired
    private PmsProductPublishService publishService;
    
    @ApiOperation("创建商品")
    @PostMapping("/create")
    public CommonResult<String> create(@RequestBody @Valid PmsProductPublishDto productPublishDto) {
        boolean success = publishService.publish(productPublishDto);
        if (success) {
            return CommonResult.success("创建成功");
        }
        return CommonResult.failed("创建失败");
    }
    
    @ApiOperation("更新商品")
    @PostMapping("/update/{id}")
    public CommonResult<String> update(@PathVariable Long id,
                                       @RequestBody @Valid PmsProductPublishDto productPublishDto) {
        boolean success = publishService.update(id, productPublishDto);
        if (success) {
            return CommonResult.success("更新成功");
        }
        return CommonResult.failed("更新失败");
    }
}
```

## 13.4 事务管理详解

### 13.4.1 为什么需要事务

商品发布涉及多张表的操作，必须保证：
- **原子性**：要么全部成功，要么全部失败
- **一致性**：数据状态始终一致
- **隔离性**：并发操作互不干扰
- **持久性**：提交后数据永久保存

### 13.4.2 Spring事务配置

```java
@Configuration
@EnableTransactionManagement
public class MyBatisConfig {
    
    @Bean
    public DataSourceTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

### 13.4.3 @Transactional注解

```java
@Transactional(
    propagation = Propagation.REQUIRED,    // 传播行为：默认，加入已有事务
    isolation = Isolation.DEFAULT,          // 隔离级别：默认
    timeout = 30,                           // 超时时间：30秒
    rollbackFor = Exception.class,          // 回滚异常：所有Exception
    noRollbackFor = RuntimeException.class  // 不回滚异常
)
public boolean publish(PmsProductPublishDto publishDto) {
    // 业务逻辑
}
```

### 13.4.4 事务传播行为

| 传播行为 | 说明 |
|:---|:---|
| REQUIRED | 默认，如果存在事务则加入，否则新建 |
| REQUIRES_NEW | 新建事务，挂起已有事务 |
| NESTED | 嵌套事务，可独立回滚 |
| SUPPORTS | 有事务则加入，无则以非事务执行 |
| NOT_SUPPORTED | 以非事务执行，挂起已有事务 |
| MANDATORY | 必须有事务，否则抛异常 |
| NEVER | 必须无事务，否则抛异常 |

## 13.5 参数校验

### 13.5.1 DTO添加校验注解

```java
@Data
public class PmsProductPublishDto {
    
    @NotNull(message = "品牌ID不能为空")
    private Long brandId;
    
    @NotNull(message = "商品分类ID不能为空")
    private Long productCategoryId;
    
    @NotBlank(message = "商品名称不能为空")
    @Size(max = 200, message = "商品名称长度不能超过200")
    private String name;
    
    @NotNull(message = "售价不能为空")
    @DecimalMin(value = "0.01", message = "售价必须大于0")
    private BigDecimal price;
    
    @NotNull(message = "库存不能为空")
    @Min(value = 0, message = "库存不能小于0")
    private Integer stock;
    
    @NotBlank(message = "主图不能为空")
    private String pic;
}
```

### 13.5.2 Controller开启校验

```java
@PostMapping("/create")
public CommonResult<String> create(
        @RequestBody @Valid PmsProductPublishDto productPublishDto) {
    // @Valid 触发参数校验
    // 校验失败会自动抛出 MethodArgumentNotValidException
}
```

### 13.5.3 全局异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public CommonResult<String> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return CommonResult.validateFailed(message);
    }
}
```

## 13.6 实战练习

### 练习1：发布iPhone 15 Pro

```json
POST /product/create
{
  "brandId": 1,
  "productCategoryId": 2,
  "productAttributeCategoryId": 1,
  "name": "iPhone 15 Pro",
  "subTitle": "钛金属设计，A17 Pro芯片",
  "description": "iPhone 15 Pro采用钛金属设计，搭载A17 Pro芯片...",
  "price": 7999.00,
  "originalPrice": 8999.00,
  "stock": 1000,
  "lowStock": 100,
  "pic": "https://example.com/iphone15-pro.jpg",
  "albumPics": "https://example.com/1.jpg,https://example.com/2.jpg",
  "newStatus": 1,
  "recommandStatus": 1,
  "publishStatus": 1,
  "productAttributeValueList": [
    {"productAttributeId": 1, "value": "黑色钛金属,白色钛金属,蓝色钛金属"},
    {"productAttributeId": 2, "value": "128GB,256GB,512GB"},
    {"productAttributeId": 5, "value": "6.1英寸"},
    {"productAttributeId": 6, "value": "3274mAh"}
  ],
  "skuStockList": [
    {"sp1": "黑色钛金属", "sp2": "128GB", "price": 7999.00, "stock": 200},
    {"sp1": "黑色钛金属", "sp2": "256GB", "price": 8999.00, "stock": 200},
    {"sp1": "白色钛金属", "sp2": "128GB", "price": 7999.00, "stock": 200},
    {"sp1": "白色钛金属", "sp2": "256GB", "price": 8999.00, "stock": 200}
  ]
}
```

### 练习2：测试事务回滚

1. 故意让SKU保存失败（如传入非法数据）
2. 观察商品基本信息是否回滚
3. 验证数据库数据一致性

## 13.7 常见问题

### Q1: 事务不生效的原因？

**答**：
1. 方法不是public
2. 同类方法内部调用
3. 异常被catch未抛出
4. 数据库引擎不支持事务（如MyISAM）

### Q2: 大事务如何优化？

**答**：
1. 减少事务范围，非必要操作移出事务
2. 批量操作代替单条
3. 异步处理非核心逻辑
4. 合理设置超时时间

### Q3: 分布式事务如何处理？

**答**：
- 单体应用：@Transactional足够
- 微服务：使用Seata、Saga等分布式事务方案
- 最终一致性：消息队列 + 本地事务表

## 13.8 本节小结

本节我们学习了：
1. **商品发布流程**：6个步骤的完整流程
2. **DTO设计**：聚合多表数据，简化接口
3. **事务管理**：保证数据一致性
4. **参数校验**：@Valid注解实现自动校验

下节预告：**第14节：SKU管理与库存** - SKU生成算法、库存锁定与扣减、库存预警。

---

**课后作业**：
1. 实现商品发布接口
2. 测试事务回滚功能
3. 添加参数校验，测试异常处理
