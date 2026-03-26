# 第25节 订单设置与优化

## 学习目标

- 掌握订单设置页面的开发
- 学习表单验证的实现
- 理解订单超时机制
- 掌握表单提交的最佳实践

## 功能概述

订单设置是电商系统的基础配置功能，主要包括：

1. **秒杀订单超时** - 未付款自动关闭时间
2. **正常订单超时** - 未付款自动关闭时间
3. **发货超时** - 未收货自动完成时间
4. **订单完成超时** - 自动结束交易时间
5. **评价超时** - 自动五星好评时间

## 完整代码实现

### 1. 订单设置页面 (setting.vue)

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getOrderSettingByIdAPI, orderSettingUpdateByIdAPI } from '@/apis/orderSetting'
import type { FormInstance, FormRules } from 'element-plus'
import type { OmsOrderSetting } from '@/types/orderSetting'

// 默认订单设置数据
const defaultOrderSetting = {
  id: 1,
  flashOrderOvertime: 30,      // 秒杀订单超时（分钟）
  normalOrderOvertime: 60,     // 正常订单超时（分钟）
  confirmOvertime: 7,          // 发货超时（天）
  finishOvertime: 7,           // 订单完成超时（天）
  commentOvertime: 7           // 评价超时（天）
}

// 订单设置数据
const orderSetting = ref<OmsOrderSetting>(Object.assign({}, defaultOrderSetting))

// 获取详情
const getDetail = async () => {
  const response = await getOrderSettingByIdAPI(orderSetting.value.id)
  orderSetting.value = response.data
}

// 组件挂载后获取详情
onMounted(() => {
  getDetail()
})

// 订单设置表单引用
const orderSettingForm = ref<FormInstance>()

// 时间验证规则
const checkTime = (rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (!value) {
    return callback(new Error('时间不能为空'))
  }
  const intValue = parseInt(value)
  if (!Number.isInteger(intValue)) {
    return callback(new Error('请输入数字值'))
  }
  if (intValue <= 0) {
    return callback(new Error('时间必须大于0'))
  }
  callback()
}

// 表单验证规则
const rules = ref<FormRules>({
  flashOrderOvertime: { validator: checkTime, trigger: 'blur' },
  normalOrderOvertime: { validator: checkTime, trigger: 'blur' },
  confirmOvertime: { validator: checkTime, trigger: 'blur' },
  finishOvertime: { validator: checkTime, trigger: 'blur' },
  commentOvertime: { validator: checkTime, trigger: 'blur' }
})

