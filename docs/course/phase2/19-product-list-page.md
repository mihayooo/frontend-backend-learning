# 第19节：商品列表与搜索筛选

## 学习目标

- 掌握复杂搜索表单的实现
- 理解多条件筛选的数据绑定
- 学会使用级联选择器和远程搜索
- 掌握批量操作和状态管理

## 1. 页面功能分析

商品列表页面比分类列表更复杂，需要实现：

1. **多条件搜索**：商品名称、货号、分类、品牌、上下架状态、审核状态
2. **数据展示**：商品图片、名称、价格、标签、销量等
3. **状态管理**：上架/下架、新品、推荐的快速切换
4. **SKU管理**：弹出编辑SKU库存信息
5. **批量操作**：批量上架、下架、推荐、删除等

## 2. 类型定义

### 2.1 商品类型（types/product.d.ts）

```typescript
/** 商品信息 */
export type PmsProduct = {
  /** ID */
  id?: number
  /** 商品货号 */
  productSn?: string
  /** 品牌ID */
  brandId?: number
  /** 品牌名称 */
  brandName?: string
  /** 商品分类ID */
  productCategoryId?: number
  /** 商品分类名称 */
  productCategoryName?: string
  /** 商品属性分类ID */
  productAttributeCategoryId?: number
  /** 商品名称 */
  name?: string
  /** 商品图片 */
  pic?: string
  /** 商品相册 */
  albumPics?: string
  /** 商品详情 */
  detailHtml?: string
  /** 商品价格 */
  price?: number
  /** 市场价 */
  originalPrice?: number
  /** 库存 */
  stock?: number
  /** 库存预警值 */
  lowStock?: number
  /** 单位 */
  unit?: string
  /** 商品重量 */
  weight?: number
  /** 排序 */
  sort?: number
  /** 销量 */
  sale?: number
  /** 上架状态：0->下架；1->上架 */
  publishStatus?: number
  /** 新品状态:0->不是新品；1->新品 */
  newStatus?: number
  /** 推荐状态；0->不推荐；1->推荐 */
  recommandStatus?: number
  /** 审核状态：0->未审核；1->审核通过 */
  verifyStatus?: number
  /** 删除状态：0->未删除；1->已删除 */
  deleteStatus?: number
  /** 副标题 */
  subTitle?: string
  /** 商品描述 */
  description?: string
  /** 关键字 */
  keywords?: string
  /** 备注 */
  note?: string
}

/** 商品查询参数 */
export type ProductQueryParam = {
  /** 当前页码 */
  pageNum?: number
  /** 每页数量 */
  pageSize?: number
  /** 搜索关键词 */
  keyword?: string
  /** 商品货号 */
  productSn?: string
  /** 商品分类ID */
  productCategoryId?: number
  /** 品牌ID */
  brandId?: number
  /** 上架状态 */
  publishStatus?: number
  /** 审核状态 */
  verifyStatus?: number
}
```

### 2.2 SKU库存类型（types/skuStock.d.ts）

```typescript
/** SKU库存信息 */
export type PmsSkuStock = {
  /** ID */
  id?: number
  /** 商品ID */
  productId?: number
  /** SKU编码 */
  skuCode?: string
  /** 价格 */
  price?: number
  /** 库存 */
  stock?: number
  /** 预警库存 */
  lowStock?: number
  /** 销售属性（JSON格式） */
  spData?: string
  /** 锁定库存 */
  lockStock?: number
  /** 图片 */
  pic?: string
}
```

## 3. API 接口封装

### 3.1 商品 API（apis/product.ts）

```typescript
import type { CommonPage, PageParam } from '@/types/common'
import type { PmsProduct, ProductQueryParam } from '@/types/product'
import http from '@/utils/http'

/**
 * 分页查询商品列表
 */
export function getProductListAPI(params: ProductQueryParam) {
  return http<CommonResult<CommonPage<PmsProduct>>>({
    url: '/product/list',
    method: 'get',
    params
  })
}

/**
 * 批量修改删除状态
 */
export function productUpdateDeleteStatusAPI(params: { 
  ids: string
  deleteStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/product/update/deleteStatus',
    method: 'post',
    params
  })
}

/**
 * 批量修改新品状态
 */
export function productUpdateNewStatusAPI(params: { 
  ids: string
  newStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/product/update/newStatus',
    method: 'post',
    params
  })
}

/**
 * 批量修改推荐状态
 */
export function productUpdateRecommendStatusAPI(params: { 
  ids: string
  recommendStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/product/update/recommendStatus',
    method: 'post',
    params
  })
}

/**
 * 批量修改上架状态
 */
export function productUpdatePublishStatusAPI(params: { 
  ids: string
  publishStatus: number 
}) {
  return http<CommonResult<null>>({
    url: '/product/update/publishStatus',
    method: 'post',
    params
  })
}
```

