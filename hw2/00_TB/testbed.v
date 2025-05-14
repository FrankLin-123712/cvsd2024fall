`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000

`ifdef p0
    `define INST_PATH "../00_TB/PATTERN/p0/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p0/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p0/status.dat"
	`define STATUS_LEN 47
`elsif p1
    `define INST_PATH "../00_TB/PATTERN/p1/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p1/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p1/status.dat"
	`define STATUS_LEN 12
`elsif p2
	`define INST_PATH "../00_TB/PATTERN/p2/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p2/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p2/status.dat"
	`define STATUS_LEN 8
`elsif p3
	`define INST_PATH "../00_TB/PATTERN/p3/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p3/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p3/status.dat"
	`define STATUS_LEN 27
`elsif p4
	`define INST_PATH "../00_TB/PATTERN/p4/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p4/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p4/status.dat"
	`define STATUS_LEN 4
`elsif p5
	`define INST_PATH "../00_TB/PATTERN/p5/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p5/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p5/status.dat"
	`define STATUS_LEN 3
`elsif p6
	`define INST_PATH "../00_TB/PATTERN/p6/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p6/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p6/status.dat"
	`define STATUS_LEN 2
`elsif p7
	`define INST_PATH "../00_TB/PATTERN/p7/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p7/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p7/status.dat"
	`define STATUS_LEN 3
`elsif p8
	`define INST_PATH "../00_TB/PATTERN/p8/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p8/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p8/status.dat"
	`define STATUS_LEN 5
`elsif p9
	`define INST_PATH "../00_TB/PATTERN/p9/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p9/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p9/status.dat"
	`define STATUS_LEN 2
`elsif p10
	`define INST_PATH "../00_TB/PATTERN/p10/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p10/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p10/status.dat"
	`define STATUS_LEN 3
`elsif p11
	`define INST_PATH "../00_TB/PATTERN/p11/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p11/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p11/status.dat"
	`define STATUS_LEN 5
`elsif p12
	`define INST_PATH "../00_TB/PATTERN/p12/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p12/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p12/status.dat"
	`define STATUS_LEN 4
`elsif p13
	`define INST_PATH "../00_TB/PATTERN/p13/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p13/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p13/status.dat"
	`define STATUS_LEN 39
`elsif p14
	`define INST_PATH "../00_TB/PATTERN/p14/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p14/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p14/status.dat"
	`define STATUS_LEN 4
`elsif p15
	`define INST_PATH "../00_TB/PATTERN/p15/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p15/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p15/status.dat"
	`define STATUS_LEN 4
`elsif p16
	`define INST_PATH "../00_TB/PATTERN/p16/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p16/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p16/status.dat"
	`define STATUS_LEN 7
`elsif p17
	`define INST_PATH "../00_TB/PATTERN/p17/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p17/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p17/status.dat"
	`define STATUS_LEN 7
`elsif p18
	`define INST_PATH "../00_TB/PATTERN/p18/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p18/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p18/status.dat"
	`define STATUS_LEN 2
`elsif p19
	`define INST_PATH "../00_TB/PATTERN/p19/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p19/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p19/status.dat"
	`define STATUS_LEN 3
`elsif p20
	`define INST_PATH "../00_TB/PATTERN/p20/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p20/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p20/status.dat"
	`define STATUS_LEN 5
`elsif p21
	`define INST_PATH "../00_TB/PATTERN/p21/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p21/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p21/status.dat"
	`define STATUS_LEN 2
`elsif p22
	`define INST_PATH "../00_TB/PATTERN/p22/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p22/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p22/status.dat"
	`define STATUS_LEN 3
`elsif p23
	`define INST_PATH "../00_TB/PATTERN/p23/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p23/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p23/status.dat"
	`define STATUS_LEN 5
`elsif p24
	`define INST_PATH "../00_TB/PATTERN/p24/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p24/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p24/status.dat"
	`define STATUS_LEN 1024
`elsif p25
	`define INST_PATH "../00_TB/PATTERN/p25/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p25/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p25/status.dat"
	`define STATUS_LEN 1024

`elsif p26
	`define INST_PATH "../00_TB/PATTERN/p26/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p26/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p26/status.dat"
	`define STATUS_LEN 1024

