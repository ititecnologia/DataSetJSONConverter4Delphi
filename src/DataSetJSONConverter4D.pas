unit DataSetJSONConverter4D;

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  Data.DB,
  Data.SqlTimSt,
  Data.FmtBcd;

type

  EDataSetJSONConverterException = class(Exception);

  TDataSetFieldType = (dsfUnknown, dsfJSONObject, dsfJSONArray);

  IDataSetConverter = interface
    ['{8D995E50-A1DC-4426-A603-762E1387E691}']
    function Source(const pDataSet: TDataSet): IDataSetConverter; overload;
    function Source(const pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;
  end;

  IJSONConverter = interface
    ['{1B020937-438E-483F-ACB1-44B8B2707500}']
    function Source(const pJSON: TJSONObject): IJSONConverter; overload;
    function Source(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function Source(const pJSON: TJSONArray): IJSONConverter; overload;
    function Source(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;

    procedure ToDataSet(const pDataSet: TDataSet);
  end;

  IConverter = interface
    ['{52A3BE1E-5116-4A9A-A7B6-3AF0FCEB1D8E}']
    function DataSet(): IDataSetConverter; overload;
    function DataSet(const pDataSet: TDataSet): IDataSetConverter; overload;
    function DataSet(const pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function JSON(): IJSONConverter; overload;
    function JSON(const pJSON: TJSONObject): IJSONConverter; overload;
    function JSON(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function JSON(const pJSON: TJSONArray): IJSONConverter; overload;
    function JSON(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;
  end;

function Converter(): IConverter;

function DateTimeToISOTimestamp(const pDateTime: TDateTime): string;
function DateToISODate(const pDate: TDateTime): string;
function TimeToISOTime(const pTime: TTime): string;

function ISOTimestampToDateTime(const pDateTime: string): TDateTime;
function ISODateToDate(const pDate: string): TDate;
function ISOTimeToTime(const pTime: string): TTime;

function NewDataSetField(const pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer = 0; const pOrigin: string = ''): TField;

implementation

type

  TDataSetConverter = class(TInterfacedObject, IDataSetConverter)
  private
    FSrcDataSet: TDataSet;
    FOwnsDataSet: Boolean;
    function DataSetToJSONObject(const pDataSet: TDataSet): TJSONObject;
    function DataSetToJSONArray(const pDataSet: TDataSet): TJSONArray;
    function GetDataSet(): TDataSet;
  public
    constructor Create();
    destructor Destroy(); override;

    function Source(const pDataSet: TDataSet): IDataSetConverter; overload;
    function Source(const pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function AsJSONObject(): TJSONObject;
    function AsJSONArray(): TJSONArray;
  end;

  TJSONConverter = class(TInterfacedObject, IJSONConverter)
  private
    FSrcJSONObject: TJSONObject;
    FSrcJSONArray: TJSONArray;
    FOwnsJSON: Boolean;
    procedure JSONObjectToDataSet(const pJSON: TJSONObject; const pDataSet: TDataSet);
    procedure JSONArrayToDataSet(const pJSON: TJSONArray; const pDataSet: TDataSet);
  public
    constructor Create();
    destructor Destroy(); override;

    function Source(const pJSON: TJSONObject): IJSONConverter; overload;
    function Source(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function Source(const pJSON: TJSONArray): IJSONConverter; overload;
    function Source(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;

    procedure ToDataSet(const pDataSet: TDataSet);
  end;

  TConverter = class(TInterfacedObject, IConverter)
  public
    function DataSet(): IDataSetConverter; overload;
    function DataSet(const pDataSet: TDataSet): IDataSetConverter; overload;
    function DataSet(const pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter; overload;

    function JSON(): IJSONConverter; overload;
    function JSON(const pJSON: TJSONObject): IJSONConverter; overload;
    function JSON(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter; overload;

    function JSON(const pJSON: TJSONArray): IJSONConverter; overload;
    function JSON(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter; overload;
  end;

function Converter(): IConverter;
begin
  Result := TConverter.Create;
end;

function GetDataSetFieldType(const pDataSetField: TDataSetField): TDataSetFieldType;
const
  cDescDataSetFieldType: array [TDataSetFieldType] of string = ('Unknown', 'JSONObject', 'JSONArray');
var
  vIndice: Integer;
  vOrigin: string;
begin
  Result := dsfUnknown;
  vOrigin := Trim(pDataSetField.Origin);
  for vIndice := Ord(Low(TDataSetFieldType)) to Ord(High(TDataSetFieldType)) do
    if (LowerCase(cDescDataSetFieldType[TDataSetFieldType(vIndice)]) = LowerCase(vOrigin)) then
      Exit(TDataSetFieldType(vIndice));
end;

function DateTimeToISOTimestamp(const pDateTime: TDateTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', pDateTime, vFS);
end;

function DateToISODate(const pDate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', pDate);
end;

function TimeToISOTime(const pTime: TTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', pTime, vFS);
end;

function ISOTimestampToDateTime(const pDateTime: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(pDateTime, 1, 4)), StrToInt(Copy(pDateTime, 6, 2)), StrToInt(Copy(pDateTime, 9, 2)),
    StrToInt(Copy(pDateTime, 12, 2)), StrToInt(Copy(pDateTime, 15, 2)), StrToInt(Copy(pDateTime, 18, 2)), 0);
end;

function ISODateToDate(const pDate: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(pDate, 1, 4)), StrToInt(Copy(pDate, 6, 2)), StrToInt(Copy(pDate, 9, 2)));
end;

function ISOTimeToTime(const pTime: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(pTime, 1, 2)), StrToInt(Copy(pTime, 4, 2)), StrToInt(Copy(pTime, 7, 2)), 0);
end;

function NewDataSetField(const pDataSet: TDataSet; const pFieldType: TFieldType;
  const pFieldName: string; pSize: Integer = 0; const pOrigin: string = ''): TField;
begin
  Result := DefaultFieldClasses[pFieldType].Create(pDataSet);
  Result.FieldName := pFieldName;

  if Result.FieldName = '' then
    Result.FieldName := 'Field' + IntToStr(pDataSet.FieldCount + 1);

  Result.FieldKind := fkData;
  Result.DataSet := pDataSet;
  Result.Name := pDataSet.Name + Result.FieldName;
  Result.Size := pSize;
  Result.Origin := pOrigin;

  if (pFieldType = ftString) and (pSize <= 0) then
    raise Exception.CreateFmt('Size not defined "%s".', [pFieldName]);
end;

{ TDataSetMarshal }

function TDataSetConverter.AsJSONArray: TJSONArray;
begin
  Result := DataSetToJSONArray(GetDataSet());
end;

function TDataSetConverter.AsJSONObject: TJSONObject;
begin
  Result := DataSetToJSONObject(GetDataSet());
end;

constructor TDataSetConverter.Create;
begin
  FSrcDataSet := nil;
  FOwnsDataSet := False;
end;

function TDataSetConverter.DataSetToJSONArray(const pDataSet: TDataSet): TJSONArray;
var
  vBookMark: TBookmark;
begin
  Result := nil;
  if (pDataSet <> nil) and (not pDataSet.IsEmpty) then
  begin
    try
      Result := TJSONArray.Create;
      vBookMark := pDataSet.Bookmark;
      pDataSet.First;
      while not pDataSet.Eof do
      begin
        Result.AddElement(DataSetToJSONObject(pDataSet));
        pDataSet.Next;
      end;
    finally
      if pDataSet.BookmarkValid(vBookMark) then
        pDataSet.GotoBookmark(vBookMark);
      pDataSet.FreeBookmark(vBookMark);
    end;
  end;
end;

function TDataSetConverter.DataSetToJSONObject(const pDataSet: TDataSet): TJSONObject;
var
  vI: Integer;
  vKey: string;
  vTs: TSQLTimeStamp;
  vNestedDataSet: TDataSet;
  vTypeDataSetField: TDataSetFieldType;
begin
  Result := nil;
  if (pDataSet <> nil) and (not pDataSet.IsEmpty) then
  begin
    Result := TJSONObject.Create;
    for vI := 0 to Pred(pDataSet.FieldCount) do
    begin
      vKey := pDataSet.Fields[vI].FieldName;
      case pDataSet.Fields[vI].DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsInteger));
        TFieldType.ftLargeint:
          begin
            Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsLargeInt));
          end;
        TFieldType.ftSingle, TFieldType.ftFloat:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsFloat));
        ftString, ftWideString, ftMemo:
          Result.AddPair(vKey, pDataSet.Fields[vI].AsWideString);
        TFieldType.ftDate:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, DateToISODate(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDateTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, DateTimeToISOTimestamp(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              vTs := pDataSet.Fields[vI].AsSQLTimeStamp;
              Result.AddPair(vKey, SQLTimeStampToStr('hh:nn:ss', vTs));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftCurrency:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, FormatCurr('0.00##', pDataSet.Fields[vI].AsCurrency));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftFMTBcd:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, TJSONNumber.Create(BcdToDouble(pDataSet.Fields[vI].AsBcd)));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSetField := GetDataSetFieldType(TDataSetField(pDataSet.Fields[vI]));
            vNestedDataSet := TDataSetField(pDataSet.Fields[vI]).NestedDataSet;
            case vTypeDataSetField of
              dsfJSONObject:
                Result.AddPair(vKey, DataSetToJSONObject(vNestedDataSet));
              dsfJSONArray:
                Result.AddPair(vKey, DataSetToJSONArray(vNestedDataSet));
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vKey);
      end;
    end;
  end;
end;

destructor TDataSetConverter.Destroy;
begin
  if FOwnsDataSet then
    if (FSrcDataSet <> nil) then
      FreeAndNil(FSrcDataSet);
  inherited Destroy();
end;

function TDataSetConverter.GetDataSet: TDataSet;
begin
  if (FSrcDataSet = nil) then
    raise EDataSetJSONConverterException.Create('DataSet Uninformed!');
  Result := FSrcDataSet;
end;

function TDataSetConverter.Source(const pDataSet: TDataSet): IDataSetConverter;
begin
  FSrcDataSet := pDataSet;
  Result := Self;
end;

function TDataSetConverter.Source(const pDataSet: TDataSet;
  const pOwnsDataSet: Boolean): IDataSetConverter;
begin
  FOwnsDataSet := pOwnsDataSet;
  Result := Source(pDataSet);
end;

{ TJSONMarshal }

constructor TJSONConverter.Create;
begin
  FSrcJSONObject := nil;
  FSrcJSONArray := nil;
  FOwnsJSON := False;
end;

destructor TJSONConverter.Destroy;
begin
  if FOwnsJSON then
  begin
    if (FSrcJSONObject <> nil) then
      FreeAndNil(FSrcJSONObject);
    if (FSrcJSONArray <> nil) then
      FreeAndNil(FSrcJSONArray);
  end;
  inherited Destroy();
end;

procedure TJSONConverter.JSONArrayToDataSet(const pJSON: TJSONArray; const pDataSet: TDataSet);
var
  vJv: TJSONValue;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    for vJv in pJSON do
      if (vJv is TJSONArray) then
        JSONArrayToDataSet(vJv as TJSONArray, pDataSet)
      else
        JSONObjectToDataSet(vJv as TJSONObject, pDataSet)
  end;
end;

procedure TJSONConverter.JSONObjectToDataSet(const pJSON: TJSONObject; const pDataSet: TDataSet);
var
  vField: TField;
  vJv: TJSONValue;
  vTypeDataSet: TDataSetFieldType;
  vNestedDataSet: TDataSet;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    vJv := nil;
    pDataSet.Append;
    for vField in pDataSet.Fields do
    begin
      if Assigned(pJSON.Get(vField.FieldName)) then
        vJv := pJSON.Get(vField.FieldName).JsonValue
      else
        Continue;
      case vField.DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          begin
            vField.AsInteger := StrToIntDef(vJv.Value, 0);
          end;
        TFieldType.ftLargeint:
          begin
            vField.AsLargeInt := StrToInt64Def(vJv.Value, 0);
          end;
        TFieldType.ftSingle, TFieldType.ftFloat, TFieldType.ftCurrency, TFieldType.ftFMTBcd:
          begin
            vField.AsFloat := (vJv as TJSONNumber).AsDouble;
          end;
        ftString, ftWideString, ftMemo:
          begin
            vField.AsString := vJv.Value;
          end;
        TFieldType.ftDate:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISODateToDate(vJv.Value);
          end;
        TFieldType.ftDateTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOTimestampToDateTime(vJv.Value);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := ISOTimeToTime(vJv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSet := GetDataSetFieldType(TDataSetField(vField));
            vNestedDataSet := TDataSetField(vField).NestedDataSet;
            case vTypeDataSet of
              dsfJSONObject:
                JSONObjectToDataSet(vJv as TJSONObject, vNestedDataSet);
              dsfJSONArray:
                JSONArrayToDataSet(vJv as TJSONArray, vNestedDataSet);
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vField.FieldName);
      end;
    end;
    pDataSet.Post;
  end;
end;

function TJSONConverter.Source(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter;
begin
  FOwnsJSON := pOwnsJSON;
  Result := Source(pJSON);
end;

function TJSONConverter.Source(const pJSON: TJSONObject): IJSONConverter;
begin
  FSrcJSONObject := pJSON;
  Result := Self;
end;

function TJSONConverter.Source(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter;
begin
  FOwnsJSON := pOwnsJSON;
  Result := Source(pJSON);
end;

function TJSONConverter.Source(const pJSON: TJSONArray): IJSONConverter;
begin
  FSrcJSONArray := pJSON;
  Result := Self;
end;

procedure TJSONConverter.ToDataSet(const pDataSet: TDataSet);
begin
  if (FSrcJSONObject <> nil) then
    JSONObjectToDataSet(FSrcJSONObject, pDataSet)
  else if (FSrcJSONArray <> nil) then
    JSONArrayToDataSet(FSrcJSONArray, pDataSet)
  else
    raise EDataSetJSONConverterException.Create('JSON Value Uninformed!');
end;

{ TMarshal }

function TConverter.DataSet: IDataSetConverter;
begin
  Result := TDataSetConverter.Create;
end;

function TConverter.DataSet(const pDataSet: TDataSet): IDataSetConverter;
begin
  Result := DataSet().Source(pDataSet);
end;

function TConverter.DataSet(const pDataSet: TDataSet; const pOwnsDataSet: Boolean): IDataSetConverter;
begin
  Result := DataSet().Source(pDataSet, pOwnsDataSet);
end;

function TConverter.JSON(const pJSON: TJSONObject): IJSONConverter;
begin
  Result := JSON().Source(pJSON);
end;

function TConverter.JSON: IJSONConverter;
begin
  Result := TJSONConverter.Create;
end;

function TConverter.JSON(const pJSON: TJSONObject; const pOwnsJSON: Boolean): IJSONConverter;
begin
  Result := JSON().Source(pJSON, pOwnsJSON);
end;

function TConverter.JSON(const pJSON: TJSONArray; const pOwnsJSON: Boolean): IJSONConverter;
begin
  Result := JSON().Source(pJSON, pOwnsJSON);
end;

function TConverter.JSON(const pJSON: TJSONArray): IJSONConverter;
begin
  Result := JSON().Source(pJSON);
end;

end.
