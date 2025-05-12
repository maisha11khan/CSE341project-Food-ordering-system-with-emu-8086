.model small
.stack 100h
.data
    ; Authentication data
    username db 20 dup('$')
    password db 20 dup('$')
    input_username db 20 dup('$')
    input_password db 20 dup('$')

    ; Messages
    enterUsernameMsg db 'Enter username: $'
    enterPasswordMsg db 0Dh,0Ah, 'Enter password: $'
    loginSuccessMsg db 0Dh,0Ah,'Login successful!$'
    invalidLoginMsg db 0Dh,0Ah,'Invalid login. Try again.$'
    mainMenuMsg db 0Dh,0Ah,'1. Register',0Dh,0Ah,'2. Login',0Dh,0Ah,'3. Search',0Dh,0Ah,'Enter your choice: $'
    regSuccessMsg db 0Dh,0Ah,'Registration successful!$'

    ; Menu Categories
    promptCategory db 0Dh,0Ah,'Select a category:',0Dh,0Ah,'1. Breakfast',0Dh,0Ah,'2. Lunch',0Dh,0Ah,'3. Dinner',0Dh,0Ah,'4. Snacks',0Dh,0Ah,'5. Drinks',0Dh,0Ah,'6. View Bill',0Dh,0Ah,'7. Exit',0Dh,0Ah,'Enter your choice: $'
    
    ; Menu Items with prices
    breakfastItems db 0Dh,0Ah,'Breakfast Menu:',0Dh,0Ah,'1. Eggs - Rs.50',0Dh,0Ah,'2. Toast - Rs.30',0Dh,0Ah,'3. Paratha - Rs.40',0Dh,0Ah,'Enter item number to order (0 to go back): $'
    lunchItems db 0Dh,0Ah,'Lunch Menu:',0Dh,0Ah,'1. Biryani - Rs.120',0Dh,0Ah,'2. Karahi - Rs.250',0Dh,0Ah,'3. Daal - Rs.100',0Dh,0Ah,'Enter item number to order (0 to go back): $'
    dinnerItems db 0Dh,0Ah,'Dinner Menu:',0Dh,0Ah,'1. Roti - Rs.10',0Dh,0Ah,'2. Chicken - Rs.200',0Dh,0Ah,'3. Veggies - Rs.150',0Dh,0Ah,'Enter item number to order (0 to go back): $'
    snacksItems db 0Dh,0Ah,'Snacks Menu:',0Dh,0Ah,'1. Samosa - Rs.20',0Dh,0Ah,'2. Pakora - Rs.30',0Dh,0Ah,'3. Chips - Rs.25',0Dh,0Ah,'Enter item number to order (0 to go back): $'
    drinksItems db 0Dh,0Ah,'Drinks Menu:',0Dh,0Ah,'1. Tea - Rs.20',0Dh,0Ah,'2. Coffee - Rs.50',0Dh,0Ah,'3. Juice - Rs.40',0Dh,0Ah,'Enter item number to order (0 to go back): $'

    ; Bill related messages
    billMsg db 0Dh,0Ah,'Your current bill: Rs.$'
    totalBillMsg db 0Dh,0Ah,'Total Bill: Rs.$'
    quantityMsg db 0Dh,0Ah,'Enter quantity: $'
    itemAddedMsg db 0Dh,0Ah,'Item added to bill!$'
    feedbackMsg db 0Dh,0Ah,'Please provide feedback (1-5): $'
    thankYouMsg db 0Dh,0Ah,'Thank you for your order!$'

    ; Buffers
    buffer db 20 dup('$')
    quantity db 0
    totalBill dw 0
    currentItemPrice dw 0
    currentCategory db 0

    ; Price tables for each category
    breakfastPrices dw 50, 30, 40    ; Eggs, Toast, Paratha
    lunchPrices dw 120, 250, 100     ; Biryani, Karahi, Daal
    dinnerPrices dw 10, 200, 150     ; Roti, Chicken, Veggies
    snacksPrices dw 20, 30, 25       ; Samosa, Pakora, Chips
    drinksPrices dw 20, 50, 40       ; Tea, Coffee, Juice

    ; Search related data
    search_buffer db 20 dup('$')
    search_prompt db 0Dh,0Ah,'Enter search term: $'
    search_not_found db 0Dh,0Ah,'Item not found.$'
    search_found db 0Dh,0Ah,'Found: $'
    order_prompt db 0Dh,0Ah,'Would you like to order this item? (Y/N): $'
    item_category db 0   ; Store category of found item
    item_number db 0     ; Store item number within category

    ; Feedback related data
    feedback_buffer db 100 dup('$')  ; Increased buffer size for full sentences
    feedback_prompt db 0Dh,0Ah,'Please enter your feedback (press Enter when done): $'
    feedback_thank_you db 0Dh,0Ah,'Thank you for your feedback!$'

    ; Login status
    is_logged_in db 0  ; Flag to track login status

