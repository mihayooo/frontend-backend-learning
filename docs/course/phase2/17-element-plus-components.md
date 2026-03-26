# 第17节：Element Plus 组件库使用

## 学习目标

- 掌握 Element Plus 常用组件的使用方法
- 理解组件的属性、事件和插槽
- 学会组件的自定义和二次封装
- 掌握表单验证和表格操作

## 1. Element Plus 简介

Element Plus 是一套基于 Vue 3 的桌面端组件库，提供了丰富的 UI 组件：

- **基础组件**：Button、Icon、Link、Text
- **表单组件**：Input、Select、Checkbox、Radio、Form
- **数据展示**：Table、Tag、Progress、Tree
- **导航组件**：Menu、Tabs、Breadcrumb、Dropdown
- **反馈组件**：Message、MessageBox、Notification、Dialog
- **其他组件**：Card、Pagination、Loading、Dialog

## 2. 基础组件

### 2.1 按钮（Button）

```vue
<template>
  <div>
    <!-- 按钮类型 -->
    <el-button>默认按钮</el-button>
    <el-button type="primary">主要按钮</el-button>
    <el-button type="success">成功按钮</el-button>
    <el-button type="warning">警告按钮</el-button>
    <el-button type="danger">危险按钮</el-button>
    <el-button type="info">信息按钮</el-button>

    <!-- 按钮尺寸 -->
    <el-button size="large">大型按钮</el-button>
    <el-button>默认按钮</el-button>
    <el-button size="small">小型按钮</el-button>

    <!-- 图标按钮 -->
    <el-button :icon="Search">搜索</el-button>
    <el-button type="primary" :icon="Plus">添加</el-button>
    <el-button type="danger" :icon="Delete" circle></el-button>

    <!-- 加载状态 -->
    <el-button loading>加载中</el-button>

    <!-- 禁用状态 -->
    <el-button disabled>禁用按钮</el-button>
  </div>
</template>

<script setup lang="ts">
import { Search, Plus, Delete } from '@element-plus/icons-vue'
</script>
```

### 2.2 图标（Icon）

Element Plus 使用 `@element-plus/icons-vue` 作为图标库：

```vue
<template>
  <div>
    <!-- 直接使用图标组件 -->
    <el-icon><Search /></el-icon>
    <el-icon><Edit /></el-icon>
    <el-icon><Delete /></el-icon>

    <!-- 设置图标大小和颜色 -->
    <el-icon :size="20" color="#409EFF"><Search /></el-icon>

    <!-- 按钮中使用图标 -->
    <el-button :icon="Search">搜索</el-button>
  </div>
</template>

<script setup lang="ts">
import { Search, Edit, Delete } from '@element-plus/icons-vue'
</script>
```

### 2.3 卡片（Card）

```vue
<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span>卡片标题</span>
        <el-button class="button" text>操作按钮</el-button>
      </div>
    </template>
    <div v-for="o in 4" :key="o" class="text item">{{ '列表内容 ' + o }}</div>
  </el-card>
</template>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
```

## 3. 表单组件

### 3.1 输入框（Input）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-input v-model="input1" placeholder="请输入内容" />

    <!-- 带图标 -->
    <el-input v-model="input2" placeholder="请输入内容" :prefix-icon="Search" />
    <el-input v-model="input3" placeholder="请输入内容" :suffix-icon="Calendar" />

    <!-- 带按钮 -->
    <el-input v-model="input4" placeholder="请输入内容">
      <template #append>
        <el-button :icon="Search" />
      </template>
    </el-input>

    <!-- 文本域 -->
    <el-input v-model="textarea" type="textarea" :rows="3" placeholder="请输入内容" />

    <!-- 可清空 -->
    <el-input v-model="input5" clearable placeholder="可清空的输入框" />

    <!-- 密码框 -->
    <el-input v-model="password" type="password" show-password placeholder="请输入密码" />

    <!-- 字数限制 -->
    <el-input
      v-model="text"
      maxlength="100"
      placeholder="请输入内容"
      show-word-limit
      type="textarea"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Search, Calendar } from '@element-plus/icons-vue'

