# 第18节：商品分类列表页面开发

## 学习目标

- 掌握完整的列表页面开发流程
- 理解 Vue Router 的导航和传参
- 学会表格数据展示和分页处理
- 掌握状态切换和删除操作的实现

## 1. 页面功能分析

商品分类列表页面需要实现以下功能：

1. **数据展示**：以表格形式展示分类列表
2. **分页功能**：支持分页查询
3. **状态切换**：显示/隐藏状态、导航栏状态的切换
4. **层级导航**：查看下级分类
5. **CRUD操作**：添加、编辑、删除分类

## 2. 类型定义

### 2.1 商品分类类型（types/productCate.d.ts）

```typescript
/** 商品分类信息 */
export type PmsProductCategory = {
  /** ID */
  id?: number
  /** 上级分类的编号：0表示一级分类 */
  parentId: number
  /** 分类名称 */
  name: string
  /** 分类级别：0->1级；1->2级 */
  level?: number
  /** 商品数量 */
  productCount?: number
  /** 商品单位 */
  productUnit?: string
  /** 是否显示在导航栏：0->不显示；1->显示 */
  navStatus: number
  /** 显示状态：0->不显示；1->显示 */
  showStatus: number
  /** 排序 */
  sort?: number
  /** 图标 */
  icon?: string
  /** 关键字 */
  keywords?: string
  /** 描述 */
  description?: string
  /** 筛选属性ID列表 */
  productAttributeIdList?: number[]
}

/** 商品分类信息扩展（包含子分类） */
export type PmsProductCategoryExt = PmsProductCategory & {
  /** 子级分类 */
  children?: PmsProductCategory[]
}
```

### 2.2 通用类型（types/common.d.ts）

```typescript
/** 通用分页结果封装类 */
export type CommonPage<T> = {
  /** 当前页码 */
  pageNum: number
  /** 每页数量 */
  pageSize: number
  /** 总页数 */
  totalPage: number
  /** 总条数 */
  total: number
  /** 分页数据 */
  list: T[]
}

/** 通用分页请求参数 */
export type PageParam = {
  /** 当前页码，从1开始 */
  pageNum: number
  /** 每页数量，默认10 */
  pageSize: number
  /** 查询关键字 */
  keyword?: string
}
```

## 3. API 接口封装

### 3.1 商品分类 API（apis/productCate.ts）

```typescript
import type { CommonPage, PageParam } from '@/types/common'
import type { PmsProductCategory, PmsProductCategoryExt } from '@/types/productCate'
import http from '@/utils/http'

/**
 * 查询所有一级分类及子分类（用于级联选择）
 */
export function getProductCategoryListWithChildrenAPI() {
  return http<CommonResult<PmsProductCategoryExt[]>>({
    url: '/productCategory/list/withChildren',
    method: 'get',
  })
}

/**
 * 分页查询商品分类
 * @param parentId 父分类ID，0表示查询一级分类
 * @param params 分页参数
 */
export function getProductCategoryListAPI(parentId: number, params: PageParam) {
  return http<CommonResult<CommonPage<PmsProductCategory>>>({
    url: '/productCategory/list/' + parentId,
    method: 'get',
    params: params,
  })
}

/**
 * 根据ID删除商品分类
 */
export function productCategoryDeleteByIdAPI(id: number) {
  return http<CommonResult<null>>({
    url: '/productCategory/delete/' + id,
    method: 'post',
  })
}

/**
 * 添加商品分类
 */
export function productCategoryCreateAPI(data: PmsProductCategory) {
  return http<CommonResult<null>>({
    url: '/productCategory/create',
    method: 'post',
    data: data,
  })
}

/**
 * 修改商品分类
 */
export function productCategoryUpdateByIdAPI(id: number, data: PmsProductCategory) {
  return http<CommonResult<null>>({
    url: '/productCategory/update/' + id,
    method: 'post',
    data: data,
  })
}

/**
 * 根据ID获取商品分类详情
 */
export function getProductCategoryByIdAPI(id: number) {
  return http<CommonResult<PmsProductCategory>>({
    url: '/productCategory/' + id,
    method: 'get',
  })
}

/**
 * 批量修改显示状态
 */
export function productCategoryUpdateShowStatusAPI(params: { 
  ids: string
  showStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/productCategory/update/showStatus',
    method: 'post',
    params: params,
  })
}

/**
 * 批量修改导航栏显示状态
 */
export function productCategoryUpdateNavStatusAPI(params: { 
  ids: string
  navStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/productCategory/update/navStatus',
    method: 'post',
    params: params,
  })
}
```