.code
    ; --- Helper Procedures ---
    printString proc
        mov ah, 09h
        int 21h
        ret
    printString endp

    getChar proc
        mov ah, 01h
        int 21h
        ret
    getChar endp

    readString proc
        mov cx, 0
    read_loop:
        call getChar
        cmp al, 0Dh ; Enter key
        je end_read
        mov [di], al
        inc di
        inc cx
        cmp cx, 19
        je end_read
        jmp read_loop
    end_read:
        mov [di], '$'
        ret
    readString endp

    compareStrings proc
        ; si -> string1, di -> string2
    nextChar:
        mov al, [si]
        cmp al, [di]
        jne notEqual
        cmp al, '$'
        je stringsEqual
        inc si
        inc di
        jmp nextChar
    stringsEqual:
        mov ax, 0
        ret
    notEqual:
        mov ax, 1
        ret
    compareStrings endp

    printNumber proc
        ; Print a 16-bit number in AX
        mov bx, 10
        mov cx, 0
    divide:
        mov dx, 0
        div bx
        push dx
        inc cx
        cmp ax, 0
        jne divide
    print:
        pop dx
        add dl, '0'
        mov ah, 02h
        int 21h
        loop print
        ret
    printNumber endp

    getQuantity proc
        lea dx, quantityMsg
        call printString
        call getChar
        sub al, '0'
        mov quantity, al
        ret
    getQuantity endp

    calculateBill proc
        ; Calculate item price based on selection and category
        mov ax, 0
        mov al, bl
        dec al
        mov bx, ax
        shl bx, 1  ; Multiply by 2 for word size
        
        ; Get the appropriate price based on current category
        mov ax, 0
        cmp currentCategory, 1
        je breakfastPrice
        cmp currentCategory, 2
        je lunchPrice
        cmp currentCategory, 3
        je dinnerPrice
        cmp currentCategory, 4
        je snacksPrice
        cmp currentCategory, 5
        je drinksPrice
        
    breakfastPrice:
        mov ax, breakfastPrices[bx]
        jmp calculateTotal
    lunchPrice:
        mov ax, lunchPrices[bx]
        jmp calculateTotal
    dinnerPrice:
        mov ax, dinnerPrices[bx]
        jmp calculateTotal
    snacksPrice:
        mov ax, snacksPrices[bx]
        jmp calculateTotal
    drinksPrice:
        mov ax, drinksPrices[bx]
        
    calculateTotal:
        ; Multiply price by quantity
        mov dl, quantity
        mov dh, 0
        mul dx
        add totalBill, ax
        
        lea dx, itemAddedMsg
        call printString
        ret
    calculateBill endp

    ; Helper procedure to convert character to uppercase
    to_uppercase proc
        cmp al, 'a'
        jb not_lowercase
        cmp al, 'z'
        ja not_lowercase
        sub al, 32
    not_lowercase:
        ret
    to_uppercase endp

    ; Helper procedure to search in a category
    search_in_category proc
        ; si -> category items string
        ; di -> search term
        ; dl -> category number (1-5)
        push si
        push di
        push dx  ; Save category number
        
        mov item_category, dl  ; Store category for later use
        
    search_loop:
        mov al, [si]
        cmp al, '$'
        je not_found
        
        ; Check for item number prefixes (1., 2., 3.)
        cmp al, '1'
        je check_item_number
        cmp al, '2'
        je check_item_number
        cmp al, '3'
        je check_item_number
        
        inc si
        jmp search_loop
        
    check_item_number:
        ; Store the item number
        mov item_number, al
        sub item_number, '0'  ; Convert from ASCII
        
        ; Skip to the item name (after number and period)
        inc si  ; Skip number
        inc si  ; Skip period
        inc si  ; Skip space
        
        ; Now we're at the start of the item name
        ; Start comparison with search term
        push si  ; Save the start position of the item name
        push di  ; Save the search term pointer
        
    compare_item_name:
        mov al, [di]  ; Get search term character
        cmp al, '$'   ; End of search term?
        je name_matches
        
        mov bl, [si]  ; Get menu item character
        
        ; Skip to next word if we hit space or '-'
        cmp bl, ' '
        je next_word
        cmp bl, '-'
        je next_word
        
        ; Convert both to uppercase for case-insensitive comparison
        mov al, [di]
        call to_uppercase
        mov ah, al
        
        mov al, bl
        call to_uppercase
        
        ; Compare the characters
        cmp ah, al
        jne no_match
        
        ; Characters match, continue
        inc si
        inc di
        jmp compare_item_name
        
    next_word:
        ; Skip until next word or end
        pop di  ; Restore search term
        inc si  ; Move past current character
        
    find_next_word:
        mov al, [si]
        cmp al, ' '
        je skip_char
        cmp al, '-'
        je skip_char
        jmp compare_item_name_restart
        
    skip_char:
        inc si
        jmp find_next_word
        
    compare_item_name_restart:
        push si
        push di
        jmp compare_item_name
        
    name_matches:
        ; Found a match
        pop di  ; Clean stack
        pop si  ; Get back the start of the item name
        pop dx  ; Clean stack
        pop di  ; Clean stack 
        pop si  ; Clean stack
        mov ax, 1  ; Return 1 for found
        ret
        
    no_match:
        ; No match, restore positions and continue search
        pop di
        pop si
        
        ; Skip to next item line
    skip_to_next_line:
        mov al, [si]
        cmp al, '$'
        je not_found
        cmp al, 0Dh  ; Carriage return
        je found_line_end
        inc si
        jmp skip_to_next_line
        
    found_line_end:
        inc si  ; Skip CR
        cmp byte ptr [si], 0Ah  ; Check for LF
        jne search_loop
        inc si  ; Skip LF
        jmp search_loop
        
    not_found:
        pop dx  ; Clean stack
        pop di  ; Clean stack
        pop si  ; Clean stack
        mov ax, 0  ; Return 0 for not found
        ret
    search_in_category endp

