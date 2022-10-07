#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
OBJDUMP="${OBJDUMP:-objdump}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$MACHINE/$testname
mkdir -p $t

cat <<'EOF' > $t/dyn
{
  xyz;
  foo*bar*[abc]x;
};
EOF

cat <<EOF | $CXX -fPIC -c -o $t/b.o -xc -
void xyz() {}
void foobarzx() {}
void foobarcx() {}
void foo123bar456bx() {}
void foo123bar456c() {}
void foo123bar456x() {}
int main() {}
EOF

$CC -B. -Wl,--dynamic-list=$t/dyn -o $t/exe1 $t/b.o

readelf --dyn-syms $t/exe1 > $t/log1
grep -q ' xyz$' $t/log1
! grep -q ' foobarzx$' $t/log1 || false
grep -q ' foobarcx$' $t/log1
grep -q ' foo123bar456bx$' $t/log1
! grep -q ' foo123bar456c$' $t/log1 || false
! grep -q ' foo123bar456x$' $t/log1 || false

$CC -B. -Wl,--export-dynamic-symbol-list=$t/dyn -o $t/exe2 $t/b.o

readelf --dyn-syms $t/exe2 > $t/log2
grep -q ' xyz$' $t/log2
! grep -q ' foobarzx$' $t/log2 || false
grep -q ' foobarcx$' $t/log2
grep -q ' foo123bar456bx$' $t/log2
! grep -q ' foo123bar456c$' $t/log2 || false
! grep -q ' foo123bar456x$' $t/log2 || false

echo OK