`elsif p27
	`define INST_PATH "../00_TB/PATTERN/p27/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p27/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p27/status.dat"
	`define STATUS_LEN 1024

`elsif p28
	`define INST_PATH "../00_TB/PATTERN/p28/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p28/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p28/status.dat"
	`define STATUS_LEN 1024

`elsif p29
	`define INST_PATH "../00_TB/PATTERN/p29/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p29/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p29/status.dat"
	`define STATUS_LEN 658

`elsif p30
	`define INST_PATH "../00_TB/PATTERN/p30/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p30/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p30/status.dat"
	`define STATUS_LEN 1024

`elsif p31
	`define INST_PATH "../00_TB/PATTERN/p31/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p31/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p31/status.dat"
	`define STATUS_LEN 1024

`elsif p32
	`define INST_PATH "../00_TB/PATTERN/p32/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p32/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p32/status.dat"
	`define STATUS_LEN 462

`elsif p33
	`define INST_PATH "../00_TB/PATTERN/p33/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p33/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p33/status.dat"
	`define STATUS_LEN 619

`elsif p34
	`define INST_PATH "../00_TB/PATTERN/p34/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p34/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p34/status.dat"
	`define STATUS_LEN 303

`elsif p35
	`define INST_PATH "../00_TB/PATTERN/p35/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p35/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p35/status.dat"
	`define STATUS_LEN 896

`elsif p36
	`define INST_PATH "../00_TB/PATTERN/p36/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p36/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p36/status.dat"
	`define STATUS_LEN 484

`elsif p37
	`define INST_PATH "../00_TB/PATTERN/p37/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p37/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p37/status.dat"
	`define STATUS_LEN 472

`elsif p38
	`define INST_PATH "../00_TB/PATTERN/p38/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p38/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p38/status.dat"
	`define STATUS_LEN 339

`elsif p39
	`define INST_PATH "../00_TB/PATTERN/p39/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p39/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p39/status.dat"
	`define STATUS_LEN 1004

`elsif p40
	`define INST_PATH "../00_TB/PATTERN/p40/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p40/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p40/status.dat"
	`define STATUS_LEN 1024

`elsif p41
	`define INST_PATH "../00_TB/PATTERN/p41/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p41/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p41/status.dat"
	`define STATUS_LEN 1024

`elsif p42
	`define INST_PATH "../00_TB/PATTERN/p42/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p42/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p42/status.dat"
	`define STATUS_LEN 742

`elsif p43
	`define INST_PATH "../00_TB/PATTERN/p43/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p43/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p43/status.dat"
	`define STATUS_LEN 278

`elsif p44
	`define INST_PATH "../00_TB/PATTERN/p44/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p44/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p44/status.dat"
	`define STATUS_LEN 792

`elsif p45
	`define INST_PATH "../00_TB/PATTERN/p45/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p45/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p45/status.dat"
	`define STATUS_LEN 1024

`elsif p46
	`define INST_PATH "../00_TB/PATTERN/p46/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p46/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p46/status.dat"
	`define STATUS_LEN 1024

`elsif p47
	`define INST_PATH "../00_TB/PATTERN/p47/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p47/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p47/status.dat"
	`define STATUS_LEN 1024

`elsif p48
	`define INST_PATH "../00_TB/PATTERN/p48/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p48/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p48/status.dat"
	`define STATUS_LEN 1024

`elsif p49
	`define INST_PATH "../00_TB/PATTERN/p49/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p49/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p49/status.dat"
	`define STATUS_LEN 114

`elsif p50
	`define INST_PATH "../00_TB/PATTERN/p50/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p50/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p50/status.dat"
	`define STATUS_LEN 28

`elsif p51
	`define INST_PATH "../00_TB/PATTERN/p51/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p51/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p51/status.dat"
	`define STATUS_LEN 1024

`elsif p52
	`define INST_PATH "../00_TB/PATTERN/p52/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p52/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p52/status.dat"
	`define STATUS_LEN 528

`elsif p53
	`define INST_PATH "../00_TB/PATTERN/p53/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p53/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p53/status.dat"
	`define STATUS_LEN 1024

`elsif p54
	`define INST_PATH "../00_TB/PATTERN/p54/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p54/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p54/status.dat"
	`define STATUS_LEN 1024

`elsif p55
	`define INST_PATH "../00_TB/PATTERN/p55/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p55/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p55/status.dat"
	`define STATUS_LEN 815

`elsif p56
	`define INST_PATH "../00_TB/PATTERN/p56/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p56/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p56/status.dat"
	`define STATUS_LEN 668

