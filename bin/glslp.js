var path = require('path');
var fs = require('fs');
var Server = require(path.join(path.dirname(fs.realpathSync(__filename)), '../scripts/js/lib/Server'));

new Server().serve()
