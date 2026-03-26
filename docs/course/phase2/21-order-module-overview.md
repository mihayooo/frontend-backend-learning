# 第21节：订单模块概述与订单列表页面

## 学习目标

- 理解电商订单模块的业务流程
- 掌握订单状态流转和管理
- 学会订单列表的多条件搜索实现
- 理解批量操作的设计思路

## 1. 订单模块业务概述

### 1.1 订单生命周期

电商订单从创建到完成经历多个状态：

```
待付款 → 待发货 → 已发货 → 已完成
   ↓        ↓         ↓
已关闭   订单跟踪   退货申请
```

**订单状态说明：**

| 状态码 | 状态名称 | 说明 |
|--------|----------|------|
| 0 | 待付款 | 用户已下单但未支付 |
| 1 | 待发货 | 用户已支付，等待商家发货 |
| 2 | 已发货 | 商家已发货，等待用户收货 |
| 3 | 已完成 | 用户已确认收货，订单完成 |
| 4 | 已关闭 | 订单被取消或超时关闭 |
| 5 | 无效订单 | 异常订单标记 |

### 1.2 订单模块功能清单

订单模块包含以下核心功能：

1. **订单列表**：分页展示、多条件搜索、批量操作
2. **订单详情**：订单信息、商品信息、收货信息、操作记录
3. **订单发货**：批量发货、物流信息录入
4. **订单关闭**：关闭未支付订单
5. **订单跟踪**：查看物流信息
6. **退货处理**：退货申请审核

## 2. 类型定义

### 2.1 订单类型（types/order.d.ts）

