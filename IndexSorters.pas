{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Index sorters

    Classes designed to sort lists by using only list indices.

    The list must provide compare and exchange functions, both accepting two
    indices, and also lowest and highest item index.

    Sorter then uses provided compare function to compare two items and, when
    necessary, exchanges these two items using provided exchange function.

    The compare function should return negative value when first item is
    larger (should be higher) than second item, zero when the two items are equal
    and positive value when first item is smaller (is in correct order in
    relation to the second item).

    Following sorting algorithms are currently implemented:

        - bubble sort
        - quick sort (could use some testing and optimizations)
        - bogo sort (only for fun and tests)

  ©František Milt 2018-10-20

  Version 1.0

  Dependencies:
    AuxTypes   - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses - github.com/ncs-sniper/Lib.AuxClasses

===============================================================================}
unit IndexSorters;

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

interface

uses
  AuxClasses;

{===============================================================================
--------------------------------------------------------------------------------
                                  TIndexSorter
--------------------------------------------------------------------------------
===============================================================================}

type
  TCompareMethod = Function(Index1,Index2: Integer): Integer of object;
  TCompareFunction = Function(Context: Pointer; Index1,Index2: Integer): Integer;

  TExchangeMethod = procedure(Index1,Index2: Integer) of object;
  TExchangeFunction = procedure(Context: Pointer; Index1,Index2: Integer) of object;

{===============================================================================
    TIndexSorter - class declaration
===============================================================================}
  TIndexSorter = class(TCustomObject)
  protected
    fReversed:          Boolean;
    fContext:           Pointer;
    fLowIndex:          Integer;
    fHighIndex:         Integer;
    fReversedCompare:   Boolean;
    fCompareMethod:     TCompareMethod;
    fCompareFunction:   TCompareFunction;
    fExchangeMethod:    TExchangeMethod;
    fExchangeFunction:  TExchangeFunction;
    fCompareCoef:       Integer;
    // some statistics
    fCompareCount:      Integer;
    fExchangeCount:     Integer;
    Function CompareItems(Index1,Index2: Integer): Integer; virtual;
    procedure ExchangeItems(Index1,Index2: Integer); virtual;
    procedure InitCompareCoef; virtual;
    procedure InitStatistics; virtual;
    procedure Execute; virtual; abstract;
  public
    constructor Create; overload;
    constructor Create(CompareMethod: TCompareMethod; ExchangeMethod: TExchangeMethod); overload;
    constructor Create(Context: Pointer; CompareFunction: TCompareFunction; ExchangeFunction: TExchangeFunction); overload;
    procedure Initialize(CompareMethod: TCompareMethod; ExchangeMethod: TExchangeMethod); overload; virtual;
    procedure Initialize(Context: Pointer; CompareFunction: TCompareFunction; ExchangeFunction: TExchangeFunction); overload; virtual;
    Function Sorted(LowIndex, HighIndex: Integer): Boolean; overload; virtual;
    Function Sorted: Boolean; overload; virtual;
    procedure Sort(LowIndex, HighIndex: Integer); overload; virtual;
    procedure Sort; overload; virtual;
    property Reversed: Boolean read fReversed write fReversed;
    property Context: Pointer read fContext write fContext;
    property LowIndex: Integer read fLowIndex write fLowIndex;
    property HighIndex: Integer read fHighIndex write fHighIndex;
    property ReversedCompare: Boolean read fReversedCompare write fReversedCompare;
    property CompareMethod: TCompareMethod read fCompareMethod write fCompareMethod;
    property CompareFunction: TCompareFunction read fCompareFunction write fCompareFunction;
    property ExchangeMethod: TExchangeMethod read fExchangeMethod write fExchangeMethod;
    property ExchangeFunction: TExchangeFunction read fExchangeFunction write fExchangeFunction;
    property CompareCount: Integer read fCompareCount;
    property ExchangeCount: Integer read fExchangeCount;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                               TIndexBubbleSorter
--------------------------------------------------------------------------------
===============================================================================} 
{===============================================================================
    TIndexBubbleSorter - class declaration
===============================================================================}

  TIndexBubbleSorter = class(TIndexSorter)
  protected
    procedure Execute; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                TIndexQuickSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexQuickSorter - class declaration
===============================================================================}

  TIndexQuickSorter = class(TIndexSorter)
  protected
    procedure Execute; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                TIndexBogoSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexBogoSorter - class declaration
===============================================================================}

  // only for fun, do not use, seriously...
  TIndexBogoSorter = class(TIndexSorter)
  protected
    procedure Execute; override;
  end;

implementation

{===============================================================================
--------------------------------------------------------------------------------
                                  TIndexSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexSorter - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIndexSorter - protected methods
-------------------------------------------------------------------------------}

Function TIndexSorter.CompareItems(Index1,Index2: Integer): Integer;
begin
Inc(fCompareCount);
If Assigned(fCompareMethod) then
  Result := fCompareMethod(Index1,Index2) * fCompareCoef
else If Assigned(fCompareFunction) then
  Result := fCompareFunction(fContext,Index1,Index2) * fCompareCoef
else
  Result := 0;
end;

//------------------------------------------------------------------------------

procedure TIndexSorter.ExchangeItems(Index1,Index2: Integer);
begin
Inc(fExchangeCount);
If Assigned(fExchangeMethod) then
  fExchangeMethod(Index1,Index2)
