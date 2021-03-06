# Tim Henderson & Daniel DeCovnick
# proc_storage.s handles storing proccess in PCBs
#
# Proccess Control Block Structure:
# --------------------
# | State            | 0
# --------------------
# | Process Number   | 1
# --------------------
# | Program Counter  | 2
# --------------------
# | HCB Address      | 3
# | Stack ID         | 4
# | Top Data Addr    | 5
# --------------------
# | at               | 6
# | sp               | 7
# | fp               | 8
# | gp               | 9
# | ra               | 10
# | v0               | 11
# | v1               | 12
# | a0               | 13
# | ...              |
# | a3               | 16
# | t0               | 17
# | ...              |
# | t9               | 26
# | s0               | 27
# | ...              |
# | s7               | 34
# --------------------

# states:
# 0 -> new
# 1 -> ready
# 2 -> running
# 3 -> waiting
# 4 -> halted
# 5 -> marked for clean up

# Note: These states are not actually used.

    .data
pcb_size: .word 0x8c            # 140 = 35 * 4
next_proc_num: .word 0x0        # start proccess number at 0

    .text
    # create_pcb() return $v0 -> addr of pcb
create_pcb:
{
    @mem_id = $s0
    @hcb_addr = $s1
    lw   $a0 pcb_size
    khcb_getaddr $a1
    call alloc
    addu @mem_id $v0 $zero
    addu @hcb_addr $v1 $zero
    khcb_writeback @hcb_addr
    
    addu $v0 @mem_id $zero #because kchb_writeback could clobber $v0
    return
}
    # save_proc(mem_id, status)  -> Null
save_proc:
{
    @hcb_addr = $s0
    @mem_id = $s1
    @loc = $t0
    @status = $s2
    @error = $t1
    @temp = $t2
    addu    @mem_id  $a0  $zero     # move the address of the mem_id to $t0
    addu    @status  $a1  $zero
    khcb_getaddr @hcb_addr
    
#     print_hcb @hcb_addr
#     addu $a0 @mem_id $zero
#     call print_int
#     li $a0 10
#     call print_char
    
    li      @loc 0
    put     @loc @mem_id @hcb_addr @status @error
    bne     @error $zero put_error
    
    mfc0    @temp  $14          # get the EPC register
    li      @loc 2
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error

    
#     la      @temp  __save_HCB_ADDR
#     lw      @temp 0(@temp)
#     #lw      $t1  __save_HCB_ADDR
#     li      @loc 3
#     put     @loc @mem_id @hcb_addr @temp @error
#     bne     @error $zero put_error
    
 
    lw      @temp  __save_at      # load the saved $at reg
    li      @loc 6
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  24($t0)        # save it in the PCB
    
    lw      @temp  __save_sp      # load the saved stack pointer
    li      @loc 7
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  28($t0)        # save it in the PCB
    
    lw      @temp  __save_fp      # load the saved frame pointer
    li      @loc 8
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  32($t0)        # save it in the PCB
    
    lw      @temp  __save_gp      # load the saved global pointer
    li      @loc 9
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  36($t0)        # save it in the PCB
    
    lw      @temp  __save_ra      # load the saved return address pointer
    li      @loc 10
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  40($t0)        # save it in the PCB
    
    lw      @temp  __save_v0      # load the saved $v0
    li      @loc 11
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  44($t0)        # save it in the PCB
    
    lw      @temp  __save_v1      # load the saved $v1
    li      @loc 12
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  48($t0)        # save it in the PCB
    
    lw      @temp  __save_a0      # load the saved $a0
    li      @loc 13
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  52($t0)        # save it in the PCB
    
    lw      @temp  __save_a1      # load the saved $a1
    li      @loc 14
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  56($t0)        # save it in the PCB
    
    lw      @temp  __save_a2      # load the saved $a2
    li      @loc 15
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  60($t0)        # save it in the PCB
    
    lw      @temp  __save_a3      # load the saved $a3
    li      @loc 16
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  64($t0)        # save it in the PCB
    
    lw      @temp  __save_t0      # load the saved $t0
    li      @loc 17
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  68($t0)        # save it in the PCB
    
    lw      @temp  __save_t1      # load the saved $t1
    li      @loc 18
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  72($t0)        # save it in the PCB
    
    lw      @temp  __save_t2      # load the saved $t2
    li      @loc 19
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  76($t0)        # save it in the PCB
    
    lw      @temp  __save_t3      # load the saved $t3
    li      @loc 20
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  80($t0)        # save it in the PCB
    
    lw      @temp  __save_t4      # load the saved $t3
    puti    21 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_t5      # load the saved $t3
    puti    22 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_t6      # load the saved $t3
    puti    23 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_t7      # load the saved $t3
    puti    24 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_t8      # load the saved $t3
    puti    25 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_t9      # load the saved $t3
    puti    26 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error

    #sw      $t4  84($t0)        # save $t4 in the PCB
    #sw      $t5  88($t0)        # save $t5 in the PCB
    #sw      $t6  92($t0)        # save $t6 in the PCB
    #sw      $t7  96($t0)        # save $t7 in the PCB
    #sw      $t8  100($t0)        # save $t8 in the PCB
    #sw      $t9  104($t0)       # save $t9 in the PCB
    
    lw      @temp  __save_s0      # load the saved $s0
    li      @loc 27
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  108($t0)       # save it in the PCB
    
    lw      @temp  __save_s1      # load the saved $s1
    li      @loc 28
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  112($t0)       # save it in the PCB
    
    lw      @temp  __save_s2      # load the saved $s2
    li      @loc 29
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  116($t0)       # save it in the PCB
    
    lw      @temp  __save_s3      # load the saved $s3
    li      @loc 30
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1  120($t0)       # save it in the PCB
    
    
    lw      @temp  __save_s4      # load the saved $s3
    puti    31 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_s5      # load the saved $s3
    puti    32 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_s6      # load the saved $s3
    puti    33 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    
    lw      @temp  __save_s7      # load the saved $s3
    puti    34 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error

    
    #sw      $s4  124($t0)       # save $s4 in the PCB
    #sw      $s5  128($t0)       # save $s5 in the PCB
    #sw      $s6  132($t0)       # save $s6 in the PCB
    #sw      $s7  136($t0)       # save $s7 in the PCB
    #sw      $t1  28($t0)        # save it in the PCB
    
    return
put_error:
    println  horrible_error
    exit
.data
horrible_error: .asciiz "Something really bad happened when trying to save the PCB\n"
.text
}
    
