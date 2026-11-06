// Expected: 121. Each returned closure retains its own mutable binding.
function counter() {
  var count = 0;
  function next() {
    count = count + 1;
    return count;
  }
  return next;
}

function main() {
  var first = counter();
  var second = counter();
  return first() * 100 + first() * 10 + second();
}
