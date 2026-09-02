const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').replace(/\r/g, '').split('\n');
const lines2 = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').replace(/\r/g, '').split('\n');

const methods1 = [];
lines1.forEach(l => {
    if (l.trim().startsWith('private void ') || l.trim().startsWith('public void ') || l.trim().startsWith('private IEnumerator ')) {
        methods1.push(l.trim());
    }
});

const methods2 = [];
lines2.forEach(l => {
    if (l.trim().startsWith('private void ') || l.trim().startsWith('public void ') || l.trim().startsWith('private IEnumerator ')) {
        methods2.push(l.trim());
    }
});

for (let m of methods1) {
    if (!methods2.includes(m)) {
        console.log("Missing method: " + m);
    }
}
