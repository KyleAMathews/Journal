import Typography from 'typography'
import gray from 'gray-percentage'

export const typography = new Typography({
  headerFontFamily: ['Clear Sans', 'Helvetica Neue', 'Helvetica', 'Arial', 'sans-serif'],
  headerGray: 15,
  bodyGray: 30,
  bodyFontFamily: ['Linux Libertine', 'Georgia', 'sans-serif'],
  baseFontSize: '20px',
  baseLineHeight: 1.4,
  overrideStyles: ({ adjustFontSizeTo, rhythm }) => ({
    blockquote: {
      ...adjustFontSizeTo('22px'),
      borderLeft: `${rhythm(1/4)} solid ${gray(87)}`,
      marginLeft: 0,
      paddingLeft: rhythm(3/4),
    },
  }),
})

typography.injectStyles()