### 3.2 SKU库存 API（apis/skuStock.ts）

```typescript
import type { PmsSkuStock } from '@/types/skuStock'
import http from '@/utils/http'

/**
 * 根据商品ID查询SKU库存
 */
export function getSkuListByPidAPI(productId: number, params?: { keyword?: string }) {
  return http<CommonResult<PmsSkuStock[]>>({
    url: '/skuStock/list/' + productId,
    method: 'get',
    params
  })
}

/**
 * 批量更新SKU库存
 */
export function skuUpdateByPidAPI(productId: number, skuStockList: PmsSkuStock[]) {
  return http<CommonResult<null>>({
    url: '/skuStock/update/' + productId,
    method: 'post',
    data: skuStockList
  })
}
```

## 4. 商品列表页面实现

### 4.1 完整代码（views/pms/product/index.vue）

```vue
<script setup lang="ts">
import { ref, onMounted, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Tickets, Edit } from '@element-plus/icons-vue'
import { getProductListAPI, productUpdateDeleteStatusAPI, productUpdateNewStatusAPI, productUpdateRecommendStatusAPI, productUpdatePublishStatusAPI } from '@/apis/product'
import { getSkuListByPidAPI, skuUpdateByPidAPI } from '@/apis/skuStock'
import { getBrandListAPI } from '@/apis/brand'
import { getProductCategoryListWithChildrenAPI } from '@/apis/productCate'
import type { PmsProduct, ProductQueryParam } from '@/types/product'
import type { PmsSkuStock } from '@/types/skuStock'

// ==================== 路由相关 ====================
const router = useRouter()

// ==================== 搜索筛选相关 ====================

// 列表查询参数
const listQuery = ref<ProductQueryParam>({
  pageNum: 1,
  pageSize: 10
})

// 品牌选项
const brandOptions = ref<{ label: string; value: string }[]>([])

// 商品分类选项（级联选择器用）
const productCateOptions = ref<{ label: string; value: number; children?: any[] }[]>([])

// 当前选中的商品分类（级联选择器值）
const selectProductCateValue = ref<number[]>([])

// 上架状态选项
const publishStatusOptions = ref([
  { value: 1, label: '上架' },
  { value: 0, label: '下架' }
])

// 审核状态选项
const verifyStatusOptions = ref([
  { value: 1, label: '审核通过' },
  { value: 0, label: '未审核' }
])

// 监听分类选择变化，更新查询参数
watch(selectProductCateValue, (newValue) => {
  if (newValue && newValue.length === 2) {
    listQuery.value.productCategoryId = newValue[1]
  } else {
    listQuery.value.productCategoryId = undefined
  }
}, { immediate: true })

// ==================== 列表数据相关 ====================

// 列表数据
const list = ref<PmsProduct[]>([])

// 总条数
const total = ref(0)

// 加载状态
const listLoading = ref(true)

// 选中的数据
const multipleSelection = ref<PmsProduct[]>([])

// ==================== 批量操作相关 ====================

// 批量操作选项
const operates = ref([
  { label: "商品上架", value: "publishOn" },
  { label: "商品下架", value: "publishOff" },
  { label: "设为推荐", value: "recommendOn" },
  { label: "取消推荐", value: "recommendOff" },
  { label: "设为新品", value: "newOn" },
  { label: "取消新品", value: "newOff" },
  { label: "移入回收站", value: "recycle" }
])

// 当前选中的批量操作
const operateType = ref<string>()

// ==================== SKU编辑相关 ====================

// SKU编辑弹框数据
const editSkuInfo = reactive({
  dialogVisible: false,
  productId: 0,
  productSn: '',
  productAttributeCategoryId: 0,
  stockList: [] as PmsSkuStock[],
  productAttr: [] as any[],
  keyword: ''
})

// ==================== 方法定义 ====================

/**
 * 获取列表数据
 */
const getList = async () => {
  listLoading.value = true
  try {
    const response = await getProductListAPI(listQuery.value)
    list.value = response.data.list
    total.value = response.data.total
  } catch (error) {
    console.error('获取商品列表失败:', error)
  } finally {
    listLoading.value = false
  }
}

/**
 * 获取品牌列表
 */
const getBrandList = async () => {
  try {
    const res = await getBrandListAPI({ pageNum: 1, pageSize: 100 })
    brandOptions.value = res.data.list.map(item => ({
      label: item.name!,
      value: item.id!.toString()
    }))
  } catch (error) {
    console.error('获取品牌列表失败:', error)
  }
}

/**
 * 获取商品分类列表
 */
const getProductCateList = async () => {
  try {
    const res = await getProductCategoryListWithChildrenAPI()
    productCateOptions.value = res.data.map(item => ({
      label: item.name!,
      value: item.id!,
      children: item.children?.map(child => ({
        label: child.name!,
        value: child.id!
      }))
    }))
  } catch (error) {
    console.error('获取分类列表失败:', error)
  }
}

/**
 * 搜索按钮
 */
const handleSearchList = () => {
  listQuery.value.pageNum = 1
  getList()
}

/**
 * 重置搜索
 */
const handleResetSearch = () => {
  selectProductCateValue.value = []
  listQuery.value = { pageNum: 1, pageSize: 10 }
  getList()
}

/**
 * 分页大小变化
 */
const handleSizeChange = (val: number) => {
  listQuery.value.pageNum = 1
  listQuery.value.pageSize = val
  getList()
}

/**
 * 当前页变化
 */
const handleCurrentChange = (val: number) => {
  listQuery.value.pageNum = val
  getList()
}

/**
 * 选择变化
 */
const handleSelectionChange = (val: PmsProduct[]) => {
  multipleSelection.value = val
}

/**
 * 添加上架状态变化
 */
const handlePublishStatusChange = async (index: number, row: PmsProduct) => {
  await updatePublishStatus(row.publishStatus!, [row.id!])
}

/**
 * 新品状态变化
 */
const handleNewStatusChange = async (index: number, row: PmsProduct) => {
  await updateNewStatus(row.newStatus!, [row.id!])
}

/**
 * 推荐状态变化
 */
const handleRecommendStatusChange = async (index: number, row: PmsProduct) => {
  await updateRecommendStatus(row.recommandStatus!, [row.id!])
}

/**
 * 更新上架状态
 */
const updatePublishStatus = async (publishStatus: number, ids: number[]) => {
  await productUpdatePublishStatusAPI({ 
    ids: ids.join(','), 
    publishStatus 
  })
  ElMessage.success('修改成功')
}

/**
 * 更新新品状态
 */
const updateNewStatus = async (newStatus: number, ids: number[]) => {
  await productUpdateNewStatusAPI({ 
    ids: ids.join(','), 
    newStatus 
  })
  ElMessage.success('修改成功')
}

/**
 * 更新推荐状态
 */
const updateRecommendStatus = async (recommendStatus: number, ids: number[]) => {
  await productUpdateRecommendStatusAPI({ 
    ids: ids.join(','), 
    recommendStatus 
  })
  ElMessage.success('修改成功')
}

/**
 * 更新删除状态
 */
const updateDeleteStatus = async (deleteStatus: number, ids: number[]) => {
  await productUpdateDeleteStatusAPI({ 
    ids: ids.join(','), 
    deleteStatus 
  })
  ElMessage.success('删除成功')
  getList()
}

/**
 * 批量操作
 */
const handleBatchOperate = async () => {
  if (!operateType.value) {
    ElMessage.warning('请选择操作类型')
    return
  }
  if (!multipleSelection.value || multipleSelection.value.length < 1) {
    ElMessage.warning('请选择要操作的商品')
    return
  }
  
  await ElMessageBox.confirm('是否要进行该批量操作?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  const ids = multipleSelection.value.map(item => item.id!)
  
  switch (operateType.value) {
    case 'publishOn':
      await updatePublishStatus(1, ids)
      break
    case 'publishOff':
      await updatePublishStatus(0, ids)
      break
    case 'recommendOn':
      await updateRecommendStatus(1, ids)
      break
    case 'recommendOff':
      await updateRecommendStatus(0, ids)
      break
    case 'newOn':
      await updateNewStatus(1, ids)
      break
    case 'newOff':
      await updateNewStatus(0, ids)
      break
    case 'recycle':
      await updateDeleteStatus(1, ids)
      break
  }
  
  getList()
}

/**
 * 添加商品
 */
const handleAddProduct = () => {
  router.push({ path: '/pms/addProduct' })
}

/**
 * 编辑商品
 */
const handleUpdateProduct = (index: number, row: PmsProduct) => {
  router.push({ path: '/pms/updateProduct', query: { id: row.id } })
}

/**
 * 删除商品
 */
const handleDelete = async (index: number, row: PmsProduct) => {
  await updateDeleteStatus(1, [row.id!])
}

// ==================== SKU编辑相关方法 ====================

/**
 * 显示SKU编辑弹框
 */
const handleShowSkuEditDialog = async (index: number, row: PmsProduct) => {
  editSkuInfo.dialogVisible = true
  editSkuInfo.productId = row.id!
  editSkuInfo.productSn = row.productSn || ''
  editSkuInfo.productAttributeCategoryId = row.productAttributeCategoryId || 0
  editSkuInfo.keyword = ''
  
  // 获取SKU列表
  const resp = await getSkuListByPidAPI(row.id!)
  editSkuInfo.stockList = resp.data
  
  // 获取商品属性（用于显示规格列）
  if (row.productAttributeCategoryId) {
    // TODO: 获取属性列表
  }
}

/**
 * 搜索SKU
 */
const handleSearchEditSku = async () => {
  const response = await getSkuListByPidAPI(
    editSkuInfo.productId, 
    { keyword: editSkuInfo.keyword }
  )
  editSkuInfo.stockList = response.data
}

/**
 * 确认编辑SKU
 */
const handleEditSkuConfirm = async () => {
  if (!editSkuInfo.stockList || editSkuInfo.stockList.length <= 0) {
    ElMessage.warning('暂无SKU信息')
    return
  }
  
  await ElMessageBox.confirm('是否要进行修改', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  await skuUpdateByPidAPI(editSkuInfo.productId, editSkuInfo.stockList)
  ElMessage.success('修改成功')
  editSkuInfo.dialogVisible = false
}

// ==================== 过滤器 ====================

/**
 * 审核状态过滤器
 */
const verifyStatusFilter = (value?: number) => {
  return value === 1 ? '审核通过' : '未审核'
}

// ==================== 生命周期 ====================

onMounted(() => {
  getList()
  getBrandList()
  getProductCateList()
})
</script>

<template>
  <div class="app-container">
    <!-- 搜索筛选区域 -->
    <el-card class="filter-container" shadow="never">
      <div>
        <el-icon class="el-icon-middle">
          <Search />
        </el-icon>
        <span>筛选搜索</span>
        <el-button style="float: right" @click="handleSearchList()" type="primary">
          查询结果
        </el-button>
        <el-button style="float: right; margin-right: 15px" @click="handleResetSearch()">
          重置
        </el-button>
      </div>
      <div style="margin-top: 20px">
        <el-form :inline="true" :model="listQuery" label-width="140px">
          <!-- 商品名称搜索 -->
          <el-form-item label="输入搜索：">
            <el-input 
              style="width: 203px" 
              v-model="listQuery.keyword" 
              placeholder="商品名称"
            />
          </el-form-item>
          
          <!-- 商品货号搜索 -->
          <el-form-item label="商品货号：">
            <el-input 
              style="width: 203px" 
              v-model="listQuery.productSn" 
              placeholder="商品货号"
            />
          </el-form-item>
          
          <!-- 商品分类筛选 -->
          <el-form-item label="商品分类：">
            <el-cascader 
              clearable 
              v-model="selectProductCateValue" 
              :options="productCateOptions"
              placeholder="请选择分类"
            />
          </el-form-item>
          
          <!-- 品牌筛选 -->
          <el-form-item label="商品品牌：">
            <el-select 
              v-model="listQuery.brandId" 
              placeholder="请选择品牌" 
              clearable 
              style="width: 203px;"
            >
              <el-option 
                v-for="item in brandOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
          
          <!-- 上架状态筛选 -->
          <el-form-item label="上架状态：">
            <el-select 
              v-model="listQuery.publishStatus" 
              placeholder="全部" 
              clearable 
              style="width: 203px;"
            >
              <el-option 
                v-for="item in publishStatusOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
          
          <!-- 审核状态筛选 -->
          <el-form-item label="审核状态：">
            <el-select 
              v-model="listQuery.verifyStatus" 
              placeholder="全部" 
              clearable 
              style="width: 203px;"
            >
              <el-option 
                v-for="item in verifyStatusOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
    </el-card>

    <!-- 操作栏 -->
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>数据列表</span>
      <el-button class="btn-add" @click="handleAddProduct()">
        添加
      </el-button>
    </el-card>

    <!-- 数据表格 -->
    <div class="table-container">
      <el-table 
        ref="productTable" 
        :data="list" 
        style="width: 100%" 
        @selection-change="handleSelectionChange"
        v-loading="listLoading" 
        border
      >
        <!-- 多选列 -->
        <el-table-column type="selection" width="60" align="center" />
        
        <!-- 编号列 -->
        <el-table-column label="编号" width="100" align="center">
          <template #default="scope">{{ scope.row.id }}</template>
        </el-table-column>
        
        <!-- 商品图片列 -->
        <el-table-column label="商品图片" width="120" align="center">
          <template #default="scope">
            <img style="height: 80px" :src="scope.row.pic" />
          </template>
        </el-table-column>
        
        <!-- 商品名称列 -->
        <el-table-column label="商品名称" align="center">
          <template #default="scope">
            <p>{{ scope.row.name }}</p>
            <p>品牌：{{ scope.row.brandName }}</p>
          </template>
        </el-table-column>
        
        <!-- 价格/货号列 -->
        <el-table-column label="价格/货号" width="120" align="center">
          <template #default="scope">
            <p>价格：￥{{ scope.row.price }}</p>
            <p>货号：{{ scope.row.productSn }}</p>
          </template>
        </el-table-column>
        
        <!-- 标签列 -->
        <el-table-column label="标签" width="140" align="center">
          <template #default="scope">
            <p style="margin: 6px 0px;">
              上架：
              <el-switch 
                @change="handlePublishStatusChange(scope.$index, scope.row)" 
                :active-value="1"
                :inactive-value="0" 
                v-model="scope.row.publishStatus"
              />
            </p>
            <p style="margin: 6px 0px;">
              新品：
              <el-switch 
                @change="handleNewStatusChange(scope.$index, scope.row)" 
                :active-value="1" 
                :inactive-value="0"
                v-model="scope.row.newStatus"
              />
            </p>
            <p style="margin: 6px 0px;">
              推荐：
              <el-switch 
                @change="handleRecommendStatusChange(scope.$index, scope.row)" 
                :active-value="1"
                :inactive-value="0" 
                v-model="scope.row.recommandStatus"
              />
            </p>
          </template>
        </el-table-column>
        
        <!-- 排序列 -->
        <el-table-column label="排序" width="100" align="center">
          <template #default="scope">{{ scope.row.sort }}</template>
        </el-table-column>
        
        <!-- SKU库存列 -->
        <el-table-column label="SKU库存" width="100" align="center">
          <template #default="scope">
            <el-button 
              type="primary" 
              :icon="Edit" 
              size="large"
              @click="handleShowSkuEditDialog(scope.$index, scope.row)" 
              circle
            />
          </template>
        </el-table-column>
        
        <!-- 销量列 -->
        <el-table-column label="销量" width="100" align="center">
          <template #default="scope">{{ scope.row.sale }}</template>
        </el-table-column>
        
        <!-- 审核状态列 -->
        <el-table-column label="审核状态" width="100" align="center">
          <template #default="scope">
            <p>{{ verifyStatusFilter(scope.row.verifyStatus) }}</p>
          </template>
        </el-table-column>
        
        <!-- 操作列 -->
        <el-table-column label="操作" width="160" align="center">
          <template #default="scope">
            <p>
              <el-button size="small" @click="handleUpdateProduct(scope.$index, scope.row)">
                编辑
              </el-button>
            </p>
            <p>
              <el-button size="small" type="danger" @click="handleDelete(scope.$index, scope.row)">
                删除
              </el-button>
            </p>
          </template>
        </el-table-column>
      </el-table>
    </div>

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
        class="search-button" 
        @click="handleBatchOperate()" 
        type="primary"
      >
        确定
      </el-button>
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

    <!-- SKU编辑弹框 -->
    <el-dialog title="编辑货品信息" v-model="editSkuInfo.dialogVisible" width="60%">
      <div>
        <span>商品货号：{{ editSkuInfo.productSn }}</span>
        <el-input 
          placeholder="按sku编号搜索" 
          v-model="editSkuInfo.keyword" 
          style="width: 60%; margin-left: 20px"
        >
          <template #append>
            <el-button :icon="Search" @click="handleSearchEditSku" />
          </template>
        </el-input>
      </div>
      
      <el-table style="width: 100%; margin-top: 20px" :data="editSkuInfo.stockList" border>
        <el-table-column label="SKU编号" align="center">
          <template #default="scope">
            <el-input v-model="scope.row.skuCode" />
          </template>
        </el-table-column>
        <el-table-column label="销售价格" width="100" align="center">
          <template #default="scope">
            <el-input v-model="scope.row.price" />
          </template>
        </el-table-column>
        <el-table-column label="商品库存" width="100" align="center">
          <template #default="scope">
            <el-input v-model="scope.row.stock" />
          </template>
        </el-table-column>
        <el-table-column label="库存预警值" width="100" align="center">
          <template #default="scope">
            <el-input v-model="scope.row.lowStock" />
          </template>
        </el-table-column>
      </el-table>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="editSkuInfo.dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="handleEditSkuConfirm">确 定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.filter-container {
  margin-bottom: 20px;
}

.operate-container {
  margin-bottom: 20px;
}

.operate-container .btn-add {
  float: right;
}

.table-container {
  margin-bottom: 20px;
}

.batch-operate-container {
  margin-top: 20px;
  margin-bottom: 20px;
}

.pagination-container {
  text-align: right;
}
</style>
```

