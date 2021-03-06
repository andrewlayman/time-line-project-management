    (*V2=DEBUG Extra code to allow debugging. *)
    (*V3=PARANOID Requires DEBUG. Adds checksumming. *)
    (*V5=OS2 OS/2 code changes. *)
    (*V6=DOS Regular DOS TL code. *)

    (* WARNING -- Check comments labled "WARNING" for secret tricks,
                  assumptions, short cuts and other risky stuff. *)



IMPLEMENTATION MODULE FlexPage;

  (* MODIFICATION HISTORY   (Original Author AJL)

      08-Aug-89 WKH  -First edits for OS/2.
       2-Jan-91 AJL  -Removed lock sets from pages.  Added Generations.
                     -Removed an unnecessary (and previously incorrect)
                      test of the record size against MaxDataBytesPerPage
                      from SetRecordSize.

   *)

FROM CRC16    IMPORT
    (* PROC *)      CheckSum;

FROM Dialog  IMPORT
    (* PROC *)      Error, FatalError, NotYetImplemented, Burp;

FROM FlexData IMPORT

    (* CONST *)    MaxDataSize, MaxUserRecordsPerPage, MaxRecordsPerPage,
                   MaxRecordSize, BPBS, BitsetsPerPageSet,
                   MaxRecords, 

    (* TYPE *)     APageNo, ARecordNo,
                   APageHeader, APageSet, APage, APagePointer, APageInfo,

    (* VAR *)      MaxPageSize,
                   MinPageSize, PageOverhead, MaxDataBytesPerPage;

FROM SYSTEM  IMPORT
    (* TYPE *)      BYTE, TSIZE, SIZE, ADDRESS, ADR, CODE;




    (* ------------- DEBUGGING ---------------------------*)


              (*<DEBUG

FROM FlexTrace      IMPORT
                           Trace, TraceLS,
                           TraceSize, 
                           TraceOn, TraceOff;


              DEBUG>*)





    (*$R-*) (*$S-*) (*$T-*)



(*<OS2
PROCEDURE CopyBytes( From, To : ADDRESS;  Length : CARDINAL );
BEGIN


(*
CODE	SEGMENT PARA 'code'
	ASSUME	CS:CODE


    ;(* Move Length Bytes *)

    MOV CX, [BP+4]	  ; CX := Length
    JCXZ OUT
    MOV CX, [BP+4]	 ; Bytes to move

   ;(*	Compare normalized addresses at [BP+6] and [BP+A] *)

    MOV AX,[BP+08H]	  ; Compare segments To
    CMP AX,[BP+0CH]	  ;  and From
    JB	BIGGER
    JNE SMALLER
    MOV AX,[BP+06H]	  ; Segments equal.  Compare offsets.
    CMP AX,[BP+0AH]
    JB	BIGGER
    JE	OUT		  ; Get out if addresses are equal.

    ; Here if From < To
SMALLER:
    STD 		 ; Auto Decrement
    MOV AX, [BP+8]	 ; To segment
    MOV BX, [BP+0CH]	 ; From segment
    MOV DI, [BP+6]	 ; ES:DI ------> To
    MOV ES, AX		 ;
    MOV SI, [BP+0AH]	 ; DS:SI ------> From
    MOV DS, BX
    ADD DI, CX		 ; ES:DI  ---->  To[Length]
    DEC DI
    ADD SI, CX		 ; DS:SI  ---->  From[Length]
    DEC SI
    REP MOVSB		 ; COPY CX bytes
    CLD 		 ; Auto Increment
    JMP OUT


    ; Here if From > To
BIGGER:
    CLD
    MOV AX, [BP+8]	 ; To segment
    MOV BX, [BP+0CH]	 ; From segment
    MOV DI, [BP+6]	 ; ES:DI ------> To
    MOV ES, AX		 ;
    MOV SI, [BP+0AH]	 ; DS:SI ------> From
    MOV DS, BX
    REP MOVSB		 ; COPY CX bytes

OUT:
    NOP

CODE	ENDS
	END
*)


    CODE(

       8BH, 4EH, 04H,
       0E3H, 47H       );

    CODE(
       8BH, 4EH, 04 );

    CODE(
       8BH, 46H, 08H,
       3BH, 46H, 0CH,
       72H, 29H,
       75H, 0AH,
       08BH, 46H, 06H,
       3BH, 46H, 0AH,
       72H, 1FH,
       74H, 30H );

    CODE(
       0FDH,

       8BH, 46H, 08H,
       8BH, 5EH, 0CH,
       8BH, 7EH, 06H,
       8EH, 0C0H,
       8BH, 76H, 0AH,
       8EH, 0DBH,
       03H, 0F9H,
       4FH,
       03H, 0F1H,
       4EH,
       0F3H, 0A4H,
       0FCH,
       0EBH, 14H, 90H );

    CODE(
       0FCH,
       8BH, 46H, 08H,
       8BH, 5EH, 0CH,

       8BH, 7EH, 06H,
       8EH, 0C0H,
       8BH, 76H, 0AH,
       8EH, 0DBH,
       0F3H, 0A4H
    );


END CopyBytes;
OS2>*)