// 确认提交表单
const confirm = async () => {
  if (!orderSettingForm.value) return
  
  const valid = await orderSettingForm.value.validate()
  if (valid) {
    await ElMessageBox.confirm('是否要提交修改?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await orderSettingUpdateByIdAPI(1, orderSetting.value)
    ElMessage({
      type: 'success',
      message: '提交成功!',
      duration: 1000
    })
  } else {
    ElMessage.warning('提交参数不合法')
    return false
  }
}
</script>

<template>
  <el-card class="form-container" shadow="never">
    <el-form 
      :model="orderSetting" 
      ref="orderSettingForm" 
      :rules="rules" 
      label-width="150px"
    >
      <el-form-item label="秒杀订单超过：" prop="flashOrderOvertime">
        <el-input v-model="orderSetting.flashOrderOvertime" class="input-width">
          <template #append>分</template>
        </el-input>
        <span class="note-margin">未付款，订单自动关闭</span>
      </el-form-item>
      
      <el-form-item label="正常订单超过：" prop="normalOrderOvertime">
        <el-input v-model="orderSetting.normalOrderOvertime" class="input-width">
          <template #append>分</template>
        </el-input>
        <span class="note-margin">未付款，订单自动关闭</span>
      </el-form-item>
      
      <el-form-item label="发货超过：" prop="confirmOvertime">
        <el-input v-model="orderSetting.confirmOvertime" class="input-width">
          <template #append>天</template>
        </el-input>
        <span class="note-margin">未收货，订单自动完成</span>
      </el-form-item>
      
      <el-form-item label="订单完成超过：" prop="finishOvertime">
        <el-input v-model="orderSetting.finishOvertime" class="input-width">
          <template #append>天</template>
        </el-input>
        <span class="note-margin">自动结束交易，不能申请售后</span>
      </el-form-item>
      
      <el-form-item label="订单完成超过：" prop="commentOvertime">
        <el-input v-model="orderSetting.commentOvertime" class="input-width">
          <template #append>天</template>
        </el-input>
        <span class="note-margin">自动五星好评</span>
      </el-form-item>
      
      <el-form-item>
        <el-button @click="confirm()" type="primary">提交</el-button>
      </el-form-item>
    </el-form>
  </el-card>
</template>

<style scoped>
.input-width {
  width: 50%
}

.note-margin {
  margin-left: 15px;
  color: #909399;
  font-size: 14px;
}
</style>
```

## 关键技术点

### 1. 表单验证规则

```typescript
// 自定义验证函数
const checkTime = (rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (!value) {
    return callback(new Error('时间不能为空'))
  }
  const intValue = parseInt(value)
  if (!Number.isInteger(intValue)) {
    return callback(new Error('请输入数字值'))
  }
  if (intValue <= 0) {
    return callback(new Error('时间必须大于0'))
  }
  callback()
}

// 表单验证规则配置
const rules = ref<FormRules>({
  flashOrderOvertime: { validator: checkTime, trigger: 'blur' },
  normalOrderOvertime: { validator: checkTime, trigger: 'blur' },
  confirmOvertime: { validator: checkTime, trigger: 'blur' },
  finishOvertime: { validator: checkTime, trigger: 'blur' },
  commentOvertime: { validator: checkTime, trigger: 'blur' }
})
```

### 2. 带后缀的输入框

```vue
<el-input v-model="orderSetting.flashOrderOvertime" class="input-width">
  <template #append>分</template>
</el-input>
```

### 3. 表单提交流程

```typescript
const confirm = async () => {
  // 1. 获取表单实例
  if (!orderSettingForm.value) return
  
  // 2. 表单验证
  const valid = await orderSettingForm.value.validate()
  
  if (valid) {
    // 3. 确认对话框
    await ElMessageBox.confirm('是否要提交修改?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    // 4. 调用API
    await orderSettingUpdateByIdAPI(1, orderSetting.value)
    
    // 5. 成功提示
    ElMessage.success('提交成功!')
  }
}
```

## 订单超时机制

```
┌─────────────────────────────────────────────────────────────┐
│                      订单超时机制                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 下单未付款                                               │
│     ┌──────────────┐                                        │
│     │   提交订单    │                                        │
│     └──────┬───────┘                                        │
│            │ 超过X分钟                                       │
│            ▼                                                │
│     ┌──────────────┐                                        │
│     │  自动关闭订单 │ ◄── 秒杀订单：30分钟                   │
│     └──────────────┘      正常订单：60分钟                   │
│                                                             │
│  2. 发货未收货                                               │
│     ┌──────────────┐                                        │
│     │    发货      │                                        │
│     └──────┬───────┘                                        │
│            │ 超过X天                                        │
│            ▼                                                │
│     ┌──────────────┐                                        │
│     │  自动确认收货 │ ◄── 默认7天                            │
│     └──────────────┘                                        │
│                                                             │
│  3. 完成未评价                                               │
│     ┌──────────────┐                                        │
│     │   订单完成    │                                        │
│     └──────┬───────┘                                        │
│            │ 超过X天                                        │
│            ▼                                                │
│     ┌──────────────┐                                        │
│     │  自动五星好评 │ ◄── 默认7天                            │
│     └──────────────┘                                        │
│                                                             │
│  4. 售后期限                                                 │
│     ┌──────────────┐                                        │
│     │   订单完成    │                                        │
│     └──────┬───────┘                                        │
│            │ 超过X天                                        │
│            ▼                                                │
│     ┌──────────────┐                                        │
│     │  不能申请售后 │ ◄── 默认7天                            │
│     └──────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 表单验证最佳实践

### 1. 验证时机

```typescript
// blur - 失去焦点时验证
{ validator: checkTime, trigger: 'blur' }

// change - 值改变时验证
{ validator: checkTime, trigger: 'change' }
```

### 2. 异步验证

```typescript
const checkUserName = async (rule: unknown, value: string, callback: (error?: Error) => void) => {
  const res = await checkUserNameExistsAPI(value)
  if (res.data) {
    callback(new Error('用户名已存在'))
  } else {
    callback()
  }
}
```

### 3. 多条验证规则

```typescript
const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符', trigger: 'blur' },
    { validator: checkUserName, trigger: 'blur' }
  ]
}
```

## 小结

本节我们学习了：

1. **订单设置页面** - 配置订单超时时间
2. **表单验证** - 自定义验证规则和验证时机
3. **输入框后缀** - 使用 slot 添加单位后缀
4. **订单超时机制** - 理解电商系统的自动处理逻辑

至此，订单模块的前端开发教程全部完成！

## 课程总结

### 第21-25节内容回顾

| 章节 | 内容 | 关键技术 |
|------|------|----------|
| 第21节 | 订单模块概述与列表 | 多条件搜索、批量操作 |
| 第22节 | 订单详情页面 | Steps步骤条、多对话框管理 |
| 第23节 | 订单发货功能 | Pinia Store、批量发货 |
| 第24节 | 退货申请处理 | 状态标签、退款计算 |
| 第25节 | 订单设置 | 表单验证、超时机制 |

### 订单模块核心功能

1. **订单列表** - 分页查询、状态筛选、批量操作
2. **订单详情** - 状态流程、信息展示、操作按钮
3. **订单发货** - 批量发货、物流跟踪
4. **退货处理** - 申请列表、状态管理
5. **订单设置** - 超时配置、自动处理