## 5. 代码详解

### 5.1 多条件搜索实现

```typescript
// 查询参数类型
const listQuery = ref<ProductQueryParam>({
  pageNum: 1,
  pageSize: 10,
  keyword: undefined,           // 商品名称
  productSn: undefined,         // 商品货号
  productCategoryId: undefined, // 分类ID
  brandId: undefined,           // 品牌ID
  publishStatus: undefined,     // 上架状态
  verifyStatus: undefined       // 审核状态
})

// 级联选择器处理
const selectProductCateValue = ref<number[]>([])

watch(selectProductCateValue, (newValue) => {
  if (newValue && newValue.length === 2) {
    // 取最后一级分类ID
    listQuery.value.productCategoryId = newValue[1]
  } else {
    listQuery.value.productCategoryId = undefined
  }
}, { immediate: true })
```

### 5.2 批量操作实现

```typescript
// 批量操作选项
const operates = ref([
  { label: "商品上架", value: "publishOn" },
  { label: "商品下架", value: "publishOff" },
  { label: "设为推荐", value: "recommendOn" },
  { label: "取消推荐", value: "recommendOff" },
  { label: "设为新品", value: "newOn" },
  { label: "取消新品", value: "newOff" },
  { label: "移入回收站", value: "recycle" }
])

const handleBatchOperate = async () => {
  // 1. 验证是否选择了操作类型
  // 2. 验证是否选择了数据
  // 3. 弹出确认框
  // 4. 根据操作类型调用不同API
  // 5. 刷新列表
}
```