const input1 = ref('')
const input2 = ref('')
const input3 = ref('')
const input4 = ref('')
const input5 = ref('')
const textarea = ref('')
const password = ref('')
const text = ref('')
</script>
```

### 3.2 选择器（Select）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-select v-model="value1" placeholder="请选择">
      <el-option
        v-for="item in options"
        :key="item.value"
        :label="item.label"
        :value="item.value"
      />
    </el-select>

    <!-- 可清空 -->
    <el-select v-model="value2" clearable placeholder="请选择">
      <el-option
        v-for="item in options"
        :key="item.value"
        :label="item.label"
        :value="item.value"
      />
    </el-select>

    <!-- 多选 -->
    <el-select v-model="value3" multiple placeholder="请选择">
      <el-option
        v-for="item in options"
        :key="item.value"
        :label="item.label"
        :value="item.value"
      />
    </el-select>

    <!-- 远程搜索 -->
    <el-select
      v-model="value4"
      filterable
      remote
      reserve-keyword
      placeholder="请输入关键词"
      :remote-method="remoteMethod"
      :loading="loading"
    >
      <el-option
        v-for="item in remoteOptions"
        :key="item.value"
        :label="item.label"
        :value="item.value"
      />
    </el-select>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const options = [
  { value: 'option1', label: '选项1' },
  { value: 'option2', label: '选项2' },
  { value: 'option3', label: '选项3' }
]

const value1 = ref('')
const value2 = ref('')
const value3 = ref([])
const value4 = ref('')
const loading = ref(false)
const remoteOptions = ref([])

const remoteMethod = (query: string) => {
  if (query) {
    loading.value = true
    // 模拟远程搜索
    setTimeout(() => {
      loading.value = false
      remoteOptions.value = options.filter(item => 
        item.label.toLowerCase().includes(query.toLowerCase())
      )
    }, 200)
  } else {
    remoteOptions.value = []
  }
}
</script>
```

### 3.3 级联选择器（Cascader）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-cascader v-model="value1" :options="cascaderOptions" />

    <!-- 可清空 -->
    <el-cascader v-model="value2" :options="cascaderOptions" clearable />

    <!-- 仅显示最后一级 -->
    <el-cascader v-model="value3" :options="cascaderOptions" :show-all-levels="false" />

    <!-- 多选 -->
    <el-cascader v-model="value4" :options="cascaderOptions" :props="{ multiple: true }" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const cascaderOptions = [
  {
    value: '1',
    label: '手机数码',
    children: [
      { value: '11', label: '手机' },
      { value: '12', label: '平板电脑' },
      { value: '13', label: '智能手表' }
    ]
  },
  {
    value: '2',
    label: '电脑办公',
    children: [
      { value: '21', label: '笔记本' },
      { value: '22', label: '台式机' },
      { value: '23', label: '显示器' }
    ]
  }
]

const value1 = ref([])
const value2 = ref([])
const value3 = ref([])
const value4 = ref([])
</script>
```

### 3.4 开关（Switch）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-switch v-model="value1" />

    <!-- 文字描述 -->
    <el-switch
      v-model="value2"
      active-text="上架"
      inactive-text="下架"
    />

    <!-- 自定义值 -->
    <el-switch
      v-model="value3"
      :active-value="1"
      :inactive-value="0"
      active-text="显示"
      inactive-text="隐藏"
    />

    <!-- 禁用状态 -->
    <el-switch v-model="value4" disabled />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const value1 = ref(true)
const value2 = ref(true)
const value3 = ref(1)
const value4 = ref(true)
</script>
```

### 3.5 表单（Form）与验证

