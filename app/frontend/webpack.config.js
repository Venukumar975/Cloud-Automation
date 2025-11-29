/**
 * Webpack Configuration (webpack.config.js)
 * This file tells Webpack how to find your source code and bundle it 
 * into dist/bundle.js, using Babel for compilation.
 */
const path = require('path');

module.exports = {
  mode: 'development',
  
  // The starting point for the React application
  entry: './src/main.jsx', 

  // Output the compiled file to a 'dist' folder
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js',
    publicPath: '/dist/'
  },
  
  module: {
    rules: [
      {
        // Rule to process .js and .jsx files with babel-loader
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader' 
        }
      },
      {
        // Rule for handling CSS files
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }
    ]
  },
  
  resolve: {
    extensions: ['.js', '.jsx']
  }
};