`elsif p57
	`define INST_PATH "../00_TB/PATTERN/p57/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p57/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p57/status.dat"
	`define STATUS_LEN 1024

`elsif p58
	`define INST_PATH "../00_TB/PATTERN/p58/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p58/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p58/status.dat"
	`define STATUS_LEN 1024

`elsif p59
	`define INST_PATH "../00_TB/PATTERN/p59/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p59/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p59/status.dat"
	`define STATUS_LEN 1024

`elsif p60
	`define INST_PATH "../00_TB/PATTERN/p60/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p60/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p60/status.dat"
	`define STATUS_LEN 1024

`elsif p61
	`define INST_PATH "../00_TB/PATTERN/p61/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p61/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p61/status.dat"
	`define STATUS_LEN 1024

`elsif p62
	`define INST_PATH "../00_TB/PATTERN/p62/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p62/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p62/status.dat"
	`define STATUS_LEN 612

`elsif p63
	`define INST_PATH "../00_TB/PATTERN/p63/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p63/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p63/status.dat"
	`define STATUS_LEN 1024

`elsif p64
	`define INST_PATH "../00_TB/PATTERN/p64/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p64/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p64/status.dat"
	`define STATUS_LEN 1024

`elsif p65
	`define INST_PATH "../00_TB/PATTERN/p65/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p65/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p65/status.dat"
	`define STATUS_LEN 45

`elsif p66
	`define INST_PATH "../00_TB/PATTERN/p66/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p66/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p66/status.dat"
	`define STATUS_LEN 147

`elsif p67
	`define INST_PATH "../00_TB/PATTERN/p67/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p67/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p67/status.dat"
	`define STATUS_LEN 293

`elsif p68
	`define INST_PATH "../00_TB/PATTERN/p68/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p68/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p68/status.dat"
	`define STATUS_LEN 1024

`elsif p69
	`define INST_PATH "../00_TB/PATTERN/p69/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p69/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p69/status.dat"
	`define STATUS_LEN 516

`elsif p70
	`define INST_PATH "../00_TB/PATTERN/p70/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p70/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p70/status.dat"
	`define STATUS_LEN 793
`elsif p71
	`define INST_PATH "../00_TB/PATTERN/p71/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p71/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p71/status.dat"
	`define STATUS_LEN 1024

`elsif p72
	`define INST_PATH "../00_TB/PATTERN/p72/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p72/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p72/status.dat"
	`define STATUS_LEN 563

`elsif p73
	`define INST_PATH "../00_TB/PATTERN/p73/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p73/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p73/status.dat"
	`define STATUS_LEN 1024

`elsif p74
	`define INST_PATH "../00_TB/PATTERN/p74/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p74/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p74/status.dat"
	`define STATUS_LEN 1024

`elsif p75
	`define INST_PATH "../00_TB/PATTERN/p75/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p75/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p75/status.dat"
	`define STATUS_LEN 343

`elsif p76
	`define INST_PATH "../00_TB/PATTERN/p76/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p76/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p76/status.dat"
	`define STATUS_LEN 1024

`elsif p77
	`define INST_PATH "../00_TB/PATTERN/p77/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p77/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p77/status.dat"
	`define STATUS_LEN 938

`elsif p78
	`define INST_PATH "../00_TB/PATTERN/p78/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p78/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p78/status.dat"
	`define STATUS_LEN 1024

`elsif p79
	`define INST_PATH "../00_TB/PATTERN/p79/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p79/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p79/status.dat"
	`define STATUS_LEN 1024

`elsif p80
	`define INST_PATH "../00_TB/PATTERN/p80/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p80/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p80/status.dat"
	`define STATUS_LEN 1024

`elsif p81
	`define INST_PATH "../00_TB/PATTERN/p81/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p81/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p81/status.dat"
	`define STATUS_LEN 1024

`elsif p82
	`define INST_PATH "../00_TB/PATTERN/p82/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p82/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p82/status.dat"
	`define STATUS_LEN 550

`elsif p83
	`define INST_PATH "../00_TB/PATTERN/p83/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p83/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p83/status.dat"
	`define STATUS_LEN 1024

`elsif p84
	`define INST_PATH "../00_TB/PATTERN/p84/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p84/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p84/status.dat"
	`define STATUS_LEN 1024

