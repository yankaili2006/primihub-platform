import { mount, createLocalVue } from '@vue/test-utils'
import ElementUI from 'element-ui'
import Footer from '@/components/Footer/index.vue'

const localVue = createLocalVue()
localVue.use(ElementUI)

describe('Components:Footer', () => {
  it('renders copyright text', () => {
    const wrapper = mount(Footer, { localVue })
    expect(wrapper.text()).toContain('PrimiHub')
  })

  it('renders company name', () => {
    const wrapper = mount(Footer, { localVue })
    expect(wrapper.text()).toBeTruthy()
  })
})