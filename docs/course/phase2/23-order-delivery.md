# 第23节 订单发货功能实现

## 学习目标

- 掌握批量发货页面的设计与实现
- 学习使用 Pinia Store 进行跨页面数据传递
- 实现发货信息的填写与提交
- 掌握物流公司的选择与物流单号管理

## 功能概述

订单发货是电商系统的核心功能之一，主要包括：

1. **批量选择待发货订单** - 从订单列表中选择多个待发货订单
2. **发货页面** - 填写物流公司和物流单号
3. **批量发货提交** - 一次性提交多个订单的发货信息
4. **状态更新** - 发货成功后订单状态变为"已发货"

## 完整代码实现

### 1. 订单 Store (stores/order.ts)

使用 Pinia 管理待发货订单列表，实现跨页面数据传递：

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { OmsOrder } from '@/types/order'

export const useOrderStore = defineStore('order', () => {
  // 待发货订单列表
  const deliverOrderList = ref<OmsOrder[]>([])

  // 设置待发货订单列表
  const setDeliverOrderList = (list: OmsOrder[]) => {
    deliverOrderList.value = list
  }

  return {
    deliverOrderList,
    setDeliverOrderList
  }
})
```

### 2. 批量发货页面 (deliverOrderList.vue)

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Tickets } from '@element-plus/icons-vue'
import { orderUpdateDeliveryAPI } from '@/apis/order'
import type { OmsOrder, OmsOrderDeliveryParam } from '@/types/order'
import { useOrderStore } from '@/stores/order'

// 获取路由对象
const router = useRouter()
// 获取订单store
const orderStore = useOrderStore()

// 默认物流公司选项
const defaultLogisticsCompanies = ["顺丰快递", "圆通快递", "中通快递", "韵达快递"]

// 发货订单列表数据
const list = ref<OmsOrder[]>([])
// 物流公司选项
const companyOptions = ref<string[]>(defaultLogisticsCompanies)

// 根据订单对象获取详细地址
const fortmatAddress = (order: OmsOrder) => {
  return order.receiverProvince + order.receiverCity + order.receiverRegion + order.receiverDetailAddress
}

// 组件挂载后初始化数据
onMounted(() => {
  // 从store中获取待发货订单列表
  list.value = orderStore.deliverOrderList
  // 清空store中的数据
  orderStore.setDeliverOrderList([])
})

// 取消操作
const cancel = () => {
  router.back()
}

// 确认发货操作
const confirm = async () => {
  try {
    await ElMessageBox.confirm('是否要进行发货操作?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 构建发货参数列表
    const deliveryParamList: OmsOrderDeliveryParam[] = list.value.map(item => ({
      orderId: item.id,
      deliverySn: item.orderSn,
      deliveryCompany: item.deliveryCompany
    }))
    
    // 调用发货API
    await orderUpdateDeliveryAPI(deliveryParamList)
    
    router.back()
    ElMessage({
      type: 'success',
      message: '发货成功!'
    })
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage({
        type: 'info',
        message: '已取消发货'
      })
    }
  }
}
</script>

<template>
  <div class="app-container">
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>发货列表</span>
    </el-card>
    
    <div class="table-container">
      <el-table ref="deliverOrderTable" style="width: 100%;" :data="list" border>
        <el-table-column label="订单编号" width="180" align="center">
          <template #default="scope">{{ scope.row.orderSn }}</template>
        </el-table-column>
        <el-table-column label="收货人" width="150" align="center">
          <template #default="scope">{{ scope.row.receiverName }}</template>
        </el-table-column>
        <el-table-column label="手机号码" width="160" align="center">
          <template #default="scope">{{ scope.row.receiverPhone }}</template>
        </el-table-column>
        <el-table-column label="邮政编码" width="160" align="center">
          <template #default="scope">{{ scope.row.receiverPostCode }}</template>
        </el-table-column>
        <el-table-column label="收货地址" align="center">
          <template #default="scope">{{ fortmatAddress(scope.row) }}</template>
        </el-table-column>
        <el-table-column label="配送方式" width="200" align="center">
          <template #default="scope">
            <el-select placeholder="请选择物流公司" v-model="scope.row.deliveryCompany">
              <el-option 
                v-for="item in companyOptions" 
                :key="item" 
                :label="item" 
                :value="item"
              />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="物流单号" width="180" align="center">
          <template #default="scope">
            <el-input v-model="scope.row.deliverySn" placeholder="请输入物流单号" />
          </template>
        </el-table-column>
      </el-table>
      
      <div style="margin-top: 15px;text-align: center">
        <el-button @click="cancel">取消</el-button>
        <el-button @click="confirm" type="primary">确定</el-button>
      </div>
    </div>
  </div>
</template>
```

