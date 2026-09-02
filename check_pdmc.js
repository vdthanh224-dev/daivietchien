const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').replace(/\r/g, '').split('\n');
lines1.forEach((l, i) => { if (l.includes('pendingDealMyCards = new List<List<CardModel>>();')) console.log((i+1) + ': ' + l.trim()); });
