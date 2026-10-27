const fs = require('fs');
const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const m1 = 'let globalDriversData = [';
const lpStart = 'async function loadPartnersAndVehicles() {';
const lpEnd = 'function updatePartnerKPIs() {';
const ddStart = 'function deleteDriverPartner(id) {';
const ddEnd = 'async function loadDrivers() {';
const lcStart = 'async function loadCustomers() {';
const lcEnd = 'function renderCustomersTable(list) {';
const resStart = 'async function restoreDeletedAccount(id) {';
const resEnd = 'function viewDeletedAccountSlip(id) {';

console.log('m1:', html.includes(m1));
console.log('loadPartners:', html.includes(lpStart) && html.includes(lpEnd));
console.log('deletePartner:', html.includes(ddStart) && html.includes(ddEnd));
console.log('loadCustomers:', html.includes(lcStart) && html.includes(lcEnd));
console.log('restoreDeleted:', html.includes(resStart) && html.includes(resEnd));
