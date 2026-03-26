# 第20节：商品发布表单开发

## 学习目标

- 掌握复杂表单的分步实现
- 理解表单数据的联动和校验
- 学会使用 Tabs 组织复杂表单
- 掌握富文本编辑器的集成

## 1. 页面功能分析

商品发布是一个复杂的多步骤表单，包含以下模块：

1. **商品信息**：名称、副标题、品牌、分类、货号等
2. **促销信息**：价格、库存、预警值、重量等
3. **属性信息**：选择属性分类，动态生成属性表单
4. **SKU信息**：根据规格属性自动生成SKU组合
5. **商品详情**：富文本编辑器编辑商品详情
6. **关联信息**：关联专题、优选等

## 2. 类型定义

### 2.1 商品发布DTO（types/product.d.ts）

```typescript
/** 商品发布DTO */
export type ProductPublishDto = {
  /** 商品ID（编辑时使用） */
  id?: number
  /** 品牌ID */
  brandId?: number
  /** 商品分类ID */
  productCategoryId?: number
  /** 商品属性分类ID */
  productAttributeCategoryId?: number
  /** 商品名称 */
  name?: string
  /** 副标题 */
  subTitle?: string
  /** 商品描述 */
  description?: string
  /** 商品货号 */
  productSn?: string
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
  /** 画册图片（逗号分隔） */
  albumPics?: string
  /** 商品详情 */
  detailHtml?: string
  /** 关键字 */
  keywords?: string
  /** 备注 */
  note?: string
  /** 上架状态 */
  publishStatus?: number
  /** 新品状态 */
  newStatus?: number
  /** 推荐状态 */
  recommandStatus?: number
  /** 商品属性值列表 */
  productAttributeValueList?: ProductAttributeValueDto[]
  /** SKU库存列表 */
  skuStockList?: PmsSkuStock[]
}

/** 商品属性值DTO */
export type ProductAttributeValueDto = {
  /** 属性ID */
  productAttributeId?: number
  /** 属性名称 */
  name?: string
  /** 属性值 */
  value?: string
  /** 属性类型：0->规格；1->参数 */
  type?: number
}
```

## 3. API 接口封装

### 3.1 商品发布 API（apis/product.ts）

```typescript
import type { ProductPublishDto } from '@/types/product'
import http from '@/utils/http'

/**
 * 发布商品
 */
export function productPublishAPI(data: ProductPublishDto) {
  return http<CommonResult<null>>({
    url: '/product/publish',
    method: 'post',
    data
  })
}

/**
 * 更新商品
 */
export function productUpdateAPI(id: number, data: ProductPublishDto) {
  return http<CommonResult<null>>({
    url: '/product/update/' + id,
    method: 'post',
    data
  })
}

/**
 * 根据ID获取商品详情
 */
export function getProductDetailAPI(id: number) {
  return http<CommonResult<ProductPublishDto>>({
    url: '/product/detail/' + id,
    method: 'get'
  })
}
```

## 4. 商品发布页面实现

### 4.1 页面结构

```vue
<template>
  <div class="app-container">
    <!-- 页面标题 -->
    <el-card class="operate-container" shadow="never">
      <el-icon><Tickets /></el-icon>
      <span>{{ isEdit ? '编辑商品' : '添加商品' }}</span>
    </el-card>

    <!-- 商品表单 -->
    <el-form 
      ref="productFormRef"
      :model="productForm"
      :rules="rules"
      label-width="120px"
      status-icon
    >
      <!-- 使用Tabs组织表单 -->
      <el-tabs v-model="activeTab" type="card">
        <!-- 商品信息 -->
        <el-tab-pane label="商品信息" name="info">
          <ProductInfoDetail 
            v-model:form="productForm"
            :brand-options="brandOptions"
            :category-options="categoryOptions"
          />
        </el-tab-pane>

        <!-- 促销信息 -->
        <el-tab-pane label="促销信息" name="sale">
          <ProductSaleDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 属性信息 -->
        <el-tab-pane label="属性信息" name="attr">
          <ProductAttrDetail 
            v-model:form="productForm"
            :attribute-options="attributeOptions"
          />
        </el-tab-pane>

        <!-- SKU信息 -->
        <el-tab-pane label="SKU信息" name="sku">
          <ProductSkuDetail 
            v-model:form="productForm"
          />
        </el-tab-pane>

        <!-- 商品详情 -->
        <el-tab-pane label="商品详情" name="detail">
          <ProductDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 关联信息 -->
        <el-tab-pane label="关联信息" name="relation">
          <ProductRelationDetail v-model:form="productForm" />
        </el-tab-pane>
      </el-tabs>

      <!-- 提交按钮 -->
      <div class="form-footer">
        <el-button @click="handleCancel">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitLoading">
          {{ isEdit ? '保存' : '发布' }}
        </el-button>
      </div>
    </el-form>
  </div>
</template>
```

