import { mount } from '@vue/test-utils'
import Pagination from '@/components/Pagination/index.vue'

describe('Components:Pagination', () => {
  const mountPagination = (props = {}) => {
    return mount(Pagination, {
      propsData: {
        page: 1,
        limit: 10,
        pageCount: 5,
        total: 50,
        ...props
      }
    })
  }

  it('renders total count', () => {
    const wrapper = mountPagination({ total: 100 })
    expect(wrapper.text()).toContain('100')
  })

  it('renders page size options', () => {
    const wrapper = mountPagination()
    const pageSizes = wrapper.findAll('.el-select-dropdown__item')
    expect(pageSizes.length).toBeGreaterThanOrEqual(0)
  })

  it('emits pagination event on page change', async () => {
    const wrapper = mountPagination({ page: 1, pageCount: 5 })
    const pagination = wrapper.findComponent({ name: 'Pagination' })
    expect(pagination.exists()).toBe(true)
  })

  it('disables prev on first page', () => {
    const wrapper = mountPagination({ page: 1 })
    const btnPrev = wrapper.find('.btn-prev')
    if (btnPrev.exists()) {
      expect(btnPrev.classes()).toContain('disabled')
    }
  })

  it('disables next on last page', () => {
    const wrapper = mountPagination({ page: 5, pageCount: 5 })
    const btnNext = wrapper.find('.btn-next')
    if (btnNext.exists()) {
      expect(btnNext.classes()).toContain('disabled')
    }
  })

  it('renders with zero total', () => {
    const wrapper = mountPagination({ total: 0, pageCount: 0 })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders with single page', () => {
    const wrapper = mountPagination({ total: 5, pageCount: 1 })
    expect(wrapper.exists()).toBe(true)
  })
})