(*<DOS*)
PROCEDURE CopyBytes( From, To : ADDRESS;  Length : CARDINAL );
BEGIN


(*
CODE	SEGMENT	PARA 'code'
	ASSUME	CS:CODE


    ;(* Move Length Bytes *)

    MOV CX, [BP+4]        ; CX := Length
    JCXZ OUT

  ;(* Normalize address at BP+6  *)

    MOV AX, [BP+6  ]      ;  AX := Offset DIV 16
    MOV CL, 4
    SHR AX, CL
    ADD [BP+8], AX      ;  Segment := Segment + (Offset DIV 16);
    AND WORD PTR [BP+6], 0FH       ;  Offset := Offset MOD 16

  ;(* Normalize address at BP+A  *)

    MOV AX, [BP+0AH]      ;  AX := Offset DIV 16
    MOV CL, 4
    SHR AX, CL
    ADD [BP+0CH], AX      ;  Segment := Segment + (Offset DIV 16);
    AND WORD PTR [BP+0AH], 0FH       ;  Offset := Offset MOD 16

    MOV CX, [BP+4]       ; Bytes to move

   ;(*  Compare normalized addresses at [BP+6] and [BP+A] *)

    MOV AX,[BP+08H]       ; Compare segments To
    CMP AX,[BP+0CH]       ;  and From
    JB  BIGGER
    JNE SMALLER
    MOV AX,[BP+06H]       ; Segments equal.  Compare offsets.
    CMP AX,[BP+0AH]
    JB  BIGGER
    JE  OUT               ; Get out if addresses are equal.

    ; Here if From < To
SMALLER:
    STD                  ; Auto Decrement
    MOV AX, [BP+8]       ; To segment
    MOV BX, [BP+0CH]     ; From segment
    MOV DI, [BP+6]       ; ES:DI ------> To
    MOV ES, AX           ;
    MOV SI, [BP+0AH]     ; DS:SI ------> From
    MOV DS, BX
    ADD DI, CX           ; ES:DI  ---->  To[Length]
    DEC DI
    ADD SI, CX           ; DS:SI  ---->  From[Length]
    DEC SI
    REP MOVSB            ; COPY CX bytes
    CLD                  ; Auto Increment
    JMP OUT


    ; Here if From > To
BIGGER:
    CLD
    MOV AX, [BP+8]       ; To segment
    MOV BX, [BP+0CH]     ; From segment
    MOV DI, [BP+6]       ; ES:DI ------> To
    MOV ES, AX           ;
    MOV SI, [BP+0AH]     ; DS:SI ------> From
    MOV DS, BX
    REP MOVSB            ; COPY CX bytes

OUT:
    NOP

CODE	ENDS
        END
*)


    CODE(

       8BH, 4EH, 04H,
       0E3H, 65H       );

    CODE(
       8BH, 46H, 06H,
       0B1H, 04H,
       0D3H, 0E8H,
       01H, 46H, 08H,
       81H, 66H, 06H, 0FH, 00,

       08BH, 46H, 0AH,
       0B1H, 04H,
       0D3H, 0E8H,
       01H, 46H, 0CH,
       81H, 66H, 0AH, 0FH, 00 );

    CODE(
       8BH, 4EH, 04 );

    CODE(
       8BH, 46H, 08H,
       3BH, 46H, 0CH,
       72H, 29H,
       75H, 0AH,
       08BH, 46H, 06H,
       3BH, 46H, 0AH,
       72H, 1FH,
       74H, 30H );

    CODE(
       0FDH,

       8BH, 46H, 08H,
       8BH, 5EH, 0CH,
       8BH, 7EH, 06H,
       8EH, 0C0H,
       8BH, 76H, 0AH,
       8EH, 0DBH,
       03H, 0F9H,
       4FH,
       03H, 0F1H,
       4EH,
       0F3H, 0A4H,
       0FCH,
       0EBH, 14H, 90H );

    CODE(
       0FCH,
       8BH, 46H, 08H,
       8BH, 5EH, 0CH,

       8BH, 7EH, 06H,
       8EH, 0C0H,
       8BH, 76H, 0AH,
       8EH, 0DBH,
       0F3H, 0A4H
    );


