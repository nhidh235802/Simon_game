.data
.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014
.eqv MONITOR_SCREEN 0x10010000 # Dia chi bat dau cua bo nho man hinh
.eqv RED 0x00FF0000 
.eqv GREEN 0x0000FF00
.eqv BLUE 0x000000FF
.eqv WHITE 0x00FFFFFF
.eqv YELLOW 0x00FFFF00
simon: .space 100         # Day simon
printf: .asciz "\nInput your answer (Green = 1, Red = 2, Yellow = 3, Blue = 4): "
right: .asciz "\nCorrect\n"
wrong:       .asciz "\nGame Over. "
hint:      .asciz "\nHINT: \n "
.text

main:
NGAT: 					# Xu ly ngat khi nhap tu KEYPAD
la t0, handler				# Load the interrupt service routine address to the UTVEC register
csrrs zero, utvec, t0
# Set the UEIE (User External Interrupt Enable) bit in UIE register
li t1, 0x100
csrrs zero, uie, t1 			# uie - ueie bit (bit 8)
# Set the UIE (User Interrupt Enable) bit in USTATUS register
csrrsi zero, ustatus, 1 		# ustatus - enable uie (bit 0)
# Enable the interrupt of keypad of Digital Lab Sim
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t5, 0x80 				# bit 7 = 1 to enable interrupt
sb t5, 0(t1)

simon_game:
li s0, 0              			# s0 = 0  -> s0 la n, do dai cua day simon
la s1, simon      			# s1 = A[0]
addi s1,s1,-100			# giam dia chi day simon di 100 
# Li do giam di 100: tranh va cham dia chi day simon voi dia chi cua monitor screen => RAT QUAN TRONG

game_loop:
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh:
li s3, GREEN				# 	GREEN		|	RED
sw s3, 0(s2)				#	---------------------|------------------
li s3, RED				# 	YELLOW 	 |	BLUE
sw s3, 4(s2)
li s3, YELLOW
sw s3, 8(s2)
li s3, BLUE

sw s3, 12(s2)	
addi a7, zero, 32
li a0, 500 					# Sleep 300 ms
# sinh so bat ki ( em dung 'pseudo random' bang cach lay thoi gian roi chia cho 4, lay so du + 1 )
random_generator: 
li a7, 30             			# syscall 30: lay thoi gian
ecall                 
li t0, 4
rem t1, a0, t0       			# t1 = a0 % 4  => random number: 0 -> 3
addi t1,t1,1				# t1++ 		=>random number: 1 -> 4
# Luu vao day simon
add t2, s1, s0
sb t1, 0(t2)
# EM DE CAI HINT O DAY DE KHI CHAM BAI CHO NO DE NHO HON THOI
HINT:
# In Hint					
li a7, 4
la a0, hint
ecall
li t3, 0              				# Dat t3 la 'i' -> simon[i]

print_loop:
bgt t3, s0, end_print 		# i > n thi ket thuc vong lap -> end_print
add t4, s1, t3				# t4 dia chi simon[0] + i
lb a0, 0(t4)         			# a0 = simon[i]
add s4,a0,zero			# s4 = a0
li a7, 1					# In simon[i] ra man hinh
ecall                 			
li a0, ' '           				# In space
li a7, 11
ecall

print_color_to_screen: 		# xet s4 voi s5
li s5,1
beq s4, s5,equal_1			# s4 = 1 -> Thay doi nut GREEN
li s5,2
beq s4, s5,equal_2			# s4 = 2 -> Thay doi nut RED
li s5,3
beq s4, s5,equal_3			# s4 = 3 -> Thay doi nut YELLOW
li s5,4
beq s4, s5,equal_4			# s4 = 4 -> Thay doi nut BLUE

# Bitmap: GREEN -> WHITE -> GREEN    
equal_1:
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, WHITE
sw s3, 0(s2)
li a0, 1000  		 		# delay 1000ms
li a7, 32     				# syscall 32 = sleep
ecall
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, GREEN
sw s3, 0(s2)
j out_equal

# Bitmap: RED -> WHITE -> RED
equal_2:
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, WHITE
sw s3, 4(s2)
li a0, 1000   				# delay 1000ms
li a7, 32     				# syscall 32 = sleep
ecall
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, RED
sw s3, 4(s2)
j out_equal

# Bitmap: YELLOW -> WHITE -> YELLOW
equal_3:
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, WHITE
sw s3, 8(s2)
li a0, 1000   				# delay 1000ms
li a7, 32     				# syscall 32 = sleep
ecall
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, YELLOW
sw s3, 8(s2)
j out_equal

