unit UI.Aero.Core.CustomControl;

interface

uses
  SysUtils, Windows, Messages, Classes, Controls, Graphics,
  Themes, UxTheme, DwmApi, UI.Aero.Core.BaseControl, Forms,
  GDIPUTIL, GDIPOBJ, GDIPAPI, UI.Aero.Globals;

type
  TCustomAeroControl = class(TAeroBaseControl)
  Private
    Function CreateRenderBuffer(const DrawDC: hDC;var PaintDC: hDC): hPaintBuffer;
  Protected
    function GetRenderState: TRenderConfig; Virtual; Abstract;
    procedure RenderProcedure_Vista(const ACanvas: TCanvas); override;
    procedure RenderProcedure_XP(const ACanvas: TCanvas); override;
    procedure RenderProcedure_Classic(const ACanvas: TCanvas);
    procedure ClassicRender(const ACanvas: TCanvas); Virtual; Abstract;
    procedure ThemedRender(const PaintDC: hDC; const Surface: TGPGraphics; var RConfig: TRenderConfig); Virtual; Abstract;
    procedure PostRender(const Surface: TCanvas;const RConfig: TRenderConfig); Virtual; Abstract;
  Public
    Constructor Create(AOwner: TComponent); OverRide;
    Destructor Destroy; OverRide;
  end;

implementation

uses
  UI.Aero.Core.CustomControl.Animation;

{ TCustomAeroControl }

Constructor TCustomAeroControl.Create(AOwner: TComponent);
begin
 Inherited Create(AOwner);

end;

Destructor TCustomAeroControl.Destroy;
begin

 Inherited Destroy;
end;

function TCustomAeroControl.CreateRenderBuffer(const DrawDC: hDC; var PaintDC: hDC): hPaintBuffer;
var
 rcClient: TRect;
 Params: TBPPaintParams;
begin
 rcClient:= GetClientRect;
 ZeroMemory(@Params,SizeOf(TBPPaintParams));
 Params.cbSize:= SizeOf(TBPPaintParams);
 Params.dwFlags:= BPPF_ERASE;
 Result:= BeginBufferedPaint(DrawDC, rcClient, BPBF_COMPOSITED, @params, PaintDC);
 if Result = 0 then
  PaintDC:= DrawDC
 else
  begin
   DrawAeroParentBackground(PaintDC,rcClient);
  end;
end;

procedure TCustomAeroControl.RenderProcedure_Classic(const ACanvas: TCanvas);
begin
 CreateClassicBuffer;
 DrawClassicBG;
 ClassicRender(ClassicBuffer.Canvas);
 ACanvas.Draw(0,0,ClassicBuffer);
end;

procedure TCustomAeroControl.RenderProcedure_Vista(const ACanvas: TCanvas);
var
 RConfig: TRenderConfig;
 PaintDC: hDC;
 RenderBuffer: hPaintBuffer;
 GPSurface: TGPGraphics;
begin
 PaintDC:= ACanvas.Handle;
 RenderBuffer:= 0;
 GPSurface:= nil;
 RConfig:= [];
//
 if ThemeServices.ThemesEnabled then
  begin
   if IsCompositionActive then
    RConfig:= GetRenderState+[rsComposited]
   else
    RConfig:= GetRenderState;
   if (rsBuffer in RConfig) then
    RenderBuffer:= CreateRenderBuffer(ACanvas.Handle,PaintDC);
   if (rsGDIP in RConfig) then GPSurface:= TGPGraphics.Create(PaintDC);
   ThemedRender(PaintDC,GPSurface,RConfig);
   if Assigned(GPSurface) then GPSurface.Free;
   if (rsBuffer in RConfig) and (RenderBuffer <> 0) then
    EndBufferedPaint(RenderBuffer,True);
  end
 else
  RenderProcedure_Classic(ACanvas);
 if rsPostDraw in RConfig then
  PostRender(ACanvas,RConfig);
end;

procedure TCustomAeroControl.RenderProcedure_XP(const ACanvas: TCanvas);
var
 RConfig: TRenderConfig;
 PaintDC: hDC;
 GPSurface: TGPGraphics;
begin
 PaintDC:= ACanvas.Handle;
 GPSurface:= nil;
 RConfig:= [];
//
 if ThemeServices.ThemesEnabled then
  begin
   RConfig:= GetRenderState;
   if (rsGDIP in RConfig) then GPSurface:= TGPGraphics.Create(PaintDC);
   ThemedRender(PaintDC,GPSurface,RConfig);
   if Assigned(GPSurface) then GPSurface.Free; 
  end
 else
  RenderProcedure_Classic(ACanvas);
 if rsPostDraw in RConfig then
  PostRender(ACanvas,RConfig);
end;

end.
