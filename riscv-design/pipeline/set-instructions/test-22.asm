addi x16, x0, 0
addi x15, x0, 48
addi x10, x15, 9
addi x11, x15, 9
addi x12, x15, 0
addi x13, x15, 0
addi x14, x15, 4
sw x10, 0(x16)      # address 0 of mem ---> 9
sw x11, 1(x16)      # address 1 of mem ---> 9
sw x12, 2(x16)      # address 2 of mem ---> 0
sw x13, 3(x16)      # address 3 of mem ---> 0
sw x14, 4(x16)      # address 4 of mem ---> 4
addi x10, x15, 7
addi x11, x15, 5
addi x12, x15, 4
addi x13, x15, 8
addi x14, x15, 2
addi x16, x16, 5
sw x10, 0(x16)      # address 5 of mem ---> 7
sw x11, 1(x16)      # address 6 of mem ---> 5
sw x12, 2(x16)      # address 7 of mem ---> 4
sw x13, 3(x16)      # address 8 of mem ---> 8
sw x14, 4(x16)      # address 9 of mem ---> 2
addi x10, x15, 4
addi x11, x15, 4
addi x12, x15, 6
addi x13, x15, 8
addi x14, x15, 3
addi x16, x16, 5
sw x10, 0(x16)      # address 5 of mem ---> 7
sw x11, 1(x16)      # address 6 of mem ---> 5
sw x12, 2(x16)      # address 7 of mem ---> 4
sw x13, 3(x16)      # address 8 of mem ---> 8
sw x14, 4(x16)      # address 9 of mem ---> 2
addi x10, x15, 7
addi x11, x15, 0
addi x12, x15, 9
addi x13, x15, 2
addi x14, x15, 1
addi x16, x16, 5
sw x10, 0(x16)      # address 5 of mem ---> 7
sw x11, 1(x16)      # address 6 of mem ---> 5
sw x12, 2(x16)      # address 7 of mem ---> 4
sw x13, 3(x16)      # address 8 of mem ---> 8
sw x14, 4(x16)      # address 9 of mem ---> 2
addi x10, x15, 9
addi x11, x15, 9
addi x12, x15, 5
addi x13, x15, 4
addi x14, x15, 4
addi x16, x16, 5
sw x10, 0(x16)      # address 5 of mem ---> 7
sw x11, 1(x16)      # address 6 of mem ---> 5
sw x12, 2(x16)      # address 7 of mem ---> 4
sw x13, 3(x16)      # address 8 of mem ---> 8
sw x14, 4(x16)      # address 9 of mem ---> 2
addi x18, x0, 5
addi x17, x0, 20
sw x18, 12(x17)