else If Assigned(fExchangeFunction) then
  fExchangeFunction(fContext,Index1,Index2);
end;

//------------------------------------------------------------------------------

procedure TIndexSorter.InitCompareCoef;
begin
If fReversed xor fReversedCompare then
  fCompareCoef := -1
else
  fCompareCoef := 1;
end;

//------------------------------------------------------------------------------

procedure TIndexSorter.InitStatistics;
begin
fCompareCount := 0;
fExchangeCount := 0;
end;

{-------------------------------------------------------------------------------
    TIndexSorter - public methods
-------------------------------------------------------------------------------}

constructor TIndexSorter.Create;
begin
inherited Create;
fReversed := False;
fContext := nil;
fLowIndex := 0;
fHighIndex := -1;
fCompareMethod := nil;
fCompareFunction := nil;
fExchangeMethod := nil;
fExchangeFunction := nil;
fCompareCoef := 1;
InitStatistics;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIndexSorter.Create(CompareMethod: TCompareMethod; ExchangeMethod: TExchangeMethod);
begin
Create;
Initialize(CompareMethod,ExchangeMethod);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIndexSorter.Create(Context: Pointer; CompareFunction: TCompareFunction; ExchangeFunction: TExchangeFunction);
begin
Create;
Initialize(Context,CompareFunction,ExchangeFunction);
end;

//------------------------------------------------------------------------------

procedure TIndexSorter.Initialize(CompareMethod: TCompareMethod; ExchangeMethod: TExchangeMethod);
begin
fCompareMethod := CompareMethod;
fExchangeMethod := ExchangeMethod;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIndexSorter.Initialize(Context: Pointer; CompareFunction: TCompareFunction; ExchangeFunction: TExchangeFunction);
begin
fContext := Context;
fCompareFunction := CompareFunction;
fExchangeFunction := ExchangeFunction;
end;

//------------------------------------------------------------------------------

Function TIndexSorter.Sorted(LowIndex, HighIndex: Integer): Boolean;
begin
fLowIndex := LowIndex;
fHighIndex := HighIndex;
Result := Self.Sorted;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TIndexSorter.Sorted: Boolean;
var
  i:  Integer;
begin
Result := True;
InitCompareCoef;
For i := fLowIndex to Pred(fHighIndex) do
  If CompareItems(i,i + 1) < 0 then
    begin
      Result := False;
      Break{For i};
    end;
end;

//------------------------------------------------------------------------------

procedure TIndexSorter.Sort(LowIndex, HighIndex: Integer);
begin
fLowIndex := LowIndex;
fHighIndex := HighIndex;
Sort;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIndexSorter.Sort;
begin
InitStatistics;
InitCompareCoef;
Execute;
end;


{===============================================================================
--------------------------------------------------------------------------------
                               TIndexBubbleSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexBubbleSorter - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIndexBubbleSorter - protected methods
-------------------------------------------------------------------------------}

procedure TIndexBubbleSorter.Execute;
var
  i,j:      Integer;
  ExchCntr: Integer;
begin
If fHighIndex > fLowIndex then
  For i := fHighIndex downto fLowIndex do
    begin
      ExchCntr := 0;
      For j := fLowIndex to Pred(i) do
        If CompareItems(j,j + 1) < 0 then
          begin
            ExchangeItems(j,j + 1);
            Inc(ExchCntr);
          end;
      If ExchCntr <= 0 then
        Break{For i};
    end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                TIndexQuickSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexQuickSorter - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIndexQuickSorter - protected methods
-------------------------------------------------------------------------------}

procedure TIndexQuickSorter.Execute;

  procedure QuickSort(Left,Right: Integer);
  var
    PivotIdx,LowIdx,HighIdx: Integer;
  begin
    repeat
      LowIdx := Left;
      HighIdx := Right;
      PivotIdx := (Left + Right) shr 1;
      repeat
        while CompareItems(PivotIdx,LowIdx) < 0 do
          Inc(LowIdx);
        while CompareItems(PivotIdx,HighIdx) > 0 do
          Dec(HighIdx);
        If LowIdx <= HighIdx then
          begin
            ExchangeItems(LowIdx,HighIdx);
            If PivotIdx = LowIdx then
              PivotIdx := HighIdx
            else If PivotIdx = HighIdx then
              PivotIdx := LowIdx;
            Inc(LowIdx);
            Dec(HighIdx);  
          end;
      until LowIdx > HighIdx;
      If Left < HighIdx then
        QuickSort(Left,HighIdx);
      Left := LowIdx;
    until LowIdx >= Right;
  end;

begin
If fHighIndex > fLowIndex then
  QuickSort(fLowIndex,fHighIndex);
end;


{===============================================================================
--------------------------------------------------------------------------------
                                TIndexBogoSorter
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIndexBogoSorter - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIndexBogoSorter - protected methods
-------------------------------------------------------------------------------}

procedure TIndexBogoSorter.Execute;
var
  i:  Integer;
begin
If fHighIndex > fLowIndex then
  begin
    Randomize;
    while not Sorted do
      For i := fLowIndex to Pred(fHighIndex) do
        If Random(2) <> 0 then
          ExchangeItems(i,i + 1);
  end;
end;

end.
