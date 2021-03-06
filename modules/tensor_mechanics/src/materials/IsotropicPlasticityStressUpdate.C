/****************************************************************/
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*          All contents are licensed under LGPL V2.1           */
/*             See LICENSE for full restrictions                */
/****************************************************************/
#include "IsotropicPlasticityStressUpdate.h"

#include "Function.h"
#include "ElasticityTensorTools.h"

template <>
InputParameters
validParams<IsotropicPlasticityStressUpdate>()
{
  InputParameters params = validParams<RadialReturnStressUpdate>();
  params.addClassDescription("This class uses the discrete material in a radial return isotropic "
                             "plasticity model.  This class is one of the basic radial return "
                             "constitutive models, yet it can be used in conjunction with other "
                             "creep and plasticity materials for more complex simulations.");
  // Linear strain hardening parameters
  params.addParam<FunctionName>("yield_stress_function",
                                "Yield stress as a function of temperature");
  params.addParam<Real>(
      "yield_stress", 0.0, "The point at which plastic strain begins accumulating");
  params.addParam<FunctionName>("hardening_function",
                                "True stress as a function of plastic strain");
  params.addParam<Real>("hardening_constant", 0.0, "Hardening slope");
  params.addCoupledVar("temperature", 0.0, "Coupled Temperature");
  params.addParam<std::string>(
      "plastic_prepend", "", "String that is prepended to the plastic_strain Material Property");

  return params;
}

IsotropicPlasticityStressUpdate::IsotropicPlasticityStressUpdate(const InputParameters & parameters)
  : RadialReturnStressUpdate(parameters, "plastic"),
    _plastic_prepend(getParam<std::string>("plastic_prepend")),
    _yield_stress_function(
        isParamValid("yield_stress_function") ? &getFunction("yield_stress_function") : NULL),
    _yield_stress(getParam<Real>("yield_stress")),
    _hardening_constant(getParam<Real>("hardening_constant")),
    _hardening_function(isParamValid("hardening_function") ? &getFunction("hardening_function")
                                                           : NULL),
    _yield_condition(-1.0), // set to a non-physical value to catch uninitalized yield condition
    _hardening_slope(0.0),
    _plastic_strain(declareProperty<RankTwoTensor>(_plastic_prepend + "plastic_strain")),
    _plastic_strain_old(getMaterialPropertyOld<RankTwoTensor>(_plastic_prepend + "plastic_strain")),
    _hardening_variable(declareProperty<Real>("hardening_variable")),
    _hardening_variable_old(getMaterialPropertyOld<Real>("hardening_variable")),
    _temperature(coupledValue("temperature"))
{
  if (parameters.isParamSetByUser("yield_stress") && _yield_stress <= 0.0)
    mooseError("Yield stress must be greater than zero");

  if (_yield_stress_function == NULL && !parameters.isParamSetByUser("yield_stress"))
    mooseError("Either yield_stress or yield_stress_function must be given");

  if (!parameters.isParamSetByUser("hardening_constant") && !isParamValid("hardening_function"))
    mooseError("Either hardening_constant or hardening_function must be defined");

  if (parameters.isParamSetByUser("hardening_constant") && isParamValid("hardening_function"))
    mooseError(
        "Only the hardening_constant or only the hardening_function can be defined but not both");
}

void
IsotropicPlasticityStressUpdate::initQpStatefulProperties()
{
  _hardening_variable[_qp] = 0.0;
  _plastic_strain[_qp].zero();
}

void
IsotropicPlasticityStressUpdate::propagateQpStatefulProperties()
{
  _hardening_variable[_qp] = _hardening_variable_old[_qp];
  _plastic_strain[_qp] = _plastic_strain_old[_qp];

  propagateQpStatefulPropertiesRadialReturn();
}

void
IsotropicPlasticityStressUpdate::computeStressInitialize(const Real effective_trial_stress,
                                                         const RankFourTensor & elasticity_tensor)
{
  computeYieldStress(elasticity_tensor);

  _yield_condition = effective_trial_stress - _hardening_variable_old[_qp] - _yield_stress;
  _hardening_variable[_qp] = _hardening_variable_old[_qp];
  _plastic_strain[_qp] = _plastic_strain_old[_qp];
}

Real
IsotropicPlasticityStressUpdate::computeResidual(const Real effective_trial_stress,
                                                 const Real scalar)
{
  Real residual = 0.0;

  mooseAssert(_yield_condition != -1.0,
              "the yield stress was not updated by computeStressInitialize");

  if (_yield_condition > 0.0)
  {
    _hardening_slope = computeHardeningDerivative(scalar);
    _hardening_variable[_qp] = computeHardeningValue(scalar);

    residual =
        (effective_trial_stress - _hardening_variable[_qp] - _yield_stress) / _three_shear_modulus -
        scalar;
  }
  return residual;
}

Real
IsotropicPlasticityStressUpdate::computeDerivative(const Real /*effective_trial_stress*/,
                                                   const Real /*scalar*/)
{
  Real derivative = 1.0;
  if (_yield_condition > 0.0)
    derivative = -1.0 - _hardening_slope / _three_shear_modulus;

  return derivative;
}

void
IsotropicPlasticityStressUpdate::iterationFinalize(Real scalar)
{
  if (_yield_condition > 0.0)
    _hardening_variable[_qp] = computeHardeningValue(scalar);
}

void
IsotropicPlasticityStressUpdate::computeStressFinalize(const RankTwoTensor & plasticStrainIncrement)
{
  _plastic_strain[_qp] += plasticStrainIncrement;
}

Real
IsotropicPlasticityStressUpdate::computeHardeningValue(Real scalar)
{
  Real value = _hardening_variable_old[_qp] + (_hardening_slope * scalar);
  if (_hardening_function)
  {
    const Real strain_old = _effective_inelastic_strain_old[_qp];
    Point p;

    value = _hardening_function->value(strain_old + scalar, p) - _yield_stress;
  }
  return value;
}

Real IsotropicPlasticityStressUpdate::computeHardeningDerivative(Real /*scalar*/)
{
  Real slope = _hardening_constant;
  if (_hardening_function)
  {
    const Real strain_old = _effective_inelastic_strain_old[_qp];
    Point p; // Always (0,0,0)

    slope = _hardening_function->timeDerivative(strain_old, p);
  }
  return slope;
}

void
IsotropicPlasticityStressUpdate::computeYieldStress(const RankFourTensor & /*elasticity_tensor*/)
{
  if (_yield_stress_function)
  {
    Point p;
    _yield_stress = _yield_stress_function->value(_temperature[_qp], p);
    if (_yield_stress <= 0.0)
      mooseError("The yield stress must be greater than zero, but during the simulation your yield "
                 "stress became less than zero.");
  }
}