`elsif p85
	`define INST_PATH "../00_TB/PATTERN/p85/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p85/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p85/status.dat"
	`define STATUS_LEN 1024

`elsif p86
	`define INST_PATH "../00_TB/PATTERN/p86/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p86/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p86/status.dat"
	`define STATUS_LEN 538

`elsif p87
	`define INST_PATH "../00_TB/PATTERN/p87/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p87/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p87/status.dat"
	`define STATUS_LEN 116

`elsif p88
	`define INST_PATH "../00_TB/PATTERN/p88/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p88/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p88/status.dat"
	`define STATUS_LEN 924

`elsif p89
	`define INST_PATH "../00_TB/PATTERN/p89/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p89/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p89/status.dat"
	`define STATUS_LEN 687

`elsif p90
	`define INST_PATH "../00_TB/PATTERN/p90/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p90/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p90/status.dat"
	`define STATUS_LEN 559

`elsif p91
	`define INST_PATH "../00_TB/PATTERN/p91/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p91/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p91/status.dat"
	`define STATUS_LEN 1024

`elsif p92
	`define INST_PATH "../00_TB/PATTERN/p92/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p92/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p92/status.dat"
	`define STATUS_LEN 529

`elsif p93
	`define INST_PATH "../00_TB/PATTERN/p93/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p93/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p93/status.dat"
	`define STATUS_LEN 1024

`elsif p94
	`define INST_PATH "../00_TB/PATTERN/p94/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p94/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p94/status.dat"
	`define STATUS_LEN 881

`elsif p95
	`define INST_PATH "../00_TB/PATTERN/p95/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p95/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p95/status.dat"
	`define STATUS_LEN 1024

`elsif p96
	`define INST_PATH "../00_TB/PATTERN/p96/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p96/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p96/status.dat"
	`define STATUS_LEN 1024

`elsif p97
	`define INST_PATH "../00_TB/PATTERN/p97/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p97/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p97/status.dat"
	`define STATUS_LEN 329

`elsif p98
	`define INST_PATH "../00_TB/PATTERN/p98/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p98/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p98/status.dat"
	`define STATUS_LEN 1024

`elsif p99
	`define INST_PATH "../00_TB/PATTERN/p99/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p99/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p99/status.dat"
	`define STATUS_LEN 1024
`elsif p100
	`define INST_PATH "../00_TB/PATTERN/p100/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p100/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p100/status.dat"
	`define STATUS_LEN 1024
`elsif p100
	`define INST_PATH "../00_TB/PATTERN/p100/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p100/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p100/status.dat"
	`define STATUS_LEN 1024
`elsif p101
	`define INST_PATH "../00_TB/PATTERN/p101/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p101/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p101/status.dat"
	`define STATUS_LEN 1024
`elsif p102
	`define INST_PATH "../00_TB/PATTERN/p102/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p102/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p102/status.dat"
	`define STATUS_LEN 1024
`elsif p103
	`define INST_PATH "../00_TB/PATTERN/p103/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p103/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p103/status.dat"
	`define STATUS_LEN 1024
`elsif p104
	`define INST_PATH "../00_TB/PATTERN/p104/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p104/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p104/status.dat"
	`define STATUS_LEN 1024
`elsif p105
	`define INST_PATH "../00_TB/PATTERN/p105/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p105/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p105/status.dat"
	`define STATUS_LEN 1024
`elsif p106
	`define INST_PATH "../00_TB/PATTERN/p106/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p106/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p106/status.dat"
	`define STATUS_LEN 1024
`elsif p107
	`define INST_PATH "../00_TB/PATTERN/p107/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p107/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p107/status.dat"
	`define STATUS_LEN 1024
`elsif p108
	`define INST_PATH "../00_TB/PATTERN/p108/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p108/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p108/status.dat"
	`define STATUS_LEN 1024
`elsif p109
	`define INST_PATH "../00_TB/PATTERN/p109/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p109/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p109/status.dat"
	`define STATUS_LEN 1024
`elsif p110
	`define INST_PATH "../00_TB/PATTERN/p110/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p110/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p110/status.dat"
	`define STATUS_LEN 1024
`elsif p111
	`define INST_PATH "../00_TB/PATTERN/p111/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p111/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p111/status.dat"
	`define STATUS_LEN 1024
