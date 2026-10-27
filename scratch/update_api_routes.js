const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/api/index.php', 'utf8');

const targetLine = "$r->post('/admin/drivers/{id}/verify', [AdminController::class, 'verifyDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);";

const routesToAdd = `$r->post('/admin/drivers/{id}/verify', [AdminController::class, 'verifyDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->delete('/admin/drivers/{id}', [AdminController::class, 'deleteDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/drivers/{id}/delete', [AdminController::class, 'deleteDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);`;

if (!content.includes("deleteDriver")) {
    content = content.replace(targetLine, routesToAdd);
    fs.writeFileSync('G:/oitoto/api/index.php', content, 'utf8');
    console.log('Routes added to api/index.php');
} else {
    console.log('deleteDriver routes already exist in api/index.php');
}
