.data
	prompt: .asciz "Nhap chuoi ki tu: "
	input_str: .space 200
	error_msg: .asciz "Do dai chuoi khong chia het cho 8! Vui long nhap lai.\n"
	empty_msg: .asciz "Chuoi rong! Vui long nhap lai.\n"
	header1: .asciz "      Disk 1                 Disk 2               Disk 3\n"
	header2: .asciz "----------------       ----------------       ----------------\n"
	cell_start: .asciz "|     "
	cell_mid: .asciz "     |       "
	cell_end: .asciz "     |\n"
	parity_start: .asciz "[[ "
	parity_end: .asciz " ]]       "
	comma: .asciz ","
	newline: .asciz "\n"
	again_msg: .asciz "Tiep tuc? (y/n): "
	hex_chars: .asciz "0123456789abcdef"

.text
.globl main

main:

input_loop:
    
    li a7, 4		# In yeu cau nhap chuoi kí tu
    la a0, prompt
    ecall
    
    li a7, 8		# Doc chuoi nguoi dung nhap tu ban phim
    la a0, input_str	# Luu vao input_str
    li a1, 200
    ecall
    
    # Kiem tra chuoi co phai chuoi rong hay khong
    la t0, input_str	# t0 = Dia chi cua chuoi     
    lb t1, 0(t0)	# t1 = ky tu dau tien cua chuoi
    
    beq t1, zero, empty_error    # t1 = 0 ==> chuoi rong
    
    li t2, 10
    beq t1, t2, empty_error      # t1 = enter ==> chuoi rong
    
    
    li t1, 0			# t1 = Do dai chuoi
    j count_length		# Chuoi khong rong ==> xuong ham tinh do dai chuoi
    
empty_error:
    li a7, 4			# Ham xu li chuoi rong
    la a0, empty_msg
    ecall
    j input_loop

count_length:
    lb t2, 0(t0)		# Xet tung ky tu cua chuoi
    beq t2, zero, check_length
    li t3, 10
    beq t2, t3, check_length	# Dung lai neu gap ky tu enter

    addi t1, t1, 1		# t1 ++
    addi t0, t0, 1		# Chuyen sang ky tu tiep theo cua chuoi
    j count_length		# Quay lai loop

check_length:

    li t2, 8
    rem t3, t1, t2		# t3 = t1 % 8
    bnez t3, length_error       # Do dai chuoi khong chia het cho 8 ==> in thong bao loi va yeu cau nhap lai
    
    j input_valid		# Do dai chuoi ok ==> bat dau print
    
length_error:
    li a7, 4			# Ham xu li chuoi khong chia het cho 8
    la a0, error_msg
    ecall
    j input_loop
    
input_valid:  
    # Tính so stripe cua o dia
    div s0, t1, t2              # s0 = so stripe
    
    # In cac header
    li a7, 4
    la a0, header1
    ecall
    la a0, header2
    ecall
    
    # Xu li tung stripe
    la s1, input_str        # s1 = Con tro den dau chuoi
    li s2, 0                # s2 = Bien dem stripe
    li s3, 1                # s3 = Vi trí in parity, bat dau tu Disk 3 (1=Disk3, 2=Disk2, 3=Disk1)

process_stripe:
    bge s2, s0, finish      # Xu li het cac stripe ==> finish
    
    # Tính parity cho 4+4 byte
    mv a0, s1			# a0 = Dia chi bat dau stripe
    jal ra, calculate_parity	# Goi ham calculate_parity
    
    # Ket qua parity duoc luu trong a0-a3
    mv s4, a0               # Luu lai parity bytes vào s4-s7
    mv s5, a1
    mv s6, a2  
    mv s7, a3
    
    # In du lieu theo vi trí parity
    mv a0, s1               # a0 = Dia chi stripe
    mv a1, s3               # a1 = Vi trí in parity
    mv a2, s4               # Parity byte 1
    mv a3, s5               # Parity byte 2
    mv a4, s6               # Parity byte 3
    mv a5, s7               # Parity byte 4
    
    jal ra, print_stripe	# Goi ham in stripe
    
    # Chuyen sang stripe tiep theo
    addi s1, s1, 8          # Chuyen con tro toi vi tri 4+4 bytes sau
    addi s2, s2, 1          # stripe ++
    addi s3, s3, 1          # Chuyen vi trí parity
    
    li t0, 4
    bne s3, t0, process_stripe	# Neu parity = 1, 2, 3 ==> quay lai loop
    
    li s3, 1                	# Neu parity = 4 ==> reset ve 1
    j process_stripe		# Quay lai loop

