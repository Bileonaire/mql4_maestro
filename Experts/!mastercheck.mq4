//+------------------------------------------------------------------+
//|                                                     Leon Bot.mq4 |
//|                                                       Bileonaire |
//|                                                         leon.com |
//+------------------------------------------------------------------+
#property copyright "Bileonaire"
#property link      "leon.com"
#property version   "1.00"
#property strict

string comment = "killer";
double Percentage_Risk = 1;
double Poin;
double target;

double magicNB = 5744;

string message ="";
int hour;
double latestUpdateMinute;


string analysis = "";
string cookie = NULL, headers;
char post[], result[];
int timeout = 5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection

double ND(double val)
{
return(NormalizeDouble(val, Digits));
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
  return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  string pairs[];
  int length = getAvailableCurrencyPairs(pairs);
  string buys = "Hot Buys  = ";
  string sells = "Hot Sells = ";

  for(int i=0; i < length; i++)
  {
    if (MarketInfo(pairs[i], MODE_SPREAD) < 20  && IsTradeAllowed(pairs[i], TimeCurrent())) {
      double accumulated = buyStrengthPercent(pairs[i]);

      if (accumulated>11 && meetsCriteria(pairs[i], "buy")) {
        buys += pairs[i] + accumulated + " |  ";
      }
      if (accumulated<9 && meetsCriteria(pairs[i], "sell")) {
        sells += pairs[i] + accumulated + " |  ";
      }
    }
  }

  if (latestUpdateMinute != Minute() && updateTime(Minute())) {
    string chat = "-1001632944296";  // Alerts_bileonaire_fx_channel
    if (sells != "Hot Sells = ") sendTelegram(sells, chat);
    if (buys != "Hot Buys  = ") sendTelegram(buys, chat);

    hour = Hour();
  }

  latestUpdateMinute = Minute();
  return;
}

bool updateTime (int minute) {
    if (minute % 14 == 0 || minute % 29 == 0 || minute % 44 == 0 || minute % 59 == 0) return true;
    else return false;
}

bool meetsCriteria(string cur, string direction) {
    int envs = 0;
    if (environment(cur, 15) == direction) envs += 1;
    if (environment(cur, 60) == direction) envs += 1;
    if (environment(cur, 240) == direction) envs += 1;

  if (envs>= 2 && PriceAboveBelowClose(cur, 1440, 1) == direction && pop(cur, 15) == direction && check_prev_candle(cur, 15, 1) == direction && Calculatepips_5candles(cur, 15)) return true;
  else return false;
}

bool Calculatepips_5candles(string symbol, int timef)
{
  bool goodCandle;

  double pips_current = MathAbs(iClose(symbol,timef,0) - iOpen(symbol,timef,0)) / GetPipValue(symbol);
  double pips_1 = MathAbs(iClose(symbol,timef,1) - iOpen(symbol,timef,1)) / GetPipValue(symbol);
  double pips_2 = MathAbs(iClose(symbol,timef,2) - iOpen(symbol,timef,2)) / GetPipValue(symbol);
  double pips_3 = MathAbs(iClose(symbol,timef,3) - iOpen(symbol,timef,3)) / GetPipValue(symbol);
  double pips_4 = MathAbs(iClose(symbol,timef,4) - iOpen(symbol,timef,4)) / GetPipValue(symbol);
  double pips_5 = MathAbs(iClose(symbol,timef,5) - iOpen(symbol,timef,5)) / GetPipValue(symbol);

  if (pips_current > pips_1 && pips_current > pips_2 && pips_current > pips_3 && pips_current > pips_4 && pips_current > pips_5) {
      goodCandle = true;
  }
  return goodCandle;
}


double buyStrengthPercent (string cur) {
  double accumulate = 0;
  // check prev daily candle
  if (check_prev_candle(cur, 1440, 1) == "buy") accumulate += 3;
  if (PriceAboveBelowEMA(cur, 1440, 8) ==  "above") accumulate += 3;
  if (PriceAboveBelowClose(cur, 1440, 1) == "buy") accumulate += 1;

  // h4
  if (check_prev_candle(cur, 240, 1) == "buy") accumulate += 2.5;
  if (environment(cur, 240) == "buy") accumulate += 2.5;
  if (closeAboveBelowEMA(cur, 240, 20) == "above") accumulate += 1.5;

  // h1
  if (check_prev_candle(cur, 60, 1) == "buy") accumulate += 1.5;
  if (environment(cur, 60) == "buy") accumulate += 1.5;

  // m15
  if (check_prev_candle(cur, 15, 1) == "buy") accumulate += 1;
  if (environment(cur, 15) == "buy") accumulate += 1;
  if (closeAboveBelowEMA(cur, 15, 200) == "above") accumulate += 1.5;

  // total
  return accumulate;
}

