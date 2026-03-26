# 第11节：商品分类管理

## 学习目标

- 掌握无限级分类的树形结构查询
- 学会使用MyBatis-Plus进行CRUD操作
- 理解递归构建树形数据的方法
- 掌握RESTful API设计规范

## 1. 功能需求分析

商品分类管理需要实现以下功能：

```
┌─────────────────────────────────────────────────────────────┐
│                     商品分类管理功能                          │
├─────────────────────────────────────────────────────────────┤
│  1. 创建分类（支持多级）                                      │
│  2. 修改分类信息                                             │
│  3. 删除分类（需检查子分类）                                  │
│  4. 查询分类列表（按父级ID）                                  │
│  5. 查询分类树形结构                                         │
│  6. 更新显示状态                                             │
│  7. 更新导航栏显示状态                                        │
└─────────────────────────────────────────────────────────────┘
```

## 2. 实体类设计

### 2.1 PmsProductCategory 实体类

```java
package com.macro.mall.tiny.modules.pms.model;

import com.baomidou.mybatisplus.annotation.*;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName("pms_product_category")
public class PmsProductCategory {
    
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    
    @ApiModelProperty("上级分类的编号：0表示一级分类")
    private Long parentId;
    
    @ApiModelProperty("分类名称")
    private String name;
    
    @ApiModelProperty("分类级别：0->1级；1->2级；2->3级")
    private Integer level;
    
    @ApiModelProperty("商品数量")
    private Integer productCount;
    
    @ApiModelProperty("商品单位")
    private String productUnit;
    
    @ApiModelProperty("是否显示在导航栏：0->不显示；1->显示")
    private Integer navStatus;
    
    @ApiModelProperty("显示状态：0->不显示；1->显示")
    private Integer showStatus;
    
    @ApiModelProperty("排序")
    private Integer sort;
    
    @ApiModelProperty("图标")
    private String icon;
    
    @ApiModelProperty("关键字")
    private String keywords;
    
    @ApiModelProperty("描述")
    private String description;
    
    @ApiModelProperty("创建时间")
    private LocalDateTime createTime;
    
    @ApiModelProperty("更新时间")
    private LocalDateTime updateTime;
    
    // ========== 非数据库字段 ==========
    @ApiModelProperty("子分类列表（用于树形结构）")
    @TableField(exist = false)
    private List<PmsProductCategory> children;
}
```

**关键点**：
- `@TableName`：指定数据库表名
- `@TableId`：指定主键，自增策略
- `@TableField(exist = false)`：标记非数据库字段

## 3. Mapper接口

```java
package com.macro.mall.tiny.modules.pms.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.macro.mall.tiny.modules.pms.model.PmsProductCategory;
import org.apache.ibatis.annotations.Param;
import java.util.List;

public interface PmsProductCategoryMapper extends BaseMapper<PmsProductCategory> {
    
    /**
     * 根据父级ID查询分类列表
     */
    List<PmsProductCategory> selectByParentId(@Param("parentId") Long parentId);
    
    /**
     * 获取所有一级分类
     */
    List<PmsProductCategory> selectLevelOne();
}
```

**说明**：
- 继承 `BaseMapper<PmsProductCategory>` 获得基础CRUD方法
- 自定义方法用于特殊查询需求

## 4. Service实现

### 4.1 接口定义

```java
package com.macro.mall.tiny.modules.pms.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.macro.mall.tiny.modules.pms.model.PmsProductCategory;
import java.util.List;

public interface PmsProductCategoryService extends IService<PmsProductCategory> {
    
    boolean create(PmsProductCategory productCategory);
    boolean update(Long id, PmsProductCategory productCategory);
    boolean delete(Long id);
    List<PmsProductCategory> getListByParentId(Long parentId);
    List<PmsProductCategory> getTreeList();
    List<PmsProductCategory> getLevelOne();
    boolean updateShowStatus(Long id, Integer showStatus);
    boolean updateNavStatus(Long id, Integer navStatus);
}
```

### 4.2 实现类（核心代码）

