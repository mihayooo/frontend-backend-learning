# 第14节：SKU管理与库存

## 本节目标

- 理解SKU的概念和设计原理
- 掌握SKU生成算法（笛卡尔积）
- 实现库存锁定、扣减、释放
- 理解库存预警机制

## 14.1 SKU概述

### 14.1.1 什么是SKU

**SKU**（Stock Keeping Unit，库存量单位）是库存管理的最小单元。

**示例**：iPhone 15 Pro
- 颜色：黑色、白色、蓝色
- 存储：128GB、256GB、512GB

**SKU组合**：
1. 黑色-128GB
2. 黑色-256GB
3. 黑色-512GB
4. 白色-128GB
5. 白色-256GB
6. 白色-512GB
7. 蓝色-128GB
8. 蓝色-256GB
9. 蓝色-512GB

**共 3 × 3 = 9 个SKU**

### 14.1.2 SKU vs SPU

| 概念 | 全称 | 说明 | 示例 |
|:---|:---|:---|:---|
| **SPU** | Standard Product Unit | 标准化产品单元 | iPhone 15 Pro |
| **SKU** | Stock Keeping Unit | 库存量单位 | iPhone 15 Pro 黑色 128GB |

**关系**：1个SPU对应多个SKU

## 14.2 SKU数据库设计

```sql
CREATE TABLE pms_sku_stock (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT COMMENT '商品ID',
    sku_code VARCHAR(64) COMMENT 'SKU编码',
    price DECIMAL(10,2) COMMENT '价格',
    stock INT DEFAULT 0 COMMENT '库存',
    low_stock INT DEFAULT 0 COMMENT '预警库存',
    sp1 VARCHAR(64) COMMENT '销售属性1（如颜色）',
    sp2 VARCHAR(64) COMMENT '销售属性2（如尺码）',
    sp3 VARCHAR(64) COMMENT '销售属性3',
    pic VARCHAR(255) COMMENT '展示图片',
    sale INT DEFAULT 0 COMMENT '销量',
    promotion_price DECIMAL(10,2) COMMENT '促销价',
    lock_stock INT DEFAULT 0 COMMENT '锁定库存',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 14.2.1 字段说明

| 字段 | 说明 |
|:---|:---|
| `product_id` | 关联的商品ID |
| `sku_code` | 唯一标识，如 SKU123-BLACK-128GB |
| `sp1/sp2/sp3` | 销售属性值，最多支持3个维度 |
| `stock` | 实际库存 |
| `lock_stock` | 已锁定但未支付的库存 |
| `sale` | 累计销量 |

### 14.2.2 库存状态公式

```
可用库存 = stock - lock_stock
可售判断：可用库存 > 0
```

## 14.3 SKU生成算法

### 14.3.1 笛卡尔积算法

```java
/**
 * 生成SKU组合（笛卡尔积）
 */
public List<Map<String, String>> generateSkuCombinations(
        Map<String, List<String>> specMap) {
    
    List<Map<String, String>> result = new ArrayList<>();
    List<String> keys = new ArrayList<>(specMap.keySet());
    
    // 递归生成组合
    generateCombinations(specMap, keys, 0, new HashMap<>(), result);
    
    return result;
}

private void generateCombinations(
        Map<String, List<String>> specMap,
        List<String> keys,
        int index,
        Map<String, String> current,
        List<Map<String, String>> result) {
    
    if (index == keys.size()) {
        // 完成一组组合
        result.add(new HashMap<>(current));
        return;
    }
    
    String key = keys.get(index);
    List<String> values = specMap.get(key);
    
    for (String value : values) {
        current.put(key, value);
        generateCombinations(specMap, keys, index + 1, current, result);
        current.remove(key);  // 回溯
    }
}
```

### 14.3.2 使用示例

```java
// 定义规格
Map<String, List<String>> specMap = new HashMap<>();
specMap.put("颜色", Arrays.asList("黑色", "白色", "蓝色"));
specMap.put("存储", Arrays.asList("128GB", "256GB"));

// 生成SKU组合
List<Map<String, String>> skus = generateSkuCombinations(specMap);