// cur = currency
int mastercheck(string cur) {
  // buy
  if (check_prev_candle(cur, 43200, 1) == "buy" && PriceAboveBelowClose(cur, 43200, 1) == "buy" && environment(cur, 240) == "buy" && check_prev_candle(cur, 240, 1) == "buy" && environment(cur, 15) == "buy") {
      if (pricebelowEMAs_m5(cur) == "buy") {
          // if (checkSpread(cur) < 21) {
            if (currency_open_orders(cur) == 0 && all_open_orders () < 3) {
              // entry
              double poin = GetPipValue(cur);

              double stop = low(cur, 5, 1) - 2*poin;
              double entryPrice = MarketInfo(cur, MODE_BID);
              double pips = MathAbs(entryPrice - stop) / GetPipValue(cur);
              double tprofit = entryPrice + pips*1.82*poin;
              Alert("hot buy : ", cur, " entry: ", entryPrice , " sl : ", stop, " tp : ", tprofit);

              // executeTrade("buy", cur, 10, 100, 0, stop, tprofit);
            }
          // }
      }
  }

  if (check_prev_candle(cur, 43200, 1) == "sell" && PriceAboveBelowClose(cur, 43200, 1) == "sell" && environment(cur, 240) == "sell" && check_prev_candle(cur, 240, 1) == "sell" && environment(cur, 15) == "sell") {
      if (pricebelowEMAs_m5(cur) == "sell") {
        // if (checkSpread(cur) < 21) {
            if (currency_open_orders(cur) == 0 && all_open_orders () < 3) {
              // entry
              double poin = GetPipValue(cur);

              double stop = low(cur, 5, 1) + 2*poin;
              double entryPrice = MarketInfo(cur, MODE_ASK);
              double pips = MathAbs(entryPrice - stop) / GetPipValue(cur);
              double tprofit = entryPrice - pips*1.82*poin;
              Alert("hot buy : ", cur, " entry: ", entryPrice , " sl : ", stop, " tp : ", tprofit);

              // executeTrade("sell", cur, 10, 100, 0, stop, tprofit);
            }
        // }
      }
  }
  return(0);
}

//+------------------------------------------------------------------+
int getAvailableCurrencyPairs(string & availableCurrencyPairs[])
{
//---
   bool selected = false;
   const int symbolsCount = SymbolsTotal(selected);
   int currencypairsCount;
   ArrayResize(availableCurrencyPairs, symbolsCount);
   int idxCurrencyPair = 0;
   for(int idxSymbol = 0; idxSymbol < symbolsCount; idxSymbol++)
     {
         string symbol = SymbolName(idxSymbol, selected);
         string firstChar = StringSubstr(symbol, 0, 1);
         if(firstChar != "#" && StringLen(symbol) == 6)
           {
               availableCurrencyPairs[idxCurrencyPair++] = symbol;
           }
     }
     currencypairsCount = idxCurrencyPair;
     ArrayResize(availableCurrencyPairs, currencypairsCount);
     return currencypairsCount;
}
//+------------------------------------------------------------------+
class CFix { } ExtFix; // Force expressions evaluation while debugging

//+------------------------------------------------------------------+
// check previous candle of a timeframe if bullish or bearish
string PriceAboveBelowEMA(string currency, int timef, int movingAVG)
{
   string status = "";
   double PriceAsk = MarketInfo(currency, MODE_ASK);

   if (PriceAsk > iMA(currency,timef,movingAVG,0,MODE_EMA,PRICE_CLOSE,0)) {
     status = "above";
   } else {
     status = "below";
   }
   return status;
}

string closeAboveBelowEMA (string cur, int timef, int movingAVG) {
  double close = close(cur, timef, 1);

  double ema = iMA(cur,timef,movingAVG,0,MODE_EMA,PRICE_CLOSE,0);
  string situation = "";
  if (close > ema) situation = "above";
  if (close < ema) situation = "below";
  return situation;
}

string openAboveBelowEMA (string cur, int timef, int movingAVG) {
  double open = open(cur, timef, 1);

  double ema = iMA(cur,timef,movingAVG,0,MODE_EMA,PRICE_CLOSE,0);
  string situation = "";
  if (open > ema) situation = "above";
  if (open < ema) situation = "below";
  return situation;
}

