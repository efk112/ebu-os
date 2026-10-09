import struct, math, sys
S=2048
kern=open('ebu.bin','rb').read()
nsec512=math.ceil(len(kern)/512)
kern_pad=kern+b'\0'*(-len(kern)%S)
def both32(n): return struct.pack('<I',n)+struct.pack('>I',n)
def both16(n): return struct.pack('<H',n)+struct.pack('>H',n)
def rec(lba,length,flags,name):
    nl=len(name); r=33+nl+(1 if nl%2==0 else 0)
    d=bytes([r,0])+both32(lba)+both32(length)+bytes([126,10,10,12,0,0,0])+bytes([flags,0,0])+both16(1)+bytes([nl])+name
    return d.ljust(r,b'\0')
LBA_PVD,LBA_BR,LBA_TERM,LBA_CAT,LBA_PTL,LBA_PTM,LBA_ROOT,LBA_KERN=16,17,18,19,20,21,22,23
total=LBA_KERN+len(kern_pad)//S
def pad(b): return b.ljust(S,b'\0')
root=rec(LBA_ROOT,S,2,b'\0')+rec(LBA_ROOT,S,2,b'\1')+rec(LBA_KERN,len(kern),0,b'EBUBOOT.BIN;1')
def a(s,n): return s.encode().ljust(n,b' ')
date=b'2026101000000000\0'
pvd=bytes([1])+b'CD001'+bytes([1,0])+a('EBU',32)+a('EBU_OS',32)+bytes(8)+both32(total)+bytes(32)+both16(1)+both16(1)+both16(S)+both32(10)
pvd+=struct.pack('<I',LBA_PTL)+bytes(4)+struct.pack('>I',LBA_PTM)+bytes(4)+rec(LBA_ROOT,S,2,b'\0')
pvd+=a('EBU',128)+a('EBU',128)+a('EBU',128)+a('EBU OS',128)+a('',37)+a('',37)+a('',37)+date*2+b'0000000000000000\0'+date+bytes([1,0])
pvd=pad(pvd)
br=pad(bytes([0])+b'CD001'+bytes([1])+b'EL TORITO SPECIFICATION'.ljust(32,b'\0')+bytes(32)+struct.pack('<I',LBA_CAT))
term=pad(bytes([255])+b'CD001'+bytes([1]))
val=bytearray(32); val[0]=1; val[1]=0; val[4:4+24]=b'EBU OS'.ljust(24,b'\0'); val[30]=0x55; val[31]=0xAA
cs=-sum(struct.unpack('<16H',bytes(val)))&0xFFFF; val[28:30]=struct.pack('<H',cs)
assert sum(struct.unpack('<16H',bytes(val)))&0xFFFF==0
ent=bytearray(32); ent[0]=0x88; ent[1]=0; ent[2:4]=struct.pack('<H',0); ent[4]=0; ent[6:8]=struct.pack('<H',nsec512); ent[8:12]=struct.pack('<I',LBA_KERN)
cat=pad(bytes(val)+bytes(ent))
ptl=pad(bytes([1,0])+struct.pack('<I',LBA_ROOT)+struct.pack('<H',1)+b'\0\0')
ptm=pad(bytes([1,0])+struct.pack('>I',LBA_ROOT)+struct.pack('>H',1)+b'\0\0')
iso=bytes(16*S)+pvd+br+term+cat+ptl+ptm+pad(root)+kern_pad
open('ebu-os-mini.iso','wb').write(iso)
# kendi kendini dogrula
d=open('ebu-os-mini.iso','rb').read()
assert d[16*S+1:16*S+6]==b'CD001' and d[17*S+7:17*S+30]==b'EL TORITO SPECIFICATION'
assert struct.unpack('<I',d[17*S+71:17*S+75])[0]==LBA_CAT
c=d[LBA_CAT*S:]; assert c[0]==1 and c[30:32]==b'\x55\xaa' and c[32]==0x88 and c[33]==0
lba=struct.unpack('<I',c[40:44])[0]; n=struct.unpack('<H',c[38:40])[0]
assert d[lba*S:lba*S+len(kern)]==kern and struct.unpack('<I',d[16*S+80:16*S+84])[0]*S==len(d)
print('ISO OK:',len(d),'bayt | boot LBA',lba,'| sektor',n)
