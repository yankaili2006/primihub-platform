import { aesEncrypt, aesDecrypt } from '@/utils/aes.js'

describe('Utils:aes', () => {
  it('encrypt and decrypt string', () => {
    const original = 'hello world'
    const encrypted = aesEncrypt(original)
    expect(encrypted).not.toBe(original)
    expect(encrypted).toBeTruthy()
    const decrypted = aesDecrypt(encrypted)
    expect(decrypted).toBe(original)
  })

  it('encrypt and decrypt chinese', () => {
    const original = '你好，隐私计算平台'
    const encrypted = aesEncrypt(original)
    expect(encrypted).not.toBe(original)
    const decrypted = aesDecrypt(encrypted)
    expect(decrypted).toBe(original)
  })

  it('encrypt and decrypt with special chars', () => {
    const original = 'admin@123!@#$%^&*()_+-='
    const encrypted = aesEncrypt(original)
    const decrypted = aesDecrypt(encrypted)
    expect(decrypted).toBe(original)
  })

  it('encrypt and decrypt numbers', () => {
    const original = '1234567890'
    const encrypted = aesEncrypt(original)
    const decrypted = aesDecrypt(encrypted)
    expect(decrypted).toBe(original)
  })

  it('encrypt produces different output for same input (different IV)', () => {
    const original = 'test'
    const encrypted1 = aesEncrypt(original)
    const encrypted2 = aesEncrypt(original)
    expect(encrypted1).not.toBe(encrypted2)
    const decrypted1 = aesDecrypt(encrypted1)
    const decrypted2 = aesDecrypt(encrypted2)
    expect(decrypted1).toBe(original)
    expect(decrypted2).toBe(original)
  })

  it('decrypt invalid string returns empty', () => {
    const result = aesDecrypt('invalid_base64_string')
    expect(result).toBe('')
  })

  it('encrypt empty string', () => {
    const encrypted = aesEncrypt('')
    expect(encrypted).toBeTruthy()
    const decrypted = aesDecrypt(encrypted)
    expect(decrypted).toBe('')
  })
})