// picture of power
string pop(string cur, int timef) {
  string pop_status;

  if (closeAboveBelowEMA(cur, timef, 200) == "above" && closeAboveBelowEMA(cur, timef, 20) == "above" && openAboveBelowEMA(cur, timef, 20) == "above") {
    pop_status = "buy";
  }
  if (closeAboveBelowEMA(cur, timef, 200) == "below" && closeAboveBelowEMA(cur, timef, 20) == "below"  && openAboveBelowEMA(cur, timef, 20) == "below") {
    pop_status = "sell";
  }

  return pop_status;
}

string check_prev_candle(string currency, int timef, int shift)
{
   string status = "";
   if (iOpen(currency,timef,shift) > iClose(currency,timef,shift)) {
     status = "sell";
   } else {
     status = "buy";
   }
   return status;
}
//+------------------------------------------------------------------+
// check if current price is above/below prev close
string PriceAboveBelowClose(string currency, int timef, int shift)
{
   double PriceAsk = MarketInfo(currency, MODE_ASK);
  //  double PriceBid = MarketInfo(currency, MODE_BID);

   string status = "";
   if (PriceAsk > iClose(currency,timef,shift)) {
     status = "buy";
   } else {
     status = "sell";
   }
   return status;
}

double open(string currency, int timef, int shift)
{
   double val=iOpen(currency,timef,shift);
   return val;
}

double close(string currency, int timef, int shift)
{
   double val=iClose(currency,timef,shift);
   return val;
}

double high(string currency, int timef, int shift)
{
   double val=iHigh(currency,timef,shift);
   return val;
}

double low(string currency, int timef, int shift)
{
   double val;
   val=iLow(currency,timef,shift);
   return val;
}

// Lowest in the past ___ bars
double lowest(string currency, double bars)
{
   double val;
   int val_index;
   val_index=iLowest(currency,0,MODE_LOW,bars,0);
   if(val_index!=-1) val=High[val_index];
   else val=0;

   return val;
}

// Highest in the past ___ bars
double highest(string currency, double bars)
{
   double val;
   int  val_index=iHighest(currency,60,MODE_HIGH,bars,1);
   if(val_index!=-1) val=High[val_index];
   else val=0;

   return val;
// else PrintFormat("Error in call iHighest. Error code=%d",GetLastError());
}

//  Check orders
string currency_open_orders (string currency)
{
  double currency_orders = 0;
  for(int i=0;i<OrdersTotal();i++) {
    int order = OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
    if (OrderComment() == comment && OrderSymbol() == currency) currency_orders++;
  }
  return currency_orders;
}

//  All orders
double all_open_orders ()
{
  double orderplaced = 0;
  for(int i=0;i<OrdersTotal();i++) {
    int order = OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
    if (OrderComment() == comment) orderplaced++;
    }
  return orderplaced;
}

