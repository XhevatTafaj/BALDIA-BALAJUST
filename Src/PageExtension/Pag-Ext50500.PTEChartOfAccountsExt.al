namespace AvantMoney.ExportDailyMonthly;
using System.Utilities;
using Microsoft.Finance.GeneralLedger.Account;
pageextension 50500 "PTE ChartOfAccountsExt" extends "Chart of Accounts"
{
    actions
    {
        addlast(processing)
        {
            action(DailyExport)
            {
                Caption = 'Export Daily File Manualy';
                Image = Export;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    DailyMonthlyExport: Codeunit "PTE Daily/Monthly Export";
                begin
                    DailyMonthlyExport.EnableDownloadFileToLocal();
                    DailyMonthlyExport.ExportDailyBalanceFileOnAzure(Today);
                end;
            }
            action(MonthlyExport)
            {
                Caption = 'Monthly Export';
                Image = Export;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    FileName: Text[100];
                    TempBlob: Codeunit "Temp Blob";
                    Outstream: OutStream;
                    Ins: InStream;
                begin
                    FileName := 'MONTHLY_BALANCE_' + Format(Today(), 0, 'yyyyMMdd') + '.txt';
                    TempBlob.CreateOutStream(Outstream);
                    Xmlport.Export(50503, Outstream);
                    TempBlob.CreateInStream(Ins);
                    DownloadFromStream(Ins, FileName, '', 'text/plain', FileName);
                end;
            }
        }
    }
}