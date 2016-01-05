[Mesh]
  file = hertz_cyl_qsym_1deg_q8.e
  displacements = 'disp_x disp_y'
[]

[Problem]
  type = ReferenceResidualProblem
  solution_variables = 'disp_x disp_y'
  reference_residual_variables = 'saved_x saved_y'
[]

[Variables]
  [./disp_x]
    order = SECOND
    family = LAGRANGE
  [../]
  [./disp_y]
    order = SECOND
    family = LAGRANGE
  [../]
[]

[AuxVariables]
  [./stress_xx]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_xy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./saved_x]
    order = SECOND
  [../]
  [./saved_y]
    order = SECOND
  [../]
  [./diag_saved_x]
    order = SECOND
  [../]
  [./diag_saved_y]
    order = SECOND
  [../]
  [./inc_slip_x]
    order = SECOND
  [../]
  [./inc_slip_y]
    order = SECOND
  [../]
  [./accum_slip_x]
    order = SECOND
  [../]
  [./accum_slip_y]
    order = SECOND
  [../]
  [./tang_force_x]
    order = SECOND
  [../]
  [./tang_force_y]
    order = SECOND
  [../]
[]

[Functions]
  [./disp_ramp_vert]
    type = PiecewiseLinear
    x = '0. 1. 2.'
    y = '0. -0.0020 -0.0020'
  [../]
  [./disp_ramp_zero]
    type = PiecewiseLinear
    x = '0. 1. 2.'
    y = '0. 0.0 0.0'
  [../]
[]

[SolidMechanics]
  [./solid]
    disp_x = disp_x
    disp_y = disp_y
    save_in_disp_y = saved_y
    save_in_disp_x = saved_x
    diag_save_in_disp_y = diag_saved_y
    diag_save_in_disp_x = diag_saved_x
  [../]
[]

[AuxKernels]
  [./stress_xx]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_xx
    index = 0
  [../]
  [./stress_yy]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_yy
    index = 1
  [../]
  [./stress_xy]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_xy
    index = 3
  [../]
  [./inc_slip_x]
    type = PenetrationAux
    variable = inc_slip_x
    execute_on = timestep_end
    boundary = 4
    paired_boundary = 3
  [../]
  [./inc_slip_y]
    type = PenetrationAux
    variable = inc_slip_y
    execute_on = timestep_end
    boundary = 4
    paired_boundary = 3
  [../]
  [./accum_slip_x]
    type = PenetrationAux
    variable = accum_slip_x
    execute_on = timestep_end
    boundary = 4
    paired_boundary = 3
  [../]
  [./accum_slip_y]
    type = PenetrationAux
    variable = accum_slip_y
    execute_on = timestep_end
    boundary = 4
    paired_boundary = 3
  [../]
  [./penetration]
    type = PenetrationAux
    variable = penetration
    boundary = 4
    paired_boundary = 3
  [../]
  [./tang_force_x]
    type = PenetrationAux
    variable = tang_force_x
    quantity = tangential_force_x
    boundary = 4
    paired_boundary = 3
  [../]
  [./tang_force_y]
    type = PenetrationAux
    variable = tang_force_y
    quantity = tangential_force_y
    boundary = 4
    paired_boundary = 3
  [../]
[]

[Postprocessors]
  [./bot_react_x]
    type = NodalSum
    variable = saved_x
    boundary = 1
  [../]
  [./bot_react_y]
    type = NodalSum
    variable = saved_y
    boundary = 1
  [../]
  [./top_react_x]
    type = NodalSum
    variable = saved_x
    boundary = 5
  [../]
  [./top_react_y]
    type = NodalSum
    variable = saved_y
    boundary = 5
  [../]
  [./ref_resid_x]
    type = NodalL2Norm
    execute_on = timestep_end
    variable = saved_x
  [../]
  [./ref_resid_y]
    type = NodalL2Norm
    execute_on = timestep_end
    variable = saved_y
  [../]
  [./disp_x281]
    type = NodalVariableValue
    nodeid = 280
    variable = disp_x
  [../]
  [./_dt]
    type = TimestepSize
  [../]
  [./num_lin_it]
    type = NumLinearIterations
  [../]
  [./num_nonlin_it]
    type = NumNonlinearIterations
  [../]
[]

[BCs]
  [./side_x]
    type = DirichletBC
    variable = disp_y
    boundary = '1 3'
    value = 0.0
  [../]
  [./bot_y]
    type = DirichletBC
    variable = disp_x
    boundary = '1 2 3'
    value = 0.0
  [../]
  [./top_y_disp]
    type = FunctionPresetBC
    variable = disp_y
    boundary = 5
    function = disp_ramp_vert
  [../]
[]

[Materials]
  [./stiffStuff1]
    type = Elastic
    block = 1
    disp_x = disp_x
    disp_y = disp_y
    youngs_modulus = 1e10
    poissons_ratio = 0.0
  [../]
  [./stiffStuff2]
    type = Elastic
    block = 2
    disp_x = disp_x
    disp_y = disp_y
    youngs_modulus = 1e6
    poissons_ratio = 0.3
  [../]
  [./stiffStuff3]
    type = Elastic
    block = 3
    disp_x = disp_x
    disp_y = disp_y
    youngs_modulus = 1e6
    poissons_ratio = 0.3
  [../]
  [./stiffStuff4]
    type = Elastic
    block = 4
    disp_x = disp_x
    disp_y = disp_y
    youngs_modulus = 1e6
    poissons_ratio = 0.3
  [../]
[]

[Executioner]
  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu     superlu_dist'

  line_search = 'none'

  nl_abs_tol = 1e-7
  nl_rel_tol = 1e-6
  l_max_its = 50
  nl_max_its = 100

  start_time = 0.0
  dt = 0.1
  dtmin = 0.1
  num_steps = 10
  end_time = 1.0
  l_tol = 1e-4
[]

[VectorPostprocessors]
  [./x_disp]
    type = NodalValueSampler
    variable = disp_x
    boundary = '3 4 5'
    sort_by = id
  [../]
  [./y_disp]
    type = NodalValueSampler
    variable = disp_y
    boundary = '3 4 5'
    sort_by = id
  [../]
  [./cont_press]
    type = NodalValueSampler
    variable = contact_pressure
    boundary = '4'
    sort_by = id
  [../]
[]

[Outputs]
  print_linear_residuals = true
  print_perf_log = true
  [./exodus]
    type = Exodus
    elemental_as_nodal = true
  [../]
  [./console]
    type = Console
    max_rows = 5
  [../]
  [./chkfile]
    type = CSV
    show = 'bot_react_x bot_react_y disp_x281 ref_resid_x ref_resid_y top_react_x top_react_y x_disp y_disp cont_press'
    start_time = 0.9
    execute_vector_postprocessors_on = timestep_end
  [../]
  [./outfile]
    type = CSV
    delimiter = ' '
    execute_vector_postprocessors_on = none
  [../]
[]

[Contact]
  [./interface]
    master = 3
    slave = 4
    disp_x = disp_x
    disp_y = disp_y
    order = SECOND
    system = constraint
    normalize_penalty = true
    tangential_tolerance = 1e-3
    penalty = 1e+11
  [../]
[]