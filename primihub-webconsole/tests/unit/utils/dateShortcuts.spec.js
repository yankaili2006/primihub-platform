import { dateRangeShortcuts, dateRangePickerOptions } from '@/utils/dateShortcuts.js'

describe('Utils:dateShortcuts', () => {
  it('exports 6 shortcuts', () => {
    expect(dateRangeShortcuts).toHaveLength(6)
  })

  it('shortcuts have text and onClick', () => {
    dateRangeShortcuts.forEach(s => {
      expect(s.text).toBeTruthy()
      expect(typeof s.onClick).toBe('function')
    })
  })

  it('today shortcut text is 今天', () => {
    expect(dateRangeShortcuts[0].text).toBe('今天')
  })

  it('yesterday shortcut text is 昨天', () => {
    expect(dateRangeShortcuts[1].text).toBe('昨天')
  })

  it('last 7 days shortcut text is 最近7天', () => {
    expect(dateRangeShortcuts[2].text).toBe('最近7天')
  })

  it('last 30 days shortcut text is 最近30天', () => {
    expect(dateRangeShortcuts[3].text).toBe('最近30天')
  })

  it('this month shortcut text is 本月', () => {
    expect(dateRangeShortcuts[4].text).toBe('本月')
  })

  it('last 90 days shortcut text is 最近90天', () => {
    expect(dateRangeShortcuts[5].text).toBe('最近90天')
  })

  it('pickerOptions contains shortcuts', () => {
    expect(dateRangePickerOptions.shortcuts).toBe(dateRangeShortcuts)
  })

  it('today onClick emits correct date range', () => {
    const mockPicker = { $emit: jest.fn() }
    const now = new Date()
    dateRangeShortcuts[0].onClick(mockPicker)
    expect(mockPicker.$emit).toHaveBeenCalledWith('pick', expect.any(Array))
    const [start, end] = mockPicker.$emit.mock.calls[0][1]
    expect(start.getHours()).toBe(0)
    expect(start.getMinutes()).toBe(0)
    expect(end.getHours()).toBe(23)
    expect(end.getMinutes()).toBe(59)
  })

  it('yesterday onClick emits yesterday date range', () => {
    const mockPicker = { $emit: jest.fn() }
    dateRangeShortcuts[1].onClick(mockPicker)
    const [start, end] = mockPicker.$emit.mock.calls[0][1]
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    expect(start.getDate()).toBe(yesterday.getDate())
    expect(start.getHours()).toBe(0)
    expect(end.getDate()).toBe(yesterday.getDate())
    expect(end.getHours()).toBe(23)
  })
})