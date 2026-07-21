import { param2Obj } from '@/utils/index.js'

describe('Utils:param2Obj', () => {
  it('parses single query param', () => {
    const url = 'https://example.com?page=1'
    expect(param2Obj(url)).toEqual({ page: '1' })
  })

  it('parses multiple query params', () => {
    const url = 'https://example.com?page=1&size=10&name=test'
    expect(param2Obj(url)).toEqual({ page: '1', size: '10', name: 'test' })
  })

  it('parses params with special chars', () => {
    const url = 'https://example.com?keyword=%2D001&type=test'
    expect(param2Obj(url)).toEqual({ keyword: '-001', type: 'test' })
  })

  it('returns empty object for no params', () => {
    const url = 'https://example.com'
    expect(param2Obj(url)).toEqual({})
  })

  it('returns empty object for empty string', () => {
    expect(param2Obj('')).toEqual({})
  })

  it('parses params with encoded chinese', () => {
    const url = 'https://example.com?name=%E4%B8%AD%E6%96%87'
    expect(param2Obj(url)).toEqual({ name: '中文' })
  })

  it('parses boolean-like params', () => {
    const url = 'https://example.com?enabled=true&disabled=false'
    expect(param2Obj(url)).toEqual({ enabled: 'true', disabled: 'false' })
  })

  it('parses params with hash', () => {
    const url = 'https://example.com?page=1#section'
    expect(param2Obj(url)).toEqual({ page: '1' })
  })
})