### 4.2 完整代码（views/pms/product/components/ProductInfoDetail.vue）

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import type { ProductPublishDto } from '@/types/product'
import { getBrandListAPI } from '@/apis/brand'
import { getProductCategoryListWithChildrenAPI } from '@/apis/productCate'
import { getProductAttributeCategoryListAPI } from '@/apis/productAttr'

// ==================== Props ====================
const props = defineProps<{
  form: ProductPublishDto
}>()

const emit = defineEmits<{
  (e: 'update:form', value: ProductPublishDto): void
}>()

// ==================== 选项数据 ====================

// 品牌选项
const brandOptions = ref<{ label: string; value: number }[]>([])

// 商品分类选项
const categoryOptions = ref<{ label: string; value: number; children?: any[] }[]>([])

// 属性分类选项
const attributeCategoryOptions = ref<{ label: string; value: number }[]>([])

// 选中的分类值
const selectedCategory = ref<number[]>([])

// ==================== 表单验证规则 ====================

const rules: FormRules = {
  name: [
    { required: true, message: '请输入商品名称', trigger: 'blur' },
    { min: 2, max: 140, message: '长度在 2 到 140 个字符', trigger: 'blur' }
  ],
  subTitle: [
    { required: true, message: '请输入商品副标题', trigger: 'blur' }
  ],
  brandId: [
    { required: true, message: '请选择商品品牌', trigger: 'change' }
  ],
  productCategoryId: [
    { required: true, message: '请选择商品分类', trigger: 'change' }
  ],
  productAttributeCategoryId: [
    { required: true, message: '请选择属性分类', trigger: 'change' }
  ],
  productSn: [
    { required: true, message: '请输入商品货号', trigger: 'blur' }
  ]
}

// ==================== 方法 ====================

/**
 * 获取品牌列表
 */
const getBrandList = async () => {
  const res = await getBrandListAPI({ pageNum: 1, pageSize: 100 })
  brandOptions.value = res.data.list.map(item => ({
    label: item.name!,
    value: item.id!
  }))
}

/**
 * 获取商品分类列表
 */
const getCategoryList = async () => {
  const res = await getProductCategoryListWithChildrenAPI()
  categoryOptions.value = res.data.map(item => ({
    label: item.name!,
    value: item.id!,
    children: item.children?.map(child => ({
      label: child.name!,
      value: child.id!
    }))
  }))
}

/**
 * 获取属性分类列表
 */
const getAttributeCategoryList = async () => {
  const res = await getProductAttributeCategoryListAPI({ pageNum: 1, pageSize: 100 })
  attributeCategoryOptions.value = res.data.list.map(item => ({
    label: item.name!,
    value: item.id!
  }))
}

/**
 * 处理分类选择变化
 */
const handleCategoryChange = (value: number[]) => {
  if (value && value.length === 2) {
    emit('update:form', {
      ...props.form,
      productCategoryId: value[1]
    })
  }
}

// ==================== 生命周期 ====================

onMounted(() => {
  getBrandList()
  getCategoryList()
  getAttributeCategoryList()
})
</script>

