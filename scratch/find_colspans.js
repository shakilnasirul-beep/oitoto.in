const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const regex = /colspan=["']?(\d+)["']?/g;
let match;
while ((match = regex.exec(content)) !== null) {
    const start = Math.max(0, match.index - 100);
    const end = Math.min(content.length, match.index + 100);
    const snippet = content.substring(start, end);
    if (snippet.includes('deletedAccounts') || snippet.includes('No deleted account') || snippet.includes('Loading audit')) {
        console.log('Found colspan:', match[1], 'around:', snippet.replace(/\s+/g, ' '));
    }
}