```vue
<template>
  <el-form
    ref="formRef"
    :model="form"
    :rules="rules"
    label-width="120px"
    status-icon
  >
    <el-form-item label="分类名称" prop="name">
      <el-input v-model="form.name" placeholder="请输入分类名称" />
    </el-form-item>

    <el-form-item label="上级分类" prop="parentId">
      <el-select v-model="form.parentId" placeholder="请选择上级分类">
        <el-option label="无上级分类" :value="0" />
        <el-option
          v-for="item in parentOptions"
          :key="item.id"
          :label="item.name"
          :value="item.id"
        />
      </el-select>
    </el-form-item>

    <el-form-item label="数量单位" prop="productUnit">
      <el-input v-model="form.productUnit" placeholder="例如：件、个、套" />
    </el-form-item>

    <el-form-item label="排序" prop="sort">
      <el-input-number v-model="form.sort" :min="0" />
    </el-form-item>

    <el-form-item label="是否显示">
      <el-switch
        v-model="form.showStatus"
        :active-value="1"
        :inactive-value="0"
      />
    </el-form-item>

    <el-form-item label="导航栏显示">
      <el-switch
        v-model="form.navStatus"
        :active-value="1"
        :inactive-value="0"
      />
    </el-form-item>

    <el-form-item label="分类描述" prop="description">
      <el-input
        v-model="form.description"
        type="textarea"
        :rows="3"
        placeholder="请输入分类描述"
      />
    </el-form-item>

    <el-form-item>
      <el-button type="primary" @click="submitForm">提交</el-button>
      <el-button @click="resetForm">重置</el-button>
    </el-form-item>
  </el-form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'

interface CategoryForm {
  name: string
  parentId: number
  productUnit: string
  sort: number
  showStatus: number
  navStatus: number
  description: string
}

const formRef = ref<FormInstance>()

const form = reactive<CategoryForm>({
  name: '',
  parentId: 0,
  productUnit: '',
  sort: 0,
  showStatus: 1,
  navStatus: 1,
  description: ''
})

const rules = reactive<FormRules<CategoryForm>>({
  name: [
    { required: true, message: '请输入分类名称', trigger: 'blur' },
    { min: 2, max: 50, message: '长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  parentId: [
    { required: true, message: '请选择上级分类', trigger: 'change' }
  ],
  productUnit: [
    { required: true, message: '请输入数量单位', trigger: 'blur' }
  ],
  sort: [
    { required: true, message: '请输入排序', trigger: 'blur' }
  ]
})

const parentOptions = ref([
  { id: 1, name: '手机数码' },
  { id: 2, name: '电脑办公' }
])

const submitForm = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate((valid, fields) => {
    if (valid) {
      ElMessage.success('提交成功')
      console.log('表单数据:', form)
    } else {
      console.log('验证失败:', fields)
    }
  })
}

const resetForm = () => {
  if (!formRef.value) return
  formRef.value.resetFields()
}
</script>
```

## 4. 数据展示组件

### 4.1 表格（Table）

```vue
<template>
  <div>
    <!-- 基础表格 -->
    <el-table :data="tableData" style="width: 100%" border>
      <el-table-column prop="date" label="日期" width="180" />
      <el-table-column prop="name" label="姓名" width="180" />
      <el-table-column prop="address" label="地址" />
    </el-table>

    <!-- 带操作的表格 -->
    <el-table :data="tableData" style="width: 100%; margin-top: 20px" border>
      <el-table-column type="selection" width="55" />
      <el-table-column prop="id" label="ID" width="80" align="center" />
      <el-table-column prop="name" label="名称" align="center" />
      <el-table-column prop="status" label="状态" align="center">
        <template #default="scope">
          <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
            {{ scope.row.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="180">
        <template #default="scope">
          <el-button size="small" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button size="small" type="danger" @click="handleDelete(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 自定义列内容 -->
    <el-table :data="tableData" style="width: 100%; margin-top: 20px" border>
      <el-table-column label="用户信息" align="center">
        <template #default="scope">
          <div>
            <p><strong>{{ scope.row.name }}</strong></p>
            <p style="color: #999; font-size: 12px">{{ scope.row.address }}</p>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="自定义表头" align="center">
        <template #header>
          <span>自定义表头</span>
          <el-tooltip content="这里是提示信息" placement="top">
            <el-icon><QuestionFilled /></el-icon>
          </el-tooltip>
        </template>
        <template #default="scope">
          {{ scope.row.date }}
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { QuestionFilled } from '@element-plus/icons-vue'

const tableData = [
  { id: 1, date: '2024-01-01', name: '张三', address: '北京市', status: 1 },
  { id: 2, date: '2024-01-02', name: '李四', address: '上海市', status: 0 },
  { id: 3, date: '2024-01-03', name: '王五', address: '广州市', status: 1 }
]

const handleEdit = (row: any) => {
  console.log('编辑:', row)
}

const handleDelete = (row: any) => {
  console.log('删除:', row)
}
</script>
```

### 4.2 分页（Pagination）