END CopyBytes;
(*DOS>*)

    (*$R=*) (*$S=*) (*$T=*)






PROCEDURE InitializePage( VAR Page : APage; Size : CARDINAL; PageNo : APageNo );
    (*<PARANOID
VAR
     i : CARDINAL;
    PARANOID>*)
BEGIN
    WITH Page.Header DO
        Check     := 0;
        PageSize  := Size;
        DataBytesThisPage := Size - PageOverhead;
        LockCount := 0;
        LastEntry := 0;
        NeedsSqueeze := FALSE;
        PageNumber   := PageNo;
    END;

    Page.StartAt[0]     := 0;
    Page.FreeSet[0]     := {};

        (* To give a length to the preceding entry. *)
    Page.StartAt[1]    := Page.Header.DataBytesThisPage;


    (*<PARANOID
        FOR i := 0 TO Page.Header.DataBytesThisPage-1 DO
            Page.Data[i] := CHR(0);
        END;
    PARANOID>*)

END InitializePage;





PROCEDURE SizeOfRecord( VAR Page    : APage;
                            RecNo   : ARecordNo ) : CARDINAL;
BEGIN
    RETURN (Page.StartAt[RecNo+1])
          -(Page.StartAt[RecNo  ]);
END SizeOfRecord;





PROCEDURE MarkPageDirty( VAR Page : APage );
BEGIN
        (*<DEBUG
    CheckSumAPage(Page);
        DEBUG>*)
    Page.Header.Dirty := TRUE;
END MarkPageDirty;







PROCEDURE SqueezePage( VAR Page     : APage );
VAR
    Target : CARDINAL;
    Size   : CARDINAL;
    RecNo  : ARecordNo;
BEGIN
        (* Unless the page is locked, reduce the size of all the freed
           records to zero by compacting the records still in use to
           the front of the page. *)

    IF (Page.Header.LockCount = 0) THEN
        Target := 0;
        FOR RecNo := 0 TO Page.Header.LastEntry DO
            WITH Page DO

                IF ((RecNo MOD BPBS) IN (FreeSet[RecNo DIV BPBS])) THEN
                    Size := 0;
                ELSE
                    Size := SizeOfRecord(Page,RecNo);
                    CopyBytes( ADR( Page.Data[StartAt[RecNo]] ),
                               ADR( Page.Data[Target] ),
                               Size );
                END;
                StartAt[RecNo] := Target;
                INC(Target,Size);

            END;
        END;
        Page.Header.NeedsSqueeze := FALSE;
        MarkPageDirty(Page);
    END;
END SqueezePage;








PROCEDURE PageHasRoomFor( VAR Page  : APage;
                              Size  : CARDINAL
                        ):BOOLEAN;
VAR
    RecNo : ARecordNo;
    Room  : CARDINAL;
BEGIN
    RETURN (SizeOfRecord(Page,Page.Header.LastEntry) >= Size);
END PageHasRoomFor;





PROCEDURE DataAddress( VAR Page : APage;
                           RecNo : ARecordNo ) : ADDRESS;
BEGIN
    RETURN ADR(Page.Data[ Page.StartAt[RecNo]] );
END DataAddress;











PROCEDURE RemoveRecordFromPage( VAR Page     : APage;
                                    RecNo    : ARecordNo );
VAR
    Last     : ARecordNo;
    Need     : BOOLEAN;
    PageNo   : APageNo;
    Size     : CARDINAL;
