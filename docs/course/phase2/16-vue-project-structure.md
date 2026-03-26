# 第16节：Vue 3 + TypeScript 项目结构解析

## 学习目标

- 理解 mall-admin-web 项目整体架构
- 掌握 Vue 3 + TypeScript + Vite 技术栈
- 熟悉项目目录结构和代码组织方式
- 理解 Composition API 和 `<script setup>` 语法

## 1. 技术栈概览

mall-admin-web 采用现代化的前端技术栈：

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.5+ | 渐进式JavaScript框架 |
| TypeScript | 5.9+ | 类型安全的JavaScript超集 |
| Vite | 7.2+ | 下一代前端构建工具 |
| Element Plus | 2.12+ | UI组件库 |
| Vue Router | 4.6+ | 路由管理 |
| Pinia | 3.0+ | 状态管理 |
| Axios | 1.13+ | HTTP客户端 |

## 2. 项目目录结构

```
mall-admin-web/
├── public/                 # 静态资源（不经过构建）
│   ├── tinymce/           # 富文本编辑器静态文件
│   └── ...
├── src/
│   ├── apis/              # API接口封装
│   │   ├── productCate.ts
│   │   ├── product.ts
│   │   ├── brand.ts
│   │   └── ...
│   ├── components/        # 公共组件
│   │   ├── Breadcrumb/    # 面包屑导航
│   │   ├── Hamburger/     # 侧边栏折叠按钮
│   │   ├── SvgIcon/       # SVG图标组件
│   │   ├── Tinymce/       # 富文本编辑器
│   │   └── Upload/        # 上传组件
│   ├── composables/       # 组合式函数
│   ├── directives/        # 自定义指令
│   ├── router/            # 路由配置
│   │   └── index.ts
│   ├── stores/            # Pinia状态管理
│   │   ├── app.ts
│   │   ├── settings.ts
│   │   └── user.ts
│   ├── styles/            # 全局样式
│   │   ├── element-plus.scss
│   │   ├── index.scss
│   │   ├── mixin.scss
│   │   ├── sidebar.scss
│   │   └── variables.scss
│   ├── types/             # TypeScript类型定义
│   │   ├── common.d.ts
│   │   ├── productCate.d.ts
│   │   ├── product.d.ts
│   │   └── ...
│   ├── utils/             # 工具函数
│   │   ├── http.ts        # Axios封装
│   │   ├── auth.ts        # 认证相关
│   │   └── ...
│   ├── views/             # 页面组件
│   │   ├── home/          # 首页
│   │   ├── layout/        # 布局组件
│   │   ├── login/         # 登录页
│   │   ├── pms/           # 商品管理
│   │   │   ├── product/       # 商品列表
│   │   │   ├── productCate/   # 商品分类
│   │   │   ├── productAttr/   # 商品属性
│   │   │   └── brand/         # 品牌管理
│   │   ├── oms/           # 订单管理
│   │   ├── sms/           # 营销管理
│   │   └── ums/           # 权限管理
│   ├── App.vue            # 根组件
│   └── main.ts            # 入口文件
├── index.html             # HTML模板
├── package.json           # 依赖配置
├── tsconfig.json          # TypeScript配置
├── vite.config.ts         # Vite配置
└── ...
```

## 3. 核心概念讲解

### 3.1 Composition API vs Options API

Vue 3 引入了 Composition API，相比 Options API 有以下优势：

**Options API（Vue 2风格）：**
```vue
<script>
export default {
  data() {
    return {
      count: 0
    }
  },
  methods: {
    increment() {
      this.count++
    }
  },
  mounted() {
    console.log('组件挂载')
  }
}
</script>
```

**Composition API（Vue 3推荐）：**
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'

// 响应式数据
const count = ref(0)

// 方法
const increment = () => {
  count.value++
}

// 生命周期钩子
onMounted(() => {
  console.log('组件挂载')
})
</script>
```

### 3.2 `<script setup>` 语法糖

`<script setup>` 是 Vue 3.2+ 引入的编译时语法糖，特点：

1. **更简洁的代码**：无需 `return` 暴露变量
2. **更好的TypeScript支持**：类型推断更精准
3. **更好的运行时性能**：模板编译优化

```vue
<script setup lang="ts">
// 自动暴露给模板使用，无需 return
const message = 'Hello Vue 3'

// 导入的组件自动可用
import MyComponent from './MyComponent.vue'
</script>

<template>
  <div>{{ message }}</div>
  <MyComponent />
</template>
```

### 3.3 响应式系统

Vue 3 使用 Proxy 实现响应式，主要API：

```typescript
import { ref, reactive, computed, watch } from 'vue'

