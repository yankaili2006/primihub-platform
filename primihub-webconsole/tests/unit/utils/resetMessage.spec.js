import { resetMessage } from '@/utils/resetMessage.js'

describe('Utils:resetMessage', () => {
  it('has error/success/info/warning methods', () => {
    expect(typeof resetMessage.error).toBe('function')
    expect(typeof resetMessage.success).toBe('function')
    expect(typeof resetMessage.info).toBe('function')
    expect(typeof resetMessage.warning).toBe('function')
  })

  it('error accepts string message', () => {
    expect(typeof resetMessage.error('test error')).toBe('function')
  })

  it('success accepts string message', () => {
    expect(typeof resetMessage.success('test success')).toBe('function')
  })

  it('info accepts string message', () => {
    expect(typeof resetMessage.info('test info')).toBe('function')
  })

  it('warning accepts string message', () => {
    expect(typeof resetMessage.warning('test warning')).toBe('function')
  })

  it('error accepts object options', () => {
    expect(typeof resetMessage.error({ message: 'test', duration: 3000 })).toBe('function')
  })

  it('success accepts object options', () => {
    expect(typeof resetMessage.success({ message: 'test', duration: 3000 })).toBe('function')
  })
})