`elsif p112
	`define INST_PATH "../00_TB/PATTERN/p112/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p112/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p112/status.dat"
	`define STATUS_LEN 1024
`elsif p113
	`define INST_PATH "../00_TB/PATTERN/p113/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p113/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p113/status.dat"
	`define STATUS_LEN 1024
`elsif p114
	`define INST_PATH "../00_TB/PATTERN/p114/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p114/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p114/status.dat"
	`define STATUS_LEN 1024
`elsif p115
	`define INST_PATH "../00_TB/PATTERN/p115/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p115/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p115/status.dat"
	`define STATUS_LEN 1024
`elsif p116
	`define INST_PATH "../00_TB/PATTERN/p116/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p116/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p116/status.dat"
	`define STATUS_LEN 1024
`elsif p117
	`define INST_PATH "../00_TB/PATTERN/p117/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p117/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p117/status.dat"
	`define STATUS_LEN 1024
`elsif p118
	`define INST_PATH "../00_TB/PATTERN/p118/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p118/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p118/status.dat"
	`define STATUS_LEN 1024
`elsif p119
	`define INST_PATH "../00_TB/PATTERN/p119/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p119/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p119/status.dat"
	`define STATUS_LEN 1024
`elsif p120
	`define INST_PATH "../00_TB/PATTERN/p120/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p120/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p120/status.dat"
	`define STATUS_LEN 1024
`elsif p121
	`define INST_PATH "../00_TB/PATTERN/p121/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p121/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p121/status.dat"
	`define STATUS_LEN 1024
`elsif p122
	`define INST_PATH "../00_TB/PATTERN/p122/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p122/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p122/status.dat"
	`define STATUS_LEN 1024
`elsif p123
	`define INST_PATH "../00_TB/PATTERN/p123/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p123/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p123/status.dat"
	`define STATUS_LEN 476
`elsif p124
	`define INST_PATH "../00_TB/PATTERN/p124/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p124/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p124/status.dat"
	`define STATUS_LEN 1024
`elsif p125
	`define INST_PATH "../00_TB/PATTERN/p125/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p125/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p125/status.dat"
	`define STATUS_LEN 1024
`elsif p126
	`define INST_PATH "../00_TB/PATTERN/p126/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p126/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p126/status.dat"
	`define STATUS_LEN 1024
`elsif p127
	`define INST_PATH "../00_TB/PATTERN/p127/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p127/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p127/status.dat"
	`define STATUS_LEN 1024
`elsif p128
	`define INST_PATH "../00_TB/PATTERN/p128/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p128/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p128/status.dat"
	`define STATUS_LEN 605
`elsif p129
	`define INST_PATH "../00_TB/PATTERN/p129/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p129/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p129/status.dat"
	`define STATUS_LEN 1024
`elsif p130
	`define INST_PATH "../00_TB/PATTERN/p130/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p130/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p130/status.dat"
	`define STATUS_LEN 1024
`elsif p131
	`define INST_PATH "../00_TB/PATTERN/p131/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p131/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p131/status.dat"
	`define STATUS_LEN 1024
`elsif p132
	`define INST_PATH "../00_TB/PATTERN/p132/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p132/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p132/status.dat"
	`define STATUS_LEN 1024
`elsif p133
	`define INST_PATH "../00_TB/PATTERN/p133/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p133/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p133/status.dat"
	`define STATUS_LEN 1024
`elsif p134
	`define INST_PATH "../00_TB/PATTERN/p134/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p134/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p134/status.dat"
	`define STATUS_LEN 782
`elsif p135
	`define INST_PATH "../00_TB/PATTERN/p135/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p135/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p135/status.dat"
	`define STATUS_LEN 1024
`elsif p136
	`define INST_PATH "../00_TB/PATTERN/p136/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p136/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p136/status.dat"
	`define STATUS_LEN 1024
`elsif p137
	`define INST_PATH "../00_TB/PATTERN/p137/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p137/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p137/status.dat"
	`define STATUS_LEN 907
`elsif p138
	`define INST_PATH "../00_TB/PATTERN/p138/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p138/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p138/status.dat"
	`define STATUS_LEN 161
`elsif p139
	`define INST_PATH "../00_TB/PATTERN/p139/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p139/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p139/status.dat"
	`define STATUS_LEN 1024
