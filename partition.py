#!/bin/python3
import subprocess, sys, types
firstlba=34
blocksize = subprocess.run(['blockdev','--getsz',sys.argv[1]], capture_output=True, text=True).stdout
lastlba = (int(blocksize)-firstlba)
partition1 = type('Partition', (object,),{'start' : 2048, 'size': 204800})()
partition2 = type('Partition', (object,),{
    'start' : partition1.size + partition1.start, 
    'size': 32768
    })()
partition4 = type('Partition', (object,),{
    'start' : 0, 
    'size': 1400832
    })()
partition4.start=lastlba - partition4.size
partition3 = type('Partition', (object,),{
    'start' : partition2.size + partition2.start, 
    'size': 0
    })()
partition3.size = partition4.start - partition3.start

def writeline(newContent,oldContent):
    i=0
    finalLine=[]
    while i < len(oldContent):
        if i < len(newContent):
            finalLine.append(newContent[i])
        else: 
            finalLine.append(oldContent[i])
        i=i+1
    print(' '.join(finalLine))
        

with open ('partition.dump','r') as f:
    while line := f.readline():
        w = line.split()
        if len(w) > 0:
            if 'first-lba' in w[0]:
                writeline([w[0],str(firstlba)],w)
            elif 'last-lba' in w[0]:
                writeline([w[0],str(lastlba)],w)
            elif 'EFI system partition' in line:
                writeline([w[0],w[1],w[2],str(partition1.start),w[4],str(partition1.size)],w)
            elif 'Microsoft reserved partition' in line:
                writeline([w[0],w[1],w[2],str(partition2.start),w[4],str(partition2.size)],w)
            elif 'Basic data partition' in line:
                writeline([w[0],w[1],w[2],str(partition3.start),w[4],str(partition3.size)],w)
            elif 'RequiredPartition' in line:
                writeline([w[0],w[1],w[2],str(partition4.start),w[4],str(partition4.size)],w)
            else:
                writeline(w,w)