BEGIN
    Size  := SizeOfRecord( Page, RecNo );
  
    Last  := Page.Header.LastEntry;

        (* Mark the record as freed.  *)

    INCL( Page.FreeSet[ RecNo DIV BPBS ],  (RecNo MOD BPBS) );

        (* If the record was the last record in the page, consolidate
           it with the free space at the end of the page, and any
           adjacent free space.  Otherwise, mark the page as needing
           to be squeezed.   We take this cautious approach since it
           will not change the locations of any records, which could
           have problems if records are locked. *)

    Need := TRUE;

    WHILE (RecNo+1 = Last)
          AND ( (RecNo MOD BPBS) IN Page.FreeSet[ RecNo DIV BPBS ] ) DO
        Page.StartAt[Last] := Page.Header.DataBytesThisPage;
        Need := FALSE;
        Last := RecNo;
        IF (RecNo > 0) THEN
            DEC(RecNo);
        END;
    END;

    Page.Header.LastEntry := Last;

    IF (Need) THEN
        Page.Header.NeedsSqueeze := TRUE;
    END;

    MarkPageDirty(Page);

    PageNo := Page.Header.PageNumber;

END RemoveRecordFromPage;






PROCEDURE SetRecordSize( VAR Page     : APage;
                             RecNo    : ARecordNo;
                             NewSize  : CARDINAL
                    ) : BOOLEAN;
VAR
    CurrentSize       : CARDINAL;
    ShiftLength       : CARDINAL;
    Difference        : CARDINAL;
    i                 : CARDINAL;
    PageNo            : APageNo;
    CannotChangeSize  : BOOLEAN;

    PROCEDURE MoveFollowingRecords;
    BEGIN
        CopyBytes( ADR( Page.Data[ Page.StartAt[RecNo]+CurrentSize ] ),
                   ADR( Page.Data[ Page.StartAt[RecNo+1]           ] ),
                   ShiftLength );
    END MoveFollowingRecords;

BEGIN
        (* Determine if we can move other records around, or
           whether we must keep other records in this page in
           place.  The test to allow the last record to always
           change size is important to prevent this routine
           from going into infinite recursion. *)

    CannotChangeSize := (Page.Header.LockCount > 0)
                        AND
                        (RecNo+1 < Page.Header.LastEntry);

    CurrentSize := SizeOfRecord(Page,RecNo);

    ShiftLength := Page.StartAt[Page.Header.LastEntry]
                   - Page.StartAt[RecNo+1];

        (* Move the other records in the array. *)

    IF (NewSize = CurrentSize) THEN
       (* Nothing *)

    ELSIF (NewSize > CurrentSize)     (* Bigger *)
       OR (CannotChangeSize) THEN

        (* Unnecessary--The test below against free space will catch it.
        IF (NewSize > Page.Header.DataBytesThisPage ) THEN
            RETURN FALSE;
        END;
        *)

        IF (NOT CannotChangeSize) THEN               (* Avoid cardinal overflow. *)
            Difference := NewSize - CurrentSize;
        END; 

        IF (CannotChangeSize) OR
           (SizeOfRecord(Page,Page.Header.LastEntry) < Difference) THEN

                (* Record won't fit on the current page, or the
                   current page is locked.  This is more than we can
                   accomplish.   *)

            RETURN FALSE;
        ELSE
                (* Record does fit on the page. *)
            FOR i := (RecNo + 1) TO (Page.Header.LastEntry) DO
                INC(Page.StartAt[i], Difference);
            END;

            MoveFollowingRecords();
        END;

        MarkPageDirty( Page );

    ELSIF ( NewSize < CurrentSize ) THEN

            (* Record fits easily on the page because it has become smaller. *)

        Difference := CurrentSize - NewSize;
        FOR i := (RecNo + 1) TO (Page.Header.LastEntry) DO
            DEC(Page.StartAt[i], Difference);
        END;

        MoveFollowingRecords();

        MarkPageDirty( Page );
    END;

    RETURN TRUE;

END SetRecordSize;




PROCEDURE AddRecordToPage( VAR Page  : APage;
                           VAR RecNo : CARDINAL;
                               Size  : CARDINAL
                          ) : BOOLEAN;
VAR
    Data, NextIndex : ADDRESS;
    Last : CARDINAL;
    i, j, k, FreeCount : CARDINAL;
    AccumulatedSize, ExcessSize : CARDINAL;
    SizeOfRecK      : CARDINAL;
    Distance        : CARDINAL;