`elsif p140
	`define INST_PATH "../00_TB/PATTERN/p140/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p140/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p140/status.dat"
	`define STATUS_LEN 1024
`elsif p141
	`define INST_PATH "../00_TB/PATTERN/p141/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p141/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p141/status.dat"
	`define STATUS_LEN 1024
`elsif p142
	`define INST_PATH "../00_TB/PATTERN/p142/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p142/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p142/status.dat"
	`define STATUS_LEN 1024
`elsif p143
	`define INST_PATH "../00_TB/PATTERN/p143/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p143/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p143/status.dat"
	`define STATUS_LEN 1024
`elsif p144
	`define INST_PATH "../00_TB/PATTERN/p144/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p144/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p144/status.dat"
	`define STATUS_LEN 1024
`elsif p145
	`define INST_PATH "../00_TB/PATTERN/p145/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p145/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p145/status.dat"
	`define STATUS_LEN 1024
`elsif p146
	`define INST_PATH "../00_TB/PATTERN/p146/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p146/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p146/status.dat"
	`define STATUS_LEN 1024
`elsif p147
	`define INST_PATH "../00_TB/PATTERN/p147/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p147/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p147/status.dat"
	`define STATUS_LEN 1024
`elsif p148
	`define INST_PATH "../00_TB/PATTERN/p148/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p148/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p148/status.dat"
	`define STATUS_LEN 1024
`elsif p149
	`define INST_PATH "../00_TB/PATTERN/p149/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p149/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p149/status.dat"
	`define STATUS_LEN 1024
`elsif p150
	`define INST_PATH "../00_TB/PATTERN/p150/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p150/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p150/status.dat"
	`define STATUS_LEN 260
`elsif p151
	`define INST_PATH "../00_TB/PATTERN/p151/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p151/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p151/status.dat"
	`define STATUS_LEN 1024
`elsif p152
	`define INST_PATH "../00_TB/PATTERN/p152/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p152/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p152/status.dat"
	`define STATUS_LEN 1024
`elsif p153
	`define INST_PATH "../00_TB/PATTERN/p153/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p153/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p153/status.dat"
	`define STATUS_LEN 1024
`elsif p154
	`define INST_PATH "../00_TB/PATTERN/p154/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p154/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p154/status.dat"
	`define STATUS_LEN 1024
`elsif p155
	`define INST_PATH "../00_TB/PATTERN/p155/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p155/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p155/status.dat"
	`define STATUS_LEN 1024
`elsif p156
	`define INST_PATH "../00_TB/PATTERN/p156/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p156/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p156/status.dat"
	`define STATUS_LEN 1024
`elsif p157
	`define INST_PATH "../00_TB/PATTERN/p157/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p157/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p157/status.dat"
	`define STATUS_LEN 1024
`elsif p158
	`define INST_PATH "../00_TB/PATTERN/p158/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p158/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p158/status.dat"
	`define STATUS_LEN 1024
`elsif p159
	`define INST_PATH "../00_TB/PATTERN/p159/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p159/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p159/status.dat"
	`define STATUS_LEN 1024
`elsif p160
	`define INST_PATH "../00_TB/PATTERN/p160/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p160/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p160/status.dat"
	`define STATUS_LEN 176
`elsif p161
	`define INST_PATH "../00_TB/PATTERN/p161/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p161/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p161/status.dat"
	`define STATUS_LEN 1024
`elsif p162
	`define INST_PATH "../00_TB/PATTERN/p162/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p162/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p162/status.dat"
	`define STATUS_LEN 1024
`elsif p163
	`define INST_PATH "../00_TB/PATTERN/p163/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p163/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p163/status.dat"
	`define STATUS_LEN 1024
`elsif p164
	`define INST_PATH "../00_TB/PATTERN/p164/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p164/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p164/status.dat"
	`define STATUS_LEN 136
`elsif p165
	`define INST_PATH "../00_TB/PATTERN/p165/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p165/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p165/status.dat"
	`define STATUS_LEN 1024
`elsif p166
	`define INST_PATH "../00_TB/PATTERN/p166/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p166/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p166/status.dat"
	`define STATUS_LEN 1024
`elsif p167
	`define INST_PATH "../00_TB/PATTERN/p167/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p167/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p167/status.dat"
	`define STATUS_LEN 1024
