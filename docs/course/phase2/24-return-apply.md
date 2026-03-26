# 第24节 退货申请处理

## 学习目标

- 掌握退货申请列表页面的开发
- 学习退货状态的管理与展示
- 实现退货申请的查看与处理
- 掌握退款金额的计算

## 功能概述

退货申请处理是售后服务的重要环节，主要包括：

1. **退货申请列表** - 展示所有退货申请记录
2. **状态筛选** - 按处理状态筛选（待处理、退货中、已完成、已拒绝）
3. **申请详情** - 查看退货申请的详细信息
4. **处理操作** - 同意/拒绝退货申请

## 完整代码实现

### 1. 退货申请列表页面 (apply/index.vue)

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Tickets } from '@element-plus/icons-vue'
import { formatDateTime } from '@/utils/datetime'
import { getReturnApplyListAPI, returnApplyDeleteByIdsAPI } from '@/apis/returnApply'
import type { OmsOrderReturnApply, ReturnApplyQueryParam } from '@/types/returnApply'

// 获取路由对象
const router = useRouter()

// 默认处理状态选项
const defaultStatusOptions = [
  { label: '待处理', value: 0 },
  { label: '退货中', value: 1 },
  { label: '已完成', value: 2 },
  { label: '已拒绝', value: 3 }
]

// 列表查询参数
const listQuery = ref<ReturnApplyQueryParam>({
  pageNum: 1,
  pageSize: 10
})

// 状态选项
const statusOptions = ref(Object.assign({}, defaultStatusOptions))
// 列表数据
const list = ref<OmsOrderReturnApply[]>([])
// 总数
const total = ref(0)
// 加载状态
const listLoading = ref(false)
// 多选数据
const multipleSelection = ref<OmsOrderReturnApply[]>([])

// 获取列表
const getList = async () => {
  listLoading.value = true
  const res = await getReturnApplyListAPI(listQuery.value)
  listLoading.value = false
  list.value = res.data.list
  total.value = res.data.total
}

// 组件挂载后获取列表
onMounted(() => {
  getList()
})

// 操作类型
const operateType = ref<number>()
// 操作选项
const operateOptions = ref([
  { label: "批量删除", value: 1 }
])

// 格式化状态
const formatStatus = (status: number) => {
  return defaultStatusOptions.find(item => item.value === status)?.label
}

// 格式化退款金额
const formatReturnAmount = (row: OmsOrderReturnApply) => {
  return row.productRealPrice * row.productCount
}

// 处理选择变化
const handleSelectionChange = (val: OmsOrderReturnApply[]) => {
  multipleSelection.value = val
}

// 重置搜索
const handleResetSearch = () => {
  listQuery.value = { pageNum: 1, pageSize: 10 }
}

// 搜索列表
const handleSearchList = () => {
  listQuery.value.pageNum = 1
  getList()
}

// 查看详情
const handleViewDetail = (index: number, row: OmsOrderReturnApply) => {
  router.push({ path: '/oms/returnApplyDetail', query: { id: row.id } })
}

// 批量操作
const handleBatchOperate = async () => {
  if (!multipleSelection.value || multipleSelection.value.length < 1) {
    ElMessage.warning('请选择要操作的申请')
    return
  }
  
  if (operateType.value === 1) {
    // 批量删除
    await ElMessageBox.confirm('是否要进行删除操作?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await returnApplyDeleteByIdsAPI({ 
      ids: multipleSelection.value.map(item => item.id).join(',') 
    })
    getList()
    ElMessage.success('删除成功!')
  }
}

// 处理每页大小变化
const handleSizeChange = (val: number) => {
  listQuery.value.pageNum = 1
  listQuery.value.pageSize = val
  getList()
}

// 处理当前页变化
const handleCurrentChange = (val: number) => {
  listQuery.value.pageNum = val
  getList()
}
</script>

