# 第22节 订单详情页面开发

## 学习目标

- 掌握订单详情页面的布局设计
- 学习使用 Element Plus 的 Steps 步骤条组件
- 实现订单状态的可视化展示
- 掌握多对话框的管理

## 页面功能概述

订单详情页面是订单管理的核心页面，需要展示：

1. **订单状态流程图** - 使用 Steps 组件展示订单生命周期
2. **操作按钮区域** - 根据订单状态显示不同的操作按钮
3. **基本信息** - 订单编号、支付方式、订单来源等
4. **收货人信息** - 姓名、电话、地址等
5. **商品信息** - 订单包含的商品列表
6. **费用信息** - 商品金额、运费、优惠等
7. **操作记录** - 订单的历史操作日志

## 完整代码实现

### 1. 订单详情页面 (orderDetail.vue)

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox, type CascaderOption } from 'element-plus'
import { Warning } from '@element-plus/icons-vue'
import { 
  getOrderDetailByIdAPI, 
  orderUpdateReceiverInfoAPI, 
  orderUpdateMoneyInfoAPI, 
  orderUpdateCloseAPI, 
  orderUpdateNoteAPI, 
  orderDeleteByIdsAPI 
} from '@/apis/order'
import LogisticsDialog from '@/views/oms/order/components/logisticsDialog.vue'
import type { OmsOrder, OmsOrderDetail, OmsReceiverInfoParam } from '@/types/order'
import { formatDateTime } from '@/utils/datetime'
import { pcaTextArr } from 'element-china-area-data'

// ========== 路由与数据 ==========
const router = useRouter()
const route = useRoute()
const id = ref<number>()
const order = ref<OmsOrderDetail>({} as OmsOrderDetail)

// 组件挂载后获取订单详情
onMounted(async () => {
  id.value = Number(route.query.id)
  const res = await getOrderDetailByIdAPI(id.value!)
  order.value = res.data
})

// ========== 对话框状态管理 ==========
const receiverDialogVisible = ref(false)  // 修改收货人信息
const moneyDialogVisible = ref(false)     // 修改费用信息
const messageDialogVisible = ref(false)   // 发送站内信
const closeDialogVisible = ref(false)     // 关闭订单
const markOrderDialogVisible = ref(false) // 备注订单
const logisticsDialogVisible = ref(false) // 物流跟踪

// ========== 表单数据 ==========
const receiverInfo = ref<OmsReceiverInfoParam>({} as OmsReceiverInfoParam)
const selectedRegions = ref<string[]>([])
const moneyInfo = ref({ orderId: 0, freightAmount: 0, discountAmount: 0, status: 0 })
const message = ref({ title: '', content: '' })
const closeInfo = ref({ note: '', id: 0 })
const markInfo = ref({ id: 0, note: '' })

// ========== 格式化函数 ==========

// 格式化订单状态
const formatStatus = (value: number) => {
  const statusMap: Record<number, string> = {
    0: '待付款',
    1: '待发货',
    2: '已发货',
    3: '已完成',
    4: '已关闭',
    5: '无效订单'
  }
  return statusMap[value] || '未知状态'
}

// 格式化支付方式
const formatPayType = (value: number) => {
  const payTypeMap: Record<number, string> = {
    1: '支付宝',
    2: '微信'
  }
  return payTypeMap[value] || '未支付'
}

// 格式化订单来源
const formatSourceType = (value: number) => {
  return value === 1 ? 'APP订单' : 'PC订单'
}

// 格式化地址
const formatAddress = (order: OmsOrder) => {
  return `${order.receiverProvince} ${order.receiverCity} ${order.receiverRegion} ${order.receiverDetailAddress}`
}

// 格式化商品属性（JSON字符串转可读格式）
const formatProductAttr = (value: string) => {
  if (!value) return ''
  const attr = JSON.parse(value)
  return attr.map((item: { key: string; value: string }) => 
    `${item.key}:${item.value}`
  ).join('; ')
}

