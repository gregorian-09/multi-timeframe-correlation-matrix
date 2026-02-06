#pragma once

// Visual rendering for the correlation matrix.

#include <Constants.mqh>

/**
 * Renders correlation matrix as chart objects.
 */
class CMatrixDisplay
{
private:
    string m_prefix;
    int m_x;
    int m_y;
    int m_cell;
    color m_pos;
    color m_neg;
    color m_neutral;
    bool m_visible;
    string m_title;
    bool m_tooltips_enabled;
    int m_pool_count;
    double m_last_values[];
    string m_last_symbols[];

    /**
     * Builds object name for a cell.
     * @param row Row index.
     * @param col Column index.
     * @return Object name.
     */
    string CellName(int row, int col) const
    {
        return m_prefix + "CELL_" + IntegerToString(row) + "_" + IntegerToString(col);
    }

    /**
     * Builds object name for a cell label.
     * @param row Row index.
     * @param col Column index.
     * @return Object name.
     */
    string LabelName(int row, int col) const
    {
        return m_prefix + "LABEL_" + IntegerToString(row) + "_" + IntegerToString(col);
    }

    /**
     * Builds object name for a row header label.
     * @param index Row index.
     * @return Object name.
     */
    string HeaderRowName(int index) const
    {
        return m_prefix + "HDR_R_" + IntegerToString(index);
    }

    /**
     * Builds object name for a column header label.
     * @param index Column index.
     * @return Object name.
     */
    string HeaderColName(int index) const
    {
        return m_prefix + "HDR_C_" + IntegerToString(index);
    }

    /**
     * Builds object name for the legend label.
     * @return Object name.
     */
    string LegendName() const
    {
        return m_prefix + "LEGEND";
    }

    /**
     * Builds object name for the title label.
     * @return Object name.
     */
    string TitleName() const
    {
        return m_prefix + "TITLE";
    }

    /**
     * Creates or updates a rectangle label.
     * @param name Object name.
     * @param x X position.
     * @param y Y position.
     * @param w Width.
     * @param h Height.
     * @param fill Fill color.
     * @return none
     */
    void CreateOrUpdateRect(const string name, int x, int y, int w, int h, color fill, const string tooltip = "")
    {
        if(ObjectFind(0, name) < 0)
            ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
        ObjectSetInteger(0, name, OBJPROP_COLOR, fill);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, m_visible ? OBJ_ALL_PERIODS : 0);
        if(m_tooltips_enabled)
            ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
        else
            ObjectSetString(0, name, OBJPROP_TOOLTIP, "");
    }

    /**
     * Creates or updates a text label.
     * @param name Object name.
     * @param x X position.
     * @param y Y position.
     * @param text Label text.
     * @param txt Text color.
     * @return none
     */
    void CreateOrUpdateLabel(const string name, int x, int y, const string text, color txt)
    {
        if(ObjectFind(0, name) < 0)
            ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, m_visible ? OBJ_ALL_PERIODS : 0);
    }

    /**
     * Returns flattened index for matrix storage.
     * @param row Row index.
     * @param col Col index.
     * @param count Matrix size.
     * @return Flattened index.
     */
    int FlatIndex(int row, int col, int count) const
    {
        return (row * count) + col;
    }

    /**
     * Returns true if symbol headers are unchanged.
     * @param symbols Current symbol list.
     * @return true if unchanged.
     */
    bool SymbolsUnchanged(const string &symbols[]) const
    {
        int count = ArraySize(symbols);
        if(ArraySize(m_last_symbols) != count)
            return false;

        for(int i = 0; i < count; i++)
        {
            if(m_last_symbols[i] != symbols[i])
                return false;
        }
        return true;
    }

    /**
     * Stores latest symbol list snapshot.
     * @param symbols Current symbol list.
     * @return none
     */
    void SaveSymbols(const string &symbols[])
    {
        int count = ArraySize(symbols);
        ArrayResize(m_last_symbols, count);
        for(int i = 0; i < count; i++)
            m_last_symbols[i] = symbols[i];
    }

    /**
     * Ensures pooled objects and value cache are sized for matrix dimensions.
     * @param symbols Symbol list.
     * @return none
     */
    void EnsurePool(const string &symbols[])
    {
        int count = ArraySize(symbols);
        if(count <= 0)
            return;

        bool rebuild = (m_pool_count != count);
        if(rebuild)
        {
            m_pool_count = count;
            ArrayResize(m_last_values, count * count);
            for(int i = 0; i < ArraySize(m_last_values); i++)
                m_last_values[i] = EMPTY_VALUE;
            ArrayResize(m_last_symbols, 0);
        }

        if(rebuild || !SymbolsUnchanged(symbols))
        {
            for(int i = 0; i < count; i++)
            {
                int headerX = m_x + m_cell + (i * m_cell);
                int headerY = m_y;
                CreateOrUpdateLabel(HeaderColName(i), headerX, headerY, symbols[i], clrWhite);

                int rowHeaderX = m_x;
                int rowHeaderY = m_y + m_cell + (i * m_cell);
                CreateOrUpdateLabel(HeaderRowName(i), rowHeaderX, rowHeaderY, symbols[i], clrWhite);
            }
            SaveSymbols(symbols);
        }

        if(rebuild)
        {
            for(int row = 0; row < count; row++)
            {
                for(int col = 0; col < count; col++)
                {
                    int x = m_x + m_cell + (col * m_cell);
                    int y = m_y + m_cell + (row * m_cell);
                    CreateOrUpdateRect(CellName(row, col), x, y, m_cell, m_cell, m_neutral);
                    CreateOrUpdateLabel(LabelName(row, col), x + 5, y + 5, "", clrWhite);
                }
            }
        }
    }