BEGIN
    Last  := Page.Header.LastEntry;

        (* Try to find internal space.
           Search for a series of free records whose total size is 
           large enough. *)
    RecNo := 0;                   (* First free record *)
    j := 0;                       (* Last free record *)
    AccumulatedSize := 0;
    FreeCount := 0;
        (* We need two free records in a row, or a free record at the
           end of the page.   Look for a sequence of free and unlocked
           records, beginning and ending with an unlocked record. 
           Unlocked (moveable) records in the middle don't contribute
           to the free space, but they don't prevent consolication either.
           Anything at the end of the page is acceptable. *)
    REPEAT
        IF ((j MOD BPBS) IN Page.FreeSet[ j DIV BPBS ] ) THEN
            IF (FreeCount = 0) THEN 
                RecNo := j;
            END;
            INC(AccumulatedSize, SizeOfRecord( Page, j ) );
            INC(FreeCount);
        ELSIF ((j MOD BPBS) IN Page.LockSet[ j DIV BPBS ] ) THEN
            AccumulatedSize := 0;
            FreeCount := 0;
        (* else not free, but not locked either. *)
        END;

        INC(j);
    UNTIL (j > Last) OR
          ((AccumulatedSize >= Size) AND (FreeCount >= 2));

        (* j is now one too large.  It is just past the last of the 
           free records. *)

        (* If there is no location for this record, exit saying so.
           There can be no location for one of two reasons: either there
           just isn't enough free space, or there is enough, be we don't
           have two or more free records without intervening locked
           records, so we cannot move enough records to get the space
           we need consolidated.  *)

    IF (AccumulatedSize < Size) OR ((FreeCount < 2) AND (j <= Last)) THEN
        RETURN FALSE;
    END;

    DEC(j);     (* j now points to the last free record. *)

        (* If the first unused record is also the last entry in the
           list of records, then we must move the last entry down
           by one. *)

    IF (RecNo > Last) THEN
        FatalError();
    ELSIF (RecNo = Last) THEN
        INC(Last);
        j := Last;  (* ??? *)
        Page.Header.LastEntry := Last;

        Page.StartAt[Last] := Page.StartAt[RecNo];  (* Since Length = 0 *)

        INCL(Page.FreeSet[ Last DIV BPBS ], (Last MOD BPBS) );

            (* The Last+1 index points to no data. *)
        Page.StartAt[Last+1] := Page.Header.DataBytesThisPage;
    END;

        (* Move the moveable records and consolidate the free ones. 
           We do this by working bottom to top, moving all the records
           down so that we end up with the amount of free space we
           need near the top of the page, and any excess towards the end.  *)

    IF (AccumulatedSize > Size) THEN
        ExcessSize :=  AccumulatedSize - Size;
    ELSE
        ExcessSize := 0;
    END;

    Distance := 0;
    FOR k := j TO RecNo+1 BY -1 DO
        SizeOfRecK := SizeOfRecord(Page,k);
           (* Adjust sizes of free records. *)
        IF ((k MOD BPBS) IN Page.FreeSet[ k DIV BPBS ] ) THEN
                (* A free record.  Change its size to less.   But don't open 
                   up more free space than we need.   The free record lowest
                   in the page may not end up with its size going to zero,
                   but all the other free records we examine will.  *)
            Distance := SizeOfRecK-ExcessSize;
            ExcessSize := 0;

        ELSE
                (* Move the moveable record. *)
            CopyBytes( ADR( Page.Data[StartAt[i]] ),
                       ADR( Page.Data[StartAt[i]+Distance] ),
                       SizeOfRecK );
        END;
            (* Record k starts lower on the page. *)
        Page.StartAt[k] := Page.StartAt[k]+Distance;
    END;
    
        (* At this point, record RecNo is sized correctly as Size bytes,
           and all the free records in the range RecNo+1 to j-1 will have
           size 0, while record j will have size of AccumulatedSize - Size. *)

         (* Mark the new record as in use. *)

    EXCL( Page.FreeSet[ RecNo DIV BPBS ], (RecNo MOD BPBS) );

         (* Set the generation to something. *)

    Page.Generation[RecNo] := 10C;        (* Starting value. *)

         (* Page has been altered. *)

    MarkPageDirty(Page);

    RETURN TRUE;

END AddRecordToPage;








PROCEDURE CheckSumAPage( VAR Page : APage );
BEGIN
    Page.Header.Check := CheckSum(ADR(Page.Header.PageNumber),
                           Page.Header.PageSize-SIZE(Page.Header.Check) );
END CheckSumAPage;





PROCEDURE TestPageCheckSum(VAR Page:APage);
BEGIN
   IF (Page.Header.Check <> CheckSum(ADR(Page.Header.PageNumber),
                           Page.Header.PageSize-SIZE(Page.Header.Check) ) ) THEN
       FatalError();
   END;
END TestPageCheckSum;






END FlexPage.