```java
package com.macro.mall.tiny.modules.pms.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.macro.mall.tiny.modules.pms.mapper.PmsProductCategoryMapper;
import com.macro.mall.tiny.modules.pms.model.PmsProductCategory;
import com.macro.mall.tiny.modules.pms.service.PmsProductCategoryService;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class PmsProductCategoryServiceImpl extends ServiceImpl<PmsProductCategoryMapper, PmsProductCategory>
        implements PmsProductCategoryService {

    @Override
    public boolean create(PmsProductCategory productCategory) {
        productCategory.setCreateTime(LocalDateTime.now());
        productCategory.setUpdateTime(LocalDateTime.now());
        productCategory.setProductCount(0);
        
        // 自动设置分类级别
        if (productCategory.getParentId() == 0) {
            productCategory.setLevel(0);
        } else {
            PmsProductCategory parent = getById(productCategory.getParentId());
            if (parent != null) {
                productCategory.setLevel(parent.getLevel() + 1);
            }
        }
        
        return save(productCategory);
    }

    @Override
    public boolean delete(Long id) {
        // 检查是否有子分类
        List<PmsProductCategory> children = getListByParentId(id);
        if (!children.isEmpty()) {
            throw new RuntimeException("该分类下有子分类，不能删除");
        }
        return removeById(id);
    }

    /**
     * 递归构建树形结构（核心算法）
     */
    @Override
    public List<PmsProductCategory> getTreeList() {
        // 1. 获取所有分类
        List<PmsProductCategory> allList = list();
        
        // 2. 递归构建树
        return buildTree(allList, 0L);
    }
    
    /**
     * 递归方法：构建树形结构
     * @param allList 所有分类列表
     * @param parentId 父级ID
     * @return 该父级下的子分类树
     */
    private List<PmsProductCategory> buildTree(List<PmsProductCategory> allList, Long parentId) {
        List<PmsProductCategory> result = new ArrayList<>();
        
        for (PmsProductCategory category : allList) {
            if (category.getParentId().equals(parentId)) {
                // 递归获取子分类
                category.setChildren(buildTree(allList, category.getId()));
                result.add(category);
            }
        }
        
        return result;
    }

    @Override
    public List<PmsProductCategory> getListByParentId(Long parentId) {
        LambdaQueryWrapper<PmsProductCategory> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PmsProductCategory::getParentId, parentId)
               .orderByAsc(PmsProductCategory::getSort);
        return list(wrapper);
    }
    
    // ... 其他方法省略
}
```

### 4.3 树形构建算法解析

```
输入：所有分类列表
输出：树形结构

示例数据：
id  name        parent_id
1   手机数码     0
2   手机通讯     1
3   智能手机     2
4   数码配件     1

构建过程：
1. buildTree(all, 0) → 找到 parent_id=0 的 [手机数码]
2. 对 [手机数码] 递归 buildTree(all, 1) → 找到 parent_id=1 的 [手机通讯, 数码配件]
3. 对 [手机通讯] 递归 buildTree(all, 2) → 找到 parent_id=2 的 [智能手机]
4. 对 [智能手机] 递归 buildTree(all, 3) → 无子分类，返回空列表

最终结果：
手机数码
├── 手机通讯
│   └── 智能手机
└── 数码配件
```

## 5. Controller实现

```java
package com.macro.mall.tiny.modules.pms.controller;

import com.macro.mall.tiny.common.api.CommonResult;
import com.macro.mall.tiny.modules.pms.model.PmsProductCategory;
import com.macro.mall.tiny.modules.pms.service.PmsProductCategoryService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@Api(tags = "商品分类管理")
@RequestMapping("/productCategory")
public class PmsProductCategoryController {

    @Autowired
    private PmsProductCategoryService productCategoryService;

    @ApiOperation("添加商品分类")
    @PostMapping("/create")
    public CommonResult create(@RequestBody PmsProductCategory productCategory) {
        boolean success = productCategoryService.create(productCategory);
        return success ? CommonResult.success(null, "创建成功") 
                      : CommonResult.failed("创建失败");
    }

    @ApiOperation("修改商品分类")
    @PostMapping("/update/{id}")
    public CommonResult update(@PathVariable Long id, 
                               @RequestBody PmsProductCategory productCategory) {
        boolean success = productCategoryService.update(id, productCategory);
        return success ? CommonResult.success(null, "更新成功") 
                      : CommonResult.failed("更新失败");
    }

    @ApiOperation("删除商品分类")
    @PostMapping("/delete/{id}")
    public CommonResult delete(@PathVariable Long id) {
        boolean success = productCategoryService.delete(id);
        return success ? CommonResult.success(null, "删除成功") 
                      : CommonResult.failed("删除失败");
    }

    @ApiOperation("根据父级ID获取分类列表")
    @GetMapping("/list/{parentId}")
    public CommonResult<List<PmsProductCategory>> getListByParentId(
            @PathVariable Long parentId) {
        List<PmsProductCategory> list = productCategoryService.getListByParentId(parentId);
        return CommonResult.success(list);
    }

    @ApiOperation("获取分类树形结构")
    @GetMapping("/treeList")
    public CommonResult<List<PmsProductCategory>> getTreeList() {
        List<PmsProductCategory> list = productCategoryService.getTreeList();
        return CommonResult.success(list);
    }

    @ApiOperation("获取分类详情")
    @GetMapping("/{id}")
    public CommonResult<PmsProductCategory> getItem(@PathVariable Long id) {
        PmsProductCategory category = productCategoryService.getById(id);
        return CommonResult.success(category);
    }

    @ApiOperation("修改显示状态")
    @PostMapping("/update/showStatus")
    public CommonResult updateShowStatus(@RequestParam Long id, 
                                          @RequestParam Integer showStatus) {
        boolean success = productCategoryService.updateShowStatus(id, showStatus);
        return success ? CommonResult.success(null, "修改成功") 
                      : CommonResult.failed("修改失败");
    }
}
```

