import Typography from 'typography'

export const typography = new Typography({
  headerFontFamily: '"Clear Sans", "Helvetica Neue", Helvetica, Arial, sans-serif',
  headerGray: 15,
  bodyGray: 30,
  bodyFontFamily: '"Linux Libertine", Georgia, sans-serif',
  baseFontSize: '20px',
  baseLineHeight: '26px',
  modularScales: [
    'major third',
    ['768px', 'minor third']
  ]
})

typography.injectStyles()
