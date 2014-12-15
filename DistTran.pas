unit DistTran;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, OleDB, COmObj, ADOInt, MSAccess;

function DTCTransactionStart: ITransaction;
procedure DTCTransactionCommit(ATransaction: ITransaction);
procedure DTCTransactionRollback(ATransaction: ITransaction);

procedure JoinSessionIntoTransaction(AConnectionArray: array of TMSConnection; ATransaction:ITransaction);
procedure UnJoinSession(AConnectionArray: array of TMSConnection);

implementation

function DtcGetTransactionManager(
  hostName: PChar;
  tmName: PChar;
  iid: Pointer;
  dwReserved1: DWord;
  wReserved2: Word;
  pvReserved: Pointer;
  out txnDispenser: ITransactionDispenser
): HResult; cdecl; external 'xolehlp.dll';

function DTCTransactionStart: ITransaction;
var
  ID: ITransactionDispenser;
begin
  Result := Nil;
  
  OLECheck(
    DtcGetTransactionManager(Nil, Nil, @IID_ITransactionDispenser, 0, 0, Nil, ID)
  );

  OLECheck(
    ID.BeginTransaction(Nil, ISOLATIONLEVEL_READCOMMITTED, 0, Nil, Result)
  );
end;

procedure DTCTransactionCommit(ATransaction:ITransaction);
begin
  OLECheck(
    ATransaction.Commit(False, 0, 0)
  );
end;

procedure DTCTransactionRollback(ATransaction: ITransaction);
begin
  OLECheck(
    ATransaction.Abort(Nil, False, False)
  );
end;

type THack = class(TMSConnection);

procedure JoinSessionIntoTransaction(AConnectionArray: array of TMSConnection; ATransaction: ITransaction);
var
  ITJ: ITransactionJoin;
  i: Integer;
begin
  for i:= Low(AConnectionArray) to High(AConnectionArray) do
  begin
    if not AConnectionArray[i].Connected then
      AConnectionArray[i].Open;

    OLECheck(
      THack(AConnectionArray[i]).IConnection.SessionProperties.QueryInterface(IID_ITransactionJoin, ITJ)
    );

    OLECheck(
      ITJ.JoinTransaction(ATransaction, ISOLATIONLEVEL_READCOMMITTED, 0, Nil)
    );
  end;
end;

procedure UnJoinSession(AConnectionArray: array of TMSConnection);
var
  ITJ: ITransactionJoin;
  i: Integer;
begin
  for i:= Low(AConnectionArray) to High(AConnectionArray) do
  begin
    if not AConnectionArray[i].Connected then
      AConnectionArray[i].Open;

    OLECheck(
      THack(AConnectionArray[i]).IConnection.SessionProperties.QueryInterface(IID_ITransactionJoin, ITJ)
    );

    OLECheck(
      ITJ.JoinTransaction(Nil, 0, 0, Nil)
    );
  end;
end;

end.