## 4. 列表页面实现

### 4.1 完整代码（views/pms/productCate/index.vue）

```vue
<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Tickets } from '@element-plus/icons-vue'
import { 
  getProductCategoryListAPI, 
  productCategoryDeleteByIdAPI,
  productCategoryUpdateShowStatusAPI,
  productCategoryUpdateNavStatusAPI 
} from '@/apis/productCate'
import type { PmsProductCategory } from '@/types/productCate'

// ==================== 路由相关 ====================
const router = useRouter()
const route = useRoute()

// ==================== 数据状态 ====================
// 当前列表页父分类ID（0表示一级分类）
const parentId = ref(0)

// 列表查询参数
const listQuery = ref({
  pageNum: 1,
  pageSize: 10
})

// 列表数据
const list = ref<PmsProductCategory[]>([])

// 总条数
const total = ref(0)

// 加载状态
const listLoading = ref(true)

// ==================== 方法定义 ====================

/**
 * 重置父级ID
 * 根据路由参数设置parentId
 */
const resetParentId = () => {
  listQuery.value.pageNum = 1
  if (route.query.parentId != null) {
    parentId.value = Number(route.query.parentId)
  } else {
    parentId.value = 0
  }
}

/**
 * 获取列表数据
 */
const getList = async () => {
  listLoading.value = true
  try {
    const res = await getProductCategoryListAPI(parentId.value, listQuery.value)
    list.value = res.data.list
    total.value = res.data.total
  } catch (error) {
    console.error('获取分类列表失败:', error)
  } finally {
    listLoading.value = false
  }
}

/**
 * 处理分页大小变化
 */
const handleSizeChange = (val: number) => {
  listQuery.value.pageNum = 1
  listQuery.value.pageSize = val
  getList()
}

/**
 * 处理当前页变化
 */
const handleCurrentChange = (val: number) => {
  listQuery.value.pageNum = val
  getList()
}

/**
 * 处理导航栏状态变化
 */
const handleNavStatusChange = async (index: number, row: PmsProductCategory) => {
  try {
    await productCategoryUpdateNavStatusAPI({ 
      ids: [row.id!].join(','), 
      navStatus: row.navStatus 
    })
    ElMessage({
      message: '修改成功',
      type: 'success',
      duration: 1000
    })
  } catch (error) {
    // 失败时恢复原状态
    row.navStatus = row.navStatus === 1 ? 0 : 1
  }
}

/**
 * 处理显示状态变化
 */
const handleShowStatusChange = async (index: number, row: PmsProductCategory) => {
  try {
    await productCategoryUpdateShowStatusAPI({ 
      ids: [row.id!].join(','), 
      showStatus: row.showStatus 
    })
    ElMessage({
      message: '修改成功',
      type: 'success',
      duration: 1000
    })
  } catch (error) {
    // 失败时恢复原状态
    row.showStatus = row.showStatus === 1 ? 0 : 1
  }
}

/**
 * 查看下级分类
 */
const handleShowNextLevel = (index: number, row: PmsProductCategory) => {
  router.push({ 
    path: '/pms/productCate', 
    query: { parentId: row.id } 
  })
}

/**
 * 转移商品
 */
const handleTransferProduct = (index: number, row: PmsProductCategory) => {
  console.log('转移商品:', row)
  // TODO: 实现转移商品功能
}

/**
 * 添加商品分类
 */
const handleAddProductCate = () => {
  router.push('/pms/addProductCate')
}

/**
 * 编辑分类
 */
const handleUpdate = (index: number, row: PmsProductCategory) => {
  router.push({ 
    path: '/pms/updateProductCate', 
    query: { id: row.id } 
  })
}

/**
 * 删除分类
 */
const handleDelete = async (index: number, row: PmsProductCategory) => {
  try {
    await ElMessageBox.confirm('是否要删除该分类', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await productCategoryDeleteByIdAPI(row.id!)
    ElMessage({
      message: '删除成功',
      type: 'success',
      duration: 1000
    })
    getList()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}

// ==================== 过滤器 ====================

/**
 * 分类级别过滤器
 */
const levelFilter = (value: number) => {
  if (value === 0) {
    return '一级'
  } else if (value === 1) {
    return '二级'
  }
  return '-'
}

/**
 * 禁用下级按钮（二级分类没有下级）
 */
const disableNextLevel = (value: number) => {
  return value !== 0
}

// ==================== 生命周期 ====================

onMounted(() => {
  resetParentId()
  getList()
})

// 监听路由参数变化（用于返回上级分类时刷新）
watch(() => route.query, () => {
  resetParentId()
  getList()
})
</script>

<template>
  <div class="app-container">
    <!-- 操作栏 -->
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>数据列表</span>
      <el-button class="btn-add" @click="handleAddProductCate()">
        添加
      </el-button>
    </el-card>

    <!-- 数据表格 -->
    <div class="table-container">
      <el-table 
        ref="productCateTable" 
        style="width: 100%" 
        :data="list" 
        v-loading="listLoading" 
        border
      >
        <!-- 编号列 -->
        <el-table-column label="编号" width="100" align="center">
          <template #default="scope">{{ scope.row.id }}</template>
        </el-table-column>

        <!-- 分类名称列 -->
        <el-table-column label="分类名称" align="center">
          <template #default="scope">{{ scope.row.name }}</template>
        </el-table-column>

        <!-- 级别列 -->
        <el-table-column label="级别" width="100" align="center">
          <template #default="scope">{{ levelFilter(scope.row.level) }}</template>
        </el-table-column>

        <!-- 商品数量列 -->
        <el-table-column label="商品数量" width="100" align="center">
          <template #default="scope">{{ scope.row.productCount || 0 }}</template>
        </el-table-column>

        <!-- 数量单位列 -->
        <el-table-column label="数量单位" width="100" align="center">
          <template #default="scope">{{ scope.row.productUnit }}</template>
        </el-table-column>

        <!-- 导航栏状态列 -->
        <el-table-column label="导航栏" width="100" align="center">
          <template #default="scope">
            <el-switch 
              @change="handleNavStatusChange(scope.$index, scope.row)" 
              :active-value="1" 
              :inactive-value="0"
              v-model="scope.row.navStatus"
            />
          </template>
        </el-table-column>

        <!-- 显示状态列 -->
        <el-table-column label="是否显示" width="100" align="center">
          <template #default="scope">
            <el-switch 
              @change="handleShowStatusChange(scope.$index, scope.row)" 
              :active-value="1" 
              :inactive-value="0"
              v-model="scope.row.showStatus"
            />
          </template>
        </el-table-column>

        <!-- 排序列 -->
        <el-table-column label="排序" width="100" align="center">
          <template #default="scope">{{ scope.row.sort }}</template>
        </el-table-column>

        <!-- 设置列 -->
        <el-table-column label="设置" width="200" align="center">
          <template #default="scope">
            <el-button 
              size="small" 
              :disabled="disableNextLevel(scope.row.level)"
              @click="handleShowNextLevel(scope.$index, scope.row)"
            >
              查看下级
            </el-button>
            <el-button 
              size="small" 
              @click="handleTransferProduct(scope.$index, scope.row)"
            >
              转移商品
            </el-button>
          </template>
        </el-table-column>

        <!-- 操作列 -->
        <el-table-column label="操作" width="200" align="center">
          <template #default="scope">
            <el-button size="small" @click="handleUpdate(scope.$index, scope.row)">
              编辑
            </el-button>
            <el-button 
              size="small" 
              type="danger" 
              @click="handleDelete(scope.$index, scope.row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页组件 -->
    <div class="pagination-container">
      <el-pagination 
        background 
        @size-change="handleSizeChange" 
        @current-change="handleCurrentChange"
        layout="total, sizes, prev, pager, next, jumper" 
        :page-size="listQuery.pageSize" 
        :page-sizes="[5, 10, 15]"
        v-model:current-page="listQuery.pageNum" 
        :total="total"
      />
    </div>
  </div>
</template>

<style scoped>
.operate-container {
  margin-bottom: 20px;
}

.operate-container .el-icon {
  margin-right: 8px;
  vertical-align: middle;
}

.btn-add {
  float: right;
}

.table-container {
  margin-bottom: 20px;
}

.pagination-container {
  text-align: right;
}
</style>
```

