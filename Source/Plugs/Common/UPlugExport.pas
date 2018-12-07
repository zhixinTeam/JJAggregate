{*******************************************************************************
  ����: dmzn@163.com 2013-11-22
  ����: ģ���������
*******************************************************************************}
unit UPlugExport;

interface

uses
  Windows, Classes, UMgrPlug, UMgrControl, UBusinessPacker, UBusinessWorker,
  UPlugModule, UEventWorker, USysLoger;

procedure BackupEnvironment(const nNewEnv: PPlugEnvironment); stdcall;
procedure LoadModuleWorker(var nWorker: TPlugEventWorkerClass); stdcall;
procedure LibraryEntity(const nReason: Integer);
//��ں���

implementation

var
  gIsBackup: Boolean = False;
  gPlugEnv: TPlugEnvironment;
  //ģ�黷��

//Date: 2013-11-23
//Parm: ��������
//Desc: ���ݵ�ǰ����,ʹ��nNewEnv����
procedure BackupEnvironment(const nNewEnv: PPlugEnvironment); stdcall;
begin
  if not gIsBackup then
  begin
    gPlugEnv.FExtendObjects := TStringList.Create;
    //env extend

    TPlugManager.EnvAction(@gPlugEnv, True);
    TPlugManager.EnvAction(nNewEnv, False);
    gIsBackup := True;

    gPlugEnv.FCtrlManager.MoveTo(gControlManager);
    gPlugEnv.FPackerManager.MoveTo(gBusinessPackerManager);
    gPlugEnv.FWorkerManager.MoveTo(gBusinessWorkerManager);
    //�ƽ�����
  end;
end;

//Desc: �ָ���������
procedure RestoreEnvironment;
begin
  if gIsBackup then
  begin
    TPlugManager.EnvAction(@gPlugEnv, False);
    //restore all param
    gPlugEnv.FExtendObjects.Free;
    //release extend
  end;
end;

procedure LoadModuleWorker(var nWorker: TPlugEventWorkerClass); stdcall;
begin
  nWorker := TPlugWorker;
end;

procedure LibraryEntity(const nReason: Integer);
begin
  case nReason of
   DLL_PROCESS_DETACH : RestoreEnvironment;
   DLL_THREAD_ATTACH : IsMultiThread := True;
  end;
end;

end.
