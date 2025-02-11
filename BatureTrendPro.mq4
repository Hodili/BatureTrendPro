//+------------------------------------------------------------------+
//| BatureTrendPro - Trend Identification Indicator for MT4         |
//| Based on EMA, ADX, RSI, MACD                                    |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Lime
#property indicator_color2 Red
#property indicator_type1 DRAW_ARROW
#property indicator_type2 DRAW_ARROW

// Indicator Buffers
double UpTrendBuffer[];
double DownTrendBuffer[];

// Indicator Settings
int ShortEMA = 50;
int LongEMA = 200;
double ADXThreshold = 25.0;
double RSIThreshold = 50.0;

// Trend State Tracking
int PreviousTrendState = 0; // 0 - Uncertain, 1 - Uptrend, -1 - Downtrend

// Handles Initialization
int OnInit()
{
   IndicatorShortName("BatureTrendPro");  // Set the displayed indicator name
   IndicatorBuffers(2);
   SetIndexBuffer(0, UpTrendBuffer);
   SetIndexBuffer(1, DownTrendBuffer);
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexStyle(1, DRAW_ARROW);
   SetIndexArrow(0, 233);
   SetIndexArrow(1, 234);
   
   ArraySetAsSeries(UpTrendBuffer, true);
   ArraySetAsSeries(DownTrendBuffer, true);
   
   return(INIT_SUCCEEDED);
}

// Trend Calculation
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (rates_total < LongEMA) return 0;
   
   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
   string msg; // Declare message variable once
   
   for(int i = start; i < rates_total - 1; i++)
   {
      // Calculate technical indicators once per bar
      double ema50 = iMA(NULL, 0, ShortEMA, 0, MODE_EMA, PRICE_CLOSE, i);
      double ema200 = iMA(NULL, 0, LongEMA, 0, MODE_EMA, PRICE_CLOSE, i);
      double adx = iADX(NULL, 0, 14, PRICE_CLOSE, MODE_MAIN, i);
      double rsi = iRSI(NULL, 0, 14, PRICE_CLOSE, i);
      double macd = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, i);
      double signal = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, i);
      
      // Determine the current trend
      int currentTrendState = 0; // Uncertain by default

      if (ema50 > ema200 && adx > ADXThreshold && rsi > RSIThreshold && macd > signal) {
         currentTrendState = 1; // Uptrend
      } else if (ema50 < ema200 && adx > ADXThreshold && rsi < RSIThreshold && macd < signal) {
         currentTrendState = -1; // Downtrend
      }

      // Check for trend change and trigger signals accordingly
      if (currentTrendState != PreviousTrendState)
      {
         if (currentTrendState == 1) {
            UpTrendBuffer[i] = low[i] - 10 * Point;
            DownTrendBuffer[i] = 0;
            msg = "Trend changed to UP at " + TimeToString(time[i]);
            Alert(msg);
            SendNotification(msg);
         }
         else if (currentTrendState == -1) {
            DownTrendBuffer[i] = high[i] + 10 * Point;
            UpTrendBuffer[i] = 0;
            msg = "Trend changed to DOWN at " + TimeToString(time[i]);
            Alert(msg);
            SendNotification(msg);
         }
         else {
            UpTrendBuffer[i] = 0;
            DownTrendBuffer[i] = 0;
         }
         
         PreviousTrendState = currentTrendState; // Update previous trend state
      }
      else {
         UpTrendBuffer[i] = 0;
         DownTrendBuffer[i] = 0;
      }
   }
   return(rates_total);
}
