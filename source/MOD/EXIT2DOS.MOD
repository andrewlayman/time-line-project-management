IMPLEMENTATION MODULE Exit2Dos;

(*  =========================================================================
    Last Edit : January 30, 1991 10:23AM by RSC
    Language  : Logitech Modula-2/86 Version 3

    Description:

        Manager for programs that need to do some action when Time Line
        is exiting to DOS.  This manager provides a vector mechanism outside
        of the Notices system, which requires heap space, and therefore
        cannot be used by alternate heap providers like TLXMS, TLVIDMEM,
        and TLEMS.

    MODIFICATION HISTORY:

    30-Jan-91 RSC First version.


    =========================================================================
*)



    (* Clients, like TLXMS, TLVIDMEM, and TLEMS, steal this vector in
       the normal way (using Overlays' InstallProcedure routine).
       TLDOS calls this with TRUE when it is just about to exit to
       DOS, after all other processing has been done, including
       notices.

       Upon re-entry from DOS, this procedure is again called 
       with FALSE ("not exiting"), and clients can reload memory
       or whatever.

       Note that, particulary on reload, no Heap memory may yet be available,
       as the heap managers may be reloading.  So this means that clients
       of this procedure should never rely on heap memory, such as
       file handles, notice records, or other data structures.

       - Clients return TRUE if all is ok.
       - Any client that returns FALSE will cause exiting to stop.
       - FALSE on reentry is too bad, but is ignored (what else can we do?)
         On re-entry, clients should just return TRUE.
       - Clients should be prepared to be called with "not exiting" when
         they have not been called with "exiting".  This means that
         on an attempt to exit someone returned FALSE, so we tell everyone
         to reload by calling the procedure with "not exiting".

         For this reasons, clients need to track whether they have, in
         fact, exited.
    *)




PROCEDURE XExitProc( Exiting : BOOLEAN ) : BOOLEAN;
BEGIN
    RETURN TRUE;
END XExitProc;





BEGIN  (* module Exit2Dos *)
    ExitingToDOSNotification := XExitProc;
END Exit2Dos.