<template>
  <div class="form-container">
    <el-form-item label="商品分类：" prop="productCategoryId">
      <el-cascader
        v-model="selectedCategory"
        :options="categoryOptions"
        placeholder="请选择商品分类"
        @change="handleCategoryChange"
      />
    </el-form-item>

    <el-form-item label="商品名称：" prop="name">
      <el-input 
        v-model="form.name" 
        placeholder="请输入商品名称"
        style="width: 400px"
      />
    </el-form-item>

    <el-form-item label="副标题：" prop="subTitle">
      <el-input 
        v-model="form.subTitle" 
        placeholder="请输入商品副标题"
        style="width: 400px"
      />
    </el-form-item>

    <el-form-item label="商品品牌：" prop="brandId">
      <el-select v-model="form.brandId" placeholder="请选择品牌">
        <el-option
          v-for="item in brandOptions"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        />
      </el-select>
    </el-form-item>

    <el-form-item label="商品介绍：">
      <el-input
        v-model="form.description"
        type="textarea"
        :rows="3"
        placeholder="请输入商品介绍"
        style="width: 400px"
      />
    </el-form-item>

    <el-form-item label="商品货号：" prop="productSn">
      <el-input 
        v-model="form.productSn" 
        placeholder="请输入商品货号"
        style="width: 200px"
      />
    </el-form-item>

    <el-form-item label="商品售价：">
      <el-input-number v-model="form.price" :min="0" :precision="2" />
    </el-form-item>

    <el-form-item label="市场价：">
      <el-input-number v-model="form.originalPrice" :min="0" :precision="2" />
    </el-form-item>

    <el-form-item label="商品库存：">
      <el-input-number v-model="form.stock" :min="0" />
    </el-form-item>

    <el-form-item label="库存预警值：">
      <el-input-number v-model="form.lowStock" :min="0" />
    </el-form-item>

    <el-form-item label="计量单位：">
      <el-input v-model="form.unit" placeholder="例如：件、个、套" style="width: 150px" />
    </el-form-item>

    <el-form-item label="商品重量：">
      <el-input-number v-model="form.weight" :min="0" :precision="2" />
      <span style="margin-left: 10px">克</span>
    </el-form-item>

    <el-form-item label="排序：">
      <el-input-number v-model="form.sort" :min="0" />
    </el-form-item>

    <el-form-item label="属性分类：" prop="productAttributeCategoryId">
      <el-select 
        v-model="form.productAttributeCategoryId" 
        placeholder="请选择属性分类"
      >
        <el-option
          v-for="item in attributeCategoryOptions"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        />
      </el-select>
    </el-form-item>
  </div>
</template>

<style scoped>
.form-container {
  padding: 20px;
}
</style>
```

### 4.3 促销信息组件（ProductSaleDetail.vue）

```vue
<script setup lang="ts">
import type { ProductPublishDto } from '@/types/product'

const props = defineProps<{
  form: ProductPublishDto
}>()

const emit = defineEmits<{
  (e: 'update:form', value: ProductPublishDto): void
}>()
</script>

<template>
  <div class="form-container">
    <el-form-item label="赠送积分：">
      <el-input-number :min="0" placeholder="请输入" />
    </el-form-item>

    <el-form-item label="赠送成长值：">
      <el-input-number :min="0" placeholder="请输入" />
    </el-form-item>

    <el-form-item label="积分购买限制：">
      <el-input-number :min="0" placeholder="请输入" />
    </el-form-item>

    <el-form-item label="预告商品：">
      <el-switch 
        v-model="form.publishStatus" 
        :active-value="0" 
        :inactive-value="1"
        active-text="是"
        inactive-text="否"
      />
    </el-form-item>

    <el-form-item label="商品上架：">
      <el-switch 
        v-model="form.publishStatus" 
        :active-value="1" 
        :inactive-value="0"
      />
    </el-form-item>

    <el-form-item label="商品推荐：">
      <div style="display: flex; gap: 20px;">
        <el-checkbox v-model="form.newStatus" :true-label="1" :false-label="0">
          新品
        </el-checkbox>
        <el-checkbox v-model="form.recommandStatus" :true-label="1" :false-label="0">
          推荐
        </el-checkbox>
      </div>
    </el-form-item>

    <el-form-item label="服务保证：">
      <el-checkbox-group>
        <el-checkbox label="无忧退货" />
        <el-checkbox label="快速退款" />
        <el-checkbox label="免费包邮" />
      </el-checkbox-group>
    </el-form-item>

    <el-form-item label="详细页标题：">
      <el-input placeholder="请输入详细页标题" style="width: 400px" />
    </el-form-item>

    <el-form-item label="详细页描述：">
      <el-input 
        type="textarea" 
        :rows="3" 
        placeholder="请输入详细页描述"
        style="width: 400px"
      />
    </el-form-item>

    <el-form-item label="商品关键字：">
      <el-input v-model="form.keywords" placeholder="请输入商品关键字" style="width: 400px" />
    </el-form-item>

    <el-form-item label="商品备注：">
      <el-input 
        v-model="form.note"
        type="textarea" 
        :rows="3" 
        placeholder="请输入商品备注"
        style="width: 400px"
      />
    </el-form-item>
  </div>
