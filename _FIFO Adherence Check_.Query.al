query 50102 "FIFO Adherence Check"
{
    QueryType = Normal;
    Caption = 'FIFO Adherence Check';

    elements
    {
    dataitem(SalesShipmentLine;
    "Sales Shipment Line")
    {
    column(DocumentNo;
    "Document No.")
    {
    }
    column(LineNo;
    "Line No.")
    {
    }
    column(ItemNo;
    "No.")
    {
    }
    column(ShipmentDate;
    "Shipment Date")
    {
    }
    column(LocationCode;
    "Location Code")
    {
    }
    column(Quantity;
    Quantity)
    {
    }
    column(OrderNo;
    "Order No.")
    {
    }
    column(OrderLineNo;
    "Order Line No.")
    {
    }
    dataitem(ShippedItemLedgerEntry;
    "Item Ledger Entry")
    {
    DataItemLink = "Document No."=SalesShipmentLine."Document No.", "Document Line No."=SalesShipmentLine."Line No.", "Item No."=SalesShipmentLine."No.", "Location Code"=SalesShipmentLine."Location Code";
    SqlJoinType = InnerJoin;

    column(LotNo;
    "Lot No.")
    {
    }
    column(PostingDate;
    "Posting Date")
    {
    }
    dataitem(EarliestLot;
    "Item Ledger Entry")
    {
    SqlJoinType = LeftOuterJoin;
    DataItemLink = "Item No."=ShippedItemLedgerEntry."Item No.", "Location Code"=ShippedItemLedgerEntry."Location Code";
    DataItemTableFilter = "Entry Type"=const(Purchase), "Remaining Quantity"=filter(>0);

    column(EarliestLotNo;
    "Lot No.")
    {
    }
    column(EarliestPostingDate;
    "Posting Date")
    {
    }
    }
    }
    }
    }
}
