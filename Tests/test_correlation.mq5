#property script_show_inputs

#include <CorrelationEngine.mqh>

/**
 * Prints a simple PASS/FAIL line.
 * @param name Test name.
 * @param pass Test result.
 * @return none
 */
void PrintResult(string name, bool pass)
{
    Print(name, ": ", pass ? "PASS" : "FAIL");
}

/**
 * Runs correlation tests with known outcomes.
 * @return none
 */
void OnStart()
{
    CCorrelationEngine engine;
    engine.Initialize(100, 0.3);

    double a1[] = {1,2,3,4,5};
    double b1[] = {2,4,6,8,10};
    double c1[] = {5,4,3,2,1};

    double corr_pos = engine.CalculateCorrelation(a1, b1, 5);
    double corr_neg = engine.CalculateCorrelation(a1, c1, 5);

    bool pass_pos = (corr_pos != EMPTY_VALUE) && (MathAbs(corr_pos - 1.0) < 0.0001);
    bool pass_neg = (corr_neg != EMPTY_VALUE) && (MathAbs(corr_neg + 1.0) < 0.0001);

    PrintResult("Correlation +1", pass_pos);
    PrintResult("Correlation -1", pass_neg);

    double z1[] = {1,1,1,1};
    double z2[] = {2,2,2,2};
    double corr_zero_var = engine.CalculateCorrelation(z1, z2, 4);
    PrintResult("Zero variance -> EMPTY_VALUE", corr_zero_var == EMPTY_VALUE);
}
