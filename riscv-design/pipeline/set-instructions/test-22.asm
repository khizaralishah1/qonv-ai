#40099
addi x15, x0, 48
addi x10, x15, 9
addi x11, x15, 9
addi x12, x15, 0
addi x13, x15, 0
addi x14, x15, 4
sw x10, 0(x0)      # address 0 of mem ---> 9
sw x11, 1(x0)      # address 1 of mem ---> 9
sw x12, 2(x0)      # address 2 of mem ---> 0
sw x13, 3(x0)      # address 3 of mem ---> 0
sw x14, 4(x0)      # address 4 of mem ---> 4