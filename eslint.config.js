import antfu from '@antfu/eslint-config'

export default antfu({
  typescript: true,
  vue: true,
  formatters: {
    css: true,
  },
  ignores: ['./db.ts'],
})
