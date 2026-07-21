import { mount, createLocalVue } from '@vue/test-utils'
import ElementUI from 'element-ui'
import StatusIcon from '@/components/StatusIcon/index.vue'

const localVue = createLocalVue()
localVue.use(ElementUI)

describe('Components:StatusIcon', () => {
  it('renders with default status', () => {
    const wrapper = mount(StatusIcon, { localVue })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders success status', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'success' } })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders warning status', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'warning' } })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders danger status', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'danger' } })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders info status', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'info' } })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders with custom size', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'success', size: 'large' } })
    expect(wrapper.exists()).toBe(true)
  })

  it('renders with label', () => {
    const wrapper = mount(StatusIcon, { localVue, propsData: { status: 'success', label: '运行中' } })
    expect(wrapper.exists()).toBe(true)
  })
})