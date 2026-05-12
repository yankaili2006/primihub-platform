
import router, { constantRoutes, asyncRoutes, resetRouter } from '@/router'

/**
 * 创建菜单路由
 * @param {*} routers 所有动态路由
 * @param {*} rootList 后端返回数据list
 * @returns 权限路由集合
 */

function getRoutes(routers, rootList) {
  const realRoutes = []
  const filter = (code) => rootList.find(cur => cur.authCode === code)
  routers.forEach((item) => {
    if (!filter(item.name)) return
    const route = {
      name: item.name,
      path: item.path,
      component: item.component,
      meta: item.meta,
      hidden: item.hidden || false,
      redirect: item.redirect || '',
      children: [],
    }
    if (item.children && item.children.length > 0) {
      item.children.forEach(child => {
        if (filter(child.name)) {
          route.children.push({
            name: child.name,
            path: child.path,
            component: child.component,
            meta: child.meta,
            hidden: child.hidden || false,
            redirect: child.redirect || '',
          })
        }
      })
    }
    if (item.children && item.children.length > 0 && route.children.length === 0) return
    realRoutes.push(route)
  })
  return realRoutes
}

/**
 * 遍历权限树，获取authType为3的按钮权限
 * @param {*} list 后端返回权限list
 * @returns 按钮权限集合
 */
function filterButtonPermission(list) {
  list = list.filter(item => item.authType === 3)
  const result = []
  list.forEach(item => {
    result.push(item.authCode)
  })
  return result
}

const state = {
  routes: [],
  buttonPermissionList: []
}

const mutations = {
  SET_ROUTES(state, routes) {
    state.routes = constantRoutes.concat(routes)
  },
  SET_BUTTON_PERMISSION(state, list) {
    state.buttonPermissionList = list
  }
}

const actions = {
  generateRoutes({ commit }, authList) {
    return new Promise(resolve => {
      const buttonPermission = filterButtonPermission(authList)
      const accessedRoutes = getRoutes(asyncRoutes, authList)
      resetRouter() // 先清除路由再添加，防止重复添加
      router.addRoutes(accessedRoutes)

      commit('SET_BUTTON_PERMISSION', buttonPermission)
      commit('SET_ROUTES', accessedRoutes)
      resolve(accessedRoutes)
    })
  }
}
export default {
  namespaced: true,
  state,
  mutations,
  actions
}