// 格式化步骤状态（用于 Steps 组件）
const formatStepStatus = (value: number) => {
  const stepMap: Record<number, number> = {
    0: 1, // 待付款 -> 第1步
    1: 2, // 待发货 -> 第2步
    2: 3, // 已发货 -> 第3步
    3: 4, // 已完成 -> 第4步
    4: 1, // 已关闭 -> 第1步
    5: 1  // 无效订单 -> 第1步
  }
  return stepMap[value] || 1
}

// ========== 事件处理函数 ==========

// 显示修改收货人信息对话框
const showUpdateReceiverDialog = () => {
  receiverDialogVisible.value = true
  receiverInfo.value = {
    orderId: order.value.id,
    receiverName: order.value.receiverName,
    receiverPhone: order.value.receiverPhone,
    receiverPostCode: order.value.receiverPostCode,
    receiverDetailAddress: order.value.receiverDetailAddress,
    receiverProvince: order.value.receiverProvince,
    receiverCity: order.value.receiverCity,
    receiverRegion: order.value.receiverRegion,
    status: order.value.status
  }
  // 初始化省市区选择器
  selectedRegions.value = [
    receiverInfo.value.receiverProvince!,
    receiverInfo.value.receiverCity!,
    receiverInfo.value.receiverRegion!
  ]
}

// 选择地区变化
const onSelectRegionChange = () => {
  receiverInfo.value.receiverProvince = selectedRegions.value[0]
  receiverInfo.value.receiverCity = selectedRegions.value[1]
  receiverInfo.value.receiverRegion = selectedRegions.value[2]
}

// 处理更新收货人信息
const handleUpdateReceiverInfo = async () => {
  await ElMessageBox.confirm('是否要修改收货信息?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  await orderUpdateReceiverInfoAPI(receiverInfo.value)
  receiverDialogVisible.value = false
  ElMessage.success('修改成功!')
  // 刷新订单详情
  const response = await getOrderDetailByIdAPI(id.value!)
  order.value = response.data
}

// 显示修改费用信息对话框
const showUpdateMoneyDialog = () => {
  moneyDialogVisible.value = true
  moneyInfo.value = {
    orderId: order.value.id,
    freightAmount: order.value.freightAmount,
    discountAmount: order.value.discountAmount,
    status: order.value.status
  }
}

// 处理更新费用信息
const handleUpdateMoneyInfo = async () => {
  await ElMessageBox.confirm('是否要修改费用信息?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  await orderUpdateMoneyInfoAPI(moneyInfo.value)
  moneyDialogVisible.value = false
  ElMessage.success('修改成功!')
  const response = await getOrderDetailByIdAPI(id.value!)
  order.value = response.data
}

// 处理关闭订单
const handleCloseOrder = async () => {
  try {
    await ElMessageBox.confirm('是否要关闭订单?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await orderUpdateCloseAPI({ 
      ids: closeInfo.value.id.toString(), 
      note: closeInfo.value.note 
    })
    closeDialogVisible.value = false
    ElMessage.success('订单关闭成功!')
    const response = await getOrderDetailByIdAPI(id.value!)
    order.value = response.data
  } catch (error) {
    if (error !== 'cancel') {
      console.error('关闭订单失败:', error)
    }
  }
}

// 处理备注订单
const handleMarkOrder = async () => {
  await ElMessageBox.confirm('是否要备注订单?', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  })
  await orderUpdateNoteAPI({ 
    id: markInfo.value.id, 
    note: markInfo.value.note, 
    status: order.value.status 
  })
  markOrderDialogVisible.value = false
  ElMessage.success('订单备注成功!')
  const response = await getOrderDetailByIdAPI(id.value!)
  order.value = response.data
}

// 处理删除订单
const handleDeleteOrder = async () => {
  try {
    await ElMessageBox.confirm('是否要进行该删除操作?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await orderDeleteByIdsAPI({ ids: id.value!.toString() })
    ElMessage.success('删除成功！')
    router.back()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除订单失败:', error)
    }
  }
}
</script>

