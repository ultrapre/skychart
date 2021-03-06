unit variables1;

{$MODE Delphi}

{
Copyright (C) 2008 Patrick Chevalley

http://www.ap-i.net
pch@ap-i.net

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

interface

uses
  {$ifdef mswindows}
  Windows, shlobj, ShellAPI,
  {$endif}
  {$ifdef unix}
  unix, baseunix, unixutil,
  {$endif}
  Clipbrd, LCLIntf, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, UScaleDPI,
  StdCtrls, ComCtrls, Buttons, IniFiles, Printers, FileUtil, LazUTF8,
  cu_cdcclient, u_util2,
  Menus, ExtCtrls, LResources, PrintersDlgs, Grids, EditBtn, jdcalendar, u_param;

type

  { TVarForm }

  TVarForm = class(TForm)
    DateEdit1: TDateEdit;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    EditEph1: TMenuItem;
    PrinterSetupDialog1: TPrinterSetupDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Open1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Grid1: TStringGrid;
    Setting1: TMenuItem;
    Help1: TMenuItem;
    Print1: TMenuItem;
    Printersetup1: TMenuItem;
    N6: TMenuItem;
    PopupMenu1: TPopupMenu;
    Lightcurve1: TMenuItem;
    Enterobservation1: TMenuItem;
    ShowChart1: TMenuItem;
    Edit3: TMenuItem;
    Content1: TMenuItem;
    TimePicker1: TTimePicker;
    Panel1: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    BitBtn1: TBitBtn;
    Edit1: TEdit;
    Edit2: TEdit;
    RadioGroup1: TRadioGroup;
    Edit4: TEdit;
    BitBtn3: TBitBtn;
    About1: TMenuItem;
    AAVSOTools1: TMenuItem;
    PrepareLPVBulletin1: TMenuItem;
    AAVSOwebpage1: TMenuItem;
    AAVSOChart1: TMenuItem;
    procedure BitBtn1Click(Sender: TObject);
    procedure DateEdit1Change(Sender: TObject);
    procedure Editeph1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Grid1SelectCell(Sender: TObject; aCol, aRow: integer;
      var CanSelect: boolean);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Grid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure Setting1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Print1Click(Sender: TObject);
    procedure Printersetup1Click(Sender: TObject);
    procedure Lightcurve1Click(Sender: TObject);
    procedure ShowChart1Click(Sender: TObject);
    procedure Newobservation1Click(Sender: TObject);
    procedure Content1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure PrepareLPVBulletin1Click(Sender: TObject);
    procedure AAVSOwebpage1Click(Sender: TObject);
    procedure AAVSOChart1Click(Sender: TObject);
  private
    { Private declarations }
    tcpclient: TCDCclient;
    procedure ScaleMainForm;
    procedure GetAppDir;
    procedure DrawSkyChart;
    procedure SkychartPurge;
    procedure InitSkyChart;
    function SkychartCmd(cmd: string): boolean;
  public
    { Public declarations }
  end;

function datef(jdt: double): string;

type
  TVarinfo = class(TObject)
    i: array[1..13] of double;
  end;

var
  VarForm: TVarForm;

implementation

{$R *.lfm}

uses detail1, SettingUnit, ObsUnit, splashunit, aavsochart, LazFileUtils;

procedure FreeInfo(var gr: TStringgrid);
var
  i: integer;
begin
  with gr do
    if rowcount >= 2 then
      for i := 2 to rowcount - 1 do
        Objects[0, i].Free;
end;

function nextword(var buf: string): string;
var
  p: integer;
begin
  p := pos(',', buf);
  if p = 0 then
    p := length(buf) + 1;
  Result := copy(buf, 1, p - 1);
  buf := copy(buf, p + 1, 999);
end;

procedure PulsVar(jdobs, magmax, magmin, jdini, period, rise: double;
  var actmag, prevmini, prevmaxi, nextmini, nextmaxi, next2mini: double);
var
  risep: double;
begin
  nextmaxi := jdini;
  if jdobs > jdini then
  begin
    repeat
      nextmaxi := nextmaxi + period;
    until nextmaxi > jdobs;
  end
  else
  begin
    repeat
      nextmaxi := nextmaxi - period;
    until nextmaxi < jdobs;
    nextmaxi := nextmaxi + period;
  end;
  risep := period * rise / 100;
  nextmini := nextmaxi - risep;
  prevmini := nextmini - period;
  prevmaxi := nextmaxi - period;
  next2mini := nextmini + period;
  if jdobs < nextmini then
    actmag := magmax + (jdobs - prevmaxi) * (magmin - magmax) / (period - risep)
  else
    actmag := magmin - (jdobs - nextmini) * (magmin - magmax) / risep;
end;

procedure EcliVar(jdobs, magmax, magmin, jdini, period, rise: double;
  var actmag, prevmini, prev2maxi, prevmaxi, nextmini, nextmaxi, next2maxi, next2mini: double);
var
  risep: double;
begin
  nextmini := jdini;
  if jdobs > jdini then
  begin
    repeat
      nextmini := nextmini + period;
    until nextmini > jdobs;
  end
  else
  begin
    repeat
      nextmini := nextmini - period;
    until nextmini < jdobs;
    nextmini := nextmini + period;
  end;
  risep := period * rise / 100 / 2;
  prevmini := nextmini - period;
  next2mini := nextmini + period;
  nextmaxi := nextmini + risep;
  prevmaxi := nextmini - risep;
  prev2maxi := prevmini + risep;
  next2maxi := next2mini - risep;
  if (jdobs < prev2maxi) then
    actmag := magmin - (jdobs - prevmini) * (magmin - magmax) / risep
  else if (jdobs < prevmaxi) then
    actmag := magmax
  else if (jdobs < nextmini) then
    actmag := magmax + (jdobs - prevmaxi) * (magmin - magmax) / risep
  else if (jdobs < nextmaxi) then
    actmag := magmin - (jdobs - nextmini) * (magmin - magmax) / risep
  else if (jdobs < next2maxi) then
    actmag := magmax
  else
    actmag := magmax + (jdobs - next2maxi) * (magmin - magmax) / risep;
end;

function datef(jdt: double): string;
var
  yy, mm, dd: integer;
  hm: double;
begin
  case varform.RadioGroup1.ItemIndex of
    0:
    begin
      djd(jdt + TZ / 24, yy, mm, dd, hm);
      Result := formatdatetime('yyyy-mm-dd hh:mm:ss', encodedate(yy, mm, dd) + hm / 24);
    end;
    1:
    begin
      str(jdt: 9: 4, Result);
    end;
    2:
    begin
      djd(jdt, yy, mm, dd, hm);
      str((hm / 24): 1: 4, Result);
      Result := formatdatetime('yyyymmdd', encodedate(yy, mm, dd)) + copy(Result, 2, 9);
    end;
    else
      Result := '';
  end;
end;

procedure Errmsg(m1, m2: string);
begin
  ShowMessage('Missing value for ' + m1 + '  ' + m2);
end;

procedure CalculVar;
var
  f: textfile;
  ww, buf, Name, vtype, design: string;
  yy, mm, dd, r, curvtype, p: integer;
  y1, m1, d1: word;
  magmax, magmin, jdini, period, rise, actmag, next2mini, nextmini, nextmaxi,
  next2maxi, prevmini, prevmaxi, prev2maxi, hm: double;
  aavsodesign, uncertain: boolean;
  varinfo: Tvarinfo;
begin
  if not FileExistsUTF8(planname) then
  begin
    ShowMessage('File not found : ' + planname);
    exit;
  end;
  FreeInfo(VarForm.Grid1);
  varform.Caption := 'Variables Star Observer, current file : ' + extractfilename(planname);
  VarForm.Grid1.RowCount := 2;
  VarForm.Grid1.Cells[0, 0] := 'Name';
  VarForm.Grid1.Cells[1, 0] := 'Design.';
  VarForm.Grid1.Cells[2, 0] := 'Type';
  VarForm.Grid1.Cells[3, 0] := 'Max.';
  VarForm.Grid1.Cells[4, 0] := 'Min.';
  VarForm.Grid1.Cells[5, 0] := 'Actual';
  VarForm.Grid1.Cells[6, 0] := 'Minima';
  VarForm.Grid1.Cells[7, 0] := 'Maxima';
  VarForm.Grid1.Cells[8, 0] := 'Minima';
  VarForm.Grid1.Cells[9, 0] := 'Maxima';
  VarForm.Grid1.Cells[10, 0] := 'Minima';
  aavsodesign := False;
  try
    r := 1;
    assignfile(f, SafeUTF8ToSys(planname));
    reset(f);
    //decodetime(varform.timepicker1.time,hh,mi,ss,mss);
    getdate(varform.DateEdit1.date, y1, m1, d1);
    yy := y1;
    mm := m1;
    dd := d1;
    hm := varform.timepicker1.time;
    jdact := jd(yy, mm, dd, hm) + (TZ / 24);
    djd(jdact, yy, mm, dd, hm);
    datim := IntToStr(yy) + '-' + IntToStr(mm) + '-' + IntToStr(dd) + ' ' + formatdatetime(
      'hh:mm', hm / 24) + ' UT';
    //datim:=formatdatetime('yyyy-mm-dd',varform.DateEdit1.date);
    //datim:=datim+'  '+formatdatetime('hh:mm',varform.timepicker1.time)+' UT';
    //yy:=y1 ; mm:=m1 ; dd:=d1;
    //hm:=hh+mi/60+ss/3600;
    //jdact:=jd(yy,mm,dd,hm);
    datact := datef(jdact);
    repeat
      uncertain := False;
      readln(f, buf);
      if trim(buf) = '' then
        continue;
      if buf[1] = ';' then
        continue;
      Name := nextword(buf);
      if Name = 'ENDOFLIST' then
        continue;
      Name := trim(words(Name, '', 1, 1) + ' ' + words(Name, '', 2, 1) + ' ' + words(
        Name, '', 3, 1) + ' ' + words(Name, '', 4, 99));
      vtype := trim(nextword(buf));
      curvtype := 0;
      ww := vtype;
      p := pos('+', ww);                 // keep only first type
      if p > 0 then
        ww := copy(ww, 1, p - 1);
      p := pos('/', ww);
      if p > 0 then
        ww := copy(ww, 1, p - 1);
      p := pos(':', ww);
      if p > 0 then
        ww := copy(ww, 1, p - 1);
      ww := trim(ww);
      if pos(' ' + ww + ' ', pulslist) > 0 then
        curvtype := 1;
      if pos(' ' + ww + ' ', rotlist) > 0 then
        curvtype := 1;
      if pos(' ' + ww + ' ', ecllist) > 0 then
        curvtype := 2;
      ww := trim(nextword(buf));
      if ww <> '' then
        magmax := strtofloat(ww)
      else
      begin
        magmax := 0;
        uncertain := True;
      end;
      ww := trim(nextword(buf));
      if ww <> '' then
        magmin := strtofloat(ww)
      else
      begin
        magmin := 16;
        uncertain := True;
      end;
      ww := trim(nextword(buf));
      if ww <> '' then
        jdini := strtofloat(ww)
      else
      begin
        curvtype := 0;
        jdini := jdact;
      end;
      ww := trim(nextword(buf));
      if ww <> '' then
        period := strtofloat(ww)
      else
      begin
        curvtype := 0;
        period := 100;
      end;
      ww := trim(nextword(buf));
      if ww <> '' then
        rise := strtofloat(ww)
      else
      begin
        if copy(vtype, 1, 1) = 'E' then
          rise := 5
        else
          rise := 50;
        uncertain := True;
      end;
      if (length(ww) = 3) and (pos('.', ww) = 0) then
        rise := rise / 10; // bizarerie du gcvs pour les EA
      if (vtype = 'RV') or (vtype = 'RVA') or (vtype = 'RVB') then
      begin  // minima for RV Tau
        jdini := jdini + period * rise / 100;                        // convert to maxima
      end;
      ww := trim(nextword(buf));
      if ww <> '' then
        design := ww
      else
        design := '';
      if magmax = magmin then
      begin
        magmin := magmin + 0.001;
        uncertain := True;
      end;
      next2maxi := 0;
      prev2maxi := 0;
      case curvtype of
        1: PulsVar(jdact, magmax, magmin, jdini, period, rise, actmag, prevmini,
            prevmaxi, nextmini, nextmaxi, next2mini);
        2: EcliVar(jdact, magmax, magmin, jdini, period, rise, actmag, prevmini,
            prev2maxi, prevmaxi, nextmini, nextmaxi, next2maxi, next2mini);
        else
        begin
          actmag := -9999;
          prevmini := 0;
          prevmaxi := 0;
          nextmini := 0;
          nextmaxi := 0;
          next2mini := 0;
        end;
      end;
      varform.Grid1.RowCount := r + 1;
      buf := trim(Name);
      varform.Grid1.Cells[0, r] := buf;
      buf := trim(design);
      if buf <> '' then
        aavsodesign := True;
      varform.Grid1.Cells[1, r] := buf;
      buf := trim(vtype);
      varform.Grid1.Cells[2, r] := buf;
      str(magmax: 5: 2, buf);
      varform.Grid1.Cells[3, r] := buf;
      str(magmin: 5: 2, buf);
      varform.Grid1.Cells[4, r] := buf;
      varinfo := Tvarinfo.Create;
      if actmag > -999 then
      begin
        str(actmag: 2: 0, buf);
        if uncertain then
          buf := buf + '?';
        varform.Grid1.Cells[5, r] := buf;
        varinfo.i[3] := actmag;
      end
      else
      begin
        varform.Grid1.Cells[5, r] := '-';
        varinfo.i[3] := magmin;
      end;
      if prevmini > 0 then
      begin
        varform.Grid1.Cells[6, r] := datef(prevmini);
        varinfo.i[4] := prevmini;
      end
      else
      begin
        varform.Grid1.Cells[6, r] := '-';
        varinfo.i[4] := jdact - period;
      end;
      if prev2maxi > 0 then
      begin
        varinfo.i[12] := prev2maxi;
      end
      else
      begin
        varinfo.i[12] := 0;
      end;
      if prevmaxi > 0 then
      begin
        varform.Grid1.Cells[7, r] := datef(prevmaxi);
        varinfo.i[5] := prevmaxi;
      end
      else
      begin
        varform.Grid1.Cells[7, r] := '-';
        varinfo.i[5] := jdact - period / 2;
      end;
      if nextmini > 0 then
      begin
        varform.Grid1.Cells[8, r] := datef(nextmini);
        varinfo.i[6] := nextmini;
      end
      else
      begin
        varform.Grid1.Cells[8, r] := '-';
        varinfo.i[6] := jdact;
      end;
      if nextmaxi > 0 then
      begin
        varform.Grid1.Cells[9, r] := datef(nextmaxi);
        varinfo.i[7] := nextmaxi;
      end
      else
      begin
        varform.Grid1.Cells[9, r] := '-';
        varinfo.i[7] := jdact + period / 2;
      end;
      if next2maxi > 0 then
      begin
        varinfo.i[13] := next2maxi;
      end
      else
      begin
        varinfo.i[13] := 0;
      end;
      if next2mini > 0 then
      begin
        varform.Grid1.Cells[10, r] := datef(next2mini);
        varinfo.i[8] := next2mini;
      end
      else
      begin
        varform.Grid1.Cells[10, r] := '-';
        varinfo.i[8] := jdact + period;
      end;
      varinfo.i[1] := magmax;
      varinfo.i[2] := magmin;
      varinfo.i[9] := period;
      varinfo.i[10] := rise;
      varinfo.i[11] := curvtype;
      varform.Grid1.Objects[0, r] := varinfo;
      Inc(r);
    until EOF(f);
    if aavsodesign then
      varform.Grid1.ColWidths[1] := 120
    else
      varform.Grid1.ColWidths[1] := 0;
  finally
    closefile(f);
  end;
end;

procedure TVarForm.BitBtn1Click(Sender: TObject);
begin
  CalculVar;
end;


procedure ReadParam;
var
  i: integer;
  buf: string;
begin
  i := 0;
  while i <= param.Count - 1 do
  begin
    if param[i] = '-c' then
    begin
      Inc(i);
      buf := systoutf8(param[i]);
      if fileexistsutf8(buf) then
        planname := buf;
    end
    else if pos('.var', param[i]) > 0 then
    begin
      buf := systoutf8(param[i]);
      if fileexistsutf8(buf) then
        planname := buf;
    end;
    Inc(i);
  end;
end;

procedure TVarForm.GetAppDir;
var
  buf: string;
{$ifdef darwin}
  i: integer;
{$endif}
{$ifdef mswindows}
  PIDL: PItemIDList;
  Folder: array[0..MAX_PATH] of char;
{$endif}
begin
{$ifdef darwin}
  appdir := getcurrentdir;
  if not DirectoryExists(slash(appdir) + slash('data') + slash('varobs')) then
  begin
    appdir := ExtractFilePath(ParamStr(0));
    i := pos('.app/', appdir);
    if i > 0 then
    begin
      appdir := ExtractFilePath(copy(appdir, 1, i));
    end;
  end;
{$else}
  appdir := getcurrentdir;
  GetDir(0, appdir);
{$endif}
  privatedir := DefaultPrivateDir;
  configfile := Defaultconfigfile;
{$ifdef unix}
  appdir := expandfilename(appdir);
  privatedir := expandfilename(PrivateDir);
  configfile := expandfilename(configfile);
{$endif}
{$ifdef mswindows}
  buf := systoutf8(appdir);
  buf := trim(buf);
  appdir := safeutf8tosys(buf);
  buf := '';
  SHGetSpecialFolderLocation(0, CSIDL_LOCAL_APPDATA, PIDL);
  SHGetPathFromIDList(PIDL, Folder);
  buf := WinCPToUTF8(Folder);
  buf := trim(buf);
  buf := safeutf8tosys(buf);
  if buf = '' then
  begin  // old windows version
    SHGetSpecialFolderLocation(0, CSIDL_APPDATA, PIDL);
    SHGetPathFromIDList(PIDL, Folder);
    buf := trim(WinCPToUTF8(Folder));
  end;
  privatedir := slash(buf) + privatedir;
  configfile := slash(privatedir) + configfile;
{$endif}
  skychart := slash(appdir) + DefaultSkychart;
  if not FileExists(skychart) then
    skychart := DefaultSkychart;
  lpvb := slash(appdir) + Defaultlpvb;
  if not FileExists(lpvb) then
    lpvb := Defaultlpvb;
  if not directoryexists(privatedir) then
    CreateDir(privatedir);
  if not directoryexists(privatedir) then
    forcedirectory(privatedir);
  if not directoryexists(privatedir) then
  begin
    MessageDlg('Unable to create ' + privatedir,
      mtError, [mbAbort], 0);
    Halt;
  end;
  if not directoryexists(slash(privatedir) + 'quicklook') then
    CreateDir(slash(privatedir) + 'quicklook');
  if not directoryexists(slash(privatedir) + 'afoevdata') then
    CreateDir(slash(privatedir) + 'afoevdata');

  if (not directoryexists(slash(appdir) + slash('data') + 'varobs')) then
  begin
    // try under the current directory
    buf := GetCurrentDir;
    if (directoryexists(slash(buf) + slash('data') + 'varobs')) then
      appdir := buf
    else
    begin
      // try under the program directory
      buf := ExtractFilePath(ParamStr(0));
      if (directoryexists(slash(buf) + slash('data') + 'varobs')) then
        appdir := buf
      else
      begin
        // try share directory under current location
        buf := ExpandFileName(slash(GetCurrentDir) + SharedDir);
        if (directoryexists(slash(buf) + slash('data') + 'varobs')) then
          appdir := buf
        else
        begin
          // try share directory at the same location as the program
          buf := ExpandFileName(slash(ExtractFilePath(ParamStr(0))) + SharedDir);
          if (directoryexists(slash(buf) + slash('data') + 'varobs')) then
            appdir := buf
          else
          begin
            MessageDlg('Could not found the application data directory.' +
              crlf + 'Please check the program installation.',
              mtError, [mbAbort], 0);
            Halt;
          end;
        end;
      end;
    end;
  end;

  ConstDir := slash(appdir) + slash('data') + slash('varobs');
end;

procedure TVarForm.ScaleMainForm;
begin
  UScaleDPI.UseScaling := True;
  {$ifdef SCALE_BY_DPI_ONLY}
  UScaleDPI.RunDPI := Screen.PixelsPerInch;
  {$else}
  UScaleDPI.SetScale(Canvas);
  {$endif}
  ScaleDPI(Self);
end;

procedure TVarForm.FormCreate(Sender: TObject);
begin
  lockdate := False;
  lockselect := False;
  started := False;
  param := TStringList.Create;
  GetAppDir;
  DefaultFormatSettings.DecimalSeparator := '.';
  DefaultFormatSettings.ThousandSeparator := ',';
  DefaultFormatSettings.DateSeparator := '-';
  DefaultFormatSettings.TimeSeparator := ':';
  DefaultFormatSettings.ShortdateFormat := 'yyyy-mm-dd';
  OpenFileCmd := DefaultOpenFileCMD;
  Grid1.ColWidths[0] := 60;
  Grid1.ColWidths[1] := 120;
  Grid1.ColWidths[2] := 45;
  Grid1.ColWidths[3] := 40;
  Grid1.ColWidths[4] := 40;
  Grid1.ColWidths[5] := 30;
  ScaleMainForm;
end;

procedure TVarForm.Exit1Click(Sender: TObject);
begin
  VarForm.Close;
end;

procedure TVarForm.Edit1Change(Sender: TObject);
var
  yy, mm, dd: integer;
  hm, jdt: double;
  buf1, buf: string;
begin
  if lockdate then
  begin
    lockdate := False;
    exit;
  end;
  if locktime then
  begin
    locktime := False;
    exit;
  end;
  try
    jdt := strtofloat(edit1.Text);
    djd(jdt + (TZ / 24), yy, mm, dd, hm);
    if (yy > 1800) and (yy < 3000) then
    begin
      edit1.color := clWindow;
      lockdate := True;
      locktime := True;
      DateEdit1.date := setdate(yy, mm, dd);
      lockdate := True;
      locktime := True;
      varform.timepicker1.time := hm / 24;
      djd(jdt, yy, mm, dd, hm);
      buf1 := format('%.4d%.2d%.2d', [yy, mm, dd]);
      //  str(frac(varform.timepicker1.time):1:4,buf);
      str((hm / 24): 1: 4, buf);
      lockdate := True;
      locktime := True;
      edit2.Text := buf1 + copy(buf, 2, 9);
      edit2.color := clWindow;
    end
    else
    begin
      edit1.color := clRed;
    end;
  except
    edit1.color := clRed;
  end;
  Application.ProcessMessages;
  lockdate := False;
  locktime := False;
end;

procedure TVarForm.Edit2Change(Sender: TObject);
var
  yy, mm, dd, p: integer;
  hm, jdt: double;
  buf: string;
begin
  if lockdate then
  begin
    lockdate := False;
    exit;
  end;
  if locktime then
  begin
    locktime := False;
    exit;
  end;
  try
    buf := trim(edit2.Text);
    p := pos('.', buf);
    if p = 0 then
      p := length(buf);
    if p < 5 then
    begin
      edit2.color := clRed;
      exit;
    end;
    yy := StrToInt(copy(buf, 1, p - 5));
    mm := StrToInt(copy(buf, p - 4, 2));
    dd := StrToInt(copy(buf, p - 2, 2));
    hm := strtofloat(copy(buf, p, 9)) * 24;
    if (yy > 1800) and (yy < 3000) then
    begin
      edit2.color := clWindow;
      str(jd(yy, mm, dd, hm): 9: 4, buf);
      lockdate := True;
      locktime := True;
      edit1.Text := buf;
      jdt := jd(yy, mm, dd, hm) + (TZ / 24);
      Djd(jdt, yy, mm, dd, hm);
      lockdate := True;
      locktime := True;
      DateEdit1.date := setdate(yy, mm, dd);
      lockdate := True;
      locktime := True;
      varform.timepicker1.time := hm / 24;
    end
    else
    begin
      edit2.color := clRed;
    end;
  except
    edit2.color := clRed;
  end;
  Application.ProcessMessages;
  lockdate := False;
  locktime := False;
end;

procedure TVarForm.Open1Click(Sender: TObject);
begin
  try
    opendialog1.FilterIndex := 2;
    opendialog1.InitialDir := privatedir;
    opendialog1.Filename := slash(privatedir) + 'obs.dat';
    if opendialog1.Execute then
    begin
      planname := opendialog1.FileName;
      varform.Caption := 'Variables Star Observer, current file : ' + planname;
      chdir(appdir);
      CalculVar;
    end;
  finally
    chdir(appdir);
  end;
end;

procedure TVarForm.MenuItem6Click(Sender: TObject);
begin
  try
    opendialog1.FilterIndex := 2;
    opendialog1.InitialDir := ConstDir;
    opendialog1.Filename := slash(ConstDir) + 'And.dat';
    opendialog1.DoFolderChange;
    if opendialog1.Execute then
    begin
      planname := opendialog1.FileName;
      varform.Caption := 'Variables Star Observer, current file : ' + planname;
      chdir(appdir);
      CalculVar;
    end;
  finally
    chdir(appdir);
  end;
end;

procedure TVarForm.FormShow(Sender: TObject);
var
  inifile: Tinifile;
  section, buf: string;
  i: integer;
begin
  planname := systoutf8(slash(privatedir) + 'aavsoeasy.dat');
  if not FileExistsUTF8(planname) then
  begin
    CopyFile(systoutf8(slash(appdir) + slash('data') + slash('sample') + 'aavsoeasy.dat'),
      planname, True);
  end;
  defqlurl := 'http://www.aavso.org/cgi-bin/newql.pl?name=$star&output=votable';
  defafoevurl := 'ftp://cdsarc.u-strasbg.fr/pub/afoev/';
  defaavsocharturl :='https://www.aavso.org/apps/vsp/chart/?fov=$fov&star=$star&orientation=visual&maglimit=$mag&resolution=150&north=$north&east=$east&type=chart';
  defwebobsurl := 'http://www.aavso.org/webobs';
  aavsourl := 'http://www.aavso.org';
  varobsurl := 'http://www.ap-i.net/skychart';
  pcobscaption := 'PCObs Data Entry';
  inifile := Tinifile.Create(configfile);
  section := 'Default';
  with inifile do
  begin
    planname := systoutf8(ReadString(section, 'planname', safeutf8tosys(planname)));
    Radiogroup1.ItemIndex := ReadInteger(section, 'dateformat', 0);
    OptForm.tz.Value := ReadInteger(section, 'tz', 0);
    OptForm.Radiogroup1.ItemIndex := ReadInteger(section, 'obstype', 0);
    OptForm.Radiogroup4.ItemIndex := ReadInteger(section, 'obsformat', 0);
    OptForm.Radiogroup5.ItemIndex := ReadInteger(section, 'obspgm', 0);
    //    OptForm.Radiogroup6.itemindex:=ReadInteger(section,'onlinedata',0); // AAVSO quicklook is no more available in votable format
    OptForm.Radiogroup6.ItemIndex := 1;
    // Force to use AFOEV ftp
    OptForm.FilenameEdit8.Text := ReadString(section, 'pcobs', 'C:\pcobs\pcobs.exe');
    pcobscaption := ReadString(section, 'pcobscaption', pcobscaption);
    OptForm.FilenameEdit0.Text :=
      ReadString(section, 'faavsovis', slash(privatedir) + 'aavsovis.txt');
    optform.RadioGroup7.ItemIndex := ReadInteger(section, 'fautoincrement', 1);
    OptForm.FilenameEdit1.Text :=
      ReadString(section, 'faavsosum', slash(privatedir) + 'aavsosum.txt');
    OptForm.FilenameEdit2.Text :=
      ReadString(section, 'fvsnet', slash(privatedir) + 'vsnet.txt');
    OptForm.DirectoryEdit3.Text := ReadString(section, 'dafoev', privatedir);
    OptForm.FilenameEdit4.Text :=
      ReadString(section, 'freeformat', slash(privatedir) + 'freeformat.txt');
    OptForm.CheckBox1.Checked := ReadBool(section, 'skycharteq', True);
    OptForm.CheckBox2.Checked := ReadBool(section, 'skychartzoom', True);
    OptForm.SpinEdit1.Value := ReadInteger(section, 'skychartzoomto', 15);
    OptForm.qlurl.Text := ReadString(section, 'quicklookurl', defqlurl);
    OptForm.afoevurl.Text := ReadString(section, 'afoevurl', defafoevurl);
    buf := ReadString(section, 'charturl', defaavsocharturl);
    if pos('charttitle', buf) > 0 then
      buf := defaavsocharturl;
    OptForm.charturl.Text := buf;
    buf := ReadString(section, 'webobsurl', defwebobsurl);
    if pos('/submit/', buf) > 0 then
      buf := defwebobsurl;
    OptForm.webobsurl.Text := buf;
    OptForm.FilenameEdit3.Text :=
      ReadString(section, 'fobs', slash(privatedir) + 'aavsovis.txt');
    OptForm.Edit1.Text := ReadString(section, 'namepos', '1');
    OptForm.Edit2.Text := ReadString(section, 'datepos', '2');
    OptForm.Edit3.Text := ReadString(section, 'magpos', '3');
    OptForm.Radiogroup2.ItemIndex := ReadInteger(section, 'datetype', 1);
    OptForm.Radiogroup3.ItemIndex := ReadInteger(section, 'formattype', 0);
    OptForm.Radiogroup8.ItemIndex := ReadInteger(section, 'aavsochart', 0);
    Optform.DirectoryEdit2.Text := ReadString(section, 'aavsochartdir', privatedir);
    DetailForm.Checkbox1.Checked := ReadBool(section, 'followcurve', True);
    DetailForm.Checkbox2.Checked := ReadBool(section, 'plotobs', True);
    DetailForm.Checkbox3.Checked := ReadBool(section, 'owncolor', True);
    DetailForm.Checkbox4.Checked := ReadBool(section, 'plotql', False);
    DetailForm.Checkbox5.Checked := ReadBool(section, 'plotgroup', False);
    OptForm.Edit4.Text := ReadString(section, 'observer', '');
    DetailForm.Shape1.Brush.Color := ReadInteger(section, 'color1', clBlack);
    DetailForm.Shape2.Brush.Color := ReadInteger(section, 'color2', clWhite);
    DetailForm.Shape3.Brush.Color := ReadInteger(section, 'color3', clRed);
    DetailForm.Shape4.Brush.Color := ReadInteger(section, 'color4', clAqua);
    DetailForm.Shape5.Brush.Color := ReadInteger(section, 'color5', clRed);
    DetailForm.Shape6.Brush.Color := ReadInteger(section, 'color6', clLime);
    DetailForm.Shape7.Brush.Color := ReadInteger(section, 'color7', clYellow);
    DetailForm.Shape8.Brush.Color := ReadInteger(section, 'color8', clBlue);
    DetailForm.Shape9.Brush.Color := ReadInteger(section, 'color9', clGreen);
    DetailForm.Shape10.Brush.Color := ReadInteger(section, 'color10', clTeal);
    Varform.top := ReadInteger(section, 'formtop', Varform.top);
    Varform.left := ReadInteger(section, 'formleft', Varform.left);
    Varform.Width := ReadInteger(section, 'formwidth', Varform.Width);
    Varform.Height := ReadInteger(section, 'formheight', Varform.Height);
    OpenFileCmd := ReadString(section, 'OpenFileCmd', OpenFileCmd);
  end;
  inifile.Free;
  detail1.savecheckbox1 := Detailform.checkbox1.Checked;
  param.Clear;
  if paramcount > 0 then
  begin
    for i := 1 to paramcount do
      param.Add(ParamStr(i));
    ReadParam;
  end;
  TZ := OptForm.tz.Value;
  timepicker1.time := now;
  lockdate := True;
  DateEdit1.date := now;
  started := True;
  DateEdit1change(Sender);
  CalculVar;
end;

procedure TVarForm.Grid1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  Acol, Arow: integer;
begin
  if not started then
    exit;
  Grid1.MouseToCell(X, Y, Acol, Arow);
  if (Arow = 0) and (Acol >= 0) then
  begin
    grid1.StrictSort := True;
    Grid1.SortColRow(True, Acol);
    Grid1.TopRow := 1;
  end;
  if (Arow <= 0) or (trim(Grid1.cells[0, arow]) = '') then
    exit;
  case button of
    mbLeft:
    begin
      CurrentRow := Arow;
      Detail1.current := ARow;
      FormPos(DetailForm, mouse.cursorpos.x, mouse.cursorpos.y);
      DetailForm.ShowModal;
    end;
    mbRight:
    begin
      CurrentRow := Arow;
      popupmenu1.popup(mouse.cursorpos.x, mouse.cursorpos.y);
    end;
  end;
end;

procedure TVarForm.Grid1SelectCell(Sender: TObject; aCol, aRow: integer;
  var CanSelect: boolean);
begin
  CurrentRow := Arow;
end;

procedure TVarForm.Setting1Click(Sender: TObject);
begin
  OptForm.opencmd.Text := OpenFileCmd;
  FormPos(OptForm, mouse.cursorpos.x, mouse.cursorpos.y);
  OptForm.showmodal;
  OpenFileCmd := OptForm.opencmd.Text;
  TZ := OptForm.tz.Value;
  chdir(appdir);
end;

procedure TVarForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  inifile: Tinifile;
  section: string;
begin
  inifile := Tinifile.Create(configfile);
  section := 'Default';
  with inifile do
  begin
    WriteString(section, 'planname', safeutf8tosys(planname));
    WriteInteger(section, 'dateformat', Radiogroup1.ItemIndex);
    WriteInteger(section, 'tz', OptForm.tz.Value);
    WriteInteger(section, 'obstype', OptForm.Radiogroup1.ItemIndex);
    WriteInteger(section, 'obsformat', OptForm.Radiogroup4.ItemIndex);
    WriteInteger(section, 'obspgm', OptForm.Radiogroup5.ItemIndex);
    WriteInteger(section, 'onlinedata', OptForm.Radiogroup6.ItemIndex);
    WriteString(section, 'pcobs', OptForm.FilenameEdit8.Text);
    WriteString(section, 'pcobscaption', pcobscaption);
    WriteString(section, 'faavsovis', OptForm.FilenameEdit0.Text);
    WriteInteger(section, 'fautoincrement', optform.RadioGroup7.ItemIndex);
    WriteString(section, 'faavsosum', OptForm.FilenameEdit1.Text);
    WriteString(section, 'fvsnet', OptForm.FilenameEdit2.Text);
    WriteString(section, 'dafoev', OptForm.DirectoryEdit3.Text);
    WriteString(section, 'freeformat', OptForm.FilenameEdit4.Text);
    WriteString(section, 'fobs', OptForm.FilenameEdit3.Text);
    WriteBool(section, 'skycharteq', OptForm.CheckBox1.Checked);
    WriteBool(section, 'skychartzoom', OptForm.CheckBox2.Checked);
    WriteInteger(section, 'skychartzoomto', OptForm.SpinEdit1.Value);
    WriteString(section, 'quicklookurl', OptForm.qlurl.Text);
    WriteString(section, 'afoevurl', OptForm.afoevurl.Text);
    WriteString(section, 'charturl', OptForm.charturl.Text);
    WriteString(section, 'webobsurl', OptForm.webobsurl.Text);
    WriteString(section, 'namepos', OptForm.Edit1.Text);
    WriteString(section, 'datepos', OptForm.Edit2.Text);
    WriteString(section, 'magpos', OptForm.Edit3.Text);
    WriteInteger(section, 'datetype', OptForm.Radiogroup2.ItemIndex);
    WriteInteger(section, 'formattype', OptForm.Radiogroup3.ItemIndex);
    WriteInteger(section, 'aavsochart', OptForm.Radiogroup8.ItemIndex);
    WriteString(section, 'aavsochartdir', Optform.DirectoryEdit2.Text);
    WriteBool(section, 'followcurve', Detail1.SaveCheckbox1);
    WriteBool(section, 'plotobs', DetailForm.Checkbox2.Checked);
    WriteBool(section, 'owncolor', DetailForm.Checkbox3.Checked);
    WriteBool(section, 'plotql', DetailForm.Checkbox4.Checked);
    WriteBool(section, 'plotgroup', DetailForm.Checkbox5.Checked);
    WriteString(section, 'observer', OptForm.Edit4.Text);
    WriteInteger(section, 'color1', DetailForm.Shape1.Brush.Color);
    WriteInteger(section, 'color2', DetailForm.Shape2.Brush.Color);
    WriteInteger(section, 'color3', DetailForm.Shape3.Brush.Color);
    WriteInteger(section, 'color4', DetailForm.Shape4.Brush.Color);
    WriteInteger(section, 'color5', DetailForm.Shape5.Brush.Color);
    WriteInteger(section, 'color6', DetailForm.Shape6.Brush.Color);
    WriteInteger(section, 'color7', DetailForm.Shape7.Brush.Color);
    WriteInteger(section, 'color8', DetailForm.Shape8.Brush.Color);
    WriteInteger(section, 'color9', DetailForm.Shape9.Brush.Color);
    WriteInteger(section, 'color10', DetailForm.Shape10.Brush.Color);
    WriteInteger(section, 'formtop', Varform.top);
    WriteInteger(section, 'formleft', Varform.left);
    WriteInteger(section, 'formwidth', Varform.Width);
    WriteInteger(section, 'formheight', Varform.Height);
    WriteString(section, 'OpenFileCmd', OpenFileCmd);
  end;
  inifile.Free;
  if tcpclient <> nil then
  begin
    SkychartCmd('QUIT');
    tcpclient.Disconnect;
  end;
end;

procedure PrtGrid(Grid: TStringGrid; PrtTitle, PrtText, PrtTextDate: string);
type
  TCols = array[0..20] of integer;
var
  Rapport, pw, ph, marg: integer;
  r, c: longint;
  cols: ^TCols;
  y: integer;
  MargeLeft, Margetop, MargeRight: integer;
  StrDate: string;
  TextDown: integer;

  procedure VerticalLines;
  var
    c: longint;
  begin
    with Printer.Canvas do
    begin
      for c := 0 to Grid.ColCount - 1 do
      begin
        MoveTo(Cols^[c], MargeTop + TextDown);
        LineTo(Cols^[c], y);
      end;
      MoveTo(MargeRight, MargeTop + TextDown);
      LineTo(MargeRight, y);
    end;
  end;

  procedure PrintRow(r: longint);
  var
    c: longint;
  begin
    with Printer.Canvas do
    begin
      for c := 0 to Grid.ColCount - 1 do
        TextOut(Cols^[c] + 10, y + 10, Grid.Cells[c, r]);
      Inc(y, TextDown);
      MoveTo(MargeLeft, y);
      LineTo(MargeRight, y);
    end;
  end;

  procedure Entete;
  var
    rr: longint;
  begin
    with Printer.Canvas do
    begin
      Font.Style := [fsBold];

      TextOut(MargeLeft, MargeTop, PrtText);
      TextOut(MargeRight - TextWidth(StrDate), MargeTop, StrDate);
      y := MargeTop + TextDown;

      Brush.Color := clSilver;
      FillRect(Classes.Rect(MargeLeft, y, MargeRight, y + TextDown * Grid.FixedRows));
      MoveTo(MargeLeft, y);
      LineTo(MargeRight, y);
      for rr := 0 to Grid.FixedRows - 1 do
        PrintRow(rr);
      Brush.Color := clWhite;

      Font.Style := [];
    end;
  end;

begin
  y := 0;
  GetMem(Cols, Grid.ColCount * SizeOf(integer));
  StrDate := PrtTextDate + DateToStr(Date);
  with Printer do
  begin
    Title := PrtTitle;
    if Orientation = poLandscape then
    begin
      marg := 50;
      pw := PageHeight;
      ph := PageWidth;
    end
    else
    begin
      marg := 25;
      pw := PageWidth;
      ph := PageHeight;
    end;
    MargeLeft := pw div marg;
    MargeTop := ph div marg;
    MargeRight := pw - MargeLeft;
    Rapport := (MargeRight) div Grid.GridWidth;
    BeginDoc;
    with Canvas do
    begin
      Font.Name := Grid.Font.Name;
      Font.Height := Grid.Font.Height * Rapport;
      if Font.Height = 0 then
        Font.Height := 11 * Rapport;
      Font.Color := clBlack;
      Pen.Color := clBlack;
      TextDown := TextHeight(StrDate) * 3 div 2;
    end;
    { calcul des Cols }
    Cols^[0] := MargeLeft;
    for c := 1 to Grid.ColCount - 1 do
    begin
      Cols^[c] := round(Cols^[c - 1] + Grid.ColWidths[c - 1] * Rapport);
    end;
    Entete;
    for r := Grid.FixedRows to Grid.RowCount - 1 do
    begin
      PrintRow(r);
      if y >= (ph - MargeTop) then
      begin
        VerticalLines;
        NewPage;
        Entete;
      end;
    end;
    VerticalLines;
    EndDoc;
  end;
  FreeMem(Cols, Grid.ColCount * SizeOf(integer));
end;

procedure TVarForm.Print1Click(Sender: TObject);
begin
  PrtGrid(Grid1, 'varObs', 'Variables stars ' + datim, '');
end;

procedure TVarForm.Printersetup1Click(Sender: TObject);
begin
  PrinterSetupDialog1.Execute;
end;

procedure TVarForm.DateEdit1Change(Sender: TObject);
var
  y1, m1, d1: word;
  hm: double;
  buf, buf1: string;
begin
  if lockdate then
  begin
    lockdate := False;
    exit;
  end;
  if locktime then
  begin
    locktime := False;
    exit;
  end;
  //getdate(DateEdit1.date,y1,m1,d1);
  //hm:=frac(timepicker1.time);
  //buf1:=format('%.4d%.2d%.2d',[y1,m1,d1]);
  //str(hm:1:4,buf);
  hm := frac(timepicker1.time) - TZ / 24;
  hm := hm + trunc(DateEdit1.date);
  getdate(trunc(hm), y1, m1, d1);
  buf1 := format('%.4d%.2d%.2d', [y1, m1, d1]);
  hm := frac(hm);
  str(hm: 1: 4, buf);
  lockdate := True;
  locktime := True;
  edit2.Text := buf1 + copy(buf, 2, 9);
  Application.ProcessMessages;
  str(jd(y1, m1, d1, hm * 24): 9: 4, buf);
  lockdate := True;
  locktime := True;
  edit1.Text := buf;
  edit1.color := clWindow;
  edit2.color := clWindow;
  Application.ProcessMessages;
  lockdate := False;
  locktime := False;
end;

procedure TVarForm.Editeph1Click(Sender: TObject);
begin
  ExecuteFile(SafeUTF8ToSys(planname));
end;

procedure TVarForm.Lightcurve1Click(Sender: TObject);
begin
  Detail1.current := CurrentRow;
  FormPos(DetailForm, mouse.cursorpos.x, mouse.cursorpos.y);
  DetailForm.ShowModal;
end;

procedure TVarForm.SkychartPurge;
var
  resp: string;
  timeo: TDateTime;
begin
  timeo := now + cmddelay;
  repeat
    resp := tcpclient.Sock.RecvBufferStr(1024, 0);
  until (resp = '') or (now > timeo);
  ;
end;

function TVarForm.SkychartCmd(cmd: string): boolean;
var
  resp: string;
  timeo: TDateTime;
begin
  SkychartPurge;
  timeo := now + cmddelay;
  repeat
    tcpclient.Sock.SendString(cmd + crlf);
    Application.ProcessMessages;
    resp := tcpclient.recvstring;
  until ((resp <> '') and (resp <> '.')) or (now > timeo);
  if pos('OK', resp) > 0 then
    Result := True
  else
    Result := False;
end;

procedure TVarForm.InitSkyChart;
var
  resp: string;
  timeo: TDateTime;
begin
  ExecNoWait(skychart + blank + skychartopt);
  if tcpclient = nil then
  begin
    tcpclient := TCDCclient.Create;
  end;
  tcpclient.Disconnect;
  tcpclient.TargetHost := '127.0.0.1';
  tcpclient.TargetPort := '3292';
  tcpclient.Timeout := 500;
  timeo := now + connectdelay;
  repeat
    tcpclient.Connect;
    Application.ProcessMessages;
    resp := tcpclient.recvstring;
  until ((resp <> '') and (resp <> '.')) or (now > timeo);
  if OptForm.CheckBox1.Checked then
    SkychartCmd('SETPROJ EQUAT');
  if OptForm.CheckBox2.Checked then
    SkychartCmd('SETFOV ' + trim(OptForm.SpinEdit1.Text));
end;

procedure TVarForm.DrawSkyChart;
begin
  if (tcpclient = nil) or (not SkychartCmd('LISTCHART')) then
    InitSkyChart;
  SkychartCmd('SEARCH "' + trim(Grid1.Cells[0, currentrow]) + '"');
end;

procedure TVarForm.ShowChart1Click(Sender: TObject);
begin
  DrawSkyChart;
end;


procedure RunPCObs;
{$ifdef mswindows}
var
  nom, id: string;
  pcobshnd: Thandle;
  ok: boolean;
  i: integer;
{$endif}
begin
{$ifdef mswindows}
  nom := trim(varform.Grid1.Cells[0, currentrow]);
  id := trim(varform.Grid1.Cells[1, currentrow]);
  if id = '' then
    clipboard.settextbuf(PChar(nom))
  else
    clipboard.settextbuf(PChar(id));
  pcobshnd := findwindow(nil, PChar(pcobscaption));
  ok := pcobshnd <> 0;
  if ok then
  begin
    SendMessage(pcobshnd, WM_SYSCOMMAND, SC_RESTORE, 0);
    SetForegroundWindow(pcobshnd);
  end
  else
  begin
    i := ExecuteFile(OptForm.FilenameEdit8.Text);
    chdir(appdir);
    if i <= 32 then
      ShowMessage('Error ' + IntToStr(i) +
        '. Please verify that PCObs program is installed at location : ' +
        OptForm.FilenameEdit8.Text);
  end;
{$else}
  ExecNoWait(OptForm.FilenameEdit8.Text);
{$endif}
end;

procedure TVarForm.Newobservation1Click(Sender: TObject);
begin
  case Optform.radiogroup5.ItemIndex of
    0:
    begin
      if trim(optform.Edit4.Text) = '' then
      begin
        ShowMessage('Set your observer initial using the Option menu first!');
        exit;
      end;
      ObsUnit.current := CurrentRow;
      if Obsform.Visible then
      begin
        ObsForm.Edit1.Text := varform.Grid1.Cells[0, CurrentRow];
        ObsForm.Edit3.Text := '';
        ObsForm.Edit6.Text := '';
        ObsForm.Edit9.Text := '';
        ObsForm.CheckBox2.Checked := False;
        ObsForm.BringToFront;
      end
      else
      begin
        FormPos(ObsForm, mouse.cursorpos.x, mouse.cursorpos.y);
        ObsForm.Show;
      end;
    end;
    1:
    begin
      RunPCObs;
    end;
    2:
    begin
      executefile(OptForm.webobsurl.Text);
    end;
  end;
end;

procedure TVarForm.Content1Click(Sender: TObject);
begin
  executefile(slash(appdir) + slash('doc') + slash('varobs') + 'varobs.html');
end;

procedure TVarForm.BitBtn3Click(Sender: TObject);
var
  i: integer;
begin
  i := grid1.cols[0].IndexOf(edit4.Text);
  grid1.TopRow := i;
end;

procedure TVarForm.About1Click(Sender: TObject);
begin
  splash := Tsplash.Create(application);
  splash.SplashTimer := False;
  splash.showmodal;
  splash.Free;
end;

procedure TVarForm.PrepareLPVBulletin1Click(Sender: TObject);
begin
  ExecNoWait(lpvb);
end;

procedure TVarForm.AAVSOwebpage1Click(Sender: TObject);
begin
  executefile(aavsourl);
end;

procedure TVarForm.MenuItem7Click(Sender: TObject);
begin
  executefile(varobsurl);
end;

procedure TVarForm.AAVSOChart1Click(Sender: TObject);
var
  i: integer;
  buf, id, chartlist: string;
  f: textfile;
begin
  if (OptForm.Radiogroup8.ItemIndex = 1) then
  begin // cdrom
    chartlist := '';
    chdir(appdir);
    assignfile(f, slash(appdir) + slash('data') + slash('varobs') + 'united.txt');
    reset(f);
    try
      repeat
        readln(f, buf);
        i := pos('#', buf);
        id := trim(copy(buf, 1, i - 1));
        if id = VarForm.Grid1.Cells[1, currentrow] then
        begin
          i := lastdelimiter('#', buf);
          chartlist := trim(copy(buf, i + 1, 9999));
          break;
        end;
      until EOF(f);
    finally
      closefile(f);
    end;
    chartform.chartlist := chartlist;
    chartform.chartdir := Optform.DirectoryEdit2.Text;
  end;
  chartform.starname := VarForm.Grid1.Cells[0, currentrow];
  chartform.chartsource := OptForm.Radiogroup8.ItemIndex;
  FormPos(chartform, mouse.cursorpos.x, mouse.cursorpos.y);
  chartform.ShowModal;
end;

end.
