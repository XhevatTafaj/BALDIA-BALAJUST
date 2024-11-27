namespace AvantMoney.ExportDailyMonthly;
permissionset 50500 "PTE Exp_DailyMonthly"
{
    Caption = 'Export Daily Monthly Reports';
    Assignable = true;
    Permissions = tabledata "PTE Daily/Monthly Register" = RIMD,
        table "PTE Daily/Monthly Register" = X,
        codeunit "PTE Daily/Monthly Export" = X,
        codeunit "PTE Isolated Storage Mgt." = X,
        xmlport "PTE Daily Balance" = X,
        xmlport "PTE Monthly Balance" = X,
        page "PTE Daily/Monthly Registers" = X;
}