```typescript
import type { PageParam } from './common'

/** 订单信息 */
export type OmsOrder = {
  /** 订单id */
  id: number
  /** 会员id */
  memberId?: number
  /** 优惠券id */
  couponId?: number
  /** 订单编号 */
  orderSn?: string
  /** 提交时间 */
  createTime: string
  /** 用户帐号 */
  memberUsername?: string
  /** 订单总金额 */
  totalAmount: number
  /** 应付金额（实际支付金额） */
  payAmount: number
  /** 运费金额 */
  freightAmount: number
  /** 促销优化金额 */
  promotionAmount?: number
  /** 积分抵扣金额 */
  integrationAmount?: number
  /** 优惠券抵扣金额 */
  couponAmount?: number
  /** 管理员后台调整订单使用的折扣金额 */
  discountAmount: number
  /** 支付方式：0->未支付；1->支付宝；2->微信 */
  payType: number
  /** 订单来源：0->PC订单；1->app订单 */
  sourceType: number
  /** 订单状态：0->待付款；1->待发货；2->已发货；3->已完成；4->已关闭；5->无效订单 */
  status: number
  /** 订单类型：0->正常订单；1->秒杀订单 */
  orderType: number
  /** 物流公司(配送方式) */
  deliveryCompany?: string
  /** 物流单号 */
  deliverySn?: string
  /** 自动确认时间（天） */
  autoConfirmDay?: number
  /** 可以获得的积分 */
  integration?: number
  /** 可以活动的成长值 */
  growth?: number
  /** 活动信息 */
  promotionInfo: string
  /** 发票类型：0->不开发票；1->电子发票；2->纸质发票 */
  billType?: number
  /** 发票抬头 */
  billHeader?: string
  /** 发票内容 */
  billContent?: string
  /** 收票人电话 */
  billReceiverPhone?: string
  /** 收票人邮箱 */
  billReceiverEmail?: string
  /** 收货人姓名 */
  receiverName?: string
  /** 收货人电话 */
  receiverPhone?: string
  /** 收货人邮编 */
  receiverPostCode?: string
  /** 省份/直辖市 */
  receiverProvince: string
  /** 城市 */
  receiverCity?: string
  /** 区 */
  receiverRegion?: string
  /** 详细地址 */
  receiverDetailAddress?: string
  /** 订单备注 */
  note?: string
  /** 确认收货状态：0->未确认；1->已确认 */
  confirmStatus?: number
  /** 删除状态：0->未删除；1->已删除 */
  deleteStatus?: number
  /** 下单时使用的积分 */
  useIntegration?: number
  /** 支付时间 */
  paymentTime: string
  /** 发货时间 */
  deliveryTime: string
  /** 确认收货时间 */
  receiveTime: string
  /** 评价时间 */
  commentTime: string
  /** 修改时间 */
  modifyTime?: string
}

/** 订单商品项 */
export type OmsOrderItem = {
  /** 商品项id */
  id: number
  /** 订单id */
  orderId: number
  /** 订单编号 */
  orderSn: string
  /** 商品id */
  productId: number
  /** 商品图片 */
  productPic: string
  /** 商品名称 */
  productName: string
  /** 商品品牌 */
  productBrand: string
  /** 商品货号 */
  productSn: string
  /** 销售价格 */
  productPrice: number
  /** 购买数量 */
  productQuantity: number
  /** 商品sku编号 */
  productSkuId: number
  /** 商品sku条码 */
  productSkuCode: string
  /** 商品分类id */
  productCategoryId: number
  /** 商品促销名称 */
  promotionName: string
  /** 商品促销分解金额 */
  promotionAmount: number
  /** 优惠券优惠分解金额 */
  couponAmount: number
  /** 积分优惠分解金额 */
  integrationAmount: number
  /** 该商品经过优惠后的分解金额 */
  realAmount: number
  /** 赠送积分 */
  giftIntegration: number
  /** 赠送成长值 */
  giftGrowth: number
  /** 商品销售属性 */
  productAttr: string
}

/** 订单操作历史 */
export type OmsOrderOperateHistory = {
  /** 历史记录id */
  id: number
  /** 订单id */
  orderId: number
  /** 操作人：用户；系统；后台管理员 */
  operateMan: string
  /** 操作时间 */
  createTime: string
  /** 订单状态 */
  orderStatus: number
  /** 备注 */
  note: string
}

/** 订单列表查询参数 */
export type OrderQueryParam = PageParam & {
  /** 订单编号 */
  orderSn?: string
  /** 收货人姓名/号码 */
  receiverKeyword?: string
  /** 订单状态 */
  status?: number
  /** 订单类型：0->正常订单；1->秒杀订单 */
  orderType?: number
  /** 订单来源：0->PC订单；1->app订单 */
  sourceType?: number
  /** 订单提交时间 */
  createTime?: string
}

/** 订单发货参数 */
export type OmsOrderDeliveryParam = {
  /** 订单id */
  orderId: number
  /** 物流公司 */
  deliveryCompany?: string
  /** 物流单号 */
  deliverySn?: string
}

/** 订单详情信息 */
export type OmsOrderDetail = OmsOrder & {
  /** 订单商品列表 */
  orderItemList: OmsOrderItem[]
  /** 订单操作记录列表 */
  historyList: OmsOrderOperateHistory[]
}
```

## 3. API 接口封装

### 3.1 订单 API（apis/order.ts）

```typescript
import type { CommonPage } from '@/types/common'
import type {
  OmsMoneyInfoParam,
  OmsOrder,
  OmsOrderDeliveryParam,
  OmsOrderDetail,
  OmsReceiverInfoParam,
  OrderQueryParam,
} from '@/types/order'
import http from '@/utils/http'

/**
 * 分页查询订单列表
 */
export function getOrderListAPI(params: OrderQueryParam) {
  return http<CommonPage<OmsOrder>>({
    url: '/order/list',
    method: 'get',
    params: params,
  })
}

/**
 * 批量关闭订单
 */
export function orderUpdateCloseAPI(params: { ids: string; note: string }) {
  return http({
    url: '/order/update/close',
    method: 'post',
    params: params,
  })
}

/**
 * 批量删除订单
 */
export function orderDeleteByIdsAPI(params: { ids: string }) {
  return http({
    url: '/order/delete',
    method: 'post',
    params: params,
  })
}

/**
 * 批量发货
 */
export function orderUpdateDeliveryAPI(data: OmsOrderDeliveryParam[]) {
  return http({
    url: '/order/update/delivery',
    method: 'post',
    data: data,
  })
}

/**
 * 获取订单详情
 */
export function getOrderDetailByIdAPI(id: number) {
  return http<OmsOrderDetail>({
    url: '/order/' + id,
    method: 'get',
  })
}

/**
 * 修改收货人信息
 */
export function orderUpdateReceiverInfoAPI(data: OmsReceiverInfoParam) {
  return http({
    url: '/order/update/receiverInfo',
    method: 'post',
    data: data,
  })
}

/**
 * 修改订单费用信息
 */
export function orderUpdateMoneyInfoAPI(data: OmsMoneyInfoParam) {
  return http({
    url: '/order/update/moneyInfo',
    method: 'post',
    data: data,
  })
}

/**
 * 备注订单
 */
export function orderUpdateNoteAPI(params: { id: number; note: string; status: number }) {
  return http({
    url: '/order/update/note',
    method: 'post',
    params: params,
  })
}
```

