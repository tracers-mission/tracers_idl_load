;; utility function to take an array of version number strings (e.g. '1.3',
;; '2.3.17', etc.) and return the index of the highest version number. The
;; NumFields indicates the number of expected fields in each version string
;; (they all have to be the same). We limit this value to a max of 3.
;;
;; If the MinVerToUse keyword is set, then it needs to be a version string with
;; exactly NumFields field (e.g., 1.2.3 if NumFields=3). Any version numbers in
;; VerStrArr that are lower than MinVerToUse in version will be ignored when
;; seeking the highest version number, Note that the only practical use-case for
;; this is for checking if *all* the input versions are lower than the
;; threshold. In that case, the return value is -9.
;;
;; If it ever proves necessary, the new code could be generalized to allow the
;; specification of a min or a max version to consider. Or maybe even to allow
;; both to be provided, to specify a range to consider.


function get_highest_version, VerStrArr, NumFields, min_ver_to_use=MinVerToUse

TRUE = 1
FALSE = 0

;; be very carefull the limit is ever raised above 3, as there are hard-coded
;; values scattered in the code below.
if NumFields gt 3 then begin
   print, 'Error (get_highest_version): Max of 3 fields allowed in version string!'
   return, -1
endif

CheckMinVer = FALSE
if n_elements(MinVerToUse) gt 0 then begin
   CheckMinVer = TRUE

   ;; to confirm that MinVerToUse is a valid version string, we tack it on to
   ;; the front of VerStrArr, and process them together to the poine where that
   ;; confirmation can be made.
   TempVerStrArr = [MinVerToUse, VerStrArr]
endif else begin
   TempVerStrArr = VerStrArr
endelse


NumStr = n_elements(TempVerStrArr)

;; convert the array of version strings to a list, and then split each string
;; into period-separated elements. Result in VerElemStr is a list of N-element
;; arrays, where N should equal NumFields for every string.
VerLst = list(TempVerStrArr, /extract)
VerElemStrLst = VerLst.Map(Lambda(S:S.Split('\.')))

;; get the value of N for each string, and confirm that each are the expected
;; value.
NumElem = VerElemStrLst.Map(Lambda(A:n_elements(A)))
Temp_Ndx = where(NumElem ne NumFields, Cnt)
if Cnt gt 0 then begin
   if CheckMinVer && (Temp_Ndx[0] eq 0) then begin
      print, 'Error (get_highest_version): MinVerToUse has incorrect number of elements!'
   endif else begin
      print, 'Error (get_highest_version): Version strings have varying number of elements!'
   endelse

   return, -1
endif

;; convert the list to a [NumStr, NumFields] array.
VerElemStrArr = VerElemStrLst.ToArray()

;; check that each string element consists of just integers.
if total(stregex(VerElemStrArr, '^ *-?[0-9]+ *$', /boolean)) ne (NumFields * NumStr) then begin
   if CheckMinVer then begin
      if total(stregex(VerElemStrArr[0, *], '^ *-?[0-9]+ *$', /boolean)) ne NumFields then begin
         print, 'Error (get_highest_version): MinVerToUse string has an unexpected character!'
      endif else begin
         print, 'Error (get_highest_version): Unexpected character in version string!'
      endelse
   endif else begin
      print, 'Error (get_highest_version): Unexpected character in version string!'
   endelse

   return, -1
endif

;; convert to a [NumStr, NumFields] long integer array.
VerElemIntArr = long(VerElemStrArr)

;; if a min version has been specified, we split it off here.
if CheckMinVer then begin
   CheckElemIntArr = reform(VerElemIntArr[0, *])
   VerElemIntArr = VerElemIntArr[1:*, *]
   NumStr = NumStr - 1

   ;; final validity test for the check value.
   Dummy = where(CheckElemIntArr gt 999, TempCnt)
   if TempCnt gt 0 then begin
      print, 'Error (get_highest_version): MinVerToUse has Version element > 999!'
      return, -1
   endif

   ;; construct the single integer tag for the check string.
   CheckTag = CheckElemIntArr[NumFields - 1]
   for I = NumFields - 2, 0, -1 do begin
      CheckTag = CheckTag + CheckElemIntArr[I] * (1000L ^ (2 - I))
   endfor
endif

;; we require that no individual version level will be greater than 999.
Temp_Ndx = where(VerElemIntArr gt 999, TempCnt)
if TempCnt gt 0 then begin
    print, 'Error (get_highest_version): Version element > 999!'
   return, -1
endif

;; construct a single integer tag for each version string.
VerTag = VerElemIntArr[*, NumFields - 1]
for I = NumFields - 2, 0, -1 do begin
   VerTag = VerTag + VerElemIntArr[*, I] * (1000L ^ (2 - I))
endfor

;; make sure that there are no duplicate tag values.
if n_elements(uniq(VerTag, sort(VerTag))) ne NumStr then begin
   print, 'Error (get_highest_version): Duplicate version nunber!'
   return, -1
endif

;; if requested, remove any version tags lower than the specified minimum tag.
if CheckMinVer then begin
   Keep_Ndx = where(VerTag ge CheckTag, Cnt)
   if Cnt eq 0 then begin
      print, 'Warn (get_highest_version): All versions are lower than ' + MinVerToUse
      return, -9
   endif

   if (NumStr - Cnt) gt 0 then begin
      print, ' (get_highest_version): Excluding ', NumStr - Cnt, $
             ' versions lower than MinVerToUse.', format='(A, I0, A)'
   endif
endif else begin
   Keep_Ndx = lindgen(NumStr)
endelse

;; find the index of the maximum tag value
Dummy = max(VerTag[Keep_Ndx], MaxVerNdx)

return, Keep_Ndx[MaxVerNdx]

end
