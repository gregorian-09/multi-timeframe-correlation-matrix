#property script_show_inputs

#include <DataManager.mqh>

input int InpBars = 50;

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

void OnStart()
{
    CDataManager dm;

    // Parsing checks with an always-valid symbol and mixed spacing/casing.
    string sym = Symbol();
    string symbols_csv = sym + ", " + sym + " ";
    AssertTrue("ParseSymbols valid CSV", dm.ParseSymbols(symbols_csv));
    AssertTrue("Symbol count parsed", dm.GetSymbolCount() == 2);

    ENUM_TIMEFRAMES tfs[];
    int tf_count = dm.ParseTimeframes("h1, M15, d1", tfs);
    AssertTrue("ParseTimeframes mixed casing", tf_count == 3);
    AssertTrue("Parsed timeframe 0 = H1", tfs[0] == PERIOD_H1);
    AssertTrue("Parsed timeframe 1 = M15", tfs[1] == PERIOD_M15);
    AssertTrue("Parsed timeframe 2 = D1", tfs[2] == PERIOD_D1);

    AssertTrue("Parse invalid timeframe fails", !dm.ParseTimeframes("H1, BADTF"));

    // Initialize and cache flow checks.
    AssertTrue("Initialize with valid symbol/timeframe", dm.Initialize(sym, "H1", 60));
    AssertTrue("Timeframe count after initialize", dm.GetTimeframeCount() == 1);

    double p1[];
    int c1 = dm.GetPriceData(sym, PERIOD_H1, InpBars, p1);
    AssertTrue("Initial GetPriceData succeeds", c1 > 0 && ArraySize(p1) == c1);

    double p2[];
    int c2 = dm.GetPriceData(sym, PERIOD_H1, InpBars, p2);
    AssertTrue("Repeated GetPriceData succeeds", c2 > 0 && ArraySize(p2) == c2);

    dm.RefreshCache();
    double p3[];
    int c3 = dm.GetPriceData(sym, PERIOD_H1, InpBars, p3);
    AssertTrue("GetPriceData succeeds after RefreshCache", c3 > 0 && ArraySize(p3) == c3);

    dm.Cleanup();

    Print("Summary: passed=", g_passed, ", failed=", g_failed);
}