// 输出结果
// [{颜色=黑色, 存储=128GB}, {颜色=黑色, 存储=256GB}, 
//  {颜色=白色, 存储=128GB}, {颜色=白色, 存储=256GB},
//  {颜色=蓝色, 存储=128GB}, {颜色=蓝色, 存储=256GB}]
```

### 14.3.3 生成SKU编码

```java
/**
 * 生成SKU编码
 */
public String generateSkuCode(Long productId, String sp1, String sp2, String sp3) {
    StringBuilder sb = new StringBuilder();
    sb.append("SKU").append(productId);
    
    if (sp1 != null && !sp1.isEmpty()) {
        sb.append("-").append(hashCode(sp1));
    }
    if (sp2 != null && !sp2.isEmpty()) {
        sb.append("-").append(hashCode(sp2));
    }
    if (sp3 != null && !sp3.isEmpty()) {
        sb.append("-").append(hashCode(sp3));
    }
    
    return sb.toString();
}

private String hashCode(String str) {
    // 取hashcode的后4位，避免过长
    return String.valueOf(str.hashCode() & 0xFFFF);
}
```

## 14.4 库存管理

### 14.4.1 库存状态流转

```
┌─────────────┐     下单      ┌─────────────┐     支付      ┌─────────────┐
│   可用库存   │ ───────────→ │   锁定库存   │ ───────────→ │   已售库存   │
│  (stock)    │              │ (lock_stock)│              │   (sale)    │
└─────────────┘              └─────────────┘              └─────────────┘
       ↑                            │                            │
       │         取消订单            │         退款               │
       └────────────────────────────┘←─────────────────────────────┘
```

### 14.4.2 库存锁定

```java
/**
 * 锁定库存（下单时调用）
 */
@Update("UPDATE pms_sku_stock " +
        "SET lock_stock = lock_stock + #{quantity} " +
        "WHERE id = #{skuId} " +
        "AND (stock - lock_stock) >= #{quantity}")
int lockStock(@Param("skuId") Long skuId, @Param("quantity") Integer quantity);
```

**业务逻辑**：
```java
public boolean lockStock(Long skuId, Integer quantity) {
    // 检查可用库存
    PmsSkuStock sku = getById(skuId);
    int availableStock = sku.getStock() - sku.getLockStock();
    
    if (availableStock < quantity) {
        throw new RuntimeException("库存不足");
    }
    
    // 锁定库存
    int result = baseMapper.lockStock(skuId, quantity);
    return result > 0;
}
```

### 14.4.3 库存释放

```java
/**
 * 释放库存（取消订单时调用）
 */
@Update("UPDATE pms_sku_stock " +
        "SET lock_stock = lock_stock - #{quantity} " +
        "WHERE id = #{skuId} " +
        "AND lock_stock >= #{quantity}")
int unlockStock(@Param("skuId") Long skuId, @Param("quantity") Integer quantity);
```

### 14.4.4 库存扣减

```java
/**
 * 扣减库存（支付成功后调用）
 */
@Update("UPDATE pms_sku_stock " +
        "SET stock = stock - #{quantity}, " +
        "    lock_stock = lock_stock - #{quantity}, " +
        "    sale = sale + #{quantity} " +
        "WHERE id = #{skuId}")
int reduceStock(@Param("skuId") Long skuId, @Param("quantity") Integer quantity);
```

## 14.5 库存预警

### 14.5.1 预警机制

```java
@Service
public class StockAlertService {
    
    /**
     * 检查库存预警
     */
    public List<PmsSkuStock> checkLowStock() {
        LambdaQueryWrapper<PmsSkuStock> wrapper = new LambdaQueryWrapper<>();
        // 可用库存 <= 预警库存
        wrapper.apply("(stock - lock_stock) <= low_stock");
        wrapper.gt("stock", 0);  // 库存大于0
        return skuStockService.list(wrapper);
    }
    