main proc
    mov ax, @data
    mov ds, ax
    mov is_logged_in, 0  ; Initialize login status

    jmp mainMenu

    ; --- Main Program Flow ---
mainMenu:
    ; Display main menu
    lea dx, mainMenuMsg
    call printString

    ; Get user choice
    call getChar
    cmp al, '1'
    je registerUser
    cmp al, '2'
    je loginUser
    cmp al, '3'  ; Search option
    je searchItem
    jmp mainMenu

registerUser:
    ; Register Username
    lea dx, enterUsernameMsg
    call printString
    lea di, username
    call readString

    ; Register Password
    lea dx, enterPasswordMsg
    call printString
    lea di, password
    call readString

    ; Success Message
    lea dx, regSuccessMsg
    call printString
    jmp mainMenu

loginUser:
    ; Ask for username
    lea dx, enterUsernameMsg
    call printString
    lea di, buffer
    call readString
    lea si, username
    lea di, buffer
    call compareStrings
    jnz invalidLogin

    ; Ask for password
    lea dx, enterPasswordMsg
    call printString
    lea di, buffer
    call readString
    lea si, password
    lea di, buffer
    call compareStrings
    jnz invalidLogin

    ; Success
    mov is_logged_in, 1
    lea dx, loginSuccessMsg
    call printString
    jmp showMenu

invalidLogin:
    lea dx, invalidLoginMsg
    call printString
    jmp mainMenu

showMenu:
    ; Check login status
    cmp is_logged_in, 1
    je show_menu_options
    jmp mainMenu  ; If not logged in, return to main menu

show_menu_options:
    ; Display current bill
    lea dx, billMsg
    call printString
    mov ax, totalBill
    call printNumber

    ; Show category menu
    lea dx, promptCategory
    call printString
    call getChar

    cmp al, '1'
    je showBreakfast
    cmp al, '2'
    je showLunch
    cmp al, '3'
    je showDinner
    cmp al, '4'
    je showSnacks
    cmp al, '5'
    je showDrinks
    cmp al, '6'
    je showBill
    cmp al, '7'
    je exitProgram
    cmp al, '8'
    je searchItem
    jmp showMenu

showBreakfast:
    mov currentCategory, 1
    lea dx, breakfastItems
    call printString
    call getChar
    cmp al, '0'
    je showMenu
    sub al, '0'
    mov bl, al
    call getQuantity
    call calculateBill
    jmp showBreakfast

showLunch:
    mov currentCategory, 2
    lea dx, lunchItems
    call printString
    call getChar
    cmp al, '0'
    je showMenu
    sub al, '0'
    mov bl, al
    call getQuantity
    call calculateBill
    jmp showLunch

showDinner:
    mov currentCategory, 3
    lea dx, dinnerItems
    call printString
    call getChar
    cmp al, '0'
    je showMenu
    sub al, '0'
    mov bl, al
    call getQuantity
    call calculateBill
    jmp showDinner

showSnacks:
    mov currentCategory, 4
    lea dx, snacksItems
    call printString
    call getChar
    cmp al, '0'
    je showMenu
    sub al, '0'
    mov bl, al
    call getQuantity
    call calculateBill
    jmp showSnacks