```vue
<template>
  <div>
    <!-- 基础分页 -->
    <el-pagination
      v-model:current-page="currentPage"
      v-model:page-size="pageSize"
      :page-sizes="[10, 20, 50, 100]"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />

    <!-- 简洁分页 -->
    <el-pagination
      v-model:current-page="currentPage2"
      :page-size="10"
      :total="100"
      layout="prev, pager, next"
      @current-change="handleCurrentChange"
    />

    <!-- 带背景色的分页 -->
    <el-pagination
      v-model:current-page="currentPage3"
      :page-size="10"
      :total="100"
      background
      layout="prev, pager, next"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(100)
const currentPage2 = ref(1)
const currentPage3 = ref(1)

const handleSizeChange = (val: number) => {
  console.log(`每页 ${val} 条`)
  // 重新加载数据
}

const handleCurrentChange = (val: number) => {
  console.log(`当前页: ${val}`)
  // 重新加载数据
}
</script>
```

### 4.3 标签（Tag）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-tag>标签一</el-tag>
    <el-tag type="success">标签二</el-tag>
    <el-tag type="info">标签三</el-tag>
    <el-tag type="warning">标签四</el-tag>
    <el-tag type="danger">标签五</el-tag>

    <!-- 可关闭标签 -->
    <el-tag
      v-for="tag in tags"
      :key="tag.name"
      closable
      :type="tag.type"
      @close="handleClose(tag)"
    >
      {{ tag.name }}
    </el-tag>

    <!-- 动态编辑标签 -->
    <el-tag
      v-for="tag in dynamicTags"
      :key="tag"
      closable
      :disable-transitions="false"
      @close="handleCloseDynamic(tag)"
    >
      {{ tag }}
    </el-tag>
    <el-input
      v-if="inputVisible"
      ref="InputRef"
      v-model="inputValue"
      class="w-20"
      size="small"
      @keyup.enter="handleInputConfirm"
      @blur="handleInputConfirm"
    />
    <el-button v-else class="button-new-tag" size="small" @click="showInput">
      + 新标签
    </el-button>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import type { InputInstance } from 'element-plus'

const tags = ref([
  { name: '标签1', type: '' },
  { name: '标签2', type: 'success' },
  { name: '标签3', type: 'info' }
])

const handleClose = (tag: any) => {
  tags.value = tags.value.filter(t => t.name !== tag.name)
}

const dynamicTags = ref(['标签一', '标签二', '标签三'])
const inputVisible = ref(false)
const inputValue = ref('')
const InputRef = ref<InputInstance>()

const handleCloseDynamic = (tag: string) => {
  dynamicTags.value.splice(dynamicTags.value.indexOf(tag), 1)
}

const showInput = () => {
  inputVisible.value = true
  nextTick(() => {
    InputRef.value!.input!.focus()
  })
}

const handleInputConfirm = () => {
  if (inputValue.value) {
    dynamicTags.value.push(inputValue.value)
  }
  inputVisible.value = false
  inputValue.value = ''
}
</script>
```

## 5. 反馈组件

### 5.1 消息提示（Message）

```vue
<script setup lang="ts">
import { ElMessage } from 'element-plus'

const openSuccess = () => {
  ElMessage.success('操作成功')
}

const openWarning = () => {
  ElMessage.warning('警告信息')
}

const openError = () => {
  ElMessage.error('错误信息')
}

const openInfo = () => {
  ElMessage.info('提示信息')
}

const openCustom = () => {
  ElMessage({
    message: '自定义消息',
    type: 'success',
    duration: 5000,
    showClose: true
  })
}
</script>

<template>
  <div>
    <el-button @click="openSuccess">成功</el-button>
    <el-button @click="openWarning">警告</el-button>
    <el-button @click="openError">错误</el-button>
    <el-button @click="openInfo">信息</el-button>
    <el-button @click="openCustom">自定义</el-button>
  </div>
</template>
```

### 5.2 消息确认框（MessageBox）

```vue
<script setup lang="ts">
import { ElMessage, ElMessageBox } from 'element-plus'

const openConfirm = () => {
  ElMessageBox.confirm(
    '此操作将永久删除该文件, 是否继续?',
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  )
    .then(() => {
      ElMessage.success('删除成功!')
    })
    .catch(() => {
      ElMessage.info('已取消删除')
    })
}

