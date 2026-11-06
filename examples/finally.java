// Expected: 45. Return captures 4; finally reads the updated x and sets g to 5.
var g = 0;

function compute() {
  var x = 1;
  try {
    x = 4;
    return x;
  } finally {
    g = x + 1;
  }
}

function main() {
  var value = compute();
  return value * 10 + g;
}