showDrinks:
    mov currentCategory, 5
    lea dx, drinksItems
    call printString
    call getChar
    cmp al, '0'
    je showMenu
    sub al, '0'
    mov bl, al
    call getQuantity
    call calculateBill
    jmp showDrinks

showBill:
    lea dx, totalBillMsg
    call printString
    mov ax, totalBill
    call printNumber
    
    ; Get feedback with full sentence support
    lea dx, feedback_prompt
    call printString
    lea di, feedback_buffer
    call readString
    
    lea dx, feedback_thank_you
    call printString
    jmp exitProgram

searchItem:
    ; Get search term
    lea dx, search_prompt
    call printString
    lea di, search_buffer
    call readString

    ; Search in each category (pass category number in dl)
    lea si, breakfastItems
    lea di, search_buffer
    mov dl, 1  ; Category 1 - Breakfast
    call search_in_category
    cmp ax, 1
    je found_item

    lea si, lunchItems
    lea di, search_buffer
    mov dl, 2  ; Category 2 - Lunch
    call search_in_category
    cmp ax, 1
    je found_item

    lea si, dinnerItems
    lea di, search_buffer
    mov dl, 3  ; Category 3 - Dinner
    call search_in_category
    cmp ax, 1
    je found_item

    lea si, snacksItems
    lea di, search_buffer
    mov dl, 4  ; Category 4 - Snacks
    call search_in_category
    cmp ax, 1
    je found_item

    lea si, drinksItems
    lea di, search_buffer
    mov dl, 5  ; Category 5 - Drinks
    call search_in_category
    cmp ax, 1
    je found_item

    ; Item not found
    lea dx, search_not_found
    call printString
    
    ; Check if user is logged in
    cmp is_logged_in, 1
    je showMenu  ; If logged in, go to menu
    jmp mainMenu ; If not logged in, return to main menu

found_item:
    ; Display found message
    lea dx, search_found
    call printString
    
    ; Now display item details based on category and item number
    mov dl, item_category  ; Get category
    mov bl, item_number    ; Get item number
    
    ; Select the appropriate category items
    cmp dl, 1
    je show_breakfast_item
    cmp dl, 2
    je show_lunch_item
    cmp dl, 3
    je show_dinner_item
    cmp dl, 4
    je show_snacks_item
    cmp dl, 5
    je show_drinks_item
    jmp item_shown  ; Shouldn't get here
    
show_breakfast_item:
    lea si, breakfastItems
    jmp find_item_line
    
show_lunch_item:
    lea si, lunchItems
    jmp find_item_line
    
show_dinner_item:
    lea si, dinnerItems
    jmp find_item_line
    
show_snacks_item:
    lea si, snacksItems
    jmp find_item_line
    
show_drinks_item:
    lea si, drinksItems
    
find_item_line:
    ; Find the line with the correct item number
    mov al, [si]
    cmp al, '$'
    je item_shown  ; End of string, shouldn't happen
    
    cmp al, bl
    je found_item_line  ; Found our item number
    
    ; Skip to next line
skip_line:
    mov al, [si]
    cmp al, 0Dh  ; CR
    je line_end
    cmp al, '$'
    je item_shown
    inc si
    jmp skip_line
    
line_end:
    inc si  ; Skip CR
    cmp byte ptr [si], 0Ah  ; Check for LF
    jne find_item_line
    inc si  ; Skip LF
    jmp find_item_line
    
found_item_line:
    ; Skip the item number, period, and space
    inc si  ; Skip number
    inc si  ; Skip period
    inc si  ; Skip space
    
    ; Print the item name and price
print_item_line:
    mov al, [si]
    cmp al, 0Dh  ; End of line
    je end_item_print
    cmp al, '$'  ; End of string
    je end_item_print
    
    ; Print character
    mov dl, al
    mov ah, 02h
    int 21h
    
    inc si
    jmp print_item_line
    
end_item_print:
    ; New line
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    int 21h
    
    ; Ask if user wants to order this item
    lea dx, order_prompt
    call printString
    call getChar
    
    cmp al, 'Y'
    je order_found_item
    cmp al, 'y'
    je order_found_item
    
    ; If not ordering, go back to menu
    jmp item_shown
    
order_found_item:
    ; Set category and process the order
    mov al, item_category
    mov currentCategory, al
    mov al, item_number
    mov bl, al
    
    ; Get quantity and add to bill
    call getQuantity
    call calculateBill
    
item_shown:
    ; Check if user is logged in
    cmp is_logged_in, 1
    je showMenu  ; If logged in, go to menu
    jmp mainMenu ; If not logged in, return to main menu

exitProgram:
    mov ah, 4ch
    int 21h

main endp
end main