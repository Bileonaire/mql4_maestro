//+------------------------------------------------------------------+
//|                                                RemoteExecutor.mq4 |
//|                                      Copyright 2021, Lenny Kioko |
//|                  https://github.com/Bileonaire/RemoteMT4Executor |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2021, Bileonaire & Lenny."
#property link      "https://github.com/Bileonaire/RemoteMT4Executor"
#property description "Execute Trade from API"
#property version   "1.00"
#property strict
#property show_inputs

#include <stderror.mqh>
#include <stdlib.mqh>

#include <JAson.mqh>

extern string acc_number = "66076442";

datetime LastActiontime;
extern string httpLink = "https://tradeexecutor.herokuapp.com/api/trades/";

string resData;
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   //Comparing LastActionTime with the current starting time for the candle
   if(LastActiontime!=Time[0]){
      //Code to execute once in the bar
      remoteExecutor();
      LastActiontime=Time[0];
   }
  }
//+------------------------------------------------------------------+

string apiCall(string type, string link) {
   string cookie=NULL,headers;
   char post[],result[];

   int timeout=8000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection
   string res=WebRequest(type, link ,cookie,NULL,timeout,post,0,result,headers);
   resData = CharArrayToString(result);
return res;
}

int remoteExecutor() {
    string link = httpLink + acc_number;
    string str = apiCall("GET", link);

    if (str == "200") {
        // Object
        CJAVal json;

        // Load in and deserialize the data
        json.Deserialize(resData);

        string ordertype = json["ordertype"].ToStr();
        string symbol = json["symbol"].ToStr();
        string account = json["account"].ToStr();
        string percentage_risk = json["percentage_risk"].ToStr();
        string pendingorderprice = json["pendingorderprice"].ToStr();
        string sl = json["sl"].ToStr();
        string tp = json["tp"].ToStr();
        string id = json["id"].ToStr();

        double tradeAcc = StrToDouble(account);
        double tradePercentRisk = StrToDouble(percentage_risk);
        double tradePendingPrice = StrToDouble(pendingorderprice);
        double tradeSL = StrToDouble(sl);
        double tradeTP = StrToDouble(tp);

        int trade = executor(ordertype, symbol, tradeAcc, tradePercentRisk, tradePendingPrice, tradeSL, tradeTP);
        if (trade > 0) {
            // Executed_Successfully
            string link2 = link + "/" + id;
            string success = apiCall("GET", link2);
            if (success == "200") resData = "";
        } else {
            // Execution_Failed
            string link2 = link + "/unsuccessful/" + id;
            string success = apiCall("GET", link2);
        }
    }
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