const openPrompt = () => {
  ElMessageBox.prompt('请输入邮箱', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    inputPattern: /[\w!#$%&'*+/=?^_`{|}~-]+(?:\.[\w!#$%&'*+/=?^_`{|}~-]+)*@(?:[\w](?:[\w-]*[\w])?\.)+[\w](?:[\w-]*[\w])?/,
    inputErrorMessage: '邮箱格式不正确'
  })
    .then(({ value }) => {
      ElMessage.success(`你的邮箱是: ${value}`)
    })
    .catch(() => {
      ElMessage.info('取消输入')
    })
}
</script>

<template>
  <div>
    <el-button @click="openConfirm">打开确认框</el-button>
    <el-button @click="openPrompt">打开输入框</el-button>
  </div>
</template>
```

### 5.3 对话框（Dialog）

```vue
<template>
  <div>
    <el-button @click="dialogVisible = true">打开对话框</el-button>

    <el-dialog
      v-model="dialogVisible"
      title="提示"
      width="30%"
      :before-close="handleClose"
    >
      <span>这是一段信息</span>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="dialogVisible = false">
            确定
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 嵌套表单的对话框 -->
    <el-button @click="dialogFormVisible = true">打开嵌套表单</el-button>

    <el-dialog v-model="dialogFormVisible" title="收货地址">
      <el-form :model="form">
        <el-form-item label="活动名称" :label-width="formLabelWidth">
          <el-input v-model="form.name" autocomplete="off" />
        </el-form-item>
        <el-form-item label="活动区域" :label-width="formLabelWidth">
          <el-select v-model="form.region" placeholder="请选择活动区域">
            <el-option label="区域一" value="shanghai" />
            <el-option label="区域二" value="beijing" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogFormVisible = false">取消</el-button>
          <el-button type="primary" @click="dialogFormVisible = false">
            确定
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessageBox } from 'element-plus'

const dialogVisible = ref(false)
const dialogFormVisible = ref(false)
const formLabelWidth = '120px'

const form = reactive({
  name: '',
  region: ''
})

const handleClose = (done: () => void) => {
  ElMessageBox.confirm('确定关闭对话框吗？')
    .then(() => {
      done()
    })
    .catch(() => {
      // 取消关闭
    })
}
</script>
```

### 5.4 加载状态（Loading）

```vue
<template>
  <div>
    <!-- 指令方式 -->
    <el-table v-loading="loading" :data="tableData">
      <el-table-column prop="date" label="日期" />
      <el-table-column prop="name" label="姓名" />
    </el-table>

    <!-- 服务方式 -->
    <el-button @click="openFullScreen">全屏加载</el-button>

    <!-- 自定义加载文本 -->
    <div v-loading="loading" element-loading-text="拼命加载中...">
      内容区域
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElLoading } from 'element-plus'

const loading = ref(true)
const tableData = ref([])

const openFullScreen = () => {
  const loadingInstance = ElLoading.service({
    lock: true,
    text: 'Loading',
    background: 'rgba(0, 0, 0, 0.7)'
  })
  
  setTimeout(() => {
    loadingInstance.close()
  }, 2000)
}
</script>
```

## 6. 导航组件

### 6.1 菜单（Menu）

```vue
<template>
  <el-menu
    :default-active="activeIndex"
    class="el-menu-demo"
    mode="horizontal"
    @select="handleSelect"
  >
    <el-menu-item index="1">处理中心</el-menu-item>
    <el-sub-menu index="2">
      <template #title>我的工作台</template>
      <el-menu-item index="2-1">选项1</el-menu-item>
      <el-menu-item index="2-2">选项2</el-menu-item>
      <el-menu-item index="2-3">选项3</el-menu-item>
    </el-sub-menu>
    <el-menu-item index="3">消息中心</el-menu-item>
    <el-menu-item index="4">订单管理</el-menu-item>
  </el-menu>

  <!-- 侧边栏菜单 -->
  <el-menu
    default-active="2"
    class="el-menu-vertical-demo"
    :collapse="isCollapse"
    @open="handleOpen"
    @close="handleClose"
  >
    <el-sub-menu index="1">
      <template #title>
        <el-icon><location /></el-icon>
        <span>导航一</span>
      </template>
      <el-menu-item index="1-1">选项1</el-menu-item>
      <el-menu-item index="1-2">选项2</el-menu-item>
    </el-sub-menu>
    <el-menu-item index="2">
      <el-icon><icon-menu /></el-icon>
      <span>导航二</span>
    </el-menu-item>
    <el-menu-item index="3" disabled>
      <el-icon><document /></el-icon>
      <span>导航三</span>
    </el-menu-item>
  </el-menu>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Location, Menu as IconMenu, Document } from '@element-plus/icons-vue'

