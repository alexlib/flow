# 3D PIV velocity fields--manipulation, visualization, and analysis of random synthetic noise
![openvf](https://github.com/epicderek/flow/blob/master/illu/openfv.jpg)

## Data Structure

```matlab
vf = VelocityField(X, U, minimal = false)
```

The above is the object representation of a 3D velocity vector field with two essential data/variables: the positions on which velocity measurements were made, `X`, and the corresponding velocity vectors, `U`. Each is a 4D numeric array whose first three indices are the grid indices, specifying the grid position, while in the fourth dimension, the 3-position or 3-velocity vector is stored. The `minimal` flag pertains to the derived fields from velocity, such as vorticity. When set to true, this will prevent the calculation of these fields upon object construction.

Via different static import functions, common formats of 3D PIV data are converted to a `VelocityField` object. For example, if the positions and velocities are recorded as components on separate 3D grids, the following is used.

```matlab
vf = VelocityField.importCmps(x, y, z, u, v, w, minimal = false)
```

We may wish to inspect and perform computations on a restricted region of our overall volume, say where the velocity measurements are more reliable. Given a rectangular region specified by the beginning and ending index of each dimension

```matlab
vf.setRange([i_0 i_f; j_0 j_f; k_0 k_f])
```

Such indices may be obtained from a set of mapping functions from position to index such as `vf.getIndex_x()`. Currently, the `vf.getIndex()` methods interpolate to the nearest grid position and wrap around the boundaries, so that even an external position will be assigned a valid index on the grid. To exclude external points, one may use the `vf.inBounds([x y z]')` handle to check for inclusion. Index is the preferred means of access by most methods.

Nonetheless, we may also specify the effective region by position, where the input is a typical range array of dimensions 3 x 2, speicifying the positions of the end points in each dimension. It is not required that the position is given in ascending order, for some fields has descending positions with increasing indices. The indexing is handled properly as to proceed in the same direction of position as in the original field. **It is required however that the subsetted region, and the velocity field in general, be a 3D region--with at least two distinct positions per dimension.**

```matlab
vf.setRangePosition([-5 5; 5 -5; 0 3])
```

## Graphing

We may plot a vector field over our earlier specified range, here the velocity

```matlab
plt = vf.plotVector(vf.U, noise = 0, title_str = 'Velocity $\vec{u}$')
```

Which produces
![global velocity](https://github.com/epicderek/flow/blob/master/illu/3dv.jpg)

The vector field plotted here, `vf.U`, or involved in computation in other methods, if given in the global range, not restricted to the region of interest specified, is automatically subsetted. 

To display the velocity only upon an arbitrary plane perpendicular to the x, y, or z unit vectors, we specify the plane with a normal vector and a base position. Suppose we'd like a plane orthogonal to the x-axis, and this plane is the i<sup>th</sup> such orthogonal plane in on the grid,

```matlab
vf.plotPlaneVector(vf.U, eq = vf.getRegPlaneEq([i 0 0]), noise = 0, title_str = "Velocity $\vec{u}$")
```

Where `vf.getRegPlaneEq([i 0 0])` calculates the required format of the plane as two vectors.

![plane velocity](https://github.com/epicderek/flow/blob/master/illu/plane.jpg)

Now, we introduce noise to our system. This noise will be added to the instance variable `vf.N`, not directly added to `vf.U`, though the user may perform such an addition. The separate fields `vf.N` and `vf.N_e` storing noise is velocity are useful in studying the effect of synthetic noise, since the original field is not altered while the effect of noise is obtained by replacing `vf.U_e` with `vf.U_e + vf.N_e` in computations with noise. Methods in the class are thus implemented.

Adding Gaussian white noise,

```matlab
vf.noise_wgn(sd = 0, snr = 10)
```

We can visualize the magnitude of this noise along a regular plane, a plane orthogonal to one of the basis vectors. Here we use an additional parameter to specify the plane, considering the planar region probably differs from the 3D region of interest specified earlier. Picking the i<sup>th</sup> orthogonal plane to the x axis, we use `range = [i i; j_0 j_f; k_0 k_f]`, where the dimension with identical beginning and ending indices indicates the direction of normality as well as the index of the plane, and the other two dimensions specify the range of the plane on which noise is to be plotted.

```matlab
vf.plotPlaneScalar(sqrt(sum(vf.N.^2, 4)), range, noise = 0, title_str = 'noise $\Delta u$')
```
![plane velocity](https://github.com/epicderek/flow/blob/master/illu/noise_plane.jpg)

To show noise on multiple planes, we generate a Matlab slice plot. Obtaining the equations for the planes in the standard format, stored as a n x 3 x 2 matrix `eqs`, we call

```matlab
vf.slicePlanes(sqrt(sum(vf.N.^2,4)), eqs, noise = 0, 'noise $\Delta u$');
```

![slices](https://github.com/epicderek/flow/blob/master/illu/noise_slice.jpg)

The blank grids are where the planar positions are not proximate enough to the positions on the grid.

Finally, though not applicable to large regions and not especially insightful, we can make a scatter plot of the noise.

```matlab
 vf.plotScalar(sqrt(sum(vf.N.^2, 4)), noise = '$\Delta u$')
```
![scatter3](https://github.com/epicderek/flow/blob/master/illu/scalar-scatter.jpg)

For a continuous scalar field, in addition to `plotPlaneScalar()` and `slicePlanes()`, a standard isosurface plot can also be generated. The required proximity of the actual values in the field to the values specified is as ordained by Matlab's `isosurface()`, which may be examined further. Here we plot two isosurfaces of speed.

```matlab
vf.isosurfaces(vf.data.speed, [250, 200], 0, '$u$')
```

![isosurface](https://github.com/epicderek/flow/blob/master/illu/isosurface.jpg)

## Computation of Physical Quantities

There are corresponding solvers for typical PIV mechanical quantities. For instance, to compute the total kinetic energy of the effective region with noise,

```matlab
K = vf.kineticEnergy(with_noise = true)
```

The last argument of all functions computing a physical quantity is a boolean indicating whether noise, that is, as stored in `vf.N_e`, is to be combined with the original velocity. Here is a function computing the vorticity field from the velocity field.

```matlab
vort = vf.vorticity(with_noise = true)
```

The vorticity field is stored as a variable in `vf` as `vf.vort`, and this function is implicitly called upon construction of a `VelocityField` object. To avoid computaitons of these derivative quantities during initialization, use an optional flag in initialization.

Impulse is computed by specifying an origin. Say we use the natural origin implied by the positions on the grid.

```matlab
I = vf.impulse(origin = [0 0 0]', with_noise = true)
```

## Integration on a Cubic Surface

Surface integration is supported on a rectangular surface, specified by setting the effective region, with the `vf.intCubicSurf` prefix. To illustrate, we create a Hill's vortex, a synthetic spherical structure, which is commonly used in our error study.

```matlab
[x, y, z, u, v, w, ~] = Hill_Vortex(spacing = 0.1, sphere_radius = 1, u0 = 1, z_proportion = 1);
vf = VelocityField.import_grid_separate(x, y, z, u, v, w);
vf.plotVector(vf.U, noise = 0, '$\vec{u}$')
```

![Hill-vortex](https://github.com/epicderek/flow/blob/master/illu/hill-vortex.jpg)

Now we integrate the mass flux through this cubic surface, which is applying the del operator in a dot product with the velocity field. Since our fluid is incompressible, there should not be accumulation or net flux. The result is 6.9389e-18, negligible compared to the typical value of speed. In general, we can compute the flux of any vector field which is properly subsetted to be matching in dimension to the current effective region.

```matlab
vf.intCubicSurf_flux(vf.U_e)
```

The common operations under surface integrations are scalar surface elemtns multiplied by scalar or vector fields, vector surface elements (scalar element with normal vector) multiplied by scalar field, by vector field as dot product (flux), by vector field as cross product. These operations are implemented for a cubic surface, understood, when the ordering of multiplication matters, as `F x dS`.

