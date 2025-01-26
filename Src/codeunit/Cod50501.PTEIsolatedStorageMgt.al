namespace AvantMoney.ExportDailyMonthly;
codeunit 50501 "PTE Isolated Storage Mgt."
{
    trigger OnRun()
    begin
    end;


    procedure GetStorage("Key": Text; Datascope: DataScope; var Value: Text): Boolean
    begin
        Value := '';
        exit(ISOLATEDSTORAGE.Get(CopyStr(Key, 1, 2000), Datascope, Value));
    end;

    procedure SetStorage("Key": Text; Value: Text; Datascope: DataScope): Boolean
    begin
        if not EncryptionEnabled() then
            exit(ISOLATEDSTORAGE.Set(CopyStr(Key, 1, 2000), Value, Datascope));

        exit(ISOLATEDSTORAGE.SetEncrypted(CopyStr(Key, 1, 2000), Value, Datascope));
    end;

    procedure DeleteStorage("Key": Text; Datascope: DataScope): Boolean
    begin
        if not ISOLATEDSTORAGE.Contains(CopyStr(Key, 1, 2000), Datascope) then
            exit(false);

        exit(ISOLATEDSTORAGE.Delete(CopyStr(Key, 1, 2000), Datascope));
    end;

    procedure ContainsStorage("Key": Text; Datascope: DataScope): Boolean
    begin
        exit(ISOLATEDSTORAGE.Contains(CopyStr(Key, 1, 2000), Datascope));
    end;
}