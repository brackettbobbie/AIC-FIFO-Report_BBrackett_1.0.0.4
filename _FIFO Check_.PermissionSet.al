permissionset 50100 "FIFO Check"
{
    Assignable = true;
    Caption = 'FIFO Check Permissions';
    Permissions = table "FIFO Check Result"=X,
        tabledata "FIFO Check Result"=RMID,
        query "FIFO Adherence Check"=X,
        report "FIFO Adherence Check Report"=X;
}