## 5. 代码详解

### 5.1 响应式数据定义

```typescript
// 使用 ref 定义响应式数据
const parentId = ref(0)                          // 父分类ID
const listQuery = ref({ pageNum: 1, pageSize: 10 })  // 查询参数
const list = ref<PmsProductCategory[]>([])       // 列表数据
const total = ref(0)                             // 总条数
const listLoading = ref(true)                    // 加载状态
```

### 5.2 路由导航

```typescript
// 跳转到添加页面
const handleAddProductCate = () => {
  router.push('/pms/addProductCate')
}

// 跳转到编辑页面（带参数）
const handleUpdate = (index: number, row: PmsProductCategory) => {
  router.push({ 
    path: '/pms/updateProductCate', 
    query: { id: row.id }   // URL参数：?id=xxx
  })
}

// 查看下级分类（更新URL参数）
const handleShowNextLevel = (index: number, row: PmsProductCategory) => {
  router.push({ 
    path: '/pms/productCate', 
    query: { parentId: row.id }  // URL参数：?parentId=xxx
  })
}
```

### 5.3 状态切换处理

```typescript
const handleNavStatusChange = async (index: number, row: PmsProductCategory) => {
  try {
    // 调用API更新状态
    await productCategoryUpdateNavStatusAPI({ 
      ids: [row.id!].join(','), 
      navStatus: row.navStatus 
    })
    ElMessage.success('修改成功')
  } catch (error) {
    // API调用失败，恢复原状态
    row.navStatus = row.navStatus === 1 ? 0 : 1
  }
}
```

