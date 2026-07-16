* Roessler Attractor — Numerical Precision Stress Test
* Chaotic ODE system: extremely sensitive to floating-point precision
* Used to validate FP32 vs FP64 numerical accuracy limits
* Source: ngspice official examples/various/roessler-attractor.cir

* Solve: dx/dt = -y - z,  dy/dt = x + a*y,  dz/dt = b + z*(x - c)
* Parameters: a=0.2, b=0.2, c=5.7 (classic chaotic regime)

.param a=0.2 b=0.2 c=5.7

* Behavioral integrators using controlled sources
* x = integral of (-y - z)
Gx 0 x value = { -v(y) - v(z) }
Cx x 0 1
Rx x 0 1G

* y = integral of (x + a*y)
Gy 0 y value = { v(x) + a*v(y) }
Cy y 0 1
Ry y 0 1G

* z = integral of (b + z*(x - c))
Gz 0 z value = { b + v(z)*(v(x) - c) }
Cz z 0 1
Rz z 0 1G

* Initial conditions
.ic v(x)=1.0 v(y)=1.0 v(z)=1.0

.tran 0.01 200

.control
  echo "=== 08_roessler_attractor ==="
  tran 0.01 200 uic
  * Plot the classic attractor in x-y plane
  plot v(x) vs v(y)
  * Check final values for precision comparison
  echo "Final values (x, y, z):"
  print v(x) v(y) v(z)
.endc
.end
