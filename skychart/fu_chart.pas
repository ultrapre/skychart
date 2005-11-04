unit fu_chart;
{
Copyright (C) 2002 Patrick Chevalley

http://www.astrosurf.com/astropc
pch@freesurf.ch

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}
{
 Chart form for Linux CLX application
}

interface

uses Math,
  SysUtils, Types, Classes, QGraphics, QControls, QForms, QDialogs, Qt,
  QStdCtrls, QExtCtrls, QMenus, QTypes, QComCtrls, QPrinters, QActnList,
  fu_detail, cu_skychart, cu_indiclient, u_constant, u_util, u_projection;

const maxundo=10;

type
  Tstr1func = procedure(txt:string) of object;
  Tint2func = procedure(i1,i2:integer) of object;
  Tbtnfunc = procedure(i1,i2:integer;b1:boolean;sender:TObject) of object;
  Tshowinfo = procedure(txt:string; origin:string='';sendmsg:boolean=true; Sender: TObject=nil) of object;

  Tf_chart = class(TForm)
    RefreshTimer: TTimer;
    ActionList1: TActionList;
    zoomplus: TAction;
    zoomminus: TAction;
    MoveWest: TAction;
    MoveEast: TAction;
    MoveNorth: TAction;
    MoveSouth: TAction;
    MoveNorthWest: TAction;
    MoveNorthEast: TAction;
    MoveSouthEast: TAction;
    MoveSouthWest: TAction;
    PopupMenu1: TPopupMenu;
    zoomplus1: TMenuItem;
    zoomminus1: TMenuItem;
    Centre: TAction;
    Centre1: TMenuItem;
    Panel1: TPanel;
    Image1: TImage;
    zoomplusmove: TAction;
    zoomminusmove: TAction;
    Flipx: TAction;
    Flipy: TAction;
    GridEQ: TAction;
    Grid: TAction;
    rot_plus: TAction;
    rot_minus: TAction;
    Undo: TAction;
    Redo: TAction;
    identlabel: TLabel;
    switchstar: TAction;
    switchbackground: TAction;
    Telescope1: TMenuItem;
    Connect1: TMenuItem;
    Slew1: TMenuItem;
    Sync1: TMenuItem;
    NewFinderCircle1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    RemoveLastCircle1: TMenuItem;
    RemoveAllCircles1: TMenuItem;
    AbortSlew1: TMenuItem;
    N3: TMenuItem;
    TrackOn1: TMenuItem;
    TrackOff1: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ChartResize(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure zoomplusExecute(Sender: TObject);
    procedure zoomminusExecute(Sender: TObject);
    procedure MoveWestExecute(Sender: TObject);
    procedure MoveEastExecute(Sender: TObject);
    procedure MoveNorthExecute(Sender: TObject);
    procedure MoveSouthExecute(Sender: TObject);
    procedure MoveNorthWestExecute(Sender: TObject);
    procedure MoveNorthEastExecute(Sender: TObject);
    procedure MoveSouthWestExecute(Sender: TObject);
    procedure MoveSouthEastExecute(Sender: TObject);
    procedure CentreExecute(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure zoomplusmoveExecute(Sender: TObject);
    procedure zoomminusmoveExecute(Sender: TObject);
    procedure FlipxExecute(Sender: TObject);
    procedure FlipyExecute(Sender: TObject);
    procedure GridExecute(Sender: TObject);
    procedure GridEQExecute(Sender: TObject);
    procedure rot_minusExecute(Sender: TObject);
    procedure rot_plusExecute(Sender: TObject);
    procedure RedoExecute(Sender: TObject);
    procedure UndoExecute(Sender: TObject);
    procedure identlabelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Image1Click(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure switchstarExecute(Sender: TObject);
    procedure switchbackgroundExecute(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Connect1Click(Sender: TObject);
    procedure Slew1Click(Sender: TObject);
    procedure Sync1Click(Sender: TObject);
    procedure NewFinderCircle1Click(Sender: TObject);
    procedure RemoveLastCircle1Click(Sender: TObject);
    procedure RemoveAllCircles1Click(Sender: TObject);
    procedure AbortSlew1Click(Sender: TObject);
    procedure TrackOn1Click(Sender: TObject);
    procedure TrackOff1Click(Sender: TObject);
  private
    { Private declarations }
    FImageSetFocus: TnotifyEvent;
    FSetFocus: TnotifyEvent;
    FShowTopMessage: Tstr1func;
    FUpdateBtn: Tbtnfunc;
    FShowInfo : Tshowinfo;
    FShowCoord: Tstr1func;
    FListInfo: Tstr1func;
    FChartMove: TnotifyEvent;
    movefactor,zoomfactor: double;
    xcursor,ycursor,skipmove : integer;
    LockWheel,MovingCircle : boolean;
    FNightVision: Boolean;
    SaveColor: Starcolarray;
    SaveLabelColor: array[1..numlabtype] of Tcolor;
    procedure TelescopeCoordChange(Sender: TObject);
    procedure TelescopeStatusChange(Sender : Tobject; source: TIndiSource; status: TIndistatus);
    procedure TelescopeGetMessage(Sender : TObject; const msg : string);
    procedure SetNightVision(value:boolean);
  public
    { Public declarations }
    sc: Tskychart;
    indi1: TIndiClient;
    maximize,locked,LockTrackCursor,LockKeyboard,lastquick,lock_refresh: boolean;
    undolist : array[1..maxundo] of conf_skychart;
    lastundo,curundo,validundo,lastx,lasty,lastyzoom : integer;
    zoomstep,Xzoom1,Yzoom1,Xzoom2,Yzoom2,DXzoom,DYzoom,XZoomD1,YZoomD1,XZoomD2,YZoomD2,ZoomMove : integer;
    procedure Refresh;
    procedure AutoRefresh;
    procedure PrintChart(printlandscape:boolean; printcolor,printmethod,printresol:integer ;printcmd1,printcmd2,printpath:string);
    function  FormatDesc:string;
    procedure ShowIdentLabel;
    function  IdentXY(X, Y: Integer):boolean;
    procedure  IdentDetail(X, Y: Integer);
    function  ListXY(X, Y: Integer):boolean;
    function  LongLabel(txt:string):string;
    function  LongLabelObj(txt:string):string;
    function  LongLabelGreek(txt : string) : string;
    Function  LongLabelConst(txt : string) : string;
    procedure CKeyDown(var Key: Word; Shift: TShiftState);
    procedure CMouseWheel(Shift: TShiftState;WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    function cmd_SetCursorPosition(x,y:integer):string;
    function cmd_SetGridEQ(onoff:string):string;
    function cmd_SetGrid(onoff:string):string;
    function cmd_SetStarMode(i:integer):string;
    function cmd_SetNebMode(i:integer):string;
    function cmd_SetSkyMode(onoff:string):string;
    function cmd_SetProjection(proj:string):string;
    function cmd_SetFov(fov:string):string;
    function cmd_SetRa(param1:string):string;
    function cmd_SetDec(param1:string):string;
    function cmd_SetDate(dt:string):string;
    function cmd_SetObs(obs:string):string;
    function cmd_IdentCursor:string;
    function cmd_SaveImage(format,fn,quality:string):string;
    function ExecuteCmd(arg:Tstringlist):string;
    function SaveChartImage(format,fn : string; quality: integer=75):boolean;
    Procedure ZoomBox(action,x,y:integer);
    Procedure TrackCursor(X,Y : integer);
    Procedure ZoomCursor(yy : double);
    procedure SetField(field : double);
    procedure SetZenit(field : double; redraw:boolean=true);
    procedure SetAz(Az : double; redraw:boolean=true);
    procedure SetDate(y,m,d,h,n,s:integer);
    procedure SetJD(njd:double);
    function cmd_GetProjection:string;
    function cmd_GetSkyMode:string;
    function cmd_GetNebMode:string;
    function cmd_GetStarMode:string;
    function cmd_GetGrid:string;

    function cmd_GetGridEQ:string;

    function cmd_GetCursorPosition :string;

    function cmd_GetFov(format:string):string;
    function cmd_GetRA(format:string):string;
    function cmd_GetDEC(format:string):string;
    function cmd_GetDate:string;
    function cmd_GetObs:string;
    function cmd_SetTZ(tz:string):string;
    function cmd_GetTZ:string;
    procedure cmd_GoXY(xx,yy : string);
    function cmd_IdXY(xx,yy : string): string;
    procedure cmd_MoreStar;
    procedure cmd_LessStar;
    procedure cmd_MoreNeb;
    procedure cmd_LessNeb;
    function cmd_SetGridNum(onoff:string):string;
    function cmd_SetConstL(onoff:string):string;

    function cmd_SetConstB(onoff:string):string;

    function cmd_SwitchGridNum:string;
    function cmd_SwitchConstL:string;
    function cmd_SwitchConstB:string;

    procedure ChartActivate;
    property OnImageSetFocus: TNotifyEvent read FImageSetFocus write FImageSetFocus;
    property OnShowTopMessage: Tstr1func read FShowTopMessage write FShowTopMessage;
    property OnSetFocus: TNotifyEvent read FSetFocus write FSetFocus;
    property OnUpdateBtn: Tbtnfunc read FUpdateBtn write FUpdateBtn;
    property OnShowInfo: TShowinfo read FShowInfo write FShowInfo;
    property OnShowCoord: Tstr1func read FShowCoord write FShowCoord;
    property OnListInfo: Tstr1func read FListInfo write FListInfo;
    property OnChartMove: TnotifyEvent read FChartMove write FChartMove;
    property NightVision: Boolean read FNightVision write SetNightVision;
  end;


implementation

{$R *.xfm}

uses QClipbrd;

// include all cross-platform common code.
// you can temporarily copy the file content here
// to use the IDE facilities

{$include i_chart.pas}


// end of common code



// Specific Linux CLX code:


procedure Tf_chart.FormMouseWheel(Sender: TObject; Shift: TShiftState;

  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
// why two event for each mouse turn ?
if lockwheel then begin
   lockwheel:=false;
end else begin
   lockwheel:=true;
   CMouseWheel(Shift,WheelDelta,MousePos,Handled);
end;
end;

function Tf_chart.SaveChartImage(format,fn : string; quality : integer=75):boolean;
var
 fnw: WideString;
begin
 if fn='' then fn:='cdc.png';
 if format='' then format:='PNG';
 if format='PNG' then begin
    fnw:=changefileext(fn,'.png');
    result:=QPixMap_save (Image1.Picture.Bitmap.Handle,@fnw,PChar('PNG'));
    end
 else if format='JPEG' then begin
    fnw:=changefileext(fn,'.jpg');
    result:=QPixMap_save (Image1.Picture.Bitmap.Handle,@fnw,PChar('JPEG'), quality);
    end
 else if format='BMP' then begin
    fnw:=changefileext(fn,'.bmp');
    result:=QPixMap_save (Image1.Picture.Bitmap.Handle,@fnw,PChar('BMP'));
    end
 else result:=false;
end;


// End of Linux specific CLX code

end.