// ref: 基本类型的响应式引用
const count = ref(0)
console.log(count.value) // 访问值需要 .value

// reactive: 对象的响应式代理
const user = reactive({
  name: '张三',
  age: 25
})
console.log(user.name) // 直接访问属性

// computed: 计算属性
const doubleCount = computed(() => count.value * 2)

// watch: 侦听器
watch(count, (newVal, oldVal) => {
  console.log(`count变化: ${oldVal} -> ${newVal}`)
})
```

## 4. TypeScript 类型定义

### 4.1 接口定义（types/productCate.d.ts）

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
}

/** 商品分类信息扩展（包含子分类） */
export type PmsProductCategoryExt = PmsProductCategory & {
  /** 子级分类 */
  children?: PmsProductCategory[]
}
```

### 4.2 通用类型（types/common.d.ts）

```typescript
/** 通用返回结果封装类 */
export type CommonResult<T> = {
  /** 状态码 */
  code: number
  /** 提示信息 */
  message: string
  /** 封装数据 */
  data: T
}

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

## 5. API 接口封装

### 5.1 Axios 封装（utils/http.ts）

```typescript
import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'

// 创建axios实例
const http: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/admin',
  timeout: 10000
})

// 请求拦截器
http.interceptors.request.use(
  (config) => {
    // 添加token
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
http.interceptors.response.use(
  (response: AxiosResponse) => {
    const res = response.data
    if (res.code !== 200) {
      ElMessage.error(res.message || '请求失败')
      return Promise.reject(new Error(res.message))
    }
    return res
  },
  (error) => {
    ElMessage.error(error.message || '网络错误')
    return Promise.reject(error)
  }
)

export default http
```

### 5.2 API 模块（apis/productCate.ts）

```typescript
import type { CommonPage, PageParam } from '@/types/common'
import type { PmsProductCategory, PmsProductCategoryExt } from '@/types/productCate'
import http from '@/utils/http'

/**
 * 查询所有一级分类及子分类
 */
export function getProductCategoryListWithChildrenAPI() {
  return http<PmsProductCategoryExt[]>({
    url: '/productCategory/list/withChildren',
    method: 'get',
  })
}

/**
 * 分页查询商品分类
 */
export function getProductCategoryListAPI(parentId: number, params: PageParam) {
  return http<CommonPage<PmsProductCategory>>({
    url: '/productCategory/list/' + parentId,
    method: 'get',
    params: params,
  })
}

/**
 * 根据ID删除商品分类
 */
export function productCategoryDeleteByIdAPI(id: number) {
  return http({
    url: '/productCategory/delete/' + id,
    method: 'post',
  })
}

/**
 * 添加商品分类
 */
export function productCategoryCreateAPI(data: PmsProductCategory) {
  return http({
    url: '/productCategory/create',
    method: 'post',
    data: data,
  })
}

/**
 * 修改商品分类
 */
export function productCategoryUpdateByIdAPI(id: number, data: PmsProductCategory) {
  return http({
    url: '/productCategory/update/' + id,
    method: 'post',
    data: data,
  })
}
```

## 6. 路由配置

### 6.1 路由定义（router/index.ts）

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import Layout from '@/views/layout/Layout.vue'

const routes = [
  {
    path: '/login',
    component: () => import('@/views/normal/login/index.vue'),
    hidden: true
  },
  {
    path: '/',
    component: Layout,
    redirect: '/home',
    children: [
      {
        path: 'home',
        component: () => import('@/views/home/index.vue'),
        name: 'home',
        meta: { title: '首页', icon: 'home' }
      }
    ]
  },
  {
    path: '/pms',
    component: Layout,
    redirect: '/pms/product',
    name: 'pms',
    meta: { title: '商品', icon: 'product' },
    children: [
      {
        path: 'product',
        component: () => import('@/views/pms/product/index.vue'),
        name: 'product',
        meta: { title: '商品列表', icon: 'product-list' }
      },
      {
        path: 'addProduct',
        component: () => import('@/views/pms/product/add.vue'),
        name: 'addProduct',
        meta: { title: '添加商品', icon: 'product-add' }
      },
      {
        path: 'productCate',
        component: () => import('@/views/pms/productCate/index.vue'),
        name: 'productCate',
        meta: { title: '商品分类', icon: 'product-cate' }
      },
      {
        path: 'productAttr',
        component: () => import('@/views/pms/productAttr/index.vue'),
        name: 'productAttr',
        meta: { title: '商品类型', icon: 'product-attr' }
      },
      {
        path: 'brand',
        component: () => import('@/views/pms/brand/index.vue'),
        name: 'brand',
        meta: { title: '品牌管理', icon: 'product-brand' }
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

## 7. 状态管理（Pinia）

### 7.1 User Store（stores/user.ts）

```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  // State
  const token = ref(localStorage.getItem('token') || '')
  const userInfo = ref<any>(null)

  // Getters
  const isLoggedIn = computed(() => !!token.value)

  // Actions
  const setToken = (newToken: string) => {
    token.value = newToken
    localStorage.setItem('token', newToken)
  }

  const clearToken = () => {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('token')
  }

  const setUserInfo = (info: any) => {
    userInfo.value = info
  }

  return {
    token,
    userInfo,
    isLoggedIn,
    setToken,
    clearToken,
    setUserInfo
  }
})
```

## 8. 开发环境配置

### 8.1 Vite 配置（vite.config.ts）

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'

export default defineConfig({
  plugins: [
    vue(),
    // 自动导入Element Plus组件
    AutoImport({
      resolvers: [ElementPlusResolver()],
    }),
    Components({
      resolvers: [ElementPlusResolver()],
    }),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/admin': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})
```