# new_proc(data_amt) -> Null
#     data_amt = the amount of room this proccess gets for its heap and stack. static can't change.
new_proc:
{
    @mem_id = $s0
    @temp = $t1
    @loc = $s1
    @hcb_addr = $s2
    @error = $t2
    call create_pcb             # create a process control block
    add     @hcb_addr $v1 $zero
    add     @mem_id $v0 $0          # save the pcb addr into $s0
    
    
    lw      @temp next_proc_num   # load the next proccess number into $t1
    li      @loc 1
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1 4($s0)          # save the proc number in the pcb
    addi    @temp @temp 1           # increment the next_proc_num
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1 next_proc_num   # save it
    
    mfc0    @temp $14             # get the EPC register
    li      @loc 2
    put     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #sw      $t1 8($s0)          # save the program counter number in the pcb
    
    addu    $a0 @mem_id $0          # load pcb_addr into arg1
    li      $a1 0               # load a default status of 0 "new" into arg2
    call    save_proc
    
    return
put_error:
    println  horrible_error
    exit
.data
horrible_error: .asciiz "Something really bad happened when trying to create a new process\n"
.text
}
    
    # restore_proc(mem_id) -> Nul
restore_proc:
{
    @hcb_addr = $s0
    @mem_id = $s1
    @loc = $t0
    @error = $t1
    @temp = $t2
    
    addu    @mem_id  $a0  0         # move the address of the mem_id to $t0
    khcb_getaddr @hcb_addr

    li      @loc 2
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    #lw      $t1  8($t0)         # get the program counter from pcb
    mtc0    @temp  $14            # save it in the EPC register in the co-proc
    
#     #lw      $t1  12($t0)        # load the hcb_addr into the pcb
#     li      @loc 3
#     get     @loc @mem_id @hcb_addr @temp @error
#     bne     @error $zero put_error
#     sw      @temp  __save_HCB_ADDR
    
    
    #lw      $t1  24($t0)        # load the saved $at reg
    li      @loc 6
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_at      # 
    
    #lw      $t1  28($t0)        # load the saved stack pointer
    li      @loc 7
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_sp      # save it into its imm location
    
    #lw      $t1  32($t0)        # load the saved frame pointer
    li      @loc 8
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error

    sw      @temp  __save_fp      # save it into its imm location
    
    #lw      $t1  36($t0)        # load the saved global pointer
    li      @loc 9
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_gp      # 
    
    #lw      $t1  40($t0)        # load the saved return address pointer
    li      @loc 10
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_ra      # 
    
    #lw      $t1  44($t0)        # load the saved $v0
    li      @loc 11
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_v0      # 
    
    #lw      $t1  48($t0)        # load the saved $v1
    li      @loc 12
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_v1      # 
    
    #lw      $t1  52($t0)        # load the saved $a0
    li      @loc 13
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_a0      # 
    
    #lw      $t1  56($t0)        # load the saved $a1
    li      @loc 14
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_a1      # 
    
    #lw      $t1  60($t0)        # load the saved $a2
    li      @loc 15
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_a2      # 
    
    #lw      $t1  64($t0)        # load the saved $a3
    li      @loc 16
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_a3      # 
    
    #lw      $t1  68($t0)        # load the saved $t0
    li      @loc 17
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t0      #
    
    #lw      $t1  72($t0)        # load the saved $t1
    li      @loc 18
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t1      # 
    
    #lw      $t1  76($t0)        # load the saved $t2
    li      @loc 19
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t2      #
    
    #lw      $t1  80($t0)        # load the saved $t3
    li      @loc 20
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t3      # 
    
    #lw      $t4  84($t0)        # load $t4 from the PCB
    #lw      $t5  88($t0)        # load $t5 from the PCB
    #lw      $t6  92($t0)        # load $t6 from the PCB
    #lw      $t7  96($t0)        # load $t7 from the PCB
    #lw      $t8  100($t0)        # load $t8 from the PCB
    #lw      $t9  104($t0)       # load $t9 from the PCB
    
    
    geti    21 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t4
    
    geti    22 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t5
    
    geti    23 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t6
    
    geti    24 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t7
    
    geti    25 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t8
    
    geti    26 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_t9

    #lw      $t1  108($t0)       # load the saved $s0
    li      @loc 27
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s0      # 
    
    #lw      $t1  __save_s1      # load the saved $s1
    li      @loc 28
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s1       #
    
    #lw      $t1  116($t0)       # load the saved $s2
    li      @loc 29
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s2      # 
    
    #lw      $t1  120($t0)       # load the saved $s3
    li      @loc 30
    get     @loc @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s3
    
    #lw      $s4  124($t0)       # load $s4 from the PCB
    #lw      $s5  128($t0)       # load $s5 from the PCB
    #lw      $s6  132($t0)       # load $s6 from the PCB
    #lw      $s7  136($t0)       # load $s7 from the PCB
    geti    31 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s4
    
    geti    32 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s5
    
    geti    33 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s6
    
    geti    34 @mem_id @hcb_addr @temp @error
    bne     @error $zero put_error
    sw      @temp  __save_s7
    
    return
put_error:
    println  horrible_error
    exit
.data
horrible_error: .asciiz "Something really bad happened when trying to restore the PCB\n"
.text
}   

