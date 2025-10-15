table 50101 "FIFO Check Result"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; DocumentNo; Code[20])
        {
        }
        field(3; LineNo; Integer)
        {
        }
        field(4; ItemNo; Code[20])
        {
        }
        field(5; ShipmentDate; Date)
        {
        }
        field(6; LotNo; Code[50])
        {
        }
        field(7; EarliestLotNo; Code[50])
        {
        }
        field(8; Quantity; Decimal)
        {
        }
        field(9; PostingDate; Date)
        {
        }
        field(10; EarliestPostingDate; Date)
        {
        }
        field(11; FIFOViolation; Text[3])
        {
        }
        field(12; DebugInfo; Text[250])
        {
        }
        field(13; LotSequence; Integer)
        {
        }
        field(14; DateSequence; Integer)
        {
        }
        field(15; PickedByUser; Code[50])
        {
        }
        field(16; QuantityPicked; Decimal)
        {
        }
        field(17; LotQuantity; Decimal)
        {
        }
        field(18; RemainingQuantity; Decimal)
        {
        }
        field(19; EarliestLotQuantity; Decimal)
        {
        } // New field
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Sorting; DocumentNo, LineNo, LotNo)
        {
        }
    }
}