const activeIndex = ref('1')
const isCollapse = ref(false)

const handleSelect = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}

const handleOpen = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}

const handleClose = (key: string, keyPath: string[]) => {
  console.log(key, keyPath)
}
</script>
```

### 6.2 面包屑（Breadcrumb）

```vue
<template>
  <div>
    <!-- 基础用法 -->
    <el-breadcrumb separator="/">
      <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>活动管理</el-breadcrumb-item>
      <el-breadcrumb-item>活动列表</el-breadcrumb-item>
      <el-breadcrumb-item>活动详情</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 图标分隔符 -->
    <el-breadcrumb separator-icon="ArrowRight">
      <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>活动管理</el-breadcrumb-item>
      <el-breadcrumb-item>活动列表</el-breadcrumb-item>
    </el-breadcrumb>
  </div>
</template>
```

## 7. 组件二次封装

### 7.1 封装通用表格组件

```vue
<!-- components/CommonTable/index.vue -->
<template>
  <div class="common-table">
    <el-table
      v-loading="loading"
      :data="data"
      style="width: 100%"
      border
      @selection-change="handleSelectionChange"
    >
      <el-table-column v-if="showSelection" type="selection" width="55" />
      <el-table-column v-if="showIndex" type="index" label="序号" width="60" align="center" />
      
      <slot />
      
      <el-table-column v-if="showOperation" label="操作" :width="operationWidth" align="center">
        <template #default="scope">
          <slot name="operation" :row="scope.row" :$index="scope.$index" />
        </template>
      </el-table-column>
    </el-table>

    <div v-if="showPagination" class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  data: any[]
  loading?: boolean
  total?: number
  pageNum?: number
  pageSize?: number
  showSelection?: boolean
  showIndex?: boolean
  showOperation?: boolean
  showPagination?: boolean
  operationWidth?: number
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  total: 0,
  pageNum: 1,
  pageSize: 10,
  showSelection: false,
  showIndex: true,
  showOperation: true,
  showPagination: true,
  operationWidth: 180
})

const emit = defineEmits<{
  (e: 'update:pageNum', value: number): void
  (e: 'update:pageSize', value: number): void
  (e: 'paginationChange'): void
  (e: 'selectionChange', value: any[]): void
}>()

const currentPage = computed({
  get: () => props.pageNum,
  set: (val) => emit('update:pageNum', val)
})

const pageSize = computed({
  get: () => props.pageSize,
  set: (val) => emit('update:pageSize', val)
})

const handleSizeChange = () => {
  emit('paginationChange')
}

const handleCurrentChange = () => {
  emit('paginationChange')
}

const handleSelectionChange = (val: any[]) => {
  emit('selectionChange', val)
}
</script>

<style scoped>
.pagination-container {
  margin-top: 20px;
  text-align: right;
}
</style>
```

使用封装后的组件：

```vue
<template>
  <CommonTable
    :data="list"
    :loading="listLoading"
    :total="total"
    v-model:page-num="listQuery.pageNum"
    v-model:page-size="listQuery.pageSize"
    @pagination-change="getList"
  >
    <el-table-column prop="name" label="名称" align="center" />
    <el-table-column prop="status" label="状态" align="center">
      <template #default="scope">
        <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
          {{ scope.row.status === 1 ? '启用' : '禁用' }}
        </el-tag>
      </template>
    </el-table-column>
    
    <template #operation="{ row }">
      <el-button size="small" @click="handleEdit(row)">编辑</el-button>
      <el-button size="small" type="danger" @click="handleDelete(row)">删除</el-button>
    </template>
  </CommonTable>
</template>
```

## 8. 主题定制

### 8.1 覆盖Element Plus样式

```scss
// styles/element-plus.scss

// 覆盖主题色
:root {
  --el-color-primary: #409EFF;
  --el-color-success: #67C23A;
  --el-color-warning: #E6A23C;
  --el-color-danger: #F56C6C;
  --el-color-info: #909399;
}

// 覆盖按钮样式
.el-button {
  &--primary {
    background-color: #409EFF;
    border-color: #409EFF;
  }
}