## 4. 订单列表页面实现

### 4.1 完整代码（views/oms/order/index.vue）

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Tickets } from '@element-plus/icons-vue'
import { getOrderListAPI, orderUpdateCloseAPI, orderDeleteByIdsAPI } from '@/apis/order'
import LogisticsDialog from '@/views/oms/order/components/logisticsDialog.vue'
import { formatDateTime } from '@/utils/datetime'
import type { OmsOrder, OrderQueryParam } from '@/types/order'
import { useOrderStore } from '@/stores/order'

// ==================== 路由和状态 ====================
const router = useRouter()
const orderStore = useOrderStore()

// ==================== 搜索筛选相关 ====================

// 订单列表查询参数
const listQuery = ref<OrderQueryParam>({
  pageNum: 1,
  pageSize: 10
})

// 订单状态选项
const statusOptions = [
  { label: '待付款', value: 0 },
  { label: '待发货', value: 1 },
  { label: '已发货', value: 2 },
  { label: '已完成', value: 3 },
  { label: '已关闭', value: 4 },
  { label: '无效订单', value: 5 }
]

// 订单类型选项
const orderTypeOptions = [
  { label: '正常订单', value: 0 },
  { label: '秒杀订单', value: 1 }
]

// 订单来源选项
const sourceTypeOptions = [
  { label: 'PC订单', value: 0 },
  { label: 'APP订单', value: 1 }
]

// ==================== 列表数据相关 ====================

// 订单列表数据
const list = ref<OmsOrder[]>([])

// 加载状态
const listLoading = ref(true)

// 总条数
const total = ref(0)

// 选中的数据
const multipleSelection = ref<OmsOrder[]>([])

// ==================== 批量操作相关 ====================

// 批量操作选项
const operateOptions = [
  { label: "批量发货", value: 1 },
  { label: "关闭订单", value: 2 },
  { label: "删除订单", value: 3 }
]

// 当前选中的批量操作
const operateType = ref<number>()

// ==================== 对话框相关 ====================

// 关闭订单对话框数据
const closeOrderData = ref({
  dialogVisible: false,
  content: '',
  orderIds: [] as number[]
})

// 物流对话框可见性
const logisticsDialogVisible = ref(false)

// ==================== 方法定义 ====================

/**
 * 获取订单列表
 */
const getList = async () => {
  listLoading.value = true
  try {
    const response = await getOrderListAPI(listQuery.value)
    list.value = response.data.list
    total.value = response.data.total
  } catch (error) {
    console.error('获取订单列表失败:', error)
  } finally {
    listLoading.value = false
  }
}

/**
 * 搜索列表
 */
const handleSearchList = () => {
  listQuery.value.pageNum = 1
  getList()
}

/**
 * 重置搜索
 */