</template>

<style scoped>
.form-container {
  padding: 20px;
}
</style>
```

### 4.4 富文本编辑器组件（ProductDetail.vue）

```vue
<script setup lang="ts">
import { ref } from 'vue'
import Editor from '@tinymce/tinymce-vue'
import type { ProductPublishDto } from '@/types/product'

const props = defineProps<{
  form: ProductPublishDto
}>()

const emit = defineEmits<{
  (e: 'update:form', value: ProductPublishDto): void
}>()

// TinyMCE 配置
const tinymceInit = ref({
  language: 'zh_CN',
  height: 500,
  menubar: true,
  plugins: [
    'advlist autolink lists link image charmap print preview anchor',
    'searchreplace visualblocks code fullscreen',
    'insertdatetime media table paste code help wordcount'
  ],
  toolbar:
    'undo redo | formatselect | bold italic backcolor | \
    alignleft aligncenter alignright alignjustify | \
    bullist numlist outdent indent | removeformat | help',
  images_upload_handler: (blobInfo: any, success: any, failure: any) => {
    // 这里可以实现图片上传逻辑
    // const formData = new FormData()
    // formData.append('file', blobInfo.blob())
    // uploadImage(formData).then(res => success(res.data.url))
  }
})
</script>

<template>
  <div class="form-container">
    <el-form-item label="商品详情：">
      <Editor
        v-model="form.detailHtml"
        :init="tinymceInit"
      />
    </el-form-item>
  </div>
</template>

<style scoped>
.form-container {
  padding: 20px;
}
</style>
```

### 4.5 主页面完整代码

```vue
<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Tickets } from '@element-plus/icons-vue'
import { productPublishAPI, productUpdateAPI, getProductDetailAPI } from '@/apis/product'
import type { ProductPublishDto } from '@/types/product'

// 导入子组件
import ProductInfoDetail from './components/ProductInfoDetail.vue'
import ProductSaleDetail from './components/ProductSaleDetail.vue'
import ProductAttrDetail from './components/ProductAttrDetail.vue'
import ProductSkuDetail from './components/ProductSkuDetail.vue'
import ProductDetail from './components/ProductDetail.vue'
import ProductRelationDetail from './components/ProductRelationDetail.vue'

// ==================== 路由相关 ====================
const route = useRoute()
const router = useRouter()

// 判断是否编辑模式
const isEdit = ref(false)
const productId = ref<number>()

// ==================== 表单数据 ====================
const productFormRef = ref()

const productForm = reactive<ProductPublishDto>({
  name: '',
  subTitle: '',
  description: '',
  productSn: '',
  price: 0,
  originalPrice: 0,
  stock: 0,
  lowStock: 0,
  unit: '',
  weight: 0,
  sort: 0,
  publishStatus: 0,
  newStatus: 0,
  recommandStatus: 0,
  detailHtml: '',
  keywords: '',
  note: ''
})

// 当前激活的Tab
const activeTab = ref('info')

// 提交加载状态
const submitLoading = ref(false)

// ==================== 方法 ====================

/**
 * 获取商品详情（编辑模式）
 */
const getProductDetail = async () => {
  if (!productId.value) return
  
  try {
    const res = await getProductDetailAPI(productId.value)
    Object.assign(productForm, res.data)
  } catch (error) {
    console.error('获取商品详情失败:', error)
  }
}

/**
 * 提交表单
 */
const handleSubmit = async () => {
  // 验证表单
  const valid = await productFormRef.value?.validate().catch(() => false)
  if (!valid) {
    ElMessage.warning('请完善商品信息')
    return
  }

  submitLoading.value = true
  
  try {
    if (isEdit.value && productId.value) {
      // 编辑模式
      await productUpdateAPI(productId.value, productForm)
      ElMessage.success('保存成功')
    } else {
      // 新增模式
      await productPublishAPI(productForm)
      ElMessage.success('发布成功')
    }
    
    // 返回列表页
    router.push('/pms/product')
  } catch (error) {
    console.error('提交失败:', error)
  } finally {
    submitLoading.value = false
  }
}