// 覆盖表格样式
.el-table {
  .el-table__header {
    th {
      background-color: #f5f7fa;
      color: #606266;
      font-weight: 600;
    }
  }
}

// 覆盖分页样式
.el-pagination {
  .el-pagination__total {
    margin-right: 16px;
  }
}
```

### 8.2 暗黑模式

```vue
<script setup lang="ts">
import { ref, watch } from 'vue'
import { useDark, useToggle } from '@vueuse/core'

const isDark = useDark()
const toggleDark = useToggle(isDark)
</script>

<template>
  <el-switch
    v-model="isDark"
    active-icon="Moon"
    inactive-icon="Sunny"
    @change="toggleDark"
  />
</template>
```

## 9. 实践练习

### 练习1：创建一个商品分类选择组件

```vue
<!-- components/CategorySelect/index.vue -->
<template>
  <el-cascader
    v-model="selectedValue"
    :options="categoryOptions"
    :props="cascaderProps"
    clearable
    placeholder="请选择商品分类"
    @change="handleChange"
  />
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getProductCategoryListWithChildrenAPI } from '@/apis/productCate'
import type { PmsProductCategoryExt } from '@/types/productCate'

const selectedValue = defineModel<number[]>({ default: () => [] })

const emit = defineEmits<{
  (e: 'change', value: number[]): void
}>()

const categoryOptions = ref<PmsProductCategoryExt[]>([])

const cascaderProps = {
  value: 'id',
  label: 'name',
  children: 'children'
}

const loadCategories = async () => {
  const res = await getProductCategoryListWithChildrenAPI()
  categoryOptions.value = res.data
}

const handleChange = (value: number[]) => {
  emit('change', value)
}

onMounted(() => {
  loadCategories()
})
</script>
```

### 练习2：创建一个搜索表单组件

```vue
<!-- components/SearchForm/index.vue -->
<template>
  <el-card class="search-form" shadow="never">
    <div class="search-header">
      <el-icon><Search /></el-icon>
      <span>筛选搜索</span>
      <div class="search-actions">
        <el-button @click="handleReset">重置</el-button>
        <el-button type="primary" @click="handleSearch">查询结果</el-button>
      </div>
    </div>
    <div class="search-content">
      <slot />
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { Search } from '@element-plus/icons-vue'

const emit = defineEmits<{
  (e: 'search'): void
  (e: 'reset'): void
}>()

const handleSearch = () => {
  emit('search')
}

const handleReset = () => {
  emit('reset')
}
</script>

<style scoped>
.search-form {
  margin-bottom: 20px;
}

.search-header {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  
  .el-icon {
    margin-right: 8px;
  }
  
  .search-actions {
    margin-left: auto;
  }
}

.search-content {
  :deep(.el-form-item) {
    margin-bottom: 18px;
  }
}
</style>
```

## 10. 常见问题

### Q1: 如何解决组件类型提示问题？

安装 Element Plus 的类型声明：

```bash
npm install -D @element-plus/types
```

在 `tsconfig.json` 中添加：

```json
{
  "compilerOptions": {
    "types": ["element-plus/global"]
  }
}
```

### Q2: 如何按需引入组件样式？

使用 `unplugin-element-plus` 插件自动导入样式：

```typescript
// vite.config.ts
import ElementPlus from 'unplugin-element-plus/vite'

export default defineConfig({
  plugins: [
    ElementPlus({
      useSource: true
    })
  ]
})
```

### Q3: 如何处理组件的默认语言？

```typescript
// main.ts
import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

const app = createApp(App)
app.use(ElementPlus, { locale: zhCn })
```

## 11. 小结

本节我们学习了：

1. **基础组件**：Button、Icon、Card 的使用
2. **表单组件**：Input、Select、Switch、Form 及表单验证
3. **数据展示**：Table、Pagination、Tag 的使用
4. **反馈组件**：Message、MessageBox、Dialog、Loading
5. **导航组件**：Menu、Breadcrumb 的使用
6. **组件封装**：如何封装通用组件提高复用性
7. **主题定制**：覆盖默认样式、暗黑模式

下一节将基于这些组件，实际开发商品分类列表页面。

## 参考资源

- [Element Plus 官方文档](https://element-plus.org/zh-CN/)
- [Element Plus GitHub](https://github.com/element-plus/element-plus)
- [Element Plus 图标库](https://element-plus.org/zh-CN/component/icon.html)