# Bitmap: BLUE -> WHITE -> BLUE
equal_4:
li s2, MONITOR_SCREEN	# Nap dia chi bat dau cua man hinh
li s3, WHITE
sw s3, 12(s2)
li a0, 1000   				# delay 1000ms
li a7, 32     				# syscall 32 = sleep
ecall
li s2, MONITOR_SCREEN 	# Nap dia chi bat dau cua man hinh
li s3, BLUE
sw s3, 12(s2)
j out_equal

out_equal:
li a0, 1000   				# delay 1000ms
li a7, 32     				# syscall 32 = sleep
ecall
addi t3, t3, 1				# i++
j print_loop

end_print:				# Ket thuc in ra man hinh hint va bitmap
addi s0, s0, 1 				#n++


player_input: 
li a7, 4
la a0, printf				# In huong dan
ecall
    
li t3, 0              				# Dat t3 la 'i' -> xét so thu i trong day nhap cua nguoi choi va simon[i]
check_input:
li t6,0
bge t3, s0, correct_input		# Neu i > n thi  ( neu dung het chuoi simon) thi ket thuc vong, tiep tuc vong tiep theo 

input_keypad:
li t5,0
# ---------------------------------------------------------
# Loop to print a sequence numbers
# ---------------------------------------------------------
loop_keypad:				# Cho input cua ng choi
addi a7, zero, 32
li a0, 300 					# Sleep 300 ms
ecall
bgt t6, zero, done_keypad	# Neu t6 > 0 -> Nguoi choi da nhap thanh cong
j loop_keypad

done_keypad:			# Xet so nhap tu keypad => Doi tu hexa -> deca
li s5, 0x00000021
beq t5, s5,equal_one		# Xet s5 = 0x00000021 -> t5 = 1
li s5, 0x00000041
beq t5, s5,equal_two		# Xet s5 = 0x00000041 -> t5 = 2
li s5, 0xffffff81
beq t5, s5,equal_three		# Xet s5 = 0xffffff81      -> t5 = 3
li s5, 0x00000012
beq t5, s5,equal_four    		# Xet s5 = 0x00000012 -> t5 = 4

equal_one:				# t5 = 1
li t5,1
j compare
equal_two:				# t5 = 2
li t5,2
j compare
equal_three:				# t5 = 3
li t5,3
j compare
equal_four:				# t5 = 4
li t5,4
j compare

compare:     
add a0,t5,zero				# a0 = t5
li a7,1			
ecall						# in ra a0 de cho nguoi choi biet minh dang o so nao
li a7, 11
li a0, ' ' 					
ecall

# So sánh so ng choi nhap va simon[i]
add t4, s1, t3				# t4 = dia chi cua simon[i]
lbu t6, 0(t4)				# t6 = simon[i]

bne t6, t5, game_over		# Neu t5 != t6 -> Avengers: Endgame
addi t3, t3, 1				# i++
j check_input

correct_input:				# Nhap dung -> vong tiep theo, dai hon 1 so 
li a7, 4
la a0, right				# in ra ket qua dung
ecall
j game_loop				# vong choi moi

game_over:				# end game
li a7, 4
la a0, wrong
ecall
li a7, 10
ecall

# -----------------------------------------------------------------
# Interrupt service routine
# -----------------------------------------------------------------

handler:
# Saves the context
addi sp, sp, -24
sw a0, 0(sp)
sw a7, 4(sp)
sw t1, 8(sp)
sw t2, 12(sp)
sw t3, 16(sp)
sw t4, 20(sp)
# Handles the interrupt
start:
li t2, 1
li t3, 2					# so hang trong keypad can phai xet: n ( la 2 vi chi co 2 hang dau )
li t4, 0
get_key_code:
li t1, IN_ADDRESS_HEXA_KEYBOARD
sb t2, 0(t1) 				
# Must reassign expected row
li t1, OUT_ADDRESS_HEXA_KEYBOARD
lb a0, 0(t1)
add t5,zero,a0				# Nguoi choi nhap 1 so => t5 = a0 
beq a0,t4,next_row			# Neu khong co so hop vs input -> next row
next_row:
slli t2, t2, 1
addi t3,t3,-1
bne t5,zero, reset			# Neu t5 != 0 -> Nguoi choi da nhap duoc so -> ket thuc nhap
bne t3,zero,get_key_code
reset:
# Reset keypad 
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t3, 0x80 
sb t3, 0(t1)
# Restores the context
lw t4, 20(sp)
lw t3, 16(sp)
lw t2, 12(sp)
lw t1,   8(sp)
lw a7,  4(sp)
lw a0,  0(sp)
addi sp, sp, 24
addi t6,zero,1
# Back to the main procedure
uret
