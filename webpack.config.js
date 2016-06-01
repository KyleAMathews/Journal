const path = require('path')
const webpack = require('webpack')

module.exports = {
  entry: [
    'webpack-hot-middleware/client',
    './src/router',
  ],
  devtool: 'eval',
  output: {
    path: path.join(__dirname, 'public'),
    filename: 'bundle.js',
  },
  resolveLoader: {
    modulesDirectories: ['node_modules'],
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin(),
    new webpack.NoErrorsPlugin(),
  ],
  resolve: {
    extensions: ['', '.js', '.cjsx', '.coffee'],
  },
  module: {
    loaders: [
      { test: /\.css$/, loaders: ['style', 'css'] },
      { test: /\.cjsx$/, loaders: ['babel', 'coffee', 'cjsx'] },
      { test: /\.coffee$/, loader: 'coffee' },
      {
        test: /\.js/,
        loaders: ['babel'],
        exclude: /node_modules/,
      },
    ],
  },
}