// Environment_Check
// Call the function: environment(Symbol(),15)
string environment (string currency, int timef)
{
  double MacdCurrent = iMACD(currency,timef,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
  double twenty_ema = iMA(currency,timef,20,0,MODE_EMA,PRICE_CLOSE,0);
  double ten_ema = iMA(currency,timef,10,0,MODE_EMA,PRICE_CLOSE,0);
  string buy_or_sell = " ";

// BUY env
  if (MacdCurrent > 0 && ten_ema > twenty_ema) buy_or_sell = "buy";
// Sell env
  if (MacdCurrent < 0 && ten_ema < twenty_ema) buy_or_sell = "sell";
  return buy_or_sell;
}

string all_time_environment (string currency)
{
  double price = MarketInfo(currency,MODE_ASK);
  double ten_ema = iMA(currency,240,10,0,MODE_EMA,PRICE_CLOSE,0);

  string env_ = " ";
// BUY env
  if (environment(currency, 240) == "buy" && environment(currency, 60) == "buy" && environment(currency, 15) == "buy" && choppines(currency, 15) < 52 && price > ten_ema) env_ = "buy";
// Sell env
  if (environment(currency, 240) == "sell" && environment(currency, 60) == "sell" && environment(currency, 15) == "sell" && choppines(currency, 15) < 52 && price < ten_ema) env_ = "sell";
  return env_;
}

string pricebelowEMAs_m5 (string cur) {
  double open_m5 = open(cur, 5, 1);
  double close_m5 = close(cur, 5, 1);

  double ten_ema = iMA(cur,5,11,0,MODE_EMA,PRICE_CLOSE,0);
  double twenty_ema = iMA(cur,5,20,0,MODE_EMA,PRICE_CLOSE,0);
  string situation = "";
  if (open_m5 > ten_ema && close_m5 > twenty_ema) {
    situation = "buy";
  }
  if (open_m5 < ten_ema && close_m5 < twenty_ema) {
    situation = "sell";
  }
  return situation;
}

double choppines(string currency, int timeframe)
{
  int choppy_value = NormalizeDouble(iCustom(currency, timeframe, "Custom\\choppiness-index", 0, 0), 2);
  return choppy_value;
}

double checkSpread(string currency)
{
  double spread_value = NormalizeDouble(MarketInfo(currency, MODE_SPREAD), 2);
  return spread_value;
}

//+------------------------------------------------------------------+

double executeTrade(string orderType, string symbol, double accountSize, double percentageRisk, double pendingOrderPrice, double stopLossPrice, double takeProfitPrice)
{
  // if(IsTradingAllowed())
  // {
    double riskPerTradeDollars = (accountSize * (percentageRisk / 100));
    // buy
    if(orderType == "sell" && pendingOrderPrice == 0.0)
    {
        double entryPrice = MarketInfo(symbol, MODE_ASK);
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUY, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // sell
    if(orderType == "buy" && pendingOrderPrice == 0.0)
    {
        double entryPrice = MarketInfo(symbol, MODE_BID);
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELL, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // buystop
    if(orderType == "buystop")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUYSTOP, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // sellstop
    if(orderType == "sellstop")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELLSTOP, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // buylimit
    if(orderType == "buylimit")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_BUYLIMIT, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }

    // selllimit
    if(orderType == "selllimit")
    {
        double entryPrice = pendingOrderPrice;
        double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
        int openOrderID = OrderSend(symbol, OP_SELLLIMIT, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
        if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
        return openOrderID;
    }
  // }
  return(0);
}

//+------------------------------------------------------------------+

// custom re-usable functions

// works for fx pairs, may not work for indices
double GetPipValue(string symbol)
{
  int vdigits = (int)MarketInfo(symbol, MODE_DIGITS);

  if(vdigits >= 4)
  {
    return 0.0001;
  }
  else
  {
    return 0.01;
  }
}

double CalculateLotSize(string symbol, double riskDollars, double entryPrice, double slPrice)
{
  Alert( " symbol: " ,symbol , " risk : ", riskDollars,  " entry : ", entryPrice,  " sl : ",slPrice);

  double pipValue = MarketInfo(symbol, MODE_TICKVALUE) * 10;
  double pips = MathAbs(entryPrice - slPrice) / GetPipValue(symbol);
  double div = pips * pipValue;
  double lot = NormalizeDouble(riskDollars / div, 2);

  return lot;
}

bool IsTradingAllowed()
{
  if(!IsTradeAllowed())
  {
    Alert("Expert Advisor is NOT Allowed to Trade. Check AutoTrading.");
    return false;
  }

  if(!IsTradeAllowed(Symbol(), TimeCurrent()))
  {
    Alert("Trading NOT Allowed for specific Symbol and Time");
    return false;
  }
  return true;
}

int closeAll()
{
  int ticket;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
        if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
          {
            if (OrderType() == 0 && OrderComment() == comment)
              {
              ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, CLR_NONE);
              if (ticket == -1) Print ("Error: ", GetLastError());
              if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
              }
            if (OrderType() == 1 && OrderComment() == comment)
              {
              ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_ASK), 3, CLR_NONE);
              if (ticket == -1) Print ("Error: ",  GetLastError());
              if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
              }
          }
        }
        return ticket;
}


int sendTelegram(string mes, string chat_id)
{
   string cookie=NULL,headers;
   char post[],result[];

   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection

   string sending=StringConcatenate("https://api.telegram.org/bot1283891993:AAGa9NV3ntsmIRj89yHSGCb-znW5WUhpJio/sendMessage?chat_id="+chat_id+"&text="+mes+"&parse_mode=html");
   ResetLastError();
   int free=WebRequest("POST",sending,cookie,NULL,timeout,post,0,result,headers);
return(0);

// string chatId = "-1001366966111";  // bileonaire_fx
// string chatId = "-1001278337047";
// string chatId2 = "-1001237306634";  // bileonaire_fx_community
// string chatId3 = "-1001366966111";
}
