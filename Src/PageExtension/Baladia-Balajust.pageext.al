pageextension 50500 "ChartOfAccountsExt" extends "Chart of Accounts"
{
    actions
    {
        addlast(processing)
        {
            action(DailyExport)
            {
                Caption = 'Daily Export';
                Image = Export;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    FileName: Text[100];
                begin
                    FileName := 'Daily_BALANCE_' + Format(Today(), 0, '<Year><Month>') + '.txt';
                    Xmlport.Run(50500, true, false);
                end;
            }
            action(MonthyExport)
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
                begin
                    FileName := 'MONTHLY_BALANCE_' + Format(Today(), 0, '<Year><Month>') + '.txt';
                    Xmlport.Run(50501, true, false);
                end;
            }
        }

    }
}