calculate_parity:
    # Input: a0 = Dia chi bit cua 4 + 4 bytes
    # Output: a0-a3 = 4 parity bytes
    
    # Load 8 bytes
    lb t0, 0(a0)            # Byte 0
    lb t1, 1(a0)            # Byte 1  
    lb t2, 2(a0)            # Byte 2
    lb t3, 3(a0)            # Byte 3
    lb t4, 4(a0)            # Byte 4
    lb t5, 5(a0)            # Byte 5
    lb t6, 6(a0)            # Byte 6
    lb s8, 7(a0)            # Byte 7
    
    # Tính XOR tung cap
    xor a0, t0, t4          # Parity 1 = byte 0 XOR byte 4
    xor a1, t1, t5          # Parity 2 = byte 1 XOR byte 5  
    xor a2, t2, t6          # Parity 3 = byte 2 XOR byte 6
    xor a3, t3, s8          # Parity 4 = byte 3 XOR byte 7
    
    ret			# Quay lai ham xu li stripe

print_stripe:
    # Input: a0 = dia chi stripe
    # a1 = vi tri in parity
    # a2-a5 = parity_bytes
    
    addi sp, sp, -32	# Tao stack 32 bytes
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a2, 12(sp)
    sw a3, 16(sp)
    sw a4, 20(sp)
    sw a5, 24(sp)
    sw s8, 28(sp)
    
    mv s8, a0               # Luu dia chi stripe vao s8
    mv s9, a1               # Luu vi trí parity vao s9
    mv s10, a2              # Luu parity bytes vao s10, s11
    mv s11, a3
    # a4, a5 van se duoc luu tren stack va lay ra khi can
    
    li t0, 1
    beq s9, t0, parity_disk3	# s9 = 1 ==> Disk 3
    li t0, 2  
    beq s9, t0, parity_disk2	# s9 = 2 ==> Disk 2
    li t0, 3
    beq s9, t0, parity_disk1	# s9 = 3 ==> Disk 1
    
parity_disk3:
    
    # Disk 1: bytes 0-3
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8		# In 4 bytes dau tien cua stripe luu tai s8
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall
    
    # Disk 2: bytes 4-7  
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8
    addi a0, a0, 4	# In 4 bytes tiep theo cua stripe
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall
    
    # Disk 3: parity
    li a7, 4
    la a0, parity_start
    ecall
    
    mv a0, s10		# In parity 1
    jal ra, print_hex
    
    li a7, 4		# In dau phay
    la a0, comma
    ecall
    
    mv a0, s11		# In parity 2
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 20(sp)          # Lay a4 tu stack = parity 3
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 24(sp)          # Lay a5 tu stack =  parity 4
    jal ra, print_hex
    
    li a7, 4
    la a0, parity_end
    ecall
    
    j print_stripe_end

parity_disk2:
    # Disk 1: bytes 0-3
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8		# In 4 bytes dau tien cua stripe luu tai s8
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall
    
    # Disk 2: parity
    li a7, 4
    la a0, parity_start
    ecall
    
    mv a0, s10		# In parity 1
    jal ra, print_hex
    
    li a7, 4		# In dau phay
    la a0, comma
    ecall
    
    mv a0, s11		# In parity 2
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 20(sp)          # Lay a4 tu stack = parity 3
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 24(sp)          # Lay a5 tu stack =  parity 4
    jal ra, print_hex
    
    li a7, 4
    la a0, parity_end
    ecall
    
    # Disk 3: bytes 4-7
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8
    addi a0, a0, 4	# In 4 bytes tiep theo cua stripe
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall
    
    j print_stripe_end

