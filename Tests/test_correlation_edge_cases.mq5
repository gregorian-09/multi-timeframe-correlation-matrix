#property script_show_inputs

#include <CorrelationEngine.mqh>

int g_passed = 0;
int g_failed = 0;

void AssertTrue(const string name, bool condition)
{
    if(condition)
    {
        g_passed++;
        Print("[PASS] ", name);
    }
    else
    {
        g_failed++;
        Print("[FAIL] ", name);
    }
}

bool NearlyEqual(double a, double b, double eps = 0.0001)
{
    return MathAbs(a - b) <= eps;
}

void OnStart()
{
    CCorrelationEngine engine;
    AssertTrue("Initialize valid params", engine.Initialize(100, 0.30));

    double x1[] = {1, 2, 3, 4, 5};
    double y1[] = {1, 2, 3, 4, 5};
    double r1 = engine.CalculateCorrelation(x1, y1, 5);
    AssertTrue("Perfect positive correlation", r1 != EMPTY_VALUE && NearlyEqual(r1, 1.0));

    double x2[] = {1, 2, 3, 4, 5};
    double y2[] = {5, 4, 3, 2, 1};
    double r2 = engine.CalculateCorrelation(x2, y2, 5);
    AssertTrue("Perfect negative correlation", r2 != EMPTY_VALUE && NearlyEqual(r2, -1.0));

    double flat1[] = {7, 7, 7, 7};
    double flat2[] = {2, 2, 2, 2};
    double r_flat = engine.CalculateCorrelation(flat1, flat2, 4);
    AssertTrue("Zero variance returns EMPTY_VALUE", r_flat == EMPTY_VALUE);

    double short_a[] = {1, 2, 3};
    double short_b[] = {2, 3, 4};
    double r_bad_count = engine.CalculateCorrelation(short_a, short_b, 5);
    AssertTrue("Count larger than array returns EMPTY_VALUE", r_bad_count == EMPTY_VALUE);

    AssertTrue("Strength strong positive", engine.GetCorrelationStrength(0.90) == CORR_STRONG_POSITIVE);
    AssertTrue("Strength moderate positive", engine.GetCorrelationStrength(0.35) == CORR_MODERATE_POSITIVE);
    AssertTrue("Strength weak", engine.GetCorrelationStrength(0.00) == CORR_WEAK);
    AssertTrue("Strength moderate negative", engine.GetCorrelationStrength(-0.50) == CORR_MODERATE_NEGATIVE);
    AssertTrue("Strength strong negative", engine.GetCorrelationStrength(-0.90) == CORR_STRONG_NEGATIVE);

    AssertTrue("Divergence true when threshold exceeded", engine.DetectDivergence(0.80, 0.30));
    AssertTrue("Divergence false when below threshold", !engine.DetectDivergence(0.80, 0.60));
    AssertTrue("Divergence false when EMPTY_VALUE involved", !engine.DetectDivergence(EMPTY_VALUE, 0.10));

    AssertTrue("Initialize fails on invalid lookback", !engine.Initialize(1, 0.30));
    AssertTrue("Initialize fails on negative threshold", !engine.Initialize(100, -0.01));

    Print("Summary: passed=", g_passed, ", failed=", g_failed);
}
