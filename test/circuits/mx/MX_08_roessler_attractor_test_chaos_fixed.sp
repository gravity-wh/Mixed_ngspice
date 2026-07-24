* Roessler Attractor — Precision Stress Test

.param a=0.2 b=0.2 c=5.7

Gx 0 x value = { -v(y) - v(z) }
Cx x 0 1
Rx x 0 1G
Gy 0 y value = { v(x) + a*v(y) }
Cy y 0 1
Ry y 0 1G
Gz 0 z value = { b + v(z)*(v(x) - c) }
Cz z 0 1
Rz z 0 1G

.ic v(x)=1.0 v(y)=1.0 v(z)=1.0


Vdd VDD 0 DC 1.8
Vss VSS 0 DC 0
.option gmin=1e-12
.control
  echo "=== 08_roessler_attractor ==="
  tran 0.01 200 uic
  echo "Final x:"
  print v(x)
  echo "Final y:"
  print v(y)
  echo "Final z:"
  print v(z)
.endc
.end