    /**
     * 发送预警通知
     */
    public void sendAlert(List<PmsSkuStock> lowStockList) {
        for (PmsSkuStock sku : lowStockList) {
            // TODO: 发送邮件/短信通知
            log.warn("库存预警：SKU[{}] 可用库存[{}] 预警线[{}]", 
                    sku.getSkuCode(), 
                    sku.getStock() - sku.getLockStock(),
                    sku.getLowStock());
        }
    }
}
```

### 14.5.2 定时检查

```java
@Component
public class StockAlertJob {
    
    @Autowired
    private StockAlertService stockAlertService;
    
    /**
     * 每小时检查一次库存预警
     */
    @Scheduled(cron = "0 0 * * * ?")
    public void checkStockAlert() {
        List<PmsSkuStock> lowStockList = stockAlertService.checkLowStock();
        if (!lowStockList.isEmpty()) {
            stockAlertService.sendAlert(lowStockList);
        }
    }
}
```

## 14.6 API接口

### 14.6.1 SKU接口

| 接口 | 方法 | 说明 |
|:---|:---|:---|
| `/sku/{productId}` | GET | 根据商品ID获取SKU列表 |
| `/sku/update/{productId}` | POST | 批量更新SKU信息 |
| `/sku/lock/{skuId}` | POST | 锁定库存 |
| `/sku/unlock/{skuId}` | POST | 释放库存 |

### 14.6.2 接口示例

```java
@RestController
@RequestMapping("/sku")
public class PmsSkuStockController {
    
    @GetMapping("/{productId}")
    public CommonResult<List<PmsSkuStock>> getList(@PathVariable Long productId) {
        return CommonResult.success(skuStockService.listByProductId(productId));
    }
    
    @PostMapping("/update/{productId}")
    public CommonResult<String> update(@PathVariable Long productId, 
                                       @RequestBody List<PmsSkuStock> skuStockList) {
        boolean success = skuStockService.updateBatch(productId, skuStockList);
        return success ? CommonResult.success("更新成功") : CommonResult.failed("更新失败");
    }
}
```

## 14.7 实战练习

### 练习1：生成SKU组合

为以下商品生成所有SKU：
- 颜色：红色、蓝色、黑色
- 尺码：S、M、L、XL
- 材质：棉、涤纶

**预期结果**：3 × 4 × 2 = 24个SKU

### 练习2：库存操作测试

```java
@Test
public void testStockOperations() {
    Long skuId = 1L;
    
    // 1. 初始状态
    PmsSkuStock sku = skuStockService.getById(skuId);
    System.out.println("初始库存：" + sku.getStock());
    System.out.println("初始锁定：" + sku.getLockStock());
    
    // 2. 锁定10个
    skuStockService.lockStock(skuId, 10);
    
    // 3. 释放5个
    skuStockService.unlockStock(skuId, 5);
    
    // 4. 扣减5个（模拟支付）
    skuStockService.reduceStock(skuId, 5);
    
    // 验证最终状态
    sku = skuStockService.getById(skuId);
    System.out.println("最终库存：" + sku.getStock());
    System.out.println("最终锁定：" + sku.getLockStock());
    System.out.println("销量：" + sku.getSale());
}
```

## 14.8 常见问题

### Q1: 超卖问题如何解决？

**答**：
1. **数据库层面**：使用 `stock - lock_stock >= quantity` 条件判断
2. **应用层面**：分布式锁（Redis/Zookeeper）
3. **队列削峰**：使用消息队列串行化处理

### Q2: 库存同步延迟怎么办？

**答**：
- 允许短暂不一致，最终一致即可
- 使用缓存（Redis）加速读取
- 异步同步库存变动

### Q3: 多仓库库存如何管理？

**答**：
- 增加仓库维度表
- SKU库存拆分到仓库
- 根据收货地址匹配就近仓库

## 14.9 本节小结

本节我们学习了：
1. **SKU概念**：SPU与SKU的关系
2. **生成算法**：笛卡尔积生成SKU组合
3. **库存管理**：锁定、释放、扣减三种操作
4. **库存预警**：定时检查低库存商品

下节预告：**第15节：商品搜索与筛选** - Elasticsearch集成、多条件搜索、属性筛选。

---

**课后作业**：
1. 实现SKU生成算法
2. 测试库存锁定/释放/扣减流程
3. 思考：如何实现秒杀场景下的库存控制？