## 6. API接口列表

| 接口 | 方法 | 说明 |
|:---|:---|:---|
| /productCategory/create | POST | 创建分类 |
| /productCategory/update/{id} | POST | 更新分类 |
| /productCategory/delete/{id} | POST | 删除分类 |
| /productCategory/list/{parentId} | GET | 根据父级ID查询 |
| /productCategory/treeList | GET | 获取树形结构 |
| /productCategory/{id} | GET | 获取详情 |
| /productCategory/update/showStatus | POST | 更新显示状态 |
| /productCategory/update/navStatus | POST | 更新导航状态 |

## 7. 测试示例

### 7.1 创建分类

```bash
curl -X POST http://localhost:8080/productCategory/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "parentId": 0,
    "name": "家用电器",
    "productUnit": "件",
    "navStatus": 1,
    "showStatus": 1,
    "sort": 1,
    "keywords": "家电",
    "description": "家用电器分类"
  }'
```

### 7.2 获取树形结构

```bash
curl -X GET http://localhost:8080/productCategory/treeList \
  -H "Authorization: Bearer {token}"
```

**返回示例**：

```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "name": "手机数码",
      "level": 0,
      "children": [
        {
          "id": 2,
          "name": "手机通讯",
          "level": 1,
          "children": [
            {
              "id": 3,
              "name": "智能手机",
              "level": 2,
              "children": []
            }
          ]
        }
      ]
    }
  ]
}
```

## 8. 前端展示建议

### 8.1 Element Plus 树形组件

```vue
<template>
  <el-tree
    :data="categoryTree"
    :props="defaultProps"
    node-key="id"
    default-expand-all
  >
    <template #default="{ node, data }">
      <span>{{ data.name }}</span>
      <el-tag v-if="data.showStatus === 1" type="success">显示</el-tag>
      <el-tag v-else type="info">隐藏</el-tag>
    </template>
  </el-tree>
</template>

<script setup>
const defaultProps = {
  children: 'children',
  label: 'name'
}
</script>
```

### 8.2 级联选择器

```vue
<el-cascader
  v-model="selectedCategory"
  :options="categoryTree"
  :props="{ value: 'id', label: 'name', children: 'children' }"
  placeholder="请选择分类"
/>
```

## 9. 常见问题

### Q1: 递归查询性能问题？

**方案对比**：

| 方案 | 优点 | 缺点 | 适用场景 |
|:---|:---|:---|:---|
| 递归查询 | 代码简单 | 数据量大时性能差 | 分类层级少、数据量小 |
| 一次性查询+内存构建 | 只需一次查询 | 内存占用 | 数据量中等 |
| 路径字段(path) | 查询快 | 维护复杂 | 数据量大、查询频繁 |

### Q2: 如何限制分类层级？

在创建时检查父级层级：

```java
@Override
public boolean create(PmsProductCategory category) {
    if (category.getParentId() != 0) {
        PmsProductCategory parent = getById(category.getParentId());
        if (parent != null && parent.getLevel() >= 2) {
            throw new RuntimeException("最多支持3级分类");
        }
        category.setLevel(parent.getLevel() + 1);
    }
    // ...
}
```

## 10. 课后练习

1. **实现路径字段**：为分类表添加`path`字段（如：`0,1,5,10`），实现快速查询所有子分类
2. **批量操作**：实现批量删除、批量更新状态功能
3. **分类移动**：实现将一个分类及其子分类移动到另一个父分类下的功能

## 参考代码

- 实体类：`mall-tiny/src/main/java/com/macro/mall/tiny/modules/pms/model/PmsProductCategory.java`
- Mapper：`mall-tiny/src/main/java/com/macro/mall/tiny/modules/pms/mapper/PmsProductCategoryMapper.java`
- Service：`mall-tiny/src/main/java/com/macro/mall/tiny/modules/pms/service/PmsProductCategoryService.java`
- Controller：`mall-tiny/src/main/java/com/macro/mall/tiny/modules/pms/controller/PmsProductCategoryController.java`