### 5.3 SKU编辑弹框

```typescript
// SKU编辑弹框数据
const editSkuInfo = reactive({
  dialogVisible: false,
  productId: 0,
  productSn: '',
  stockList: [] as PmsSkuStock[],
  keyword: ''
})

// 显示弹框并加载数据
const handleShowSkuEditDialog = async (index: number, row: PmsProduct) => {
  editSkuInfo.dialogVisible = true
  editSkuInfo.productId = row.id!
  editSkuInfo.productSn = row.productSn || ''
  
  // 获取SKU列表
  const resp = await getSkuListByPidAPI(row.id!)
  editSkuInfo.stockList = resp.data
}

// 保存SKU修改
const handleEditSkuConfirm = async () => {
  await skuUpdateByPidAPI(editSkuInfo.productId, editSkuInfo.stockList)
  ElMessage.success('修改成功')
  editSkuInfo.dialogVisible = false
}
```

## 6. 小结

本节我们完成了商品列表页面的开发：

1. **多条件搜索**：实现了商品名称、货号、分类、品牌、状态的组合筛选
2. **级联选择器**：使用 Cascader 组件实现二级分类选择
3. **状态切换**：实现了上架、新品、推荐状态的快速切换
4. **批量操作**：实现了批量修改状态和删除功能
5. **SKU编辑**：实现了弹出式SKU库存编辑功能

下一节将开发最复杂的商品发布表单页面。

## 参考资源

- [Element Plus Form 组件](https://element-plus.org/zh-CN/component/form.html)
- [Element Plus Cascader 组件](https://element-plus.org/zh-CN/component/cascader.html)
- [Element Plus Dialog 组件](https://element-plus.org/zh-CN/component/dialog.html)
