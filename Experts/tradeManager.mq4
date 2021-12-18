//+------------------------------------------------------------------+
//|                                                 TradeManager.mq4 |
//|                                             Copyright 2021, Leon |
//|                  https://github.com/Bileonaire/RemoteMT4Executor |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2021, Bileonaire"
#property link      "https://github.com/Bileonaire/"
#property description "Manage Trade"
#property version   "1.00"
#property strict
#property show_inputs

#include <stderror.mqh>
#include <stdlib.mqh>

extern double RR_Ratio = 1.5;
extern double newSLPips = 2;


datetime LastActiontime;

string chatId3 = "-1001366966111";  // bileonaire_fx -- Small group with Tom
string chatId4 = "-1001662752776"; // Leon Private group
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   //Comparing LastActionTime with the current starting time for the candle
   if(LastActiontime!=Time[0]){
      //Code to execute once in the bar
      manageTrades();
      LastActiontime=Time[0];
   }
  }

int manageTrades() {
   int ordertotal = OrdersTotal();

   RefreshRates();

   for (int i=0 ; i <= ordertotal; i++)
   {
      RefreshRates();
      int order = OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         double currentPrice = MarketInfo(OrderSymbol(),MODE_ASK);

         if(OrderType()==OP_BUY) {
            if(OrderStopLoss() < OrderOpenPrice()){
                double RiskToReward = CalculateRR(OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), currentPrice);
                if(RiskToReward >= RR_Ratio) {
                    double sl_Price = OrderOpenPrice()+2*GetPipValue(OrderSymbol());
                    int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), sl_Price, OrderTakeProfit(), 0);
                    if(ticket == 1) {
                        int vdigits = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
                        string sl = DoubleToStr(sl_Price, vdigits);
                        string text = StringConcatenate(OrderSymbol()+ " - StopLoss to BreakEven (" + sl + ")");
                        SendSignal(text);
                    }
                }
            }
         }
         if(OrderType()==OP_SELL) {
            if(OrderStopLoss() > OrderOpenPrice()){
                double RiskToReward = CalculateRR(OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), currentPrice);
                if(RiskToReward >= RR_Ratio) {
                    double sl_Price = OrderOpenPrice()-2*GetPipValue(OrderSymbol());
                    int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), sl_Price, OrderTakeProfit(), 0);
                    if(ticket == 1) {
                        int vdigits = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
                        string sl = DoubleToStr(sl_Price, vdigits);
                        string text = StringConcatenate(OrderSymbol()+ " - StopLoss to BreakEven (" + sl + ")");
                        SendSignal(text);
                    }
                }
            }
         }
   }
return(0);

}

double CalculateRR(string symbol, double entryPrice, double slPrice, double currentPrice)
{
  double pipsToSL = MathAbs(entryPrice - slPrice) / GetPipValue(symbol);
  double pipsToCurrent = MathAbs(entryPrice - currentPrice) / GetPipValue(symbol);

  double RiskReward = pipsToCurrent/pipsToSL;

  return RiskReward;
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

int SendSignal(string message) {
   string cookie=NULL,headers;
   char post[],result[];
   int timeout=5000; //--- Timeout below 1000 (1 sec.) is not enough for slow Internet connection
   string bileonaire_fx_free=StringConcatenate("https://api.telegram.org/bot1283891993:AAGa9NV3ntsmIRj89yHSGCb-znW5WUhpJio/sendMessage?chat_id="+chatId3+"&text="+message+"&parse_mode=html");
   ResetLastError();
   int free=WebRequest("POST",bileonaire_fx_free,cookie,NULL,timeout,post,0,result,headers);
return(0);
}
