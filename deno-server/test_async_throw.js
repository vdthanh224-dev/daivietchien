async function foo() {
  throw new Error("sync throw inside async");
}
try {
  foo();
  console.log("Not caught!");
} catch (e) {
  console.log("Caught:", e.message);
}
