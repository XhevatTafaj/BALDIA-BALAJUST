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
                Caption = 'Export Monthly File Manualy';
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
                    DailyMonthlyExport.ExportMonthlyBalanceFileOnAzure(Today);
                end;
            }
            action(ExportDailyMonthlyFiles)
            {
                Caption = 'Export Files Manualy';
                Image = Export;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    DailyMonthlyExport: Codeunit "PTE Daily/Monthly Export";
                begin
                    DailyMonthlyExport.ExportDailyMonthlyFiles();
                end;
            }
            //
        }
    }
}