const handleResetSearch = () => {
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
const handleSelectionChange = (val: OmsOrder[]) => {
  multipleSelection.value = val
}

// ==================== 订单操作 ====================

/**
 * 查看订单详情
 */
const handleViewOrder = (index: number, row: OmsOrder) => {
  router.push({ path: '/oms/orderDetail', query: { id: row.id } })
}

/**
 * 关闭订单
 */
const handleCloseOrder = (index: number, row: OmsOrder) => {
  closeOrderData.value.dialogVisible = true
  closeOrderData.value.orderIds = [row.id!]
}

/**
 * 订单发货
 */
const handleDeliveryOrder = (index: number, row: OmsOrder) => {
  orderStore.setDeliverOrderList([row])
  router.push({ path: '/oms/deliverOrderList' })
}

/**
 * 查看物流
 */
const handleViewLogistics = (index: number, row: OmsOrder) => {
  logisticsDialogVisible.value = true
}

/**
 * 删除订单
 */
const handleDeleteOrder = async (index: number, row: OmsOrder) => {
  await deleteOrderFn([row.id!])
}

/**
 * 确认关闭订单
 */
const handleCloseOrderConfirm = async () => {
  if (!closeOrderData.value.content) {
    ElMessage.warning('操作备注不能为空')
    return
  }
  
  const orderIds = closeOrderData.value.orderIds.join(',')
  await orderUpdateCloseAPI({ 
    ids: orderIds, 
    note: closeOrderData.value.content 
  })
  
  closeOrderData.value.dialogVisible = false
  closeOrderData.value.orderIds = []
  closeOrderData.value.content = ''
  getList()
  ElMessage.success('关闭成功')
}

/**
 * 批量操作
 */
const handleBatchOperate = async () => {
  if (!multipleSelection.value || multipleSelection.value.length < 1) {
    ElMessage.warning('请选择要操作的订单')
    return
  }
  
  switch (operateType.value) {
    case 1: // 批量发货
      const deliverList = multipleSelection.value.filter(item => item.status === 1)
      if (deliverList.length < 1) {
        ElMessage.warning('选中订单中没有可以发货的订单')
        return
      }
      orderStore.setDeliverOrderList(deliverList)
      router.push({ path: '/oms/deliverOrderList' })
      break
      
    case 2: // 关闭订单
      const closeList = multipleSelection.value.filter(item => item.status === 0)
      if (closeList.length < 1) {
        ElMessage.warning('选中订单中没有可以关闭的订单')
        return
      }
      closeOrderData.value.orderIds = closeList.map(item => item.id!)
      closeOrderData.value.dialogVisible = true
      break
      
    case 3: // 删除订单
      const deleteList = multipleSelection.value.filter(item => item.status === 4)
      if (deleteList.length < 1) {
        ElMessage.warning('选中订单中没有可以删除的订单')
        return
      }
      await deleteOrderFn(deleteList.map(item => item.id!))
      break
  }
}

/**
 * 删除订单函数
 */
const deleteOrderFn = async (ids: number[]) => {
  await ElMessageBox.confirm('是否要进行该删除操作?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  
  await orderDeleteByIdsAPI({ ids: ids.join(',') })
  ElMessage.success('删除成功')
  getList()
}

// ==================== 格式化函数 ====================

/**
 * 格式化支付方式
 */
const formatPayType = (value: number) => {
  const payTypeMap: Record<number, string> = {
    0: '未支付',
    1: '支付宝',
    2: '微信'
  }
  return payTypeMap[value] || '未知'
}

/**
 * 格式化订单来源
 */
const formatSourceType = (value: number) => {
  return value === 1 ? 'APP订单' : 'PC订单'
}

/**
 * 格式化订单状态
 */
const formatStatus = (value: number) => {
  const statusMap: Record<number, string> = {
    0: '待付款',
    1: '待发货',
    2: '已发货',
    3: '已完成',
    4: '已关闭',
    5: '无效订单'
  }
  return statusMap[value] || '未知'
}

// ==================== 生命周期 ====================

onMounted(() => {
  getList()
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
              v-model="listQuery.orderSn" 
              class="input-width" 
              placeholder="订单编号"
            />
          </el-form-item>
          <el-form-item label="收货人：">
            <el-input 
              v-model="listQuery.receiverKeyword" 
              class="input-width" 
              placeholder="收货人姓名/手机号码"
            />
          </el-form-item>
          <el-form-item label="提交时间：">
            <el-date-picker 
              class="input-width" 
              v-model="listQuery.createTime" 
              value-format="YYYY-MM-DD" 
              type="date"
              placeholder="请选择时间"
            />
          </el-form-item>
          <el-form-item label="订单状态：">
            <el-select v-model="listQuery.status" class="input-width" placeholder="全部" clearable>
              <el-option 
                v-for="item in statusOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="订单分类：">
            <el-select v-model="listQuery.orderType" class="input-width" placeholder="全部" clearable>
              <el-option 
                v-for="item in orderTypeOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="订单来源：">
            <el-select v-model="listQuery.sourceType" class="input-width" placeholder="全部" clearable>
              <el-option 
                v-for="item in sourceTypeOptions" 
                :key="item.value" 
                :label="item.label" 
                :value="item.value"
              />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
    </el-card>

    <!-- 数据列表标题 -->
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>数据列表</span>
    </el-card>

    <!-- 数据表格 -->
    <div class="table-container">
      <el-table 
        ref="orderTable" 
        :data="list" 
        style="width: 100%;" 
        @selection-change="handleSelectionChange"
        v-loading="listLoading" 
        border
      >
        <el-table-column type="selection" width="60" align="center" />
        <el-table-column label="编号" width="80" align="center">
          <template #default="scope">{{ scope.row.id }}</template>
        </el-table-column>
        <el-table-column label="订单编号" width="180" align="center">
          <template #default="scope">{{ scope.row.orderSn }}</template>
        </el-table-column>
        <el-table-column label="提交时间" width="180" align="center">
          <template #default="scope">{{ formatDateTime(scope.row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="用户账号" align="center">
          <template #default="scope">{{ scope.row.memberUsername }}</template>
        </el-table-column>
        <el-table-column label="订单金额" width="120" align="center">
          <template #default="scope">￥{{ scope.row.totalAmount }}</template>
        </el-table-column>
        <el-table-column label="支付方式" width="120" align="center">
          <template #default="scope">{{ formatPayType(scope.row.payType) }}</template>
        </el-table-column>
        <el-table-column label="订单来源" width="120" align="center">
          <template #default="scope">{{ formatSourceType(scope.row.sourceType) }}</template>
        </el-table-column>
        <el-table-column label="订单状态" width="120" align="center">
          <template #default="scope">
            <el-tag :type="scope.row.status === 4 ? 'danger' : ''">
              {{ formatStatus(scope.row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center">
          <template #default="scope">
            <el-button size="small" @click="handleViewOrder(scope.$index, scope.row)">
              查看订单
            </el-button>
            <el-button 
              size="small" 
              @click="handleCloseOrder(scope.$index, scope.row)"
              v-if="scope.row.status === 0"
            >
              关闭订单
            </el-button>
            <el-button 
              size="small" 
              @click="handleDeliveryOrder(scope.$index, scope.row)"
              v-if="scope.row.status === 1"
            >
              订单发货
            </el-button>
            <el-button 
              size="small" 
              @click="handleViewLogistics(scope.$index, scope.row)"
              v-if="scope.row.status === 2 || scope.row.status === 3"
            >
              订单跟踪
            </el-button>
            <el-button 
              size="small" 
              type="danger" 
              @click="handleDeleteOrder(scope.$index, scope.row)"
              v-if="scope.row.status === 4"
            >
              删除订单
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 批量操作栏 -->
    <div class="batch-operate-container">
      <el-select v-model="operateType" placeholder="批量操作" style="width: 150px">
        <el-option 
          v-for="item in operateOptions" 
          :key="item.value" 
          :label="item.label" 
          :value="item.value"
        />
      </el-select>
      <el-button 
        style="margin-left: 20px" 
        type="primary" 
        @click="handleBatchOperate()"
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
        v-model:current-page="listQuery.pageNum"
        :page-size="listQuery.pageSize" 
        :page-sizes="[5, 10, 15]" 
        :total="total"
      />
    </div>

    <!-- 关闭订单对话框 -->
    <el-dialog title="关闭订单" v-model="closeOrderData.dialogVisible" width="30%">
      <span style="vertical-align: top">操作备注：</span>
      <el-input 
        style="width: 80%" 
        type="textarea" 
        :rows="5" 
        placeholder="请输入内容" 
        v-model="closeOrderData.content"
      />
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="closeOrderData.dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="handleCloseOrderConfirm">确 定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 物流对话框 -->
    <logistics-dialog v-model="logisticsDialogVisible" />
  </div>
</template>

<style scoped>
.input-width {
  width: 203px;
}

.filter-container {
  margin-bottom: 20px;
}

.operate-container {
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

### 5.1 状态驱动的操作按钮

根据订单状态显示不同的操作按钮：

```vue
<template #default="scope">
  <!-- 所有状态都可以查看 -->
  <el-button size="small" @click="handleViewOrder(scope.$index, scope.row)">
    查看订单
  </el-button>
  
  <!-- 只有待付款可以关闭 -->
  <el-button 
    v-if="scope.row.status === 0"
    @click="handleCloseOrder(scope.$index, scope.row)"
  >
    关闭订单
  </el-button>
  
  <!-- 只有待发货可以发货 -->
  <el-button 
    v-if="scope.row.status === 1"
    @click="handleDeliveryOrder(scope.$index, scope.row)"
  >
    订单发货
  </el-button>
  
  <!-- 已发货和已完成可以跟踪 -->
  <el-button 
    v-if="scope.row.status === 2 || scope.row.status === 3"
    @click="handleViewLogistics(scope.$index, scope.row)"
  >
    订单跟踪
  </el-button>
  
  <!-- 只有已关闭可以删除 -->
  <el-button 
    v-if="scope.row.status === 4"
    type="danger"
    @click="handleDeleteOrder(scope.$index, scope.row)"
  >
    删除订单
  </el-button>
</template>
```

### 5.2 批量操作的智能过滤

```typescript
const handleBatchOperate = async () => {
  switch (operateType.value) {
    case 1: // 批量发货 - 只筛选待发货状态的订单
      const deliverList = multipleSelection.value.filter(item => item.status === 1)
      if (deliverList.length < 1) {
        ElMessage.warning('选中订单中没有可以发货的订单')
        return
      }
      orderStore.setDeliverOrderList(deliverList)
      router.push({ path: '/oms/deliverOrderList' })
      break
      
    case 2: // 关闭订单 - 只筛选待付款状态的订单
      const closeList = multipleSelection.value.filter(item => item.status === 0)
      // ...
      break
      
    case 3: // 删除订单 - 只筛选已关闭状态的订单
      const deleteList = multipleSelection.value.filter(item => item.status === 4)
      // ...
      break
  }
}
```

### 5.3 使用 Pinia Store 传递数据

```typescript
// stores/order.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { OmsOrder } from '@/types/order'

export const useOrderStore = defineStore('order', () => {
  // 发货订单列表
  const deliverOrderList = ref<OmsOrder[]>([])
  
  const setDeliverOrderList = (list: OmsOrder[]) => {
    deliverOrderList.value = list
  }
  
  return {
    deliverOrderList,
    setDeliverOrderList
  }
})
```

## 6. 小结

本节我们完成了订单列表页面的开发：

1. **订单业务理解**：掌握了订单生命周期和状态流转
2. **类型定义**：定义了订单相关的完整类型
3. **多条件搜索**：实现了订单编号、收货人、时间、状态等多条件筛选
4. **状态驱动UI**：根据订单状态动态显示操作按钮
5. **批量操作**：实现了批量发货、关闭、删除功能

下一节将开发订单详情页面，展示订单的完整信息。

## 参考资源

- [Element Plus DatePicker](https://element-plus.org/zh-CN/component/date-picker.html)
- [Element Plus Tag](https://element-plus.org/zh-CN/component/tag.html)
- [Pinia 文档](https://pinia.vuejs.org/)
