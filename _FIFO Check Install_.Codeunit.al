codeunit 50102 "FIFO Check Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        UserPersonalization: Record "User Personalization";
        AccessControlRec: Record "Access Control";
        PermissionSetRec: Record "Permission Set";
    begin
        // Find the FIFO Check permission set
        PermissionSetRec.Reset();
        PermissionSetRec.SetRange("Role ID", 'FIFO CHECK');
        if not PermissionSetRec.FindFirst()then exit;
        // Loop through all users
        UserPersonalization.Reset();
        if UserPersonalization.FindSet()then repeat // Check if the permission set is already assigned to this user
                AccessControlRec.Reset();
                AccessControlRec.SetRange("Role ID", PermissionSetRec."Role ID");
                AccessControlRec.SetRange("User Security ID", UserPersonalization."User SID");
                if not AccessControlRec.FindFirst()then begin
                    // If not assigned, create a new access control record
                    AccessControlRec.Init();
                    AccessControlRec."User Security ID":=UserPersonalization."User SID";
                    AccessControlRec."Role ID":=PermissionSetRec."Role ID";
                    AccessControlRec."Company Name":=CompanyName;
                    AccessControlRec.Scope:=AccessControlRec.Scope::Tenant;
                    AccessControlRec.Insert(true);
                end;
            until UserPersonalization.Next() = 0;
    end;
}