parity_disk1:
    # Disk 1: parity
    li a7, 4
    la a0, parity_start
    ecall
    
    mv a0, s10		# In parity 1
    jal ra, print_hex
    
    li a7, 4		# In dau phay
    la a0, comma
    ecall
    
    mv a0, s11		# In parity 2
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 20(sp)          # Lay a4 tu stack = parity 3
    jal ra, print_hex
    
    li a7, 4
    la a0, comma
    ecall
    
    lw a0, 24(sp)          # Lay a5 tu stack =  parity 4
    jal ra, print_hex
    
    li a7, 4
    la a0, parity_end
    ecall
    
    # Disk 2: bytes 0-3
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8		# In 4 bytes dau tien cua stripe luu tai s8
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall
    
    # Disk 3: bytes 4-7
    li a7, 4
    la a0, cell_start
    ecall
    
    mv a0, s8
    addi a0, a0, 4	# In 4 bytes tiep theo cua stripe
    jal ra, print_4bytes
    
    li a7, 4
    la a0, cell_mid
    ecall

print_stripe_end:
    li a7, 4		# In ky tu enter
    la a0, newline
    ecall
    
    lw ra, 0(sp)	# Giai phong stack va khoi phuc cac thanh ghi
    lw a0, 4(sp)
    lw a1, 8(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 20(sp)
    lw a5, 24(sp)
    lw s8, 28(sp)
    addi sp, sp, 32
    ret
    
print_4bytes:
    # In 4 ký tu ASCII tu dia chi a0
    addi sp, sp, -8			# Khoi tao stack
    sw ra, 0(sp)
    sw a0, 4(sp)
    
    li t0, 0				# t0 = bien dem byte
    
print_4bytes_loop:
    li t1, 4
    bge t0, t1, print_4bytes_done	# t0 > 4 ==> In xong 4 ky tu
    lw t2, 4(sp)			# Lay lai dia chi goc
    add t2, t2, t0			# t2 = Lay dia chi byte can in
    
    lb a0, 0(t2)			# In byte hien tai
    li a7, 11
    ecall
    
    addi t0, t0, 1			# t0 ++
    j print_4bytes_loop			# QUay lai loop
    
print_4bytes_done:
    lw ra, 0(sp)			# Giai phong stack va khoi phuc cac thanh ghi
    lw a0, 4(sp)
    addi sp, sp, 8
    ret

print_hex:
    # In 1 byte duoii dang hex
    # Input: a0 lan luot duoc gán gia tri cua 4 parity
    addi sp, sp, -8		# Khoi tao stack
    sw ra, 0(sp)
    sw a0, 4(sp)
    
    la t0, hex_chars		# t0 = dia chi hex_chars
    
    # Nibble cao
    srli t1, a0, 4
    add t2, t0, t1
    lb a0, 0(t2)
    li a7, 11
    ecall
    
    # Nibble thap  
    lw a0, 4(sp)           # Khoi phuc gia tri cua a0
    andi t1, a0, 0x0F
    add t2, t0, t1
    lb a0, 0(t2)
    li a7, 11
    ecall
    
    lw ra, 0(sp)	# Giai phong stack va khoi phuc gia tri cac thanh ghi
    lw a0, 4(sp)
    addi sp, sp, 8
    ret

finish:
    li a7, 4		# In phan duoi cua o dia
    la a0, header2
    ecall
    
    li a7, 4		# In thong bao co chay lai chuong trinh khong
    la a0, again_msg
    ecall
    
    li a7, 12		# Doc ky tu do nguoi dung nhap
    ecall    
    li t0, 'y'		# Neu la 'y' thi chay lai ham
    beq a0, t0, input_loop
    
    li a7, 10		# Ket thuc
    ecall
    
