import Typography from 'typography'

export const typography = new Typography({
  headerFontFamily: '"Clear Sans", "Helvetica Neue", Helvetica, Arial, sans-serif',
  headerGray: 15,
  bodyGray: 30,
  bodyFontFamily: '"Linux Libertine", Georgia, sans-serif',
  baseFontSize: '20px',
  baseLineHeight: '26px',
  modularScales: [
    {
      scale: 'major third',
    },
    {
      maxWidth: '768px',
      scale: 'minor third',
    },
  ],
})

typography.injectStyles()