<template>
  <div class="app-container">
    <!-- 搜索区域 -->
    <el-card class="filter-container" shadow="never">
      <div>
        <el-icon class="el-icon-middle">
          <Search />
        </el-icon>
        <span>筛选搜索</span>
        <el-button style="float:right" type="primary" @click="handleSearchList()">
          查询搜索
        </el-button>
        <el-button style="float:right;margin-right: 15px" @click="handleResetSearch()">
          重置
        </el-button>
      </div>
      <div style="margin-top: 20px">
        <el-form :inline="true" :model="listQuery" label-width="140px">
          <el-form-item label="输入搜索：">
            <el-input 
              v-model="listQuery.id" 
              class="input-width" 
              placeholder="服务单号"
            />
          </el-form-item>
          <el-form-item label="处理状态：">
            <el-select 
              v-model="listQuery.status" 
              placeholder="全部" 
              clearable 
              class="input-width"
            >
              <el-option 
                v-for="item in statusOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="申请时间：">
            <el-date-picker 
              class="input-width" 
              v-model="listQuery.createTime" 
              value-format="YYYY-MM-DD" 
              type="date"
              placeholder="请选择时间"
            />
          </el-form-item>
          <el-form-item label="操作人员：">
            <el-input 
              v-model="listQuery.handleMan" 
              class="input-width" 
              placeholder="全部"
            />
          </el-form-item>
          <el-form-item label="处理时间：">
            <el-date-picker 
              class="input-width" 
              v-model="listQuery.handleTime" 
              value-format="YYYY-MM-DD" 
              type="date"
              placeholder="请选择时间"
            />
          </el-form-item>
        </el-form>
      </div>
    </el-card>
    
    <!-- 列表区域 -->
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>数据列表</span>
    </el-card>
    
    <div class="table-container">
      <el-table 
        ref="returnApplyTable" 
        :data="list" 
        style="width: 100%;" 
        @selection-change="handleSelectionChange"
        v-loading="listLoading" 
        border
      >
        <el-table-column type="selection" width="60" align="center" />
        <el-table-column label="服务单号" width="180" align="center">
          <template #default="scope">{{ scope.row.id }}</template>
        </el-table-column>
        <el-table-column label="申请时间" width="180" align="center">
          <template #default="scope">{{ formatDateTime(scope.row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="用户账号" align="center">
          <template #default="scope">{{ scope.row.memberUsername }}</template>
        </el-table-column>
        <el-table-column label="退款金额" width="180" align="center">
          <template #default="scope">￥{{ formatReturnAmount(scope.row) }}</template>
        </el-table-column>
        <el-table-column label="申请状态" width="180" align="center">
          <template #default="scope">
            <el-tag :type="scope.row.status === 0 ? 'warning' : scope.row.status === 2 ? 'success' : 'info'">
              {{ formatStatus(scope.row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="处理时间" width="180" align="center">
          <template #default="scope">{{ formatDateTime(scope.row.handleTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template #default="scope">
            <el-button size="small" @click="handleViewDetail(scope.$index, scope.row)">
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>
    
    <!-- 批量操作 -->
    <div class="batch-operate-container">
      <el-select v-model="operateType" placeholder="批量操作">
        <el-option 
          v-for="item in operateOptions" 
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
    
    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination 
        background 
        @size-change="handleSizeChange" 
        @current-change="handleCurrentChange"
        layout="total, sizes,prev, pager, next,jumper" 
        v-model:current-page="listQuery.pageNum"
        :page-size="listQuery.pageSize" 
        :page-sizes="[5, 10, 15]" 
        :total="total"
      />
    </div>
  </div>
</template>

<style scoped>
.input-width {
  width: 203px
}
</style>
```

## 关键技术点

### 1. 状态标签展示

使用 Element Plus 的 Tag 组件展示不同状态：

```vue
<el-tag :type="scope.row.status === 0 ? 'warning' : scope.row.status === 2 ? 'success' : 'info'">
  {{ formatStatus(scope.row.status) }}
</el-tag>
```

**Tag 类型对应颜色：**
- `warning` - 黄色（待处理）
- `success` - 绿色（已完成）
- `info` - 灰色（已拒绝）
- `danger` - 红色（退货中）

### 2. 退款金额计算

```typescript
const formatReturnAmount = (row: OmsOrderReturnApply) => {
  return row.productRealPrice * row.productCount
}
```

### 3. 日期范围搜索

```vue
<el-form-item label="申请时间：">
  <el-date-picker 
    v-model="listQuery.createTime" 
    value-format="YYYY-MM-DD" 
    type="date"
    placeholder="请选择时间"
  />
</el-form-item>
```

### 4. 状态筛选

```vue
<el-select v-model="listQuery.status" placeholder="全部" clearable>
  <el-option 
    v-for="item in statusOptions" 
    :key="item.value" 
    :label="item.label" 
    :value="item.value"
  />
</el-select>
```

## 退货状态流转

```
┌─────────┐    用户申请     ┌─────────┐
│  初始   │ ──────────────→ │ 待处理  │
└─────────┘                 └────┬────┘
                                 │
                    ┌────────────┼────────────┐
                    ↓            ↓            ↓
               ┌────────┐   ┌────────┐   ┌────────┐
               │ 退货中 │   │ 已完成 │   │ 已拒绝 │
               │(同意)  │   │(确认收 │   │(拒绝)  │
               │        │   │  货)   │   │        │
               └────────┘   └────────┘   └────────┘
```

## 小结

本节我们学习了：

1. **退货申请列表页面** - 展示所有退货申请记录
2. **状态管理** - 使用 Tag 组件展示不同处理状态
3. **退款金额计算** - 根据商品价格和数量计算退款金额
4. **多条件搜索** - 支持按状态、时间、操作人等条件筛选

下一节我们将学习订单设置功能的实现。
