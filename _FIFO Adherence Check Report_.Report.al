report 50122 "FIFO Adherence Check Report"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = Excel;
    ExcelLayout = 'FIFOAdherenceCheckReport.xlsx';

    dataset
    {
        dataitem(FIFOCheck; "Integer")
        {
            DataItemTableView = sorting(Number);

            column(DocumentNo; TempResult.DocumentNo)
            {
            }
            column(LineNo; TempResult.LineNo)
            {
            }
            column(ItemNo; TempResult.ItemNo)
            {
            }
            column(ShipmentDate; TempResult.ShipmentDate)
            {
            }
            column(LotNo; TempResult.LotNo)
            {
            }
            column(EarliestLotNo; TempResult.EarliestLotNo)
            {
            }
            column(Quantity; TempResult.Quantity)
            {
            }
            column(QuantityPicked; TempResult.QuantityPicked)
            {
            }
            column(LotQuantity; TempResult.LotQuantity)
            {
            }
            column(EarliestLotQuantity; TempResult.EarliestLotQuantity)
            {
            } // New field
            column(PostingDate; TempResult.PostingDate)
            {
            }
            column(EarliestPostingDate; TempResult.EarliestPostingDate)
            {
            }
            column(FIFOViolation; TempResult.FIFOViolation)
            {
            }
            column(DebugInfo; TempResult.DebugInfo)
            {
            }
            column(LotSequence; TempResult.LotSequence)
            {
            }
            column(DateSequence; TempResult.DateSequence)
            {
            }
            column(PickedByUser; TempResult.PickedByUser)
            {
            }
            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, TempResult.Count);
            end;
            trigger OnAfterGetRecord()
            begin
                if Number = 1 then TempResult.FindFirst()
                else
                    TempResult.Next();
            end;
        }
    }
    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(DaysToCheck; DaysToCheck)
                    {
                        ApplicationArea = All;
                        Caption = 'Number of Days to Check';
                        ToolTip = 'Specifies the number of past days to check for FIFO adherence';
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            if DaysToCheck = 0 then DaysToCheck:=7;
        end;
    }
    trigger OnPreReport()
    var
        FIFOQuery: Query "FIFO Adherence Check";
        EntryNo: Integer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        if DaysToCheck <= 0 then Error('The number of days to check must be greater than zero.');
        TempResult.Reset();
        TempResult.DeleteAll();
        FIFOQuery.SetRange(ShipmentDate, CalcDate('-' + Format(DaysToCheck) + 'D', WorkDate()), WorkDate());
        EntryNo:=0;
        if FIFOQuery.Open()then begin
            while FIFOQuery.Read()do begin
                EntryNo+=1;
                TempResult.Init();
                TempResult."Entry No.":=EntryNo;
                TempResult.DocumentNo:=FIFOQuery.DocumentNo;
                TempResult.LineNo:=FIFOQuery.LineNo;
                TempResult.ItemNo:=FIFOQuery.ItemNo;
                TempResult.ShipmentDate:=FIFOQuery.ShipmentDate;
                TempResult.LotNo:=FIFOQuery.LotNo;
                TempResult.PostingDate:=FIFOQuery.PostingDate;
                TempResult.PickedByUser:=GetPickedByUser(FIFOQuery.OrderNo, FIFOQuery.OrderLineNo, FIFOQuery.ItemNo, FIFOQuery.LotNo);
                // Get quantity picked for this specific lot
                ItemLedgerEntry.SetRange("Document No.", FIFOQuery.DocumentNo);
                ItemLedgerEntry.SetRange("Document Line No.", FIFOQuery.LineNo);
                ItemLedgerEntry.SetRange("Item No.", FIFOQuery.ItemNo);
                ItemLedgerEntry.SetRange("Lot No.", FIFOQuery.LotNo);
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
                if ItemLedgerEntry.FindFirst()then TempResult.QuantityPicked:=Abs(ItemLedgerEntry.Quantity)
                else
                    TempResult.QuantityPicked:=0;
                // Get total quantity for the sales line
                if SalesShipmentLine.Get(FIFOQuery.DocumentNo, FIFOQuery.LineNo)then TempResult.Quantity:=SalesShipmentLine.Quantity
                else
                    TempResult.Quantity:=0;
                // Get lot quantity
                Clear(ItemLedgerEntry);
                ItemLedgerEntry.SetRange("Item No.", FIFOQuery.ItemNo);
                ItemLedgerEntry.SetRange("Lot No.", FIFOQuery.LotNo);
                ItemLedgerEntry.CalcSums("Remaining Quantity");
                TempResult.LotQuantity:=ItemLedgerEntry."Remaining Quantity" + TempResult.QuantityPicked;
                TempResult.Insert();
            end;
            FIFOQuery.Close();
        end;
        DetermineFIFOViolations();
    end;
    local procedure GetPickedByUser(OrderNo: Code[20]; OrderLineNo: Integer; ItemNo: Code[20]; LotNo: Code[50]): Code[50]var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"S. Order");
        WarehouseEntry.SetRange("Source No.", OrderNo);
        WarehouseEntry.SetRange("Source Line No.", OrderLineNo);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        if WarehouseEntry.FindFirst()then exit(WarehouseEntry."User ID");
        exit('');
    end;
    local procedure DetermineFIFOViolations()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        CurrentDocumentNo: Code[20];
        CurrentLineNo: Integer;
        LoopCounter: Integer;
        DebugLog: Text;
    begin
        LoopCounter:=0;
        DebugLog:='';
        TempResult.Reset();
        TempResult.SetCurrentKey(DocumentNo, LineNo, LotNo);
        if TempResult.FindSet()then repeat LoopCounter+=1;
                if LoopCounter > 10000 then Error('Potential infinite loop detected. Debug Log: %1', DebugLog);
                DebugLog+=StrSubstNo('Processing: Doc %1, Line %2, Item %3, Lot %4\', TempResult.DocumentNo, TempResult.LineNo, TempResult.ItemNo, TempResult.LotNo);
                if(TempResult.DocumentNo <> CurrentDocumentNo) or (TempResult.LineNo <> CurrentLineNo)then begin
                    // New line, reset and find earliest available lot
                    CurrentDocumentNo:=TempResult.DocumentNo;
                    CurrentLineNo:=TempResult.LineNo;
                    Clear(ItemLedgerEntry);
                    ItemLedgerEntry.SetRange("Item No.", TempResult.ItemNo);
                    ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
                    ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
                    ItemLedgerEntry.SetFilter("Posting Date", '<=%1', TempResult.ShipmentDate);
                    ItemLedgerEntry.SetCurrentKey("Lot No.");
                    if ItemLedgerEntry.FindFirst()then begin
                        TempResult.EarliestLotNo:=ItemLedgerEntry."Lot No.";
                        TempResult.EarliestPostingDate:=ItemLedgerEntry."Posting Date";
                        TempResult.EarliestLotQuantity:=ItemLedgerEntry."Remaining Quantity"; // Populate new field
                    end
                    else
                    begin
                        TempResult.EarliestLotNo:='';
                        TempResult.EarliestPostingDate:=0D;
                        TempResult.EarliestLotQuantity:=0; // Set to 0 if no earliest lot found
                    end;
                end;
                // FIFO check based on Lot Number sequence
                if(TempResult.EarliestLotNo <> '') and (TempResult.LotNo > TempResult.EarliestLotNo)then begin
                    TempResult.FIFOViolation:='Yes';
                    FIFOViolationCount+=1;
                end
                else
                    TempResult.FIFOViolation:='No';
                TempResult.DebugInfo:=StrSubstNo('Shipment Date: %1, Lot No: %2, Earliest Available Lot No: %3, ' + 'Quantity Picked: %4, Earliest Lot Quantity: %5, FIFO Violation: %6', TempResult.ShipmentDate, TempResult.LotNo, TempResult.EarliestLotNo, TempResult.QuantityPicked, TempResult.EarliestLotQuantity, TempResult.FIFOViolation);
                TempResult.Modify();
            until TempResult.Next() = 0;
        if LoopCounter = 10000 then Error('Loop limit reached. Last processed: Doc %1, Line %2', CurrentDocumentNo, CurrentLineNo);
    end;
    var TempResult: Record "FIFO Check Result" temporary;
    EarliestAvailableLots: array[1000]of Code[50];
    EarliestAvailableQty: array[1000]of Decimal;
    EarliestAvailableDates: array[1000]of Date;
    EarliestAvailableCount: Integer;
    DaysToCheck: Integer;
    FIFOViolationCount: Integer;
}