<template>
  <div class="detail-container">
    <!-- 订单状态流程图 -->
    <el-steps 
      :active="formatStepStatus(order.status)" 
      finish-status="success" 
      align-center
    >
      <el-step 
        title="提交订单" 
        :description="order.createTime ? formatDateTime(order.createTime) : ''"
      />
      <el-step 
        title="支付订单" 
        :description="order.paymentTime ? formatDateTime(order.paymentTime) : ''"
      />
      <el-step 
        title="平台发货" 
        :description="order.deliveryTime ? formatDateTime(order.deliveryTime) : ''"
      />
      <el-step 
        title="确认收货" 
        :description="order.receiveTime ? formatDateTime(order.receiveTime) : ''"
      />
      <el-step 
        title="完成评价" 
        :description="order.commentTime ? formatDateTime(order.commentTime) : ''"
      />
    </el-steps>

    <!-- 操作区域 -->
    <el-card shadow="never" style="margin-top: 15px">
      <div class="operate-container">
        <el-icon class="color-danger" style="margin-left: 15px;">
          <Warning />
        </el-icon>
        <span class="color-danger">当前订单状态：{{ formatStatus(order.status) }}</span>
        
        <!-- 待付款状态操作 -->
        <div class="operate-button-container" v-show="order.status === 0">
          <el-button size="small" @click="showUpdateReceiverDialog">修改收货人信息</el-button>
          <el-button size="small" @click="showUpdateMoneyDialog">修改费用信息</el-button>
          <el-button size="small" @click="messageDialogVisible = true">发送站内信</el-button>
          <el-button size="small" @click="closeDialogVisible = true">关闭订单</el-button>
          <el-button size="small" @click="markOrderDialogVisible = true">备注订单</el-button>
        </div>
        
        <!-- 待发货状态操作 -->
        <div class="operate-button-container" v-show="order.status === 1">
          <el-button size="small" @click="showUpdateReceiverDialog">修改收货人信息</el-button>
          <el-button size="small" @click="messageDialogVisible = true">发送站内信</el-button>
          <el-button size="small">取消订单</el-button>
          <el-button size="small" @click="markOrderDialogVisible = true">备注订单</el-button>
        </div>
        
        <!-- 已发货/已完成状态操作 -->
        <div class="operate-button-container" v-show="order.status === 2 || order.status === 3">
          <el-button size="small" @click="logisticsDialogVisible = true">订单跟踪</el-button>
          <el-button size="small" @click="messageDialogVisible = true">发送站内信</el-button>
          <el-button size="small" @click="markOrderDialogVisible = true">备注订单</el-button>
        </div>
        
        <!-- 已关闭状态操作 -->
        <div class="operate-button-container" v-show="order.status === 4">
          <el-button size="small" @click="handleDeleteOrder">删除订单</el-button>
          <el-button size="small" @click="markOrderDialogVisible = true">备注订单</el-button>
        </div>
      </div>

      <!-- 基本信息 -->
      <div style="margin-top: 20px">
        <span class="font-small">基本信息</span>
      </div>
      <div class="table-layout">
        <el-row>
          <el-col :span="4" class="table-cell-title">订单编号</el-col>
          <el-col :span="4" class="table-cell-title">用户账号</el-col>
          <el-col :span="4" class="table-cell-title">支付方式</el-col>
          <el-col :span="4" class="table-cell-title">订单来源</el-col>
          <el-col :span="4" class="table-cell-title">订单类型</el-col>
          <el-col :span="4" class="table-cell-title">配送方式</el-col>
        </el-row>
        <el-row>
          <el-col :span="4" class="table-cell">{{ order.orderSn }}</el-col>
          <el-col :span="4" class="table-cell">{{ order.memberUsername }}</el-col>
          <el-col :span="4" class="table-cell">{{ formatPayType(order.payType) }}</el-col>
          <el-col :span="4" class="table-cell">{{ formatSourceType(order.sourceType) }}</el-col>
          <el-col :span="4" class="table-cell">{{ order.orderType === 1 ? '秒杀订单' : '正常订单' }}</el-col>
          <el-col :span="4" class="table-cell">{{ order.deliveryCompany || '暂无' }}</el-col>
        </el-row>
      </div>

      <!-- 收货人信息 -->
      <div style="margin-top: 20px">
        <span class="font-small">收货人信息</span>
      </div>
      <div class="table-layout">
        <el-row>
          <el-col :span="6" class="table-cell-title">收货人</el-col>
          <el-col :span="6" class="table-cell-title">手机号码</el-col>
          <el-col :span="6" class="table-cell-title">邮政编码</el-col>
          <el-col :span="6" class="table-cell-title">收货地址</el-col>
        </el-row>
        <el-row>
          <el-col :span="6" class="table-cell">{{ order.receiverName }}</el-col>
          <el-col :span="6" class="table-cell">{{ order.receiverPhone }}</el-col>
          <el-col :span="6" class="table-cell">{{ order.receiverPostCode }}</el-col>
          <el-col :span="6" class="table-cell">{{ formatAddress(order) }}</el-col>
        </el-row>
      </div>

      <!-- 商品信息 -->
      <div style="margin-top: 20px">
        <span class="font-small">商品信息</span>
      </div>
      <el-table :data="order.orderItemList" style="width: 100%;margin-top: 20px" border>
        <el-table-column label="商品图片" width="120" align="center">
          <template v-slot="scope">
            <img :src="scope.row.productPic" style="height: 80px">
          </template>
        </el-table-column>
        <el-table-column label="商品名称" align="center">
          <template v-slot="scope">
            <p>{{ scope.row.productName }}</p>
            <p>品牌：{{ scope.row.productBrand }}</p>
          </template>
        </el-table-column>
        <el-table-column label="价格/货号" width="160" align="center">
          <template v-slot="scope">
            <p>价格：￥{{ scope.row.productPrice }}</p>
            <p>货号：{{ scope.row.productSn }}</p>
          </template>
        </el-table-column>
        <el-table-column label="属性" width="160" align="center">
          <template v-slot="scope">
            {{ formatProductAttr(scope.row.productAttr) }}
          </template>
        </el-table-column>
        <el-table-column label="数量" width="120" align="center">
          <template v-slot="scope">
            {{ scope.row.productQuantity }}
          </template>
        </el-table-column>
        <el-table-column label="小计" width="120" align="center">
          <template v-slot="scope">
            ￥{{ scope.row.productPrice * scope.row.productQuantity }}
          </template>
        </el-table-column>
      </el-table>
      <div style="float: right;margin: 20px">
        合计：<span class="color-danger">￥{{ order.totalAmount }}</span>
      </div>

      <!-- 费用信息 -->
      <div style="margin-top: 60px">
        <span class="font-small">费用信息</span>
      </div>
      <div class="table-layout">
        <el-row>
          <el-col :span="6" class="table-cell-title">商品合计</el-col>
          <el-col :span="6" class="table-cell-title">运费</el-col>
          <el-col :span="6" class="table-cell-title">优惠券</el-col>
          <el-col :span="6" class="table-cell-title">积分抵扣</el-col>
        </el-row>
        <el-row>
          <el-col :span="6" class="table-cell">￥{{ order.totalAmount }}</el-col>
          <el-col :span="6" class="table-cell">￥{{ order.freightAmount }}</el-col>
          <el-col :span="6" class="table-cell">-￥{{ order.couponAmount }}</el-col>
          <el-col :span="6" class="table-cell">-￥{{ order.integrationAmount }}</el-col>
        </el-row>
        <el-row>
          <el-col :span="6" class="table-cell-title">活动优惠</el-col>
          <el-col :span="6" class="table-cell-title">折扣金额</el-col>
          <el-col :span="6" class="table-cell-title">订单总金额</el-col>
          <el-col :span="6" class="table-cell-title">应付款金额</el-col>
        </el-row>
        <el-row>
          <el-col :span="6" class="table-cell">-￥{{ order.promotionAmount }}</el-col>
          <el-col :span="6" class="table-cell">-￥{{ order.discountAmount }}</el-col>
          <el-col :span="6" class="table-cell">
            <span class="color-danger">￥{{ order.totalAmount + order.freightAmount }}</span>
          </el-col>
          <el-col :span="6" class="table-cell">
            <span class="color-danger">￥{{ order.payAmount + order.freightAmount - order.discountAmount }}</span>
          </el-col>
        </el-row>
      </div>

      <!-- 操作记录 -->
      <div style="margin-top: 20px">
        <span class="font-small">操作信息</span>
      </div>
      <el-table :data="order.historyList" style="margin-top: 20px;width: 100%" border>
        <el-table-column label="操作者" width="120" align="center" prop="operateMan" />
        <el-table-column label="操作时间" width="160" align="center">
          <template v-slot="scope">
            {{ formatDateTime(scope.row.createTime) }}
          </template>
        </el-table-column>
        <el-table-column label="订单状态" width="120" align="center">
          <template v-slot="scope">
            {{ formatStatus(scope.row.orderStatus) }}
          </template>
        </el-table-column>
        <el-table-column label="备注" align="center" prop="note" />
      </el-table>
    </el-card>

    <!-- 修改收货人信息对话框 -->
    <el-dialog title="修改收货人信息" v-model="receiverDialogVisible" width="40%">
      <el-form :model="receiverInfo" label-width="150px">
        <el-form-item label="收货人姓名：">
          <el-input v-model="receiverInfo.receiverName" style="width: 200px" />
        </el-form-item>
        <el-form-item label="手机号码：">
          <el-input v-model="receiverInfo.receiverPhone" style="width: 200px" />
        </el-form-item>
        <el-form-item label="所在区域：">
          <el-cascader 
            v-model="selectedRegions" 
            :options="(pcaTextArr as CascaderOption[])"
            @change="onSelectRegionChange" 
            placeholder="请选择省市区" 
          />
        </el-form-item>
        <el-form-item label="详细地址：">
          <el-input v-model="receiverInfo.receiverDetailAddress" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template v-slot:footer>
        <el-button @click="receiverDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleUpdateReceiverInfo">确 定</el-button>
      </template>
    </el-dialog>

    <!-- 修改费用信息对话框 -->
    <el-dialog title="修改费用信息" v-model="moneyDialogVisible" width="40%">
      <div class="table-layout">
        <el-row>
          <el-col :span="6" class="table-cell-title">商品合计</el-col>
          <el-col :span="6" class="table-cell-title">运费</el-col>
          <el-col :span="6" class="table-cell-title">折扣金额</el-col>
          <el-col :span="6" class="table-cell-title">应付款金额</el-col>
        </el-row>
        <el-row>
          <el-col :span="6" class="table-cell">￥{{ order.totalAmount }}</el-col>
          <el-col :span="6" class="table-cell">
            <el-input v-model.number="moneyInfo.freightAmount" size="small">
              <template v-slot:prepend>￥</template>
            </el-input>
          </el-col>
          <el-col :span="6" class="table-cell">
            <el-input v-model.number="moneyInfo.discountAmount" size="small">
              <template v-slot:prepend>-￥</template>
            </el-input>
          </el-col>
          <el-col :span="6" class="table-cell">
            <span class="color-danger">
              ￥{{ order.payAmount + moneyInfo.freightAmount - moneyInfo.discountAmount }}
            </span>
          </el-col>
        </el-row>
      </div>
      <template v-slot:footer>
        <el-button @click="moneyDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleUpdateMoneyInfo">确 定</el-button>
      </template>
    </el-dialog>

    <!-- 关闭订单对话框 -->
    <el-dialog title="关闭订单" v-model="closeDialogVisible" width="40%">
      <el-form :model="closeInfo" label-width="150px">
        <el-form-item label="操作备注：">
          <el-input v-model="closeInfo.note" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template v-slot:footer>
        <el-button @click="closeDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleCloseOrder">确 定</el-button>
      </template>
    </el-dialog>

    <!-- 备注订单对话框 -->
    <el-dialog title="备注订单" v-model="markOrderDialogVisible" width="40%">
      <el-form :model="markInfo" label-width="150px">
        <el-form-item label="操作备注：">
          <el-input v-model="markInfo.note" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template v-slot:footer>
        <el-button @click="markOrderDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleMarkOrder">确 定</el-button>
      </template>
    </el-dialog>

    <!-- 物流跟踪对话框 -->
    <logistics-dialog v-model="logisticsDialogVisible" />
  </div>