### 3. 订单列表页面中的发货按钮

在订单列表页面添加批量发货功能：

```vue
<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useOrderStore } from '@/stores/order'
import { ElMessage } from 'element-plus'
import type { OmsOrder } from '@/types/order'

const router = useRouter()
const orderStore = useOrderStore()

// 多选数据
const multipleSelection = ref<OmsOrder[]>([])

// 处理选择变化
const handleSelectionChange = (val: OmsOrder[]) => {
  multipleSelection.value = val
}

// 批量发货
const handleBatchDeliver = () => {
  // 筛选出待发货的订单
  const deliverList = multipleSelection.value.filter(item => item.status === 1)
  
  if (deliverList.length === 0) {
    ElMessage.warning('请选择待发货的订单')
    return
  }
  
  // 将待发货订单存入store
  orderStore.setDeliverOrderList(deliverList)
  
  // 跳转到发货页面
  router.push({ path: '/oms/deliverOrderList' })
}
</script>

<template>
  <el-table 
    ref="orderTable" 
    :data="list" 
    @selection-change="handleSelectionChange"
    border
  >
    <el-table-column type="selection" width="60" align="center" />
    <!-- 其他列... -->
  </el-table>
  
  <!-- 批量操作区域 -->
  <div class="batch-operate-container">
    <el-select v-model="operateType" placeholder="批量操作">
      <el-option label="批量发货" :value="1" />
      <el-option label="批量关闭" :value="2" />
      <el-option label="批量删除" :value="3" />
    </el-select>
    <el-button type="primary" @click="handleBatchOperate">确定</el-button>
  </div>
</template>
```

## 关键技术点

### 1. Pinia Store 状态管理

使用 Pinia 实现跨页面数据传递：

```typescript
// stores/order.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useOrderStore = defineStore('order', () => {
  const deliverOrderList = ref<OmsOrder[]>([])
  
  const setDeliverOrderList = (list: OmsOrder[]) => {
    deliverOrderList.value = list
  }
  
  return { deliverOrderList, setDeliverOrderList }
})
```

**使用步骤：**
1. 在订单列表页面选择订单并存入store
2. 跳转到发货页面
3. 发货页面从store读取数据
4. 发货完成后清空store数据

### 2. 表格行内编辑

在表格中直接编辑物流信息：

```vue
<el-table :data="list" border>
  <el-table-column label="配送方式" width="200" align="center">
    <template #default="scope">
      <el-select v-model="scope.row.deliveryCompany">
        <el-option 
          v-for="item in companyOptions" 
          :key="item" 
          :label="item" 
          :value="item"
        />
      </el-select>
    </template>
  </el-table-column>
  <el-table-column label="物流单号" width="180" align="center">
    <template #default="scope">
      <el-input v-model="scope.row.deliverySn" />
    </template>
  </el-table-column>
</el-table>
```

### 3. 批量操作确认

使用 `ElMessageBox` 进行批量操作确认：

```typescript
const confirm = async () => {
  await ElMessageBox.confirm('是否要进行发货操作?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  // 构建发货参数
  const deliveryParamList = list.value.map(item => ({
    orderId: item.id,
    deliverySn: item.orderSn,
    deliveryCompany: item.deliveryCompany
  }))
  
  await orderUpdateDeliveryAPI(deliveryParamList)
  ElMessage.success('发货成功!')
}
```

### 4. 路由跳转与返回

```typescript
// 跳转到发货页面
router.push({ path: '/oms/deliverOrderList' })

// 返回上一页
router.back()
```

## 发货流程图

```
订单列表页面
    │
    ├─ 选择待发货订单（status === 1）
    │
    ├─ 点击"批量发货"按钮
    │
    ├─ 将选中订单存入 Pinia Store
    │
    └─ 跳转到发货页面
              │
              ├─ 从 Store 读取订单列表
              │
              ├─ 填写物流公司和物流单号
              │
              ├─ 点击"确定"按钮
              │
              ├─ 确认对话框
              │
              ├─ 调用发货API
              │
              ├─ 返回订单列表
              │
              └─ 清空 Store 数据
```

## 小结

本节我们学习了：

1. **Pinia Store 的使用** - 实现跨页面数据传递
2. **批量发货页面设计** - 表格行内编辑物流信息
3. **批量操作确认** - 使用 ElMessageBox 进行二次确认
4. **路由跳转** - 页面间的导航与返回

下一节我们将学习退货申请处理功能的实现。