/**
 * 取消
 */
const handleCancel = () => {
  router.back()
}

// ==================== 生命周期 ====================

onMounted(() => {
  // 检查是否有ID参数（编辑模式）
  if (route.query.id) {
    isEdit.value = true
    productId.value = Number(route.query.id)
    getProductDetail()
  }
})
</script>

<template>
  <div class="app-container">
    <!-- 页面标题 -->
    <el-card class="operate-container" shadow="never">
      <el-icon class="el-icon-middle">
        <Tickets />
      </el-icon>
      <span>{{ isEdit ? '编辑商品' : '添加商品' }}</span>
      <el-button style="float: right" @click="handleCancel">
        返回
      </el-button>
    </el-card>

    <!-- 商品表单 -->
    <el-form
      ref="productFormRef"
      :model="productForm"
      label-width="120px"
      status-icon
    >
      <el-tabs v-model="activeTab" type="card">
        <!-- 商品信息 -->
        <el-tab-pane label="商品信息" name="info">
          <ProductInfoDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 促销信息 -->
        <el-tab-pane label="促销信息" name="sale">
          <ProductSaleDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 属性信息 -->
        <el-tab-pane label="属性信息" name="attr">
          <ProductAttrDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- SKU信息 -->
        <el-tab-pane label="SKU信息" name="sku">
          <ProductSkuDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 商品详情 -->
        <el-tab-pane label="商品详情" name="detail">
          <ProductDetail v-model:form="productForm" />
        </el-tab-pane>

        <!-- 关联信息 -->
        <el-tab-pane label="关联信息" name="relation">
          <ProductRelationDetail v-model:form="productForm" />
        </el-tab-pane>
      </el-tabs>

      <!-- 提交按钮 -->
      <div class="form-footer">
        <el-button @click="handleCancel">取消</el-button>
        <el-button 
          type="primary" 
          @click="handleSubmit" 
          :loading="submitLoading"
        >
          {{ isEdit ? '保存' : '发布' }}
        </el-button>
      </div>
    </el-form>
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

.form-footer {
  margin-top: 30px;
  text-align: center;
  padding-bottom: 30px;
}
</style>
```

## 5. 代码详解

### 5.1 父子组件双向绑定

```vue
<!-- 父组件 -->
<ProductInfoDetail v-model:form="productForm" />

<!-- 子组件 -->
<script setup>
const props = defineProps<{
  form: ProductPublishDto
}>()

const emit = defineEmits<{
  (e: 'update:form', value: ProductPublishDto): void
}>()

// 更新表单数据
const handleChange = () => {
  emit('update:form', {
    ...props.form,
    name: '新值'
  })
}
</script>
```

### 5.2 Tabs 组件使用

```vue
<el-tabs v-model="activeTab" type="card">
  <el-tab-pane label="商品信息" name="info">
    <!-- 内容 -->
  </el-tab-pane>
  <el-tab-pane label="促销信息" name="sale">
    <!-- 内容 -->
  </el-tab-pane>
</el-tabs>
```

### 5.3 表单验证

```typescript
const rules: FormRules = {
  name: [
    { required: true, message: '请输入商品名称', trigger: 'blur' },
    { min: 2, max: 140, message: '长度在 2 到 140 个字符', trigger: 'blur' }
  ],
  brandId: [
    { required: true, message: '请选择商品品牌', trigger: 'change' }
  ]
}

// 提交时验证
const handleSubmit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) {
    ElMessage.warning('请完善商品信息')
    return
  }
  // 提交逻辑
}
```

## 6. 小结

本节我们完成了商品发布表单页面的开发：

1. **分步表单**：使用 Tabs 将复杂表单拆分为多个步骤
2. **组件化**：将不同模块拆分为独立子组件
3. **双向绑定**：使用 `v-model` 实现父子组件数据同步
4. **富文本编辑**：集成 TinyMCE 编辑器
5. **表单验证**：实现表单数据的校验

至此，前端商品模块的核心页面都已开发完成。

## 参考资源

- [Element Plus Tabs 组件](https://element-plus.org/zh-CN/component/tabs.html)
- [TinyMCE Vue 集成](https://www.tiny.cloud/docs/tinymce/6/vue-pm/)
- [Vue 3 组件 v-model](https://vuejs.org/guide/components/v-model.html)
