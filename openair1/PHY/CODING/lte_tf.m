% 2 columns from From Table 7.1.7.2.1-1
N_PRB1 = [16
24
32
40
56
72
98
104
120
136
144
176
208
224
256
280
328
336
376
408
440
488
520
552
584
616
712];

N_PRB20 = [536
712
872
1160
1416
1736
2088
2472
2792
3112
3496
4008
4584
5160
5736
6200
6456
7224
7992
8504
9144
9912
10680
11448
12216
12576
14688];

R_QPSK_1  = (N_PRB1(1:10)+24)/(12*12*2);
R_QPSK_20 = (N_PRB20(1:10)+24)/(12*12*2*20);


R_QAM16_1 = (N_PRB1(10:16)+24)/(12*12*4);
R_QAM16_20 = (N_PRB20(10:16)+24)/(12*12*4*20);

R_QAM64_1 = (N_PRB1(16:27)+24)/(12*12*6);
R_QAM64_20 = (N_PRB20(16:27)+24)/(12*12*6*20);