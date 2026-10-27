const fs = require('fs');
const vm = require('vm');
const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');
const scripts = html.match(/<script[\s\S]*?<\/script>/gi) || [];

const code = scripts[2].replace(/<script[^>]*>/i, '').replace(/<\/script>/i, '');
try {
    new vm.Script(code);
} catch (e) {
    console.log(e.stack);
}