.text
.globl getuserheap
# getuserheap() --> $v0 = userheap_addr
getuserheap:
{
    @khcb_addr = $s0
    @pcb_id = $s1
    @userheap_addr = $s2
    @temp = $t0
    @err = $t1
    
    khcb_getaddr @khcb_addr
    la      @temp current_pcb
    lw      @pcb_id 0(@temp)
    
    geti    0x3 @pcb_id @khcb_addr @userheap_addr @err
    bne     @err $0 get_error
    
    addu    $v0 @userheap_addr $0
    return

    get_error:
        println get_error_msg
        addu    $v0 $0 $0
        return
    
    .data
        get_error_msg: .asciiz "get error in getuserheap"
    .text
}

.text
.globl putuserheap
# putuserheap(userheap_addr)
putuserheap:
{
    @khcb_addr = $s0
    @pcb_id = $s1
    @userheap_addr = $s2
    @temp = $t0
    @err = $t1
    
    addu    @userheap_addr $a0 $0
    
    khcb_getaddr @khcb_addr
    la      @temp current_pcb
    lw      @pcb_id 0(@temp)
    
    puti    0x3 @pcb_id @khcb_addr @userheap_addr @err
    bne     @err $0 put_error
    
    return

    put_error:
        println put_error_msg
        return
    
    .data
        put_error_msg: .asciiz "put error in putuserheap"
    .text
}