</template>

<style scoped>
.detail-container {
  width: 80%;
  padding: 20px;
  margin: 20px auto;
}

.operate-container {
  background: #F2F6FC;
  height: 80px;
  margin: -20px -20px 0;
  line-height: 80px;
}

.operate-button-container {
  float: right;
  margin-right: 20px
}

.table-layout {
  margin-top: 20px;
  border-left: 1px solid #DCDFE6;
  border-top: 1px solid #DCDFE6;
}

.table-cell {
  height: 60px;
  line-height: 40px;
  border-right: 1px solid #DCDFE6;
  border-bottom: 1px solid #DCDFE6;
  padding: 10px;
  font-size: 14px;
  color: #606266;
  text-align: center;
  overflow: hidden;
}

.table-cell-title {
  border-right: 1px solid #DCDFE6;
  border-bottom: 1px solid #DCDFE6;
  padding: 10px;
  background: #F2F6FC;
  text-align: center;
  font-size: 14px;
  color: #303133;
}

.color-danger {
  color: #F56C6C;
}

.font-small {
  font-size: 14px;
  color: #606266;
  font-weight: bold;
}
</style>
```

## 关键技术点

### 1. Steps 步骤条组件

Element Plus 的 Steps 组件非常适合展示订单状态流程：

```vue
<el-steps :active="currentStep" finish-status="success" align-center>
  <el-step title="步骤1" description="描述1" />
  <el-step title="步骤2" description="描述2" />
  <el-step title="步骤3" description="描述3" />
