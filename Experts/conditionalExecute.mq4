//+------------------------------------------------------------------+
//|                                                RemoteExecutor.mq4 |
//|                                      Copyright 2021, Lenny Kioko |
//|                  https://github.com/Bileonaire/RemoteMT4Executor |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2021, Bileonaire & Lenny."
#property link      "Bileonairefx.com"
#property description "Execute Trade from API"
#property version   "1.00"
#property strict
#property show_inputs

#include <stderror.mqh>
#include <stdlib.mqh>
#include <json.mqh>

//external parameters to be provided
enum e_condition{
 closeRed=1,
 closeGreen=2,
 closeAbovePrice = 3,
 closeBelowPrice = 4,
};

input e_condition condition = closeAbovePrice;

enum e_timeframe{
 five=1,
 fifteen=2,
 one_hr = 3,
 four_hours = 4,
};

input e_timeframe timeframe = fifteen;

enum e_orderType{
 Buy=1,
 Sell=2,
 BuyStop = 3,
 SellStop = 4,
 BuyLimit = 6,
 SellLimit = 5,
};

input e_orderType  orderType = Buy;
extern string symbol;
extern double Account = 9.33;
extern double Percentage_Risk = 100;

extern double  totalLot = 0.0;

enum e_print_lot{
 ndio=1,
 la=0,
};

input e_print_lot  print_lot = ndio;

extern int numOfOrders = 1;
extern string comment = "";


extern double PendingOrderPrice = 0.00;
double PendingOrderPips = 0.00;

enum e_Sl_Tp_Type{
 Pips=1,
 Price=2
};

input e_Sl_Tp_Type  Sl_Tp_Type = Price;

enum e_Set_SL{
 Yes=1,
 No=2,
};

input e_Set_SL Set_SL = Yes;

extern double sl = 0.0;
extern double tp = 0.0;

enum e_execute_trade{
 Yess=1,
 Noo=0,
};

int minutes;
datetime LastActiontime;

int init() {
   if (timeframe == five) minutes = 5;
   if (timeframe == fifteen) minutes = 15;
   if (timeframe == one_hr) minutes = 60;
   if (timeframe == four_hours) minutes = 240;
   return(0);
}
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   //Comparing LastActionTime with the current starting time for the candle
   if(LastActiontime!=Time[0]){
      //Code to execute once in the bar
      conditionExecutor();
      LastActiontime=Time[0];
   }
  }
//+------------------------------------------------------------------+

int conditionExecutor() {
    MessageBox(minutes);
    return(0);
}

//+------------------------------------------------------------------+

int executor(string orderType, string symbol, double accountSize, double percentageRisk, double pendingOrderPrice, double stopLossPrice, double takeProfitPrice)
{
  if (accountSize==0.00) accountSize = AccountBalance();
  double riskPerTradeDollars = (accountSize * (percentageRisk * 0.01));
  double magicNB = 5744;
  // buy
  if(orderType == "buy" && pendingOrderPrice == 0.0)
  {
      double entryPrice = MarketInfo(symbol,MODE_ASK);
      double lotSize = CalculateLotSize(symbol, riskPerTradeDollars, entryPrice, stopLossPrice);
      int openOrderID = OrderSend(symbol, OP_BUY, lotSize, entryPrice, 20, stopLossPrice, takeProfitPrice, IntegerToString(magicNB), magicNB, 0, 0); // magic number as comment
      if(openOrderID < 0) Alert("order rejected. Order error: " + GetLastError());
      return openOrderID;
  }

  // sell
  if(orderType == "sell" && pendingOrderPrice == 0.0)
  {
      double entryPrice = MarketInfo(symbol,MODE_BID);
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
  if(orderType == "buystop")
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
  return(0);
}

//+------------------------------------------------------------------+

// custom re-usable functions

// works for fx pairs, may not work for indices
double GetPipValue(string symbol)
{
  int vdigits = (int)MarketInfo( symbol, MODE_DIGITS);
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
  double pipValue = MarketInfo(symbol, MODE_TICKVALUE) * 10;
  double pips = MathAbs(entryPrice - slPrice) / GetPipValue(symbol);
  double lott = (riskDollars / pips) / pipValue;
  double lot = NormalizeDouble(lott, 2);

  return lot;
}
