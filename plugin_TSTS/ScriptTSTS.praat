###========================================
### READ ME
###========================================
###
### Praat Script TS Text Styles
### v1.0.2 2021/02/10
### 
### Thomas Schökler
### 
###
### The original purpose of this script was to set text styles globally
###  (the default settings turn every first tier of every grid italic)
###   but it can be used for any global insertion or removal of strings.
### 
### All TextGrids in the current selection will be affected.
###  Other selected objects will be ignored.
### 
### Empty point tiers will be skipped.
###  The treatment of empty intervals/points can be selected by the user.
###
### v1.0.1: Intervals/points already set to the selected TextStyle
###  ("%%", "##", "^^", or "__") are skipped.
###
### v1.0.2: Negative tier numbers will be counted starting from the bottom.
###
###========================================

###----------------------------------------
### Dialog window                               standards
  #                                                 v
    form Insert or remove text...
        sentence Tier_number                        1 (0 = all tiers)
        sentence Text                               %%
        optionmenu Placement_(or_'remove')          1
            option start of every interval/point
            option end of every interval/point
            option start of every word
            option end of every word
            option remove everywhere
        boolean Skip_empty_intervals_and_points     1
        boolean Create_backups_of_current_TextGrids 0
        comment Help for TextStyles:   italic  %%,   bold  ##,   superscript  ^^,   subscript  __
    endform

###----------------------------------------
### Options
    
    tier_number = extractNumber(tier_number$,"")
    placement$  = placement$
        startIP$    = "start of every interval/point"
        endIP$      = "end of every interval/point"
        startW$     = "start of every word"
        endW$       = "end of every word"
        remove$     = "remove everywhere"
    empty_skip  = skip_empty_intervals_and_points
    backup      = create_backups_of_current_TextGrids

    text_style  = (text$ = "%%" or text$ = "##" or text$ = "^^" or text$ = "__")
    edit        = 0
    
###----------------------------------------
### Query selection
    
    # Check whether tier_number is an integer
    round_num   = round(tier_number)
        if round_num <> tier_number
            exitScript: "Tier number must be integer."
        elif tier_number = undefined
            exitScript: "Please insert a number for 'Tier number'."
        endif
        
    # Store selected objects in variables
    grid_num    = numberOfSelected ("TextGrid")
        for gi to grid_num
            grid[gi] = selected ("TextGrid",1)
            minusObject: grid[gi]
        endfor
    other_num   = numberOfSelected ()
        for j to other_num
            other[j] = selected (j)
        endfor
    
    # Backup the TextGrids before writing
    if backup
        for gi to grid_num
            selectObject: grid[gi]
            Copy: selected$("TextGrid")+"_bak"
        endfor
    endif

###----------------------------------------
### Do the thing

  writeInfoLine: "Running Script TSTS..."

    for gi to grid_num
        selectObject: grid[gi]
        g_name$ = selected$("TextGrid")
        tn = Get number of tiers
      # Convert negative tier numbers to specified tier_num
        if tier_number < 0
            tier_num = tier_number + tn+1
        elif tier_number > 0
            tier_num = tier_number
        elif tier_number = 0
            tier_num = undefined
        endif
        
        # Skip the grid if it has fewer tiers than tier_num
        if tier_num > tn or tier_num < 1
            appendInfoLine: "Grid ",gi," '"+g_name$+"' only has ",tn," tiers, cannot edit tier ",tier_number,"; skipped"
        
        # Do the thing for tier tier_num
        elif tier_num > 0
            @theThing: tier_num
        
        # Do the thing for all tiers
        elif tier_num = undefined
            for ti to tn
                @theThing: ti
            endfor

        endif
    endfor

    @originalSelection

    if placement$ = startIP$ or placement$ = endIP$
        appendInfoLine: edit," Elements edited"
    endif
  appendInfoLine: "Process exited normally"



###----------------------------------------
### The thing

    procedure theThing: .tier
        interval = Is interval tier: .tier
        name$ = Get tier name: .tier
    
    # Interval tiers
        if interval = 1
            n = Get number of intervals: .tier
            
            if placement$ = startW$
                Replace interval texts: .tier, 1, 0, " ", " "+text$, "literals"
            elif placement$ = endW$
                Replace interval texts: .tier, 1, 0, " ", text$+" ", "literals"
            elif placement$ = remove$
                Replace interval texts: .tier, 1, 0, text$, "", "literals"
            endif
            
            for i to n
                label$ = Get label of interval: .tier, i
                if label$ = "" and empty_skip
                    appendInfoLine: "Empty interval skipped:"
                    appendInfoLine: tab$+"Grid ",gi," '"+g_name$+"', Tier ",.tier," '"+name$+"', Int ",i,""
                elif text_style and startsWith (label$, text$)
                    appendInfoLine: "Interval already starting with '"+text$+"' skipped:"
                    appendInfoLine: tab$+"Grid ",gi," '"+g_name$+"', Tier ",.tier," '"+name$+"', Int ",i," '"+label$+"'"
                elif placement$ = startIP$ or placement$ = startW$
                    Set interval text: .tier, i, text$+label$
                    edit += 1
                elif placement$ = endIP$ or placement$ = endW$
                    Set interval text: .tier, i, label$+text$
                    edit += 1
                endif
            endfor
         
    # Point tiers
        elif interval = 0
            n = Get number of points: .tier
            if n = 0
                appendInfoLine: "Empty point tier skipped:"
                appendInfoLine: tab$+"Grid ",gi," '"+g_name$+"', Tier ",.tier," '"+name$+"'"                
            else

                if placement$ = startW$
                    Replace point texts: .tier, 1, 0, " ", " "+text$, "literals"
                elif placement$ = endW$
                    Replace point texts: .tier, 1, 0, " ", text$+" ", "literals"
                elif placement$ = remove$
                    Replace point texts: .tier, 1, 0, text$, "", "literals"
                endif
                
                for i to n
                    label$ = Get label of point: .tier, i
                    if label$ = "" and empty_skip
                        appendInfoLine: "Empty point skipped:"
                        appendInfoLine: tab$+"Grid ",gi," '"+g_name$+"', Tier ",.tier," '"+name$+"', Point ",i,""
                    elif text_style and startsWith (label$, text$)
                        appendInfoLine: "Point already starting with '"+text$+"' skipped:"
                        appendInfoLine: tab$+"Grid ",gi," '"+g_name$+"', Tier ",.tier," '"+name$+"', Point ",i," '"+label$+"'"
                    elif placement$ = startIP$ or placement$ = startW$
                        Set point text: .tier, i, text$+label$
                        edit += 1
                    elif placement$ = endIP$ or placement$ = endW$
                        Set point text: .tier, i, label$+text$
                        edit += 1
                    endif
                endfor
            endif
            
        endif
    endproc
    
###----------------------------------------
### Return to original selection

    procedure originalSelection:
        for gi to grid_num
            plusObject: grid[gi]
        endfor
        if other_num <> 0
            for j to other_num
                plusObject: other[j]
            endfor
        endif
    endproc