### 8.2 TypeScript 配置（tsconfig.json）

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ESNext", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

## 9. 实践练习

### 练习1：创建第一个Vue组件

创建一个简单的计数器组件 `src/components/Counter.vue`：

```vue
<script setup lang="ts">
import { ref } from 'vue'

const count = ref(0)

const increment = () => {
  count.value++
}

const decrement = () => {
  count.value--
}
</script>

<template>
  <div class="counter">
    <h3>计数器</h3>
    <p>当前值: {{ count }}</p>
    <el-button @click="decrement">-</el-button>
    <el-button @click="increment">+</el-button>
  </div>
</template>

<style scoped>
.counter {
  padding: 20px;
  text-align: center;
}
</style>
```

### 练习2：类型安全的API调用

为品牌管理模块创建类型定义和API：

```typescript
// types/brand.d.ts
export type PmsBrand = {
  id?: number
  name: string
  firstLetter: string
  sort?: number
  factoryStatus: number
  showStatus: number
  productCount?: number
  productCommentCount?: number
  logo?: string
  bigPic?: string
  brandStory?: string
}
```

```typescript
// apis/brand.ts
import type { CommonPage, PageParam } from '@/types/common'
import type { PmsBrand } from '@/types/brand'
import http from '@/utils/http'

export function getBrandListAPI(params: PageParam & { keyword?: string }) {
  return http<CommonPage<PmsBrand>>({
    url: '/brand/list',
    method: 'get',
    params
  })
}

export function brandCreateAPI(data: PmsBrand) {
  return http({
    url: '/brand/create',
    method: 'post',
    data
  })
}
```

## 10. 常见问题

### Q1: `ref` 和 `reactive` 如何选择？

- **使用 `ref`**：基本类型（string, number, boolean）或需要重新赋值的对象
- **使用 `reactive`**：复杂对象，且不需要整体替换

```typescript
// ref适合需要替换整个对象的场景
const user = ref({ name: '张三' })
user.value = { name: '李四' } // ✅ 可以替换

// reactive适合操作对象属性的场景
const user = reactive({ name: '张三' })
user.name = '李四' // ✅ 直接修改属性
```

### Q2: 如何解决类型推断问题？

使用泛型明确指定类型：

```typescript
// 明确指定ref的类型
const list = ref<PmsProductCategory[]>([])

// 明确指定reactive的类型
const form = reactive<PmsProductCategory>({
  parentId: 0,
  name: '',
  navStatus: 1,
  showStatus: 1
})
```

### Q3: 组件间如何通信？

- **父子组件**：Props + Emits
- **跨层级组件**：Provide / Inject
- **全局状态**：Pinia Store

## 11. 小结

本节我们学习了：

1. **项目结构**：理解了 mall-admin-web 的目录组织和代码规范
2. **Vue 3 核心**：Composition API、`<script setup>`、响应式系统
3. **TypeScript**：类型定义、接口、泛型的实际应用
4. **API封装**：Axios拦截器、模块化API管理
5. **工程配置**：Vite、TSConfig、路径别名

下一节将学习 Element Plus 组件库的使用，开始构建实际的页面界面。

## 参考资源

- [Vue 3 官方文档](https://vuejs.org/)
- [TypeScript 官方文档](https://www.typescriptlang.org/)
- [Element Plus 官方文档](https://element-plus.org/)
- [Pinia 官方文档](https://pinia.vuejs.org/)
