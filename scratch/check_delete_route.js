const fs = require('fs');
const api = fs.readFileSync('G:/oitoto/api/index.php', 'utf8');
const adminCtrl = fs.readFileSync('G:/oitoto/backend/src/Controllers/AdminController.php', 'utf8');

console.log('DELETE in api/index.php:', api.includes("/admin/drivers/{id}"));
console.log('deleteDriver in AdminController.php:', adminCtrl.includes('deleteDriver'));