`elsif p168
	`define INST_PATH "../00_TB/PATTERN/p168/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p168/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p168/status.dat"
	`define STATUS_LEN 1024
`elsif p169
	`define INST_PATH "../00_TB/PATTERN/p169/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p169/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p169/status.dat"
	`define STATUS_LEN 1024
`elsif p170
	`define INST_PATH "../00_TB/PATTERN/p170/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p170/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p170/status.dat"
	`define STATUS_LEN 1024
`elsif p171
	`define INST_PATH "../00_TB/PATTERN/p171/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p171/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p171/status.dat"
	`define STATUS_LEN 1024
`elsif p172
	`define INST_PATH "../00_TB/PATTERN/p172/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p172/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p172/status.dat"
	`define STATUS_LEN 1024
`elsif p173
	`define INST_PATH "../00_TB/PATTERN/p173/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p173/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p173/status.dat"
	`define STATUS_LEN 1024
`elsif p174
	`define INST_PATH "../00_TB/PATTERN/p174/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p174/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p174/status.dat"
	`define STATUS_LEN 1024
`elsif p175
	`define INST_PATH "../00_TB/PATTERN/p175/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p175/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p175/status.dat"
	`define STATUS_LEN 1024
`elsif p176
	`define INST_PATH "../00_TB/PATTERN/p176/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p176/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p176/status.dat"
	`define STATUS_LEN 1024
`elsif p177
	`define INST_PATH "../00_TB/PATTERN/p177/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p177/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p177/status.dat"
	`define STATUS_LEN 1024
`elsif p178
	`define INST_PATH "../00_TB/PATTERN/p178/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p178/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p178/status.dat"
	`define STATUS_LEN 1024
`elsif p179
	`define INST_PATH "../00_TB/PATTERN/p179/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p179/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p179/status.dat"
	`define STATUS_LEN 1024
`elsif p180
	`define INST_PATH "../00_TB/PATTERN/p180/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p180/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p180/status.dat"
	`define STATUS_LEN 1024
`elsif p181
	`define INST_PATH "../00_TB/PATTERN/p181/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p181/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p181/status.dat"
	`define STATUS_LEN 1024
`elsif p182
	`define INST_PATH "../00_TB/PATTERN/p182/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p182/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p182/status.dat"
	`define STATUS_LEN 1024
`elsif p183
	`define INST_PATH "../00_TB/PATTERN/p183/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p183/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p183/status.dat"
	`define STATUS_LEN 1024
`elsif p184
	`define INST_PATH "../00_TB/PATTERN/p184/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p184/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p184/status.dat"
	`define STATUS_LEN 364
`elsif p185
	`define INST_PATH "../00_TB/PATTERN/p185/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p185/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p185/status.dat"
	`define STATUS_LEN 1024
`elsif p186
	`define INST_PATH "../00_TB/PATTERN/p186/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p186/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p186/status.dat"
	`define STATUS_LEN 1024
`elsif p187
	`define INST_PATH "../00_TB/PATTERN/p187/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p187/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p187/status.dat"
	`define STATUS_LEN 1024
`elsif p188
	`define INST_PATH "../00_TB/PATTERN/p188/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p188/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p188/status.dat"
	`define STATUS_LEN 1024
`elsif p189
	`define INST_PATH "../00_TB/PATTERN/p189/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p189/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p189/status.dat"
	`define STATUS_LEN 1024
`elsif p190
	`define INST_PATH "../00_TB/PATTERN/p190/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p190/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p190/status.dat"
	`define STATUS_LEN 1024
`elsif p191
	`define INST_PATH "../00_TB/PATTERN/p191/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p191/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p191/status.dat"
	`define STATUS_LEN 1024
`elsif p192
	`define INST_PATH "../00_TB/PATTERN/p192/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p192/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p192/status.dat"
	`define STATUS_LEN 1024
`elsif p193
	`define INST_PATH "../00_TB/PATTERN/p193/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p193/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p193/status.dat"
	`define STATUS_LEN 1024
`elsif p194
	`define INST_PATH "../00_TB/PATTERN/p194/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p194/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p194/status.dat"
	`define STATUS_LEN 1024
`elsif p195
	`define INST_PATH "../00_TB/PATTERN/p195/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p195/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p195/status.dat"
	`define STATUS_LEN 1024