public:
    /**
     * Constructs display with default visual settings.
     * @return none
     */
    CMatrixDisplay()
        : m_prefix(CORRELATION_PREFIX), m_x(20), m_y(50), m_cell(DEFAULT_CELL_SIZE),
          m_pos(clrGreen), m_neg(clrRed), m_neutral(clrGray), m_visible(true),
          m_title("Correlation Matrix"), m_tooltips_enabled(true), m_pool_count(0) {}

    /**
     * Initializes layout and color settings.
     * @param xPos X position.
     * @param yPos Y position.
     * @param cellSize Cell size in pixels.
     * @param positiveColor Color for positive values.
     * @param negativeColor Color for negative values.
     * @param neutralColor Color for neutral values.
     * @param prefix Object name prefix.
     * @return true on success.
     */
    bool Initialize(int xPos, int yPos, int cellSize,
                    color positiveColor, color negativeColor, color neutralColor,
                    const string prefix = CORRELATION_PREFIX)
    {
        if(cellSize <= 5)
            return false;

        m_x = xPos;
        m_y = yPos;
        m_cell = cellSize;
        m_pos = positiveColor;
        m_neg = negativeColor;
        m_neutral = neutralColor;
        m_prefix = prefix;
        m_visible = true;
        m_title = "Correlation Matrix";
        m_tooltips_enabled = true;
        m_pool_count = 0;
        ArrayResize(m_last_values, 0);
        ArrayResize(m_last_symbols, 0);
        return true;
    }

    /**
     * Maps correlation values to colors.
     * @param correlation Correlation coefficient.
     * @return Color for the value.
     */
    color GetColorForValue(double correlation)
    {
        if(correlation == EMPTY_VALUE)
            return m_neutral;
        if(correlation >= 0.7)
            return clrDarkGreen;
        if(correlation >= 0.3)
            return m_pos;
        if(correlation >= -0.3)
            return m_neutral;
        if(correlation >= -0.7)
            return m_neg;
        return clrDarkRed;
    }

    /**
     * Draws the legend text label.
     * @return none
     */
    void DrawLegend()
    {
        string text = "Strong + | Moderate + | Weak | Moderate - | Strong -";
        CreateOrUpdateLabel(LegendName(), m_x, m_y - (m_cell / 2), text, clrSilver);
    }

    /**
     * Draws the title label.
     * @param text Title text.
     * @return none
     */
    void DrawTitle(const string text)
    {
        m_title = text;
        CreateOrUpdateLabel(TitleName(), m_x, m_y - m_cell, m_title, clrWhite);
    }

    /**
     * Returns the title object name.
     * @return Object name.
     */
    string GetTitleObjectName() const
    {
        return TitleName();
    }

    /**
     * Returns current visibility state.
     * @return true if visible.
     */
    bool IsVisible() const
    {
        return m_visible;
    }

    /**
     * Sets panel title text.
     * @param text Title text.
     * @return none
     */
    void SetTitle(const string text)
    {
        m_title = text;
    }

    /**
     * Enables/disables hover tooltips for cells.
     * @param enabled Tooltip state.
     * @return none
     */
    void SetTooltipsEnabled(bool enabled)
    {
        m_tooltips_enabled = enabled;
    }

    /**
     * Draws the full heatmap with headers and values.
     * @param matrix Correlation matrix.
     * @param symbols Symbol list.
     * @return none
     */
    void DrawHeatmap(const double &matrix[][], const string &symbols[])
    {
        int count = ArraySize(symbols);
        if(count <= 0)
            return;

        EnsurePool(symbols);
        DrawTitle(m_title);
        DrawLegend();

        for(int row = 0; row < count; row++)
        {
            for(int col = 0; col < count; col++)
            {
                double value = matrix[row][col];
                int idx = FlatIndex(row, col, count);
                if(m_last_values[idx] == value)
                    continue;

                color fill = GetColorForValue(value);
                string label = (value == EMPTY_VALUE) ? "" : DoubleToString(value, 2);
                string tip = symbols[row] + " / " + symbols[col] + ": " + label;
                if(value == EMPTY_VALUE)
                    tip = symbols[row] + " / " + symbols[col] + ": N/A";

                int x = m_x + m_cell + (col * m_cell);
                int y = m_y + m_cell + (row * m_cell);

                CreateOrUpdateRect(CellName(row, col), x, y, m_cell, m_cell, fill, tip);

                int lx = x + 5;
                int ly = y + 5;
                CreateOrUpdateLabel(LabelName(row, col), lx, ly, label, clrWhite);
                m_last_values[idx] = value;
            }
        }
    }

    /**
     * Shows or hides all matrix objects.
     * @param visible true to show, false to hide.
     * @return none
     */
    void SetVisibility(bool visible)
    {
        m_visible = visible;
        int total = ObjectsTotal(0);
        for(int i = total - 1; i >= 0; i--)
        {
            string name = ObjectName(0, i);
            if(StringFind(name, m_prefix) == 0)
                ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : 0);
        }
    }

    /**
     * Updates a single cell and its label.
     * @param row Row index.
     * @param col Column index.
     * @param value Correlation value.
     * @return none
     */
    void UpdateCell(int row, int col, double value)
    {
        color fill = GetColorForValue(value);
        CreateOrUpdateRect(CellName(row, col),
                           m_x + m_cell + (col * m_cell),
                           m_y + m_cell + (row * m_cell),
                           m_cell, m_cell, fill);

        string label = (value == EMPTY_VALUE) ? "" : DoubleToString(value, 2);
        string tip = label;
        if(value == EMPTY_VALUE)
            tip = "N/A";
        CreateOrUpdateLabel(LabelName(row, col),
                            m_x + m_cell + (col * m_cell) + 5,
                            m_y + m_cell + (row * m_cell) + 5,
                            label, clrWhite);
        if(m_tooltips_enabled)
            ObjectSetString(0, CellName(row, col), OBJPROP_TOOLTIP, tip);
        else
            ObjectSetString(0, CellName(row, col), OBJPROP_TOOLTIP, "");
    }

    /**
     * Removes all objects created by this display.
     * @return none
     */
    void Clear()
    {
        int total = ObjectsTotal(0);
        for(int i = total - 1; i >= 0; i--)
        {
            string name = ObjectName(0, i);
            if(StringFind(name, m_prefix) == 0)
                ObjectDelete(0, name);
        }
        m_pool_count = 0;
        ArrayResize(m_last_values, 0);
        ArrayResize(m_last_symbols, 0);
    }
};
