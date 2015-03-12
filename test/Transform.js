var Coffeescript = require('coffee-script');

module.exports = [
    {ext: '.coffee', transform: function (content, filename) {

        // Make sure to only transform your code or the dependencies you want
        if (filename.indexOf('node_modules') === -1) {
          var result = Coffeescript.compile(content);
          return result;
        }

        return content;
    }}
];