### 5.4 删除确认

```typescript
const handleDelete = async (index: number, row: PmsProductCategory) => {
  try {
    // 显示确认对话框
    await ElMessageBox.confirm('是否要删除该分类', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 用户确认后执行删除
    await productCategoryDeleteByIdAPI(row.id!)
    ElMessage.success('删除成功')
    getList()  // 刷新列表
  } catch (error: any) {
    // 用户取消或删除失败
    if (error !== 'cancel') {
      console.error('删除失败:', error)
    }
  }
}
```

### 5.5 路由参数监听

```typescript
// 监听路由参数变化，用于处理浏览器后退/前进
watch(() => route.query, () => {
  resetParentId()
  getList()
})
```

## 6. 路由配置

在 `router/index.ts` 中添加路由：

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import Layout from '@/views/layout/Layout.vue'

const routes = [
  {
    path: '/pms',
    component: Layout,
    redirect: '/pms/product',
    name: 'pms',
    meta: { title: '商品', icon: 'product' },
    children: [
      {
        path: 'productCate',
        component: () => import('@/views/pms/productCate/index.vue'),
        name: 'productCate',
        meta: { title: '商品分类', icon: 'product-cate' }
      },
      {
        path: 'addProductCate',
        component: () => import('@/views/pms/productCate/add.vue'),
        name: 'addProductCate',
        meta: { title: '添加分类', icon: 'product-cate-add' }
      },
      {
        path: 'updateProductCate',
        component: () => import('@/views/pms/productCate/update.vue'),
        name: 'updateProductCate',
        meta: { title: '编辑分类', icon: 'product-cate-update' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
```

## 7. 面包屑导航

在页面中添加面包屑导航：

```vue
<template>
  <div class="app-container">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb-container">
      <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>商品</el-breadcrumb-item>
      <el-breadcrumb-item>商品分类</el-breadcrumb-item>
      <el-breadcrumb-item v-if="parentId !== 0">
        <el-button link @click="handleBackToTop">返回上级</el-button>
      </el-breadcrumb-item>
    </el-breadcrumb>
    
    <!-- 原有内容... -->
  </div>
</template>

<script setup>
// 返回上级分类
const handleBackToTop = () => {
  router.push('/pms/productCate')
}
</script>

<style scoped>
.breadcrumb-container {
  margin-bottom: 20px;
}
</style>
```

## 8. 实践练习

### 练习1：添加搜索功能

为商品分类列表添加按名称搜索的功能：

```vue
<script setup>
// 添加搜索关键词
const listQuery = ref({
  pageNum: 1,
  pageSize: 10,
  keyword: ''
})

// 搜索方法
const handleSearch = () => {
  listQuery.value.pageNum = 1
  getList()
}

// 重置搜索
const handleReset = () => {
  listQuery.value.keyword = ''
  listQuery.value.pageNum = 1
  getList()
}
</script>

<template>
  <div class="app-container">
    <!-- 搜索栏 -->
    <el-card class="filter-container" shadow="never">
      <div>
        <el-icon><Search /></el-icon>
        <span>筛选搜索</span>
        <el-button style="float: right" @click="handleSearch()" type="primary">
          查询结果
        </el-button>
        <el-button style="float: right; margin-right: 15px" @click="handleReset()">
          重置
        </el-button>
      </div>
      <div style="margin-top: 20px">
        <el-form :inline="true" :model="listQuery">
          <el-form-item label="输入搜索：">
            <el-input 
              style="width: 203px" 
              v-model="listQuery.keyword" 
              placeholder="分类名称"
            />
          </el-form-item>
        </el-form>
      </div>
    </el-card>
    
    <!-- 原有内容... -->
  </div>
</template>
```

### 练习2：添加批量操作

实现批量删除和批量修改状态功能：

```vue
<script setup>
// 选中的数据
const multipleSelection = ref([])

// 批量操作选项
const operates = [
  { label: '显示导航栏', value: 'showNav' },
  { label: '隐藏导航栏', value: 'hideNav' },
  { label: '显示分类', value: 'showCate' },
  { label: '隐藏分类', value: 'hideCate' },
  { label: '批量删除', value: 'delete' }
]
const operateType = ref('')

// 选择变化
const handleSelectionChange = (val) => {
  multipleSelection.value = val
}

// 批量操作
const handleBatchOperate = async () => {
  if (!operateType.value) {
    ElMessage.warning('请选择操作类型')
    return
  }
  if (multipleSelection.value.length === 0) {
    ElMessage.warning('请选择要操作的分类')
    return
  }
  
  const ids = multipleSelection.value.map(item => item.id).join(',')
  
  // 根据操作类型执行相应逻辑
  switch (operateType.value) {
    case 'showNav':
      await productCategoryUpdateNavStatusAPI({ ids, navStatus: 1 })
      break
    case 'hideNav':
      await productCategoryUpdateNavStatusAPI({ ids, navStatus: 0 })
      break
    // ... 其他操作
  }
  
  ElMessage.success('操作成功')
  getList()
}
</script>

<template>
  <div class="app-container">
    <!-- 原有内容... -->
    
    <!-- 批量操作栏 -->
    <div class="batch-operate-container">
      <el-select v-model="operateType" placeholder="批量操作" style="width: 150px">
        <el-option
          v-for="item in operates"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        />
      </el-select>
      <el-button
        style="margin-left: 20px"
        type="primary"
        @click="handleBatchOperate"
      >
        确定
      </el-button>
    </div>
  </div>
</template>
```

## 9. 常见问题

### Q1: 表格数据不更新怎么办？

确保数据是响应式的：

```typescript
// ✅ 正确：使用 ref
const list = ref([])
list.value = res.data.list

// ❌ 错误：直接赋值非响应式数据
let list = []
list = res.data.list  // 不会触发更新
```

### Q2: Switch 组件状态不同步？

确保 `:active-value` 和 `:inactive-value` 正确设置：

```vue
<el-switch 
  :active-value="1"    <!-- 开启时的值 -->
  :inactive-value="0"  <!-- 关闭时的值 -->
  v-model="scope.row.navStatus"
/>
```

### Q3: 分页组件不生效？

检查分页参数绑定：

```vue
<el-pagination 
  v-model:current-page="listQuery.pageNum"  <!-- 当前页 -->
  :page-size="listQuery.pageSize"             <!-- 每页条数 -->
  :total="total"                              <!-- 总条数 -->
  @current-change="handleCurrentChange"       <!-- 页码变化事件 -->
/>
```

## 10. 小结

本节我们完成了商品分类列表页面的开发：

1. **类型定义**：定义了商品分类的数据结构
2. **API封装**：封装了分类相关的所有接口
3. **列表展示**：使用 ElTable 展示分页数据
4. **状态切换**：实现了导航栏和显示状态的切换
5. **层级导航**：实现了查看下级分类功能
6. **CRUD操作**：实现了添加、编辑、删除功能

下一节将开发更复杂的商品列表页面，包含多条件搜索和筛选功能。

## 参考资源

- [Vue Router 文档](https://router.vuejs.org/)
- [Element Plus Table 组件](https://element-plus.org/zh-CN/component/table.html)
- [Element Plus Pagination 组件](https://element-plus.org/zh-CN/component/pagination.html)