`elsif p196
	`define INST_PATH "../00_TB/PATTERN/p196/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p196/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p196/status.dat"
	`define STATUS_LEN 784
`elsif p197
	`define INST_PATH "../00_TB/PATTERN/p197/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p197/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p197/status.dat"
	`define STATUS_LEN 1024
`elsif p198
	`define INST_PATH "../00_TB/PATTERN/p198/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p198/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p198/status.dat"
	`define STATUS_LEN 1024
`elsif p199
	`define INST_PATH "../00_TB/PATTERN/p199/inst.dat"
	`define DATA_PATH "../00_TB/PATTERN/p199/data.dat"
	`define STATUS_PATH "../00_TB/PATTERN/p199/status.dat"
	`define STATUS_LEN 1024
`endif

`define MEM_WIDTH 32
`define MEM_DEPTH 2048
`define STATUS_WIDTH 3

module testbed;

	reg  rst_n;
	reg  clk = 0;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  2 : 0 ] status;
	wire            status_valid;
	
	integer status_correct, status_error, data_correct, data_error;
	integer output_end, k, i;
	
	
	// TB variables
    reg  [`MEM_WIDTH-1:0]      golden_data [0:`MEM_DEPTH-1];
    reg  [`STATUS_WIDTH-1:0] golden_status [0:`STATUS_LEN-1];
	
	// dump waveform
    initial begin
       $fsdbDumpfile("core.fsdb");
       $fsdbDumpvars(0, testbed, "+mda");
    end
	
	
	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_status(status),
		.o_status_valid(status_valid),
		.o_we(dmem_we),
		.o_addr(dmem_addr),
		.o_wdata(dmem_wdata),
		.i_rdata(dmem_rdata)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_we),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

	always #(`HCYCLE) clk = ~clk;
	// load data memory
	initial begin 
		rst_n = 1;
		#(0.25 * `CYCLE) rst_n = 0;
		#(`CYCLE) rst_n = 1;
		$readmemb (`INST_PATH, u_data_mem.mem_r);
	end
	
	// load TB variables
	initial begin
		$readmemb(`STATUS_PATH, golden_status);
		$readmemb(`DATA_PATH, golden_data);
	end
	
	// loop: check status
    initial begin
        status_correct = 0;
        status_error   = 0;
        output_end = 0;

        // reset
        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);

        // loop
        k = 0;
        while (k < `STATUS_LEN) begin
            @(negedge clk);
            if (status_valid) begin
                if (status === golden_status[k]) begin
                    status_correct = status_correct + 1;
                end
                else begin
                    status_error = status_error + 1;
                    $display(
                        "Test[%d]: Error! Golden status =%b (%d), Yours status =%b (%d)",
                        k,
                        golden_status[k],
                        golden_status[k],
                        status,
                        status
                    );
                end
                k = k+1;
            end
            #(0.05 * `CYCLE);
        end

        // final
        output_end = 1;
    end

    // Result: check output memory
    initial begin
        wait (output_end);
		
		data_correct = 0;
        data_error   = 0;
		
		for (i = 0; i < `MEM_DEPTH; i = i + 1)begin
			if (u_data_mem.mem_r[i] === golden_data[i]) begin
                    data_correct = data_correct + 1;
                end
                else begin
                    data_error = data_error + 1;
                    $display(
                        "MEM[%d]: Error! Golden Data =%b (%d), Yours Data =%b (%d)",
                        i,
                        golden_data[i],
                        golden_data[i],
                        u_data_mem.mem_r[i],
                        u_data_mem.mem_r[i]
                    );
                end
		
		end
		
		
        if (status_error === 0 && status_correct === `STATUS_LEN) begin
            $display("----------------------------------------------");
            $display("-             ALL STATUS PASS!               -");
            $display("----------------------------------------------");
        end
        else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total STATUS Error: %d               ", status_error);
            $display("----------------------------------------------");
        end
		
		if (data_error === 0 && data_correct === `MEM_DEPTH) begin
            $display("\n\n\n----------------------------------------------");
            $display("-             ALL DATA PASS!               -");
            $display("----------------------------------------------");
        end
        else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total DATA Error: %d               ", data_error);
            $display("----------------------------------------------");
        end
		
        # (2 * `CYCLE);
        $finish;
    end
	
	// Execution time exceed MAX_CYCLE
	initial begin
        // reset
        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);
        #( `MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
    end

endmodule