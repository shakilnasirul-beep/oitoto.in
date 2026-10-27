const fs = require('fs');

const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// Check that CUST_I18N exists
console.log('CUST_I18N in content:', content.includes('const CUST_I18N = {'));
console.log('currentViewingCustomerId in content:', content.includes('currentViewingCustomerId'));
console.log('Customer modal refresh in setAdminLanguage:', content.includes('viewCustomerDetails(currentViewingCustomerId)'));