</el-steps>
```

**属性说明：**
- `active`：当前激活的步骤索引（从1开始）
- `finish-status`：已完成步骤的状态（success/wait/process/error）
- `align-center`：步骤条居中显示

### 2. 条件渲染操作按钮

根据订单状态显示不同的操作按钮：

```vue
<!-- 待付款状态 -->
<div v-show="order.status === 0">
  <el-button @click="showUpdateReceiverDialog">修改收货人信息</el-button>
  <el-button @click="showUpdateMoneyDialog">修改费用信息</el-button>
  <el-button @click="closeDialogVisible = true">关闭订单</el-button>
</div>

<!-- 待发货状态 -->
<div v-show="order.status === 1">
  <el-button @click="showUpdateReceiverDialog">修改收货人信息</el-button>
  <el-button>取消订单</el-button>
</div>
```

### 3. 省市区级联选择器

使用 `element-china-area-data` 库实现省市区选择：

```typescript
import { pcaTextArr } from 'element-china-area-data'

// 选中的地区
const selectedRegions = ref<string[]>([])

// 级联选择器
<el-cascader 
  v-model="selectedRegions" 
  :options="(pcaTextArr as CascaderOption[])"
  @change="onSelectRegionChange" 
  placeholder="请选择省市区" 
/>

// 处理选择变化
const onSelectRegionChange = () => {
  receiverInfo.value.receiverProvince = selectedRegions.value[0]
  receiverInfo.value.receiverCity = selectedRegions.value[1]
  receiverInfo.value.receiverRegion = selectedRegions.value[2]
}
```

### 4. 多对话框管理

使用多个 `ref` 管理不同对话框的显示状态：

```typescript
const receiverDialogVisible = ref(false)  // 修改收货人
const moneyDialogVisible = ref(false)     // 修改费用
const closeDialogVisible = ref(false)     // 关闭订单
const markOrderDialogVisible = ref(false) // 备注订单
```

## 小结

本节我们学习了：

1. **订单详情页面的整体布局** - 使用 Card、Steps、Table 等组件构建页面
2. **状态驱动的操作按钮** - 根据订单状态动态显示不同的操作选项
3. **多对话框管理** - 使用多个状态变量管理不同的编辑对话框
4. **省市区级联选择** - 使用 element-china-area-data 实现地址选择
5. **数据格式化** - 使用工具函数格式化订单状态、支付方式、地址等数据

下一节我们将学习订单发货功能的实现，包括批量发货和物流跟踪。
