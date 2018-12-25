
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 ef 38 00 00       	call   f0103957 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 00 3e 10 f0 	movl   $0xf0103e00,(%esp)
f010007c:	e8 8a 2d 00 00       	call   f0102e0b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 eb 11 00 00       	call   f0101271 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 8c 07 00 00       	call   f010081e <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 1b 3e 10 f0 	movl   $0xf0103e1b,(%esp)
f01000c8:	e8 3e 2d 00 00       	call   f0102e0b <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ff 2c 00 00       	call   f0102dd8 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 3e 46 10 f0 	movl   $0xf010463e,(%esp)
f01000e0:	e8 26 2d 00 00       	call   f0102e0b <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 2d 07 00 00       	call   f010081e <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 33 3e 10 f0 	movl   $0xf0103e33,(%esp)
f0100112:	e8 f4 2c 00 00       	call   f0102e0b <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 b2 2c 00 00       	call   f0102dd8 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 3e 46 10 f0 	movl   $0xf010463e,(%esp)
f010012d:	e8 d9 2c 00 00       	call   f0102e0b <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01001cb:	c3                   	ret    
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 a0 3f 10 f0 	movzbl -0xfefc060(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 a0 3f 10 f0 	movzbl -0xfefc060(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a a0 3e 10 f0 	movzbl -0xfefc160(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300
	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d 80 3e 10 f0 	mov    -0xfefc180(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
	return c;
f010027b:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 4d 3e 10 f0 	movl   $0xf0103e4d,(%esp)
f0100291:	e8 75 2b 00 00       	call   f0102e0b <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 66 35 00 00       	call   f01039a4 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 59 3e 10 f0 	movl   $0xf0103e59,(%esp)
f01005f4:	e8 12 28 00 00       	call   f0102e0b <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 a0 40 10 	movl   $0xf01040a0,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 be 40 10 	movl   $0xf01040be,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 c3 40 10 f0 	movl   $0xf01040c3,(%esp)
f010064d:	e8 b9 27 00 00       	call   f0102e0b <cprintf>
f0100652:	c7 44 24 08 78 41 10 	movl   $0xf0104178,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 cc 40 10 	movl   $0xf01040cc,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 c3 40 10 f0 	movl   $0xf01040c3,(%esp)
f0100669:	e8 9d 27 00 00       	call   f0102e0b <cprintf>
f010066e:	c7 44 24 08 a0 41 10 	movl   $0xf01041a0,0x8(%esp)
f0100675:	f0 
f0100676:	c7 44 24 04 d5 40 10 	movl   $0xf01040d5,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 c3 40 10 f0 	movl   $0xf01040c3,(%esp)
f0100685:	e8 81 27 00 00       	call   f0102e0b <cprintf>
	return 0;
}
f010068a:	b8 00 00 00 00       	mov    $0x0,%eax
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	c7 04 24 df 40 10 f0 	movl   $0xf01040df,(%esp)
f010069e:	e8 68 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006aa:	00 
f01006ab:	c7 04 24 08 42 10 f0 	movl   $0xf0104208,(%esp)
f01006b2:	e8 54 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 30 42 10 f0 	movl   $0xf0104230,(%esp)
f01006ce:	e8 38 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d3:	c7 44 24 08 e7 3d 10 	movl   $0x103de7,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 e7 3d 10 	movl   $0xf0103de7,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 54 42 10 f0 	movl   $0xf0104254,(%esp)
f01006ea:	e8 1c 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 78 42 10 f0 	movl   $0xf0104278,(%esp)
f0100706:	e8 00 27 00 00       	call   f0102e0b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070b:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f0100712:	00 
f0100713:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f010071a:	f0 
f010071b:	c7 04 24 9c 42 10 f0 	movl   $0xf010429c,(%esp)
f0100722:	e8 e4 26 00 00       	call   f0102e0b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100731:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100736:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073c:	85 c0                	test   %eax,%eax
f010073e:	0f 48 c2             	cmovs  %edx,%eax
f0100741:	c1 f8 0a             	sar    $0xa,%eax
f0100744:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100748:	c7 04 24 c0 42 10 f0 	movl   $0xf01042c0,(%esp)
f010074f:	e8 b7 26 00 00       	call   f0102e0b <cprintf>
	return 0;
}
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	57                   	push   %edi
f010075f:	56                   	push   %esi
f0100760:	53                   	push   %ebx
f0100761:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
f0100764:	89 ee                	mov    %ebp,%esi
	cprintf("Stack backtrace:\n");
f0100766:	c7 04 24 f8 40 10 f0 	movl   $0xf01040f8,(%esp)
f010076d:	e8 99 26 00 00       	call   f0102e0b <cprintf>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");

		unsigned int eip = ebp[1];
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100772:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while(ebp) {
f0100775:	e9 8f 00 00 00       	jmp    f0100809 <mon_backtrace+0xae>
		cprintf("ebp %08x ", ebp);
f010077a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010077e:	c7 04 24 0a 41 10 f0 	movl   $0xf010410a,(%esp)
f0100785:	e8 81 26 00 00       	call   f0102e0b <cprintf>
		cprintf("eip %08x args", ebp[1]);
f010078a:	8b 46 04             	mov    0x4(%esi),%eax
f010078d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100791:	c7 04 24 14 41 10 f0 	movl   $0xf0104114,(%esp)
f0100798:	e8 6e 26 00 00       	call   f0102e0b <cprintf>
		for(int i = 2; i <= 6; i++)
f010079d:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", ebp[i]);
f01007a2:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a9:	c7 04 24 22 41 10 f0 	movl   $0xf0104122,(%esp)
f01007b0:	e8 56 26 00 00       	call   f0102e0b <cprintf>
		for(int i = 2; i <= 6; i++)
f01007b5:	83 c3 01             	add    $0x1,%ebx
f01007b8:	83 fb 07             	cmp    $0x7,%ebx
f01007bb:	75 e5                	jne    f01007a2 <mon_backtrace+0x47>
		cprintf("\n");
f01007bd:	c7 04 24 3e 46 10 f0 	movl   $0xf010463e,(%esp)
f01007c4:	e8 42 26 00 00       	call   f0102e0b <cprintf>
		unsigned int eip = ebp[1];
f01007c9:	8b 5e 04             	mov    0x4(%esi),%ebx
		debuginfo_eip(eip, &info);
f01007cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007d0:	89 1c 24             	mov    %ebx,(%esp)
f01007d3:	e8 2a 27 00 00       	call   f0102f02 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007d8:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007db:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01007df:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007e2:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007f4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fb:	c7 04 24 28 41 10 f0 	movl   $0xf0104128,(%esp)
f0100802:	e8 04 26 00 00       	call   f0102e0b <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f0100807:	8b 36                	mov    (%esi),%esi
	while(ebp) {
f0100809:	85 f6                	test   %esi,%esi
f010080b:	0f 85 69 ff ff ff    	jne    f010077a <mon_backtrace+0x1f>
	}
	return 0;
}
f0100811:	b8 00 00 00 00       	mov    $0x0,%eax
f0100816:	83 c4 4c             	add    $0x4c,%esp
f0100819:	5b                   	pop    %ebx
f010081a:	5e                   	pop    %esi
f010081b:	5f                   	pop    %edi
f010081c:	5d                   	pop    %ebp
f010081d:	c3                   	ret    

f010081e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010081e:	55                   	push   %ebp
f010081f:	89 e5                	mov    %esp,%ebp
f0100821:	57                   	push   %edi
f0100822:	56                   	push   %esi
f0100823:	53                   	push   %ebx
f0100824:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100827:	c7 04 24 ec 42 10 f0 	movl   $0xf01042ec,(%esp)
f010082e:	e8 d8 25 00 00       	call   f0102e0b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100833:	c7 04 24 10 43 10 f0 	movl   $0xf0104310,(%esp)
f010083a:	e8 cc 25 00 00       	call   f0102e0b <cprintf>


	while (1) {
		buf = readline("K> ");
f010083f:	c7 04 24 39 41 10 f0 	movl   $0xf0104139,(%esp)
f0100846:	e8 b5 2e 00 00       	call   f0103700 <readline>
f010084b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010084d:	85 c0                	test   %eax,%eax
f010084f:	74 ee                	je     f010083f <monitor+0x21>
	argv[argc] = 0;
f0100851:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100858:	be 00 00 00 00       	mov    $0x0,%esi
f010085d:	eb 0a                	jmp    f0100869 <monitor+0x4b>
			*buf++ = 0;
f010085f:	c6 03 00             	movb   $0x0,(%ebx)
f0100862:	89 f7                	mov    %esi,%edi
f0100864:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100867:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100869:	0f b6 03             	movzbl (%ebx),%eax
f010086c:	84 c0                	test   %al,%al
f010086e:	74 64                	je     f01008d4 <monitor+0xb6>
f0100870:	0f be c0             	movsbl %al,%eax
f0100873:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100877:	c7 04 24 3d 41 10 f0 	movl   $0xf010413d,(%esp)
f010087e:	e8 97 30 00 00       	call   f010391a <strchr>
f0100883:	85 c0                	test   %eax,%eax
f0100885:	75 d8                	jne    f010085f <monitor+0x41>
		if (*buf == 0)
f0100887:	80 3b 00             	cmpb   $0x0,(%ebx)
f010088a:	74 48                	je     f01008d4 <monitor+0xb6>
		if (argc == MAXARGS-1) {
f010088c:	83 fe 0f             	cmp    $0xf,%esi
f010088f:	90                   	nop
f0100890:	75 16                	jne    f01008a8 <monitor+0x8a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100892:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100899:	00 
f010089a:	c7 04 24 42 41 10 f0 	movl   $0xf0104142,(%esp)
f01008a1:	e8 65 25 00 00       	call   f0102e0b <cprintf>
f01008a6:	eb 97                	jmp    f010083f <monitor+0x21>
		argv[argc++] = buf;
f01008a8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008ab:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008af:	eb 03                	jmp    f01008b4 <monitor+0x96>
			buf++;
f01008b1:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008b4:	0f b6 03             	movzbl (%ebx),%eax
f01008b7:	84 c0                	test   %al,%al
f01008b9:	74 ac                	je     f0100867 <monitor+0x49>
f01008bb:	0f be c0             	movsbl %al,%eax
f01008be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c2:	c7 04 24 3d 41 10 f0 	movl   $0xf010413d,(%esp)
f01008c9:	e8 4c 30 00 00       	call   f010391a <strchr>
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	74 df                	je     f01008b1 <monitor+0x93>
f01008d2:	eb 93                	jmp    f0100867 <monitor+0x49>
	argv[argc] = 0;
f01008d4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008db:	00 
	if (argc == 0)
f01008dc:	85 f6                	test   %esi,%esi
f01008de:	0f 84 5b ff ff ff    	je     f010083f <monitor+0x21>
f01008e4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008e9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ec:	8b 04 85 40 43 10 f0 	mov    -0xfefbcc0(,%eax,4),%eax
f01008f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008fa:	89 04 24             	mov    %eax,(%esp)
f01008fd:	e8 ba 2f 00 00       	call   f01038bc <strcmp>
f0100902:	85 c0                	test   %eax,%eax
f0100904:	75 24                	jne    f010092a <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100906:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100909:	8b 55 08             	mov    0x8(%ebp),%edx
f010090c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100910:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100913:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100917:	89 34 24             	mov    %esi,(%esp)
f010091a:	ff 14 85 48 43 10 f0 	call   *-0xfefbcb8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100921:	85 c0                	test   %eax,%eax
f0100923:	78 25                	js     f010094a <monitor+0x12c>
f0100925:	e9 15 ff ff ff       	jmp    f010083f <monitor+0x21>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010092a:	83 c3 01             	add    $0x1,%ebx
f010092d:	83 fb 03             	cmp    $0x3,%ebx
f0100930:	75 b7                	jne    f01008e9 <monitor+0xcb>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100932:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100935:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100939:	c7 04 24 5f 41 10 f0 	movl   $0xf010415f,(%esp)
f0100940:	e8 c6 24 00 00       	call   f0102e0b <cprintf>
f0100945:	e9 f5 fe ff ff       	jmp    f010083f <monitor+0x21>
				break;
	}
}
f010094a:	83 c4 5c             	add    $0x5c,%esp
f010094d:	5b                   	pop    %ebx
f010094e:	5e                   	pop    %esi
f010094f:	5f                   	pop    %edi
f0100950:	5d                   	pop    %ebp
f0100951:	c3                   	ret    
f0100952:	66 90                	xchg   %ax,%ax
f0100954:	66 90                	xchg   %ax,%ax
f0100956:	66 90                	xchg   %ax,%ax
f0100958:	66 90                	xchg   %ax,%ax
f010095a:	66 90                	xchg   %ax,%ax
f010095c:	66 90                	xchg   %ax,%ax
f010095e:	66 90                	xchg   %ax,%ax

f0100960 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100960:	55                   	push   %ebp
f0100961:	89 e5                	mov    %esp,%ebp
f0100963:	56                   	push   %esi
f0100964:	53                   	push   %ebx
f0100965:	83 ec 10             	sub    $0x10,%esp
f0100968:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010096a:	89 04 24             	mov    %eax,(%esp)
f010096d:	e8 29 24 00 00       	call   f0102d9b <mc146818_read>
f0100972:	89 c6                	mov    %eax,%esi
f0100974:	83 c3 01             	add    $0x1,%ebx
f0100977:	89 1c 24             	mov    %ebx,(%esp)
f010097a:	e8 1c 24 00 00       	call   f0102d9b <mc146818_read>
f010097f:	c1 e0 08             	shl    $0x8,%eax
f0100982:	09 f0                	or     %esi,%eax
}
f0100984:	83 c4 10             	add    $0x10,%esp
f0100987:	5b                   	pop    %ebx
f0100988:	5e                   	pop    %esi
f0100989:	5d                   	pop    %ebp
f010098a:	c3                   	ret    

f010098b <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010098b:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100992:	75 6b                	jne    f01009ff <boot_alloc+0x74>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100994:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100999:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099f:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if ( n > 0 ){
f01009a5:	85 c0                	test   %eax,%eax
f01009a7:	74 4d                	je     f01009f6 <boot_alloc+0x6b>
		char * next = nextfree;
f01009a9:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f01009af:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f01009b6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009bc:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
		if (((uint32_t)nextfree - KERNBASE) > (npages*PGSIZE))
f01009c2:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01009c8:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01009cd:	c1 e0 0c             	shl    $0xc,%eax
f01009d0:	39 c2                	cmp    %eax,%edx
f01009d2:	76 28                	jbe    f01009fc <boot_alloc+0x71>
{
f01009d4:	55                   	push   %ebp
f01009d5:	89 e5                	mov    %esp,%ebp
f01009d7:	83 ec 18             	sub    $0x18,%esp
			panic("Out of memory\n"); 
f01009da:	c7 44 24 08 64 43 10 	movl   $0xf0104364,0x8(%esp)
f01009e1:	f0 
f01009e2:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f01009e9:	00 
f01009ea:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01009f1:	e8 9e f6 ff ff       	call   f0100094 <_panic>
		return next;
	}
	else if (n == 0)
		return nextfree;
f01009f6:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f01009fb:	c3                   	ret    
		return next;
f01009fc:	89 c8                	mov    %ecx,%eax
f01009fe:	c3                   	ret    
	if ( n > 0 ){
f01009ff:	85 c0                	test   %eax,%eax
f0100a01:	75 a6                	jne    f01009a9 <boot_alloc+0x1e>
f0100a03:	eb f1                	jmp    f01009f6 <boot_alloc+0x6b>

f0100a05 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a05:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a0b:	c1 f8 03             	sar    $0x3,%eax
f0100a0e:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100a11:	89 c2                	mov    %eax,%edx
f0100a13:	c1 ea 0c             	shr    $0xc,%edx
f0100a16:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a1c:	72 26                	jb     f0100a44 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a1e:	55                   	push   %ebp
f0100a1f:	89 e5                	mov    %esp,%ebp
f0100a21:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a24:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a28:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100a2f:	f0 
f0100a30:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a37:	00 
f0100a38:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0100a3f:	e8 50 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a44:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100a49:	c3                   	ret    

f0100a4a <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a4a:	89 d1                	mov    %edx,%ecx
f0100a4c:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a4f:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a52:	a8 01                	test   $0x1,%al
f0100a54:	74 5d                	je     f0100ab3 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a56:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100a5b:	89 c1                	mov    %eax,%ecx
f0100a5d:	c1 e9 0c             	shr    $0xc,%ecx
f0100a60:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a66:	72 26                	jb     f0100a8e <check_va2pa+0x44>
{
f0100a68:	55                   	push   %ebp
f0100a69:	89 e5                	mov    %esp,%ebp
f0100a6b:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a72:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100a79:	f0 
f0100a7a:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f0100a81:	00 
f0100a82:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100a89:	e8 06 f6 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a8e:	c1 ea 0c             	shr    $0xc,%edx
f0100a91:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a97:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a9e:	89 c2                	mov    %eax,%edx
f0100aa0:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aa3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aa8:	85 d2                	test   %edx,%edx
f0100aaa:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100aaf:	0f 44 c2             	cmove  %edx,%eax
f0100ab2:	c3                   	ret    
		return ~0;
f0100ab3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100ab8:	c3                   	ret    

f0100ab9 <check_page_free_list>:
{
f0100ab9:	55                   	push   %ebp
f0100aba:	89 e5                	mov    %esp,%ebp
f0100abc:	57                   	push   %edi
f0100abd:	56                   	push   %esi
f0100abe:	53                   	push   %ebx
f0100abf:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ac2:	84 c0                	test   %al,%al
f0100ac4:	0f 85 15 03 00 00    	jne    f0100ddf <check_page_free_list+0x326>
f0100aca:	e9 26 03 00 00       	jmp    f0100df5 <check_page_free_list+0x33c>
		panic("'page_free_list' is a null pointer!");
f0100acf:	c7 44 24 08 94 46 10 	movl   $0xf0104694,0x8(%esp)
f0100ad6:	f0 
f0100ad7:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
f0100ade:	00 
f0100adf:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100ae6:	e8 a9 f5 ff ff       	call   f0100094 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aeb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aee:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100af1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100af7:	89 c2                	mov    %eax,%edx
f0100af9:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100aff:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b05:	0f 95 c2             	setne  %dl
f0100b08:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b0b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b0f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b11:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b15:	8b 00                	mov    (%eax),%eax
f0100b17:	85 c0                	test   %eax,%eax
f0100b19:	75 dc                	jne    f0100af7 <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100b1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b1e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b24:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b27:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b2a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b2c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b2f:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b34:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b39:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b3f:	eb 63                	jmp    f0100ba4 <check_page_free_list+0xeb>
f0100b41:	89 d8                	mov    %ebx,%eax
f0100b43:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b49:	c1 f8 03             	sar    $0x3,%eax
f0100b4c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b4f:	89 c2                	mov    %eax,%edx
f0100b51:	c1 ea 16             	shr    $0x16,%edx
f0100b54:	39 f2                	cmp    %esi,%edx
f0100b56:	73 4a                	jae    f0100ba2 <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100b58:	89 c2                	mov    %eax,%edx
f0100b5a:	c1 ea 0c             	shr    $0xc,%edx
f0100b5d:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b63:	72 20                	jb     f0100b85 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b69:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100b70:	f0 
f0100b71:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b78:	00 
f0100b79:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0100b80:	e8 0f f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b85:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b8c:	00 
f0100b8d:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b94:	00 
	return (void *)(pa + KERNBASE);
f0100b95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b9a:	89 04 24             	mov    %eax,(%esp)
f0100b9d:	e8 b5 2d 00 00       	call   f0103957 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba2:	8b 1b                	mov    (%ebx),%ebx
f0100ba4:	85 db                	test   %ebx,%ebx
f0100ba6:	75 99                	jne    f0100b41 <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100ba8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bad:	e8 d9 fd ff ff       	call   f010098b <boot_alloc>
f0100bb2:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bb5:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		assert(pp >= pages);
f0100bbb:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100bc1:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100bc6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bc9:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bcc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bcf:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bd2:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bd7:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bda:	e9 97 01 00 00       	jmp    f0100d76 <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100bdf:	39 ca                	cmp    %ecx,%edx
f0100be1:	73 24                	jae    f0100c07 <check_page_free_list+0x14e>
f0100be3:	c7 44 24 0c 8d 43 10 	movl   $0xf010438d,0xc(%esp)
f0100bea:	f0 
f0100beb:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100bf2:	f0 
f0100bf3:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f0100bfa:	00 
f0100bfb:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100c02:	e8 8d f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100c07:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c0a:	72 24                	jb     f0100c30 <check_page_free_list+0x177>
f0100c0c:	c7 44 24 0c ae 43 10 	movl   $0xf01043ae,0xc(%esp)
f0100c13:	f0 
f0100c14:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100c1b:	f0 
f0100c1c:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0100c23:	00 
f0100c24:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100c2b:	e8 64 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c30:	89 d0                	mov    %edx,%eax
f0100c32:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c35:	a8 07                	test   $0x7,%al
f0100c37:	74 24                	je     f0100c5d <check_page_free_list+0x1a4>
f0100c39:	c7 44 24 0c b8 46 10 	movl   $0xf01046b8,0xc(%esp)
f0100c40:	f0 
f0100c41:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100c48:	f0 
f0100c49:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0100c50:	00 
f0100c51:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100c58:	e8 37 f4 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0100c5d:	c1 f8 03             	sar    $0x3,%eax
f0100c60:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100c63:	85 c0                	test   %eax,%eax
f0100c65:	75 24                	jne    f0100c8b <check_page_free_list+0x1d2>
f0100c67:	c7 44 24 0c c2 43 10 	movl   $0xf01043c2,0xc(%esp)
f0100c6e:	f0 
f0100c6f:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100c76:	f0 
f0100c77:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0100c7e:	00 
f0100c7f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100c86:	e8 09 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c8b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c90:	75 24                	jne    f0100cb6 <check_page_free_list+0x1fd>
f0100c92:	c7 44 24 0c d3 43 10 	movl   $0xf01043d3,0xc(%esp)
f0100c99:	f0 
f0100c9a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100cb1:	e8 de f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cbb:	75 24                	jne    f0100ce1 <check_page_free_list+0x228>
f0100cbd:	c7 44 24 0c ec 46 10 	movl   $0xf01046ec,0xc(%esp)
f0100cc4:	f0 
f0100cc5:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
f0100cd4:	00 
f0100cd5:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100cdc:	e8 b3 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ce1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ce6:	75 24                	jne    f0100d0c <check_page_free_list+0x253>
f0100ce8:	c7 44 24 0c ec 43 10 	movl   $0xf01043ec,0xc(%esp)
f0100cef:	f0 
f0100cf0:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100cf7:	f0 
f0100cf8:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f0100cff:	00 
f0100d00:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100d07:	e8 88 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d0c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d11:	76 58                	jbe    f0100d6b <check_page_free_list+0x2b2>
	if (PGNUM(pa) >= npages)
f0100d13:	89 c3                	mov    %eax,%ebx
f0100d15:	c1 eb 0c             	shr    $0xc,%ebx
f0100d18:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d1b:	77 20                	ja     f0100d3d <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d21:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100d28:	f0 
f0100d29:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d30:	00 
f0100d31:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0100d38:	e8 57 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d42:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d45:	76 2a                	jbe    f0100d71 <check_page_free_list+0x2b8>
f0100d47:	c7 44 24 0c 10 47 10 	movl   $0xf0104710,0xc(%esp)
f0100d4e:	f0 
f0100d4f:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100d56:	f0 
f0100d57:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
f0100d5e:	00 
f0100d5f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100d66:	e8 29 f3 ff ff       	call   f0100094 <_panic>
			++nfree_basemem;
f0100d6b:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d6f:	eb 03                	jmp    f0100d74 <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100d71:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d74:	8b 12                	mov    (%edx),%edx
f0100d76:	85 d2                	test   %edx,%edx
f0100d78:	0f 85 61 fe ff ff    	jne    f0100bdf <check_page_free_list+0x126>
f0100d7e:	8b 5d cc             	mov    -0x34(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100d81:	85 db                	test   %ebx,%ebx
f0100d83:	7f 24                	jg     f0100da9 <check_page_free_list+0x2f0>
f0100d85:	c7 44 24 0c 06 44 10 	movl   $0xf0104406,0xc(%esp)
f0100d8c:	f0 
f0100d8d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100d94:	f0 
f0100d95:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100d9c:	00 
f0100d9d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100da4:	e8 eb f2 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100da9:	85 ff                	test   %edi,%edi
f0100dab:	7f 24                	jg     f0100dd1 <check_page_free_list+0x318>
f0100dad:	c7 44 24 0c 18 44 10 	movl   $0xf0104418,0xc(%esp)
f0100db4:	f0 
f0100db5:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0100dbc:	f0 
f0100dbd:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100dc4:	00 
f0100dc5:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100dcc:	e8 c3 f2 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0100dd1:	c7 04 24 58 47 10 f0 	movl   $0xf0104758,(%esp)
f0100dd8:	e8 2e 20 00 00       	call   f0102e0b <cprintf>
f0100ddd:	eb 2d                	jmp    f0100e0c <check_page_free_list+0x353>
	if (!page_free_list)
f0100ddf:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100de4:	85 c0                	test   %eax,%eax
f0100de6:	0f 85 ff fc ff ff    	jne    f0100aeb <check_page_free_list+0x32>
f0100dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100df0:	e9 da fc ff ff       	jmp    f0100acf <check_page_free_list+0x16>
f0100df5:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100dfc:	0f 84 cd fc ff ff    	je     f0100acf <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e02:	be 00 04 00 00       	mov    $0x400,%esi
f0100e07:	e9 2d fd ff ff       	jmp    f0100b39 <check_page_free_list+0x80>
}
f0100e0c:	83 c4 4c             	add    $0x4c,%esp
f0100e0f:	5b                   	pop    %ebx
f0100e10:	5e                   	pop    %esi
f0100e11:	5f                   	pop    %edi
f0100e12:	5d                   	pop    %ebp
f0100e13:	c3                   	ret    

f0100e14 <page_init>:
{
f0100e14:	55                   	push   %ebp
f0100e15:	89 e5                	mov    %esp,%ebp
f0100e17:	57                   	push   %edi
f0100e18:	56                   	push   %esi
f0100e19:	53                   	push   %ebx
f0100e1a:	83 ec 0c             	sub    $0xc,%esp
	int no_pages_in_extended_used = ((uint32_t)boot_alloc(0) - KERNBASE)/ PGSIZE;
f0100e1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e22:	e8 64 fb ff ff       	call   f010098b <boot_alloc>
f0100e27:	8d b0 00 00 00 10    	lea    0x10000000(%eax),%esi
f0100e2d:	c1 ee 0c             	shr    $0xc,%esi
	pages[0].pp_ref = 1;
f0100e30:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e35:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0100e3b:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100e41:	8b 3d 3c 75 11 f0    	mov    0xf011753c,%edi
f0100e47:	ba 01 00 00 00       	mov    $0x1,%edx
f0100e4c:	eb 21                	jmp    f0100e6f <page_init+0x5b>
f0100e4e:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
		pages[i].pp_ref = 0;
f0100e55:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e5a:	66 c7 44 08 04 00 00 	movw   $0x0,0x4(%eax,%ecx,1)
		pages[i].pp_link = page_free_list;
f0100e61:	89 3c d0             	mov    %edi,(%eax,%edx,8)
	for (i = 1; i < npages_basemem; i++) {
f0100e64:	83 c2 01             	add    $0x1,%edx
		page_free_list = &pages[i];
f0100e67:	89 cf                	mov    %ecx,%edi
f0100e69:	03 3d 6c 79 11 f0    	add    0xf011796c,%edi
	for (i = 1; i < npages_basemem; i++) {
f0100e6f:	39 da                	cmp    %ebx,%edx
f0100e71:	72 db                	jb     f0100e4e <page_init+0x3a>
f0100e73:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c
  		pages[i].pp_ref = 1;
f0100e79:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	for (i = 1; i < npages_basemem; i++) {
f0100e7f:	89 da                	mov    %ebx,%edx
	for(i = npages_basemem; i < npages_basemem + no_pages_in_IOhole + no_pages_in_extended_used; i++)
f0100e81:	8d 44 1e 60          	lea    0x60(%esi,%ebx,1),%eax
f0100e85:	eb 0a                	jmp    f0100e91 <page_init+0x7d>
  		pages[i].pp_ref = 1;
f0100e87:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
	for(i = npages_basemem; i < npages_basemem + no_pages_in_IOhole + no_pages_in_extended_used; i++)
f0100e8e:	83 c2 01             	add    $0x1,%edx
f0100e91:	39 c2                	cmp    %eax,%edx
f0100e93:	72 f2                	jb     f0100e87 <page_init+0x73>
f0100e95:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e9b:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100ea2:	eb 1e                	jmp    f0100ec2 <page_init+0xae>
		pages[i].pp_ref = 0;
f0100ea4:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0100eaa:	66 c7 44 01 04 00 00 	movw   $0x0,0x4(%ecx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100eb1:	89 1c 01             	mov    %ebx,(%ecx,%eax,1)
		page_free_list = &pages[i];
f0100eb4:	89 c3                	mov    %eax,%ebx
f0100eb6:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
	for (; i < npages; i++) {
f0100ebc:	83 c2 01             	add    $0x1,%edx
f0100ebf:	83 c0 08             	add    $0x8,%eax
f0100ec2:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ec8:	72 da                	jb     f0100ea4 <page_init+0x90>
f0100eca:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
}
f0100ed0:	83 c4 0c             	add    $0xc,%esp
f0100ed3:	5b                   	pop    %ebx
f0100ed4:	5e                   	pop    %esi
f0100ed5:	5f                   	pop    %edi
f0100ed6:	5d                   	pop    %ebp
f0100ed7:	c3                   	ret    

f0100ed8 <page_alloc>:
{
f0100ed8:	55                   	push   %ebp
f0100ed9:	89 e5                	mov    %esp,%ebp
f0100edb:	53                   	push   %ebx
f0100edc:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list) {
f0100edf:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ee5:	85 db                	test   %ebx,%ebx
f0100ee7:	74 6f                	je     f0100f58 <page_alloc+0x80>
		if (alloc_flags & ALLOC_ZERO) 
f0100ee9:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100eed:	74 58                	je     f0100f47 <page_alloc+0x6f>
	return (pp - pages) << PGSHIFT;
f0100eef:	89 d8                	mov    %ebx,%eax
f0100ef1:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ef7:	c1 f8 03             	sar    $0x3,%eax
f0100efa:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100efd:	89 c2                	mov    %eax,%edx
f0100eff:	c1 ea 0c             	shr    $0xc,%edx
f0100f02:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f08:	72 20                	jb     f0100f2a <page_alloc+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f0e:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100f15:	f0 
f0100f16:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f1d:	00 
f0100f1e:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0100f25:	e8 6a f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100f2a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f31:	00 
f0100f32:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f39:	00 
	return (void *)(pa + KERNBASE);
f0100f3a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f3f:	89 04 24             	mov    %eax,(%esp)
f0100f42:	e8 10 2a 00 00       	call   f0103957 <memset>
		page_free_list = ret->pp_link;
f0100f47:	8b 03                	mov    (%ebx),%eax
f0100f49:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
		ret->pp_link = 0;
f0100f4e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		return ret;
f0100f54:	89 d8                	mov    %ebx,%eax
f0100f56:	eb 05                	jmp    f0100f5d <page_alloc+0x85>
	return NULL;
f0100f58:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f5d:	83 c4 14             	add    $0x14,%esp
f0100f60:	5b                   	pop    %ebx
f0100f61:	5d                   	pop    %ebp
f0100f62:	c3                   	ret    

f0100f63 <page_free>:
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
f0100f66:	83 ec 18             	sub    $0x18,%esp
f0100f69:	8b 45 08             	mov    0x8(%ebp),%eax
	if ((pp->pp_ref != 0) || (pp->pp_link != NULL))
f0100f6c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f71:	75 05                	jne    f0100f78 <page_free+0x15>
f0100f73:	83 38 00             	cmpl   $0x0,(%eax)
f0100f76:	74 1c                	je     f0100f94 <page_free+0x31>
		panic("Page is still being used\n");
f0100f78:	c7 44 24 08 29 44 10 	movl   $0xf0104429,0x8(%esp)
f0100f7f:	f0 
f0100f80:	c7 44 24 04 4c 01 00 	movl   $0x14c,0x4(%esp)
f0100f87:	00 
f0100f88:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0100f8f:	e8 00 f1 ff ff       	call   f0100094 <_panic>
		pp->pp_link = page_free_list;
f0100f94:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100f9a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100f9c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100fa1:	c9                   	leave  
f0100fa2:	c3                   	ret    

f0100fa3 <page_decref>:
{
f0100fa3:	55                   	push   %ebp
f0100fa4:	89 e5                	mov    %esp,%ebp
f0100fa6:	83 ec 18             	sub    $0x18,%esp
f0100fa9:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100fac:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100fb0:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100fb3:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fb7:	66 85 d2             	test   %dx,%dx
f0100fba:	75 08                	jne    f0100fc4 <page_decref+0x21>
		page_free(pp);
f0100fbc:	89 04 24             	mov    %eax,(%esp)
f0100fbf:	e8 9f ff ff ff       	call   f0100f63 <page_free>
}
f0100fc4:	c9                   	leave  
f0100fc5:	c3                   	ret    

f0100fc6 <pgdir_walk>:
{
f0100fc6:	55                   	push   %ebp
f0100fc7:	89 e5                	mov    %esp,%ebp
f0100fc9:	56                   	push   %esi
f0100fca:	53                   	push   %ebx
f0100fcb:	83 ec 10             	sub    $0x10,%esp
f0100fce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pde_t pde = pgdir[PDX(va)];
f0100fd1:	89 de                	mov    %ebx,%esi
f0100fd3:	c1 ee 16             	shr    $0x16,%esi
f0100fd6:	c1 e6 02             	shl    $0x2,%esi
f0100fd9:	03 75 08             	add    0x8(%ebp),%esi
f0100fdc:	8b 06                	mov    (%esi),%eax
	if(pde & PTE_P)
f0100fde:	a8 01                	test   $0x1,%al
f0100fe0:	74 47                	je     f0101029 <pgdir_walk+0x63>
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
f0100fe2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100fe7:	89 c2                	mov    %eax,%edx
f0100fe9:	c1 ea 0c             	shr    $0xc,%edx
f0100fec:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ff2:	72 20                	jb     f0101014 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ff8:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0100fff:	f0 
f0101000:	c7 44 24 04 7c 01 00 	movl   $0x17c,0x4(%esp)
f0101007:	00 
f0101008:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010100f:	e8 80 f0 ff ff       	call   f0100094 <_panic>
		result = pg_table_p + PTX(va);
f0101014:	c1 eb 0a             	shr    $0xa,%ebx
f0101017:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
		return result;
f010101d:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0101024:	e9 85 00 00 00       	jmp    f01010ae <pgdir_walk+0xe8>
	else if(!create)
f0101029:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010102d:	74 73                	je     f01010a2 <pgdir_walk+0xdc>
		struct PageInfo *pp = page_alloc(1);
f010102f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101036:	e8 9d fe ff ff       	call   f0100ed8 <page_alloc>
		if(!pp)
f010103b:	85 c0                	test   %eax,%eax
f010103d:	74 6a                	je     f01010a9 <pgdir_walk+0xe3>
			pp->pp_ref++;
f010103f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101044:	89 c2                	mov    %eax,%edx
f0101046:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010104c:	c1 fa 03             	sar    $0x3,%edx
f010104f:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W;
f0101052:	83 ca 03             	or     $0x3,%edx
f0101055:	89 16                	mov    %edx,(%esi)
f0101057:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010105d:	c1 f8 03             	sar    $0x3,%eax
f0101060:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101063:	89 c2                	mov    %eax,%edx
f0101065:	c1 ea 0c             	shr    $0xc,%edx
f0101068:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010106e:	72 20                	jb     f0101090 <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101070:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101074:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f010107b:	f0 
f010107c:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f0101083:	00 
f0101084:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010108b:	e8 04 f0 ff ff       	call   f0100094 <_panic>
			result = pg_table_p + PTX(va);
f0101090:	c1 eb 0a             	shr    $0xa,%ebx
f0101093:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
			return result;
f0101099:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f01010a0:	eb 0c                	jmp    f01010ae <pgdir_walk+0xe8>
		return NULL;
f01010a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a7:	eb 05                	jmp    f01010ae <pgdir_walk+0xe8>
			return NULL;
f01010a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010ae:	83 c4 10             	add    $0x10,%esp
f01010b1:	5b                   	pop    %ebx
f01010b2:	5e                   	pop    %esi
f01010b3:	5d                   	pop    %ebp
f01010b4:	c3                   	ret    

f01010b5 <boot_map_region>:
{
f01010b5:	55                   	push   %ebp
f01010b6:	89 e5                	mov    %esp,%ebp
f01010b8:	57                   	push   %edi
f01010b9:	56                   	push   %esi
f01010ba:	53                   	push   %ebx
f01010bb:	83 ec 2c             	sub    $0x2c,%esp
f01010be:	89 c7                	mov    %eax,%edi
f01010c0:	8b 45 08             	mov    0x8(%ebp),%eax
    	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01010c3:	c1 e9 0c             	shr    $0xc,%ecx
f01010c6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010c9:	89 c3                	mov    %eax,%ebx
f01010cb:	be 00 00 00 00       	mov    $0x0,%esi
f01010d0:	29 c2                	sub    %eax,%edx
f01010d2:	89 55 e0             	mov    %edx,-0x20(%ebp)
        	*pte = pa | perm | PTE_P;
f01010d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010d8:	83 c8 01             	or     $0x1,%eax
f01010db:	89 45 dc             	mov    %eax,-0x24(%ebp)
    	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01010de:	eb 49                	jmp    f0101129 <boot_map_region+0x74>
        	pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f01010e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010e7:	00 
f01010e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010eb:	01 d8                	add    %ebx,%eax
f01010ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010f1:	89 3c 24             	mov    %edi,(%esp)
f01010f4:	e8 cd fe ff ff       	call   f0100fc6 <pgdir_walk>
        	if (!pte)
f01010f9:	85 c0                	test   %eax,%eax
f01010fb:	75 1c                	jne    f0101119 <boot_map_region+0x64>
			panic("boot_map_region panic, out of memory");
f01010fd:	c7 44 24 08 7c 47 10 	movl   $0xf010477c,0x8(%esp)
f0101104:	f0 
f0101105:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
f010110c:	00 
f010110d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101114:	e8 7b ef ff ff       	call   f0100094 <_panic>
        	*pte = pa | perm | PTE_P;
f0101119:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010111c:	09 da                	or     %ebx,%edx
f010111e:	89 10                	mov    %edx,(%eax)
    	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0101120:	83 c6 01             	add    $0x1,%esi
f0101123:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101129:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010112c:	75 b2                	jne    f01010e0 <boot_map_region+0x2b>
}
f010112e:	83 c4 2c             	add    $0x2c,%esp
f0101131:	5b                   	pop    %ebx
f0101132:	5e                   	pop    %esi
f0101133:	5f                   	pop    %edi
f0101134:	5d                   	pop    %ebp
f0101135:	c3                   	ret    

f0101136 <page_lookup>:
{
f0101136:	55                   	push   %ebp
f0101137:	89 e5                	mov    %esp,%ebp
f0101139:	53                   	push   %ebx
f010113a:	83 ec 14             	sub    $0x14,%esp
f010113d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t * ptep = pgdir_walk(pgdir, va, 0);
f0101140:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101147:	00 
f0101148:	8b 45 0c             	mov    0xc(%ebp),%eax
f010114b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010114f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101152:	89 04 24             	mov    %eax,(%esp)
f0101155:	e8 6c fe ff ff       	call   f0100fc6 <pgdir_walk>
f010115a:	89 c2                	mov    %eax,%edx
	if(ptep && ((*ptep) & PTE_P)) {
f010115c:	85 c0                	test   %eax,%eax
f010115e:	74 3e                	je     f010119e <page_lookup+0x68>
f0101160:	8b 00                	mov    (%eax),%eax
f0101162:	a8 01                	test   $0x1,%al
f0101164:	74 3f                	je     f01011a5 <page_lookup+0x6f>
	if (PGNUM(pa) >= npages)
f0101166:	c1 e8 0c             	shr    $0xc,%eax
f0101169:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f010116f:	72 1c                	jb     f010118d <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101171:	c7 44 24 08 a4 47 10 	movl   $0xf01047a4,0x8(%esp)
f0101178:	f0 
f0101179:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101180:	00 
f0101181:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0101188:	e8 07 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010118d:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0101193:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if(pte_store)
f0101196:	85 db                	test   %ebx,%ebx
f0101198:	74 10                	je     f01011aa <page_lookup+0x74>
			*pte_store = ptep;
f010119a:	89 13                	mov    %edx,(%ebx)
f010119c:	eb 0c                	jmp    f01011aa <page_lookup+0x74>
	return NULL;
f010119e:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a3:	eb 05                	jmp    f01011aa <page_lookup+0x74>
f01011a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01011aa:	83 c4 14             	add    $0x14,%esp
f01011ad:	5b                   	pop    %ebx
f01011ae:	5d                   	pop    %ebp
f01011af:	c3                   	ret    

f01011b0 <page_remove>:
{
f01011b0:	55                   	push   %ebp
f01011b1:	89 e5                	mov    %esp,%ebp
f01011b3:	53                   	push   %ebx
f01011b4:	83 ec 24             	sub    $0x24,%esp
f01011b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pp = page_lookup(pgdir, va, &ptep);
f01011ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011bd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01011c8:	89 04 24             	mov    %eax,(%esp)
f01011cb:	e8 66 ff ff ff       	call   f0101136 <page_lookup>
	if(!pp || !(*ptep & PTE_P))
f01011d0:	85 c0                	test   %eax,%eax
f01011d2:	74 1c                	je     f01011f0 <page_remove+0x40>
f01011d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011d7:	f6 02 01             	testb  $0x1,(%edx)
f01011da:	74 14                	je     f01011f0 <page_remove+0x40>
	page_decref(pp);		// the ref count of the physical page should decrement
f01011dc:	89 04 24             	mov    %eax,(%esp)
f01011df:	e8 bf fd ff ff       	call   f0100fa3 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011e4:	0f 01 3b             	invlpg (%ebx)
	*ptep = 0;
f01011e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f01011f0:	83 c4 24             	add    $0x24,%esp
f01011f3:	5b                   	pop    %ebx
f01011f4:	5d                   	pop    %ebp
f01011f5:	c3                   	ret    

f01011f6 <page_insert>:
{
f01011f6:	55                   	push   %ebp
f01011f7:	89 e5                	mov    %esp,%ebp
f01011f9:	57                   	push   %edi
f01011fa:	56                   	push   %esi
f01011fb:	53                   	push   %ebx
f01011fc:	83 ec 1c             	sub    $0x1c,%esp
f01011ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101202:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
f0101205:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010120c:	00 
f010120d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101210:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101214:	89 1c 24             	mov    %ebx,(%esp)
f0101217:	e8 aa fd ff ff       	call   f0100fc6 <pgdir_walk>
f010121c:	89 c6                	mov    %eax,%esi
	if(ptep == NULL)
f010121e:	85 c0                	test   %eax,%eax
f0101220:	74 42                	je     f0101264 <page_insert+0x6e>
	pp->pp_ref++;
f0101222:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	if((*ptep) & PTE_P)
f0101227:	f6 00 01             	testb  $0x1,(%eax)
f010122a:	74 0f                	je     f010123b <page_insert+0x45>
		page_remove(pgdir, va);
f010122c:	8b 45 10             	mov    0x10(%ebp),%eax
f010122f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101233:	89 1c 24             	mov    %ebx,(%esp)
f0101236:	e8 75 ff ff ff       	call   f01011b0 <page_remove>
	*ptep  = page2pa(pp) | PTE_P | perm;
f010123b:	8b 45 14             	mov    0x14(%ebp),%eax
f010123e:	83 c8 01             	or     $0x1,%eax
	return (pp - pages) << PGSHIFT;
f0101241:	2b 3d 6c 79 11 f0    	sub    0xf011796c,%edi
f0101247:	c1 ff 03             	sar    $0x3,%edi
f010124a:	c1 e7 0c             	shl    $0xc,%edi
f010124d:	09 c7                	or     %eax,%edi
f010124f:	89 3e                	mov    %edi,(%esi)
	pgdir[PDX(va)] |= perm;    //when permission of PTE changes, PDE should also change
f0101251:	8b 45 10             	mov    0x10(%ebp),%eax
f0101254:	c1 e8 16             	shr    $0x16,%eax
f0101257:	8b 55 14             	mov    0x14(%ebp),%edx
f010125a:	09 14 83             	or     %edx,(%ebx,%eax,4)
	return 0;
f010125d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101262:	eb 05                	jmp    f0101269 <page_insert+0x73>
		return -E_NO_MEM;
f0101264:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0101269:	83 c4 1c             	add    $0x1c,%esp
f010126c:	5b                   	pop    %ebx
f010126d:	5e                   	pop    %esi
f010126e:	5f                   	pop    %edi
f010126f:	5d                   	pop    %ebp
f0101270:	c3                   	ret    

f0101271 <mem_init>:
{
f0101271:	55                   	push   %ebp
f0101272:	89 e5                	mov    %esp,%ebp
f0101274:	57                   	push   %edi
f0101275:	56                   	push   %esi
f0101276:	53                   	push   %ebx
f0101277:	83 ec 4c             	sub    $0x4c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f010127a:	b8 15 00 00 00       	mov    $0x15,%eax
f010127f:	e8 dc f6 ff ff       	call   f0100960 <nvram_read>
f0101284:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101286:	b8 17 00 00 00       	mov    $0x17,%eax
f010128b:	e8 d0 f6 ff ff       	call   f0100960 <nvram_read>
f0101290:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101292:	b8 34 00 00 00       	mov    $0x34,%eax
f0101297:	e8 c4 f6 ff ff       	call   f0100960 <nvram_read>
f010129c:	c1 e0 06             	shl    $0x6,%eax
f010129f:	89 c2                	mov    %eax,%edx
		totalmem = 16 * 1024 + ext16mem;
f01012a1:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	if (ext16mem)
f01012a7:	85 d2                	test   %edx,%edx
f01012a9:	75 0b                	jne    f01012b6 <mem_init+0x45>
		totalmem = 1 * 1024 + extmem;
f01012ab:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01012b1:	85 f6                	test   %esi,%esi
f01012b3:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01012b6:	89 c2                	mov    %eax,%edx
f01012b8:	c1 ea 02             	shr    $0x2,%edx
f01012bb:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f01012c1:	89 da                	mov    %ebx,%edx
f01012c3:	c1 ea 02             	shr    $0x2,%edx
f01012c6:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012cc:	89 c2                	mov    %eax,%edx
f01012ce:	29 da                	sub    %ebx,%edx
f01012d0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012d4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01012d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012dc:	c7 04 24 c4 47 10 f0 	movl   $0xf01047c4,(%esp)
f01012e3:	e8 23 1b 00 00       	call   f0102e0b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012e8:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012ed:	e8 99 f6 ff ff       	call   f010098b <boot_alloc>
f01012f2:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01012f7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012fe:	00 
f01012ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101306:	00 
f0101307:	89 04 24             	mov    %eax,(%esp)
f010130a:	e8 48 26 00 00       	call   f0103957 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010130f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
	if ((uint32_t)kva < KERNBASE)
f0101314:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101319:	77 20                	ja     f010133b <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010131b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010131f:	c7 44 24 08 00 48 10 	movl   $0xf0104800,0x8(%esp)
f0101326:	f0 
f0101327:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f010132e:	00 
f010132f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101336:	e8 59 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010133b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101341:	83 ca 05             	or     $0x5,%edx
f0101344:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f010134a:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010134f:	c1 e0 03             	shl    $0x3,%eax
f0101352:	e8 34 f6 ff ff       	call   f010098b <boot_alloc>
f0101357:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, (npages * sizeof(struct PageInfo)));
f010135c:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101362:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101369:	89 54 24 08          	mov    %edx,0x8(%esp)
f010136d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101374:	00 
f0101375:	89 04 24             	mov    %eax,(%esp)
f0101378:	e8 da 25 00 00       	call   f0103957 <memset>
	page_init();
f010137d:	e8 92 fa ff ff       	call   f0100e14 <page_init>
	check_page_free_list(1);
f0101382:	b8 01 00 00 00       	mov    $0x1,%eax
f0101387:	e8 2d f7 ff ff       	call   f0100ab9 <check_page_free_list>
	if (!pages)
f010138c:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f0101393:	75 1c                	jne    f01013b1 <mem_init+0x140>
		panic("'pages' is a null pointer!");
f0101395:	c7 44 24 08 43 44 10 	movl   $0xf0104443,0x8(%esp)
f010139c:	f0 
f010139d:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f01013a4:	00 
f01013a5:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01013ac:	e8 e3 ec ff ff       	call   f0100094 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b1:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01013b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013bb:	eb 05                	jmp    f01013c2 <mem_init+0x151>
		++nfree;
f01013bd:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013c0:	8b 00                	mov    (%eax),%eax
f01013c2:	85 c0                	test   %eax,%eax
f01013c4:	75 f7                	jne    f01013bd <mem_init+0x14c>
	assert((pp0 = page_alloc(0)));
f01013c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cd:	e8 06 fb ff ff       	call   f0100ed8 <page_alloc>
f01013d2:	89 c7                	mov    %eax,%edi
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	75 24                	jne    f01013fc <mem_init+0x18b>
f01013d8:	c7 44 24 0c 5e 44 10 	movl   $0xf010445e,0xc(%esp)
f01013df:	f0 
f01013e0:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01013e7:	f0 
f01013e8:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f01013ef:	00 
f01013f0:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01013f7:	e8 98 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101403:	e8 d0 fa ff ff       	call   f0100ed8 <page_alloc>
f0101408:	89 c6                	mov    %eax,%esi
f010140a:	85 c0                	test   %eax,%eax
f010140c:	75 24                	jne    f0101432 <mem_init+0x1c1>
f010140e:	c7 44 24 0c 74 44 10 	movl   $0xf0104474,0xc(%esp)
f0101415:	f0 
f0101416:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010141d:	f0 
f010141e:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0101425:	00 
f0101426:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010142d:	e8 62 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101432:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101439:	e8 9a fa ff ff       	call   f0100ed8 <page_alloc>
f010143e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101441:	85 c0                	test   %eax,%eax
f0101443:	75 24                	jne    f0101469 <mem_init+0x1f8>
f0101445:	c7 44 24 0c 8a 44 10 	movl   $0xf010448a,0xc(%esp)
f010144c:	f0 
f010144d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101454:	f0 
f0101455:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f010145c:	00 
f010145d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101464:	e8 2b ec ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f0101469:	39 f7                	cmp    %esi,%edi
f010146b:	75 24                	jne    f0101491 <mem_init+0x220>
f010146d:	c7 44 24 0c a0 44 10 	movl   $0xf01044a0,0xc(%esp)
f0101474:	f0 
f0101475:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010147c:	f0 
f010147d:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101484:	00 
f0101485:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010148c:	e8 03 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101491:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101494:	39 c6                	cmp    %eax,%esi
f0101496:	74 04                	je     f010149c <mem_init+0x22b>
f0101498:	39 c7                	cmp    %eax,%edi
f010149a:	75 24                	jne    f01014c0 <mem_init+0x24f>
f010149c:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f01014a3:	f0 
f01014a4:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01014ab:	f0 
f01014ac:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f01014b3:	00 
f01014b4:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01014bb:	e8 d4 eb ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f01014c0:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014c6:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01014cb:	c1 e0 0c             	shl    $0xc,%eax
f01014ce:	89 f9                	mov    %edi,%ecx
f01014d0:	29 d1                	sub    %edx,%ecx
f01014d2:	c1 f9 03             	sar    $0x3,%ecx
f01014d5:	c1 e1 0c             	shl    $0xc,%ecx
f01014d8:	39 c1                	cmp    %eax,%ecx
f01014da:	72 24                	jb     f0101500 <mem_init+0x28f>
f01014dc:	c7 44 24 0c b2 44 10 	movl   $0xf01044b2,0xc(%esp)
f01014e3:	f0 
f01014e4:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01014eb:	f0 
f01014ec:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f01014f3:	00 
f01014f4:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01014fb:	e8 94 eb ff ff       	call   f0100094 <_panic>
f0101500:	89 f1                	mov    %esi,%ecx
f0101502:	29 d1                	sub    %edx,%ecx
f0101504:	c1 f9 03             	sar    $0x3,%ecx
f0101507:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010150a:	39 c8                	cmp    %ecx,%eax
f010150c:	77 24                	ja     f0101532 <mem_init+0x2c1>
f010150e:	c7 44 24 0c cf 44 10 	movl   $0xf01044cf,0xc(%esp)
f0101515:	f0 
f0101516:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010151d:	f0 
f010151e:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101525:	00 
f0101526:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010152d:	e8 62 eb ff ff       	call   f0100094 <_panic>
f0101532:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101535:	29 d1                	sub    %edx,%ecx
f0101537:	89 ca                	mov    %ecx,%edx
f0101539:	c1 fa 03             	sar    $0x3,%edx
f010153c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010153f:	39 d0                	cmp    %edx,%eax
f0101541:	77 24                	ja     f0101567 <mem_init+0x2f6>
f0101543:	c7 44 24 0c ec 44 10 	movl   $0xf01044ec,0xc(%esp)
f010154a:	f0 
f010154b:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101552:	f0 
f0101553:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010155a:	00 
f010155b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101562:	e8 2d eb ff ff       	call   f0100094 <_panic>
	fl = page_free_list;
f0101567:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010156c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010156f:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101576:	00 00 00 
	assert(!page_alloc(0));
f0101579:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101580:	e8 53 f9 ff ff       	call   f0100ed8 <page_alloc>
f0101585:	85 c0                	test   %eax,%eax
f0101587:	74 24                	je     f01015ad <mem_init+0x33c>
f0101589:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f0101590:	f0 
f0101591:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101598:	f0 
f0101599:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01015a0:	00 
f01015a1:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01015a8:	e8 e7 ea ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01015ad:	89 3c 24             	mov    %edi,(%esp)
f01015b0:	e8 ae f9 ff ff       	call   f0100f63 <page_free>
	page_free(pp1);
f01015b5:	89 34 24             	mov    %esi,(%esp)
f01015b8:	e8 a6 f9 ff ff       	call   f0100f63 <page_free>
	page_free(pp2);
f01015bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015c0:	89 04 24             	mov    %eax,(%esp)
f01015c3:	e8 9b f9 ff ff       	call   f0100f63 <page_free>
	assert((pp0 = page_alloc(0)));
f01015c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015cf:	e8 04 f9 ff ff       	call   f0100ed8 <page_alloc>
f01015d4:	89 c6                	mov    %eax,%esi
f01015d6:	85 c0                	test   %eax,%eax
f01015d8:	75 24                	jne    f01015fe <mem_init+0x38d>
f01015da:	c7 44 24 0c 5e 44 10 	movl   $0xf010445e,0xc(%esp)
f01015e1:	f0 
f01015e2:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01015e9:	f0 
f01015ea:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f01015f1:	00 
f01015f2:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01015f9:	e8 96 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101605:	e8 ce f8 ff ff       	call   f0100ed8 <page_alloc>
f010160a:	89 c7                	mov    %eax,%edi
f010160c:	85 c0                	test   %eax,%eax
f010160e:	75 24                	jne    f0101634 <mem_init+0x3c3>
f0101610:	c7 44 24 0c 74 44 10 	movl   $0xf0104474,0xc(%esp)
f0101617:	f0 
f0101618:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010161f:	f0 
f0101620:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101627:	00 
f0101628:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010162f:	e8 60 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101634:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010163b:	e8 98 f8 ff ff       	call   f0100ed8 <page_alloc>
f0101640:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101643:	85 c0                	test   %eax,%eax
f0101645:	75 24                	jne    f010166b <mem_init+0x3fa>
f0101647:	c7 44 24 0c 8a 44 10 	movl   $0xf010448a,0xc(%esp)
f010164e:	f0 
f010164f:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101656:	f0 
f0101657:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f010165e:	00 
f010165f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101666:	e8 29 ea ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f010166b:	39 fe                	cmp    %edi,%esi
f010166d:	75 24                	jne    f0101693 <mem_init+0x422>
f010166f:	c7 44 24 0c a0 44 10 	movl   $0xf01044a0,0xc(%esp)
f0101676:	f0 
f0101677:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010167e:	f0 
f010167f:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0101686:	00 
f0101687:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010168e:	e8 01 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101693:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101696:	39 c7                	cmp    %eax,%edi
f0101698:	74 04                	je     f010169e <mem_init+0x42d>
f010169a:	39 c6                	cmp    %eax,%esi
f010169c:	75 24                	jne    f01016c2 <mem_init+0x451>
f010169e:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f01016a5:	f0 
f01016a6:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01016ad:	f0 
f01016ae:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f01016b5:	00 
f01016b6:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01016bd:	e8 d2 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01016c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016c9:	e8 0a f8 ff ff       	call   f0100ed8 <page_alloc>
f01016ce:	85 c0                	test   %eax,%eax
f01016d0:	74 24                	je     f01016f6 <mem_init+0x485>
f01016d2:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f01016d9:	f0 
f01016da:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01016e1:	f0 
f01016e2:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f01016e9:	00 
f01016ea:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01016f1:	e8 9e e9 ff ff       	call   f0100094 <_panic>
f01016f6:	89 f0                	mov    %esi,%eax
f01016f8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01016fe:	c1 f8 03             	sar    $0x3,%eax
f0101701:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101704:	89 c2                	mov    %eax,%edx
f0101706:	c1 ea 0c             	shr    $0xc,%edx
f0101709:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010170f:	72 20                	jb     f0101731 <mem_init+0x4c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101711:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101715:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f010171c:	f0 
f010171d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101724:	00 
f0101725:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f010172c:	e8 63 e9 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f0101731:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101738:	00 
f0101739:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101740:	00 
	return (void *)(pa + KERNBASE);
f0101741:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101746:	89 04 24             	mov    %eax,(%esp)
f0101749:	e8 09 22 00 00       	call   f0103957 <memset>
	page_free(pp0);
f010174e:	89 34 24             	mov    %esi,(%esp)
f0101751:	e8 0d f8 ff ff       	call   f0100f63 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101756:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010175d:	e8 76 f7 ff ff       	call   f0100ed8 <page_alloc>
f0101762:	85 c0                	test   %eax,%eax
f0101764:	75 24                	jne    f010178a <mem_init+0x519>
f0101766:	c7 44 24 0c 18 45 10 	movl   $0xf0104518,0xc(%esp)
f010176d:	f0 
f010176e:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101775:	f0 
f0101776:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f010177d:	00 
f010177e:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101785:	e8 0a e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010178a:	39 c6                	cmp    %eax,%esi
f010178c:	74 24                	je     f01017b2 <mem_init+0x541>
f010178e:	c7 44 24 0c 36 45 10 	movl   $0xf0104536,0xc(%esp)
f0101795:	f0 
f0101796:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010179d:	f0 
f010179e:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f01017a5:	00 
f01017a6:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01017ad:	e8 e2 e8 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f01017b2:	89 f0                	mov    %esi,%eax
f01017b4:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01017ba:	c1 f8 03             	sar    $0x3,%eax
f01017bd:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01017c0:	89 c2                	mov    %eax,%edx
f01017c2:	c1 ea 0c             	shr    $0xc,%edx
f01017c5:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01017cb:	72 20                	jb     f01017ed <mem_init+0x57c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017d1:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f01017d8:	f0 
f01017d9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017e0:	00 
f01017e1:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f01017e8:	e8 a7 e8 ff ff       	call   f0100094 <_panic>
f01017ed:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017f3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
		assert(c[i] == 0);
f01017f9:	80 38 00             	cmpb   $0x0,(%eax)
f01017fc:	74 24                	je     f0101822 <mem_init+0x5b1>
f01017fe:	c7 44 24 0c 46 45 10 	movl   $0xf0104546,0xc(%esp)
f0101805:	f0 
f0101806:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010180d:	f0 
f010180e:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0101815:	00 
f0101816:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010181d:	e8 72 e8 ff ff       	call   f0100094 <_panic>
f0101822:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101825:	39 d0                	cmp    %edx,%eax
f0101827:	75 d0                	jne    f01017f9 <mem_init+0x588>
	page_free_list = fl;
f0101829:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010182c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	page_free(pp0);
f0101831:	89 34 24             	mov    %esi,(%esp)
f0101834:	e8 2a f7 ff ff       	call   f0100f63 <page_free>
	page_free(pp1);
f0101839:	89 3c 24             	mov    %edi,(%esp)
f010183c:	e8 22 f7 ff ff       	call   f0100f63 <page_free>
	page_free(pp2);
f0101841:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101844:	89 04 24             	mov    %eax,(%esp)
f0101847:	e8 17 f7 ff ff       	call   f0100f63 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010184c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101851:	eb 05                	jmp    f0101858 <mem_init+0x5e7>
		--nfree;
f0101853:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101856:	8b 00                	mov    (%eax),%eax
f0101858:	85 c0                	test   %eax,%eax
f010185a:	75 f7                	jne    f0101853 <mem_init+0x5e2>
	assert(nfree == 0);
f010185c:	85 db                	test   %ebx,%ebx
f010185e:	74 24                	je     f0101884 <mem_init+0x613>
f0101860:	c7 44 24 0c 50 45 10 	movl   $0xf0104550,0xc(%esp)
f0101867:	f0 
f0101868:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010186f:	f0 
f0101870:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0101877:	00 
f0101878:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010187f:	e8 10 e8 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f0101884:	c7 04 24 44 48 10 f0 	movl   $0xf0104844,(%esp)
f010188b:	e8 7b 15 00 00       	call   f0102e0b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101890:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101897:	e8 3c f6 ff ff       	call   f0100ed8 <page_alloc>
f010189c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010189f:	85 c0                	test   %eax,%eax
f01018a1:	75 24                	jne    f01018c7 <mem_init+0x656>
f01018a3:	c7 44 24 0c 5e 44 10 	movl   $0xf010445e,0xc(%esp)
f01018aa:	f0 
f01018ab:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01018b2:	f0 
f01018b3:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f01018ba:	00 
f01018bb:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01018c2:	e8 cd e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ce:	e8 05 f6 ff ff       	call   f0100ed8 <page_alloc>
f01018d3:	89 c3                	mov    %eax,%ebx
f01018d5:	85 c0                	test   %eax,%eax
f01018d7:	75 24                	jne    f01018fd <mem_init+0x68c>
f01018d9:	c7 44 24 0c 74 44 10 	movl   $0xf0104474,0xc(%esp)
f01018e0:	f0 
f01018e1:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01018e8:	f0 
f01018e9:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f01018f0:	00 
f01018f1:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01018f8:	e8 97 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101904:	e8 cf f5 ff ff       	call   f0100ed8 <page_alloc>
f0101909:	89 c6                	mov    %eax,%esi
f010190b:	85 c0                	test   %eax,%eax
f010190d:	75 24                	jne    f0101933 <mem_init+0x6c2>
f010190f:	c7 44 24 0c 8a 44 10 	movl   $0xf010448a,0xc(%esp)
f0101916:	f0 
f0101917:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010191e:	f0 
f010191f:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101926:	00 
f0101927:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010192e:	e8 61 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101933:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101936:	75 24                	jne    f010195c <mem_init+0x6eb>
f0101938:	c7 44 24 0c a0 44 10 	movl   $0xf01044a0,0xc(%esp)
f010193f:	f0 
f0101940:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101947:	f0 
f0101948:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f010194f:	00 
f0101950:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101957:	e8 38 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010195c:	39 c3                	cmp    %eax,%ebx
f010195e:	74 05                	je     f0101965 <mem_init+0x6f4>
f0101960:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101963:	75 24                	jne    f0101989 <mem_init+0x718>
f0101965:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f010196c:	f0 
f010196d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101974:	f0 
f0101975:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f010197c:	00 
f010197d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101984:	e8 0b e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101989:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010198e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101991:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101998:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010199b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a2:	e8 31 f5 ff ff       	call   f0100ed8 <page_alloc>
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	74 24                	je     f01019cf <mem_init+0x75e>
f01019ab:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f01019b2:	f0 
f01019b3:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01019ba:	f0 
f01019bb:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01019c2:	00 
f01019c3:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01019ca:	e8 c5 e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019dd:	00 
f01019de:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019e3:	89 04 24             	mov    %eax,(%esp)
f01019e6:	e8 4b f7 ff ff       	call   f0101136 <page_lookup>
f01019eb:	85 c0                	test   %eax,%eax
f01019ed:	74 24                	je     f0101a13 <mem_init+0x7a2>
f01019ef:	c7 44 24 0c 64 48 10 	movl   $0xf0104864,0xc(%esp)
f01019f6:	f0 
f01019f7:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01019fe:	f0 
f01019ff:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101a06:	00 
f0101a07:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101a0e:	e8 81 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a13:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a1a:	00 
f0101a1b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a22:	00 
f0101a23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a27:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a2c:	89 04 24             	mov    %eax,(%esp)
f0101a2f:	e8 c2 f7 ff ff       	call   f01011f6 <page_insert>
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	78 24                	js     f0101a5c <mem_init+0x7eb>
f0101a38:	c7 44 24 0c 9c 48 10 	movl   $0xf010489c,0xc(%esp)
f0101a3f:	f0 
f0101a40:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101a47:	f0 
f0101a48:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101a4f:	00 
f0101a50:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101a57:	e8 38 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a5f:	89 04 24             	mov    %eax,(%esp)
f0101a62:	e8 fc f4 ff ff       	call   f0100f63 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a67:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a6e:	00 
f0101a6f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a76:	00 
f0101a77:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a7b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a80:	89 04 24             	mov    %eax,(%esp)
f0101a83:	e8 6e f7 ff ff       	call   f01011f6 <page_insert>
f0101a88:	85 c0                	test   %eax,%eax
f0101a8a:	74 24                	je     f0101ab0 <mem_init+0x83f>
f0101a8c:	c7 44 24 0c cc 48 10 	movl   $0xf01048cc,0xc(%esp)
f0101a93:	f0 
f0101a94:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101a9b:	f0 
f0101a9c:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101aa3:	00 
f0101aa4:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101aab:	e8 e4 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ab0:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
	return (pp - pages) << PGSHIFT;
f0101ab6:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101abb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101abe:	8b 17                	mov    (%edi),%edx
f0101ac0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ac6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ac9:	29 c1                	sub    %eax,%ecx
f0101acb:	89 c8                	mov    %ecx,%eax
f0101acd:	c1 f8 03             	sar    $0x3,%eax
f0101ad0:	c1 e0 0c             	shl    $0xc,%eax
f0101ad3:	39 c2                	cmp    %eax,%edx
f0101ad5:	74 24                	je     f0101afb <mem_init+0x88a>
f0101ad7:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f0101ade:	f0 
f0101adf:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101ae6:	f0 
f0101ae7:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101aee:	00 
f0101aef:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101af6:	e8 99 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101afb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b00:	89 f8                	mov    %edi,%eax
f0101b02:	e8 43 ef ff ff       	call   f0100a4a <check_va2pa>
f0101b07:	89 da                	mov    %ebx,%edx
f0101b09:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b0c:	c1 fa 03             	sar    $0x3,%edx
f0101b0f:	c1 e2 0c             	shl    $0xc,%edx
f0101b12:	39 d0                	cmp    %edx,%eax
f0101b14:	74 24                	je     f0101b3a <mem_init+0x8c9>
f0101b16:	c7 44 24 0c 24 49 10 	movl   $0xf0104924,0xc(%esp)
f0101b1d:	f0 
f0101b1e:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101b25:	f0 
f0101b26:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101b2d:	00 
f0101b2e:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101b35:	e8 5a e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101b3a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b3f:	74 24                	je     f0101b65 <mem_init+0x8f4>
f0101b41:	c7 44 24 0c 5b 45 10 	movl   $0xf010455b,0xc(%esp)
f0101b48:	f0 
f0101b49:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101b50:	f0 
f0101b51:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101b58:	00 
f0101b59:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101b60:	e8 2f e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b68:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b6d:	74 24                	je     f0101b93 <mem_init+0x922>
f0101b6f:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0101b76:	f0 
f0101b77:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101b7e:	f0 
f0101b7f:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101b86:	00 
f0101b87:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101b8e:	e8 01 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b93:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b9a:	00 
f0101b9b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ba2:	00 
f0101ba3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ba7:	89 3c 24             	mov    %edi,(%esp)
f0101baa:	e8 47 f6 ff ff       	call   f01011f6 <page_insert>
f0101baf:	85 c0                	test   %eax,%eax
f0101bb1:	74 24                	je     f0101bd7 <mem_init+0x966>
f0101bb3:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f0101bba:	f0 
f0101bbb:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101bc2:	f0 
f0101bc3:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101bca:	00 
f0101bcb:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101bd2:	e8 bd e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bd7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bdc:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101be1:	e8 64 ee ff ff       	call   f0100a4a <check_va2pa>
f0101be6:	89 f2                	mov    %esi,%edx
f0101be8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101bee:	c1 fa 03             	sar    $0x3,%edx
f0101bf1:	c1 e2 0c             	shl    $0xc,%edx
f0101bf4:	39 d0                	cmp    %edx,%eax
f0101bf6:	74 24                	je     f0101c1c <mem_init+0x9ab>
f0101bf8:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f0101bff:	f0 
f0101c00:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101c07:	f0 
f0101c08:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101c0f:	00 
f0101c10:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101c17:	e8 78 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c1c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c21:	74 24                	je     f0101c47 <mem_init+0x9d6>
f0101c23:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101c32:	f0 
f0101c33:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101c3a:	00 
f0101c3b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101c42:	e8 4d e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c47:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c4e:	e8 85 f2 ff ff       	call   f0100ed8 <page_alloc>
f0101c53:	85 c0                	test   %eax,%eax
f0101c55:	74 24                	je     f0101c7b <mem_init+0xa0a>
f0101c57:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f0101c5e:	f0 
f0101c5f:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101c66:	f0 
f0101c67:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101c6e:	00 
f0101c6f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101c76:	e8 19 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c7b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c82:	00 
f0101c83:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c8a:	00 
f0101c8b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c8f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c94:	89 04 24             	mov    %eax,(%esp)
f0101c97:	e8 5a f5 ff ff       	call   f01011f6 <page_insert>
f0101c9c:	85 c0                	test   %eax,%eax
f0101c9e:	74 24                	je     f0101cc4 <mem_init+0xa53>
f0101ca0:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101cb7:	00 
f0101cb8:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101cbf:	e8 d0 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101cce:	e8 77 ed ff ff       	call   f0100a4a <check_va2pa>
f0101cd3:	89 f2                	mov    %esi,%edx
f0101cd5:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101cdb:	c1 fa 03             	sar    $0x3,%edx
f0101cde:	c1 e2 0c             	shl    $0xc,%edx
f0101ce1:	39 d0                	cmp    %edx,%eax
f0101ce3:	74 24                	je     f0101d09 <mem_init+0xa98>
f0101ce5:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f0101cec:	f0 
f0101ced:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101cf4:	f0 
f0101cf5:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101cfc:	00 
f0101cfd:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101d04:	e8 8b e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d09:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d0e:	74 24                	je     f0101d34 <mem_init+0xac3>
f0101d10:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0101d17:	f0 
f0101d18:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101d1f:	f0 
f0101d20:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101d27:	00 
f0101d28:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101d2f:	e8 60 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d34:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d3b:	e8 98 f1 ff ff       	call   f0100ed8 <page_alloc>
f0101d40:	85 c0                	test   %eax,%eax
f0101d42:	74 24                	je     f0101d68 <mem_init+0xaf7>
f0101d44:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f0101d4b:	f0 
f0101d4c:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101d53:	f0 
f0101d54:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101d5b:	00 
f0101d5c:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101d63:	e8 2c e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d68:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101d6e:	8b 02                	mov    (%edx),%eax
f0101d70:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d75:	89 c1                	mov    %eax,%ecx
f0101d77:	c1 e9 0c             	shr    $0xc,%ecx
f0101d7a:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101d80:	72 20                	jb     f0101da2 <mem_init+0xb31>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d82:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d86:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0101d8d:	f0 
f0101d8e:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101d95:	00 
f0101d96:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101d9d:	e8 f2 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101da2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101da7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101daa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101db1:	00 
f0101db2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101db9:	00 
f0101dba:	89 14 24             	mov    %edx,(%esp)
f0101dbd:	e8 04 f2 ff ff       	call   f0100fc6 <pgdir_walk>
f0101dc2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101dc5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101dc8:	39 d0                	cmp    %edx,%eax
f0101dca:	74 24                	je     f0101df0 <mem_init+0xb7f>
f0101dcc:	c7 44 24 0c c0 49 10 	movl   $0xf01049c0,0xc(%esp)
f0101dd3:	f0 
f0101dd4:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101ddb:	f0 
f0101ddc:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101de3:	00 
f0101de4:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101deb:	e8 a4 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101df0:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101df7:	00 
f0101df8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dff:	00 
f0101e00:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e04:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e09:	89 04 24             	mov    %eax,(%esp)
f0101e0c:	e8 e5 f3 ff ff       	call   f01011f6 <page_insert>
f0101e11:	85 c0                	test   %eax,%eax
f0101e13:	74 24                	je     f0101e39 <mem_init+0xbc8>
f0101e15:	c7 44 24 0c 00 4a 10 	movl   $0xf0104a00,0xc(%esp)
f0101e1c:	f0 
f0101e1d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101e24:	f0 
f0101e25:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101e2c:	00 
f0101e2d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101e34:	e8 5b e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e39:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e3f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e44:	89 f8                	mov    %edi,%eax
f0101e46:	e8 ff eb ff ff       	call   f0100a4a <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101e4b:	89 f2                	mov    %esi,%edx
f0101e4d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101e53:	c1 fa 03             	sar    $0x3,%edx
f0101e56:	c1 e2 0c             	shl    $0xc,%edx
f0101e59:	39 d0                	cmp    %edx,%eax
f0101e5b:	74 24                	je     f0101e81 <mem_init+0xc10>
f0101e5d:	c7 44 24 0c 90 49 10 	movl   $0xf0104990,0xc(%esp)
f0101e64:	f0 
f0101e65:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101e6c:	f0 
f0101e6d:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101e74:	00 
f0101e75:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101e7c:	e8 13 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e81:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e86:	74 24                	je     f0101eac <mem_init+0xc3b>
f0101e88:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0101e8f:	f0 
f0101e90:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101e97:	f0 
f0101e98:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101e9f:	00 
f0101ea0:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101ea7:	e8 e8 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101eac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eb3:	00 
f0101eb4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ebb:	00 
f0101ebc:	89 3c 24             	mov    %edi,(%esp)
f0101ebf:	e8 02 f1 ff ff       	call   f0100fc6 <pgdir_walk>
f0101ec4:	f6 00 04             	testb  $0x4,(%eax)
f0101ec7:	75 24                	jne    f0101eed <mem_init+0xc7c>
f0101ec9:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f0101ed0:	f0 
f0101ed1:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101ed8:	f0 
f0101ed9:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101ee0:	00 
f0101ee1:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101ee8:	e8 a7 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101eed:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ef2:	f6 00 04             	testb  $0x4,(%eax)
f0101ef5:	75 24                	jne    f0101f1b <mem_init+0xcaa>
f0101ef7:	c7 44 24 0c 8e 45 10 	movl   $0xf010458e,0xc(%esp)
f0101efe:	f0 
f0101eff:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101f06:	f0 
f0101f07:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101f0e:	00 
f0101f0f:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101f16:	e8 79 e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f1b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f22:	00 
f0101f23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f2a:	00 
f0101f2b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f2f:	89 04 24             	mov    %eax,(%esp)
f0101f32:	e8 bf f2 ff ff       	call   f01011f6 <page_insert>
f0101f37:	85 c0                	test   %eax,%eax
f0101f39:	74 24                	je     f0101f5f <mem_init+0xcee>
f0101f3b:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f0101f42:	f0 
f0101f43:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101f4a:	f0 
f0101f4b:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101f52:	00 
f0101f53:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101f5a:	e8 35 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f5f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f66:	00 
f0101f67:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f6e:	00 
f0101f6f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f74:	89 04 24             	mov    %eax,(%esp)
f0101f77:	e8 4a f0 ff ff       	call   f0100fc6 <pgdir_walk>
f0101f7c:	f6 00 02             	testb  $0x2,(%eax)
f0101f7f:	75 24                	jne    f0101fa5 <mem_init+0xd34>
f0101f81:	c7 44 24 0c 74 4a 10 	movl   $0xf0104a74,0xc(%esp)
f0101f88:	f0 
f0101f89:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101f90:	f0 
f0101f91:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101f98:	00 
f0101f99:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101fa0:	e8 ef e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fa5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fac:	00 
f0101fad:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fb4:	00 
f0101fb5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fba:	89 04 24             	mov    %eax,(%esp)
f0101fbd:	e8 04 f0 ff ff       	call   f0100fc6 <pgdir_walk>
f0101fc2:	f6 00 04             	testb  $0x4,(%eax)
f0101fc5:	74 24                	je     f0101feb <mem_init+0xd7a>
f0101fc7:	c7 44 24 0c a8 4a 10 	movl   $0xf0104aa8,0xc(%esp)
f0101fce:	f0 
f0101fcf:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0101fd6:	f0 
f0101fd7:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101fde:	00 
f0101fdf:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0101fe6:	e8 a9 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101feb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ff2:	00 
f0101ff3:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101ffa:	00 
f0101ffb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ffe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102002:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102007:	89 04 24             	mov    %eax,(%esp)
f010200a:	e8 e7 f1 ff ff       	call   f01011f6 <page_insert>
f010200f:	85 c0                	test   %eax,%eax
f0102011:	78 24                	js     f0102037 <mem_init+0xdc6>
f0102013:	c7 44 24 0c e0 4a 10 	movl   $0xf0104ae0,0xc(%esp)
f010201a:	f0 
f010201b:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102022:	f0 
f0102023:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f010202a:	00 
f010202b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102032:	e8 5d e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102037:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010203e:	00 
f010203f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102046:	00 
f0102047:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010204b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102050:	89 04 24             	mov    %eax,(%esp)
f0102053:	e8 9e f1 ff ff       	call   f01011f6 <page_insert>
f0102058:	85 c0                	test   %eax,%eax
f010205a:	74 24                	je     f0102080 <mem_init+0xe0f>
f010205c:	c7 44 24 0c 18 4b 10 	movl   $0xf0104b18,0xc(%esp)
f0102063:	f0 
f0102064:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010206b:	f0 
f010206c:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102073:	00 
f0102074:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010207b:	e8 14 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102080:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102087:	00 
f0102088:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010208f:	00 
f0102090:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102095:	89 04 24             	mov    %eax,(%esp)
f0102098:	e8 29 ef ff ff       	call   f0100fc6 <pgdir_walk>
f010209d:	f6 00 04             	testb  $0x4,(%eax)
f01020a0:	74 24                	je     f01020c6 <mem_init+0xe55>
f01020a2:	c7 44 24 0c a8 4a 10 	movl   $0xf0104aa8,0xc(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01020b9:	00 
f01020ba:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01020c1:	e8 ce df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020c6:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01020cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01020d1:	89 f8                	mov    %edi,%eax
f01020d3:	e8 72 e9 ff ff       	call   f0100a4a <check_va2pa>
f01020d8:	89 c1                	mov    %eax,%ecx
f01020da:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020dd:	89 d8                	mov    %ebx,%eax
f01020df:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01020e5:	c1 f8 03             	sar    $0x3,%eax
f01020e8:	c1 e0 0c             	shl    $0xc,%eax
f01020eb:	39 c1                	cmp    %eax,%ecx
f01020ed:	74 24                	je     f0102113 <mem_init+0xea2>
f01020ef:	c7 44 24 0c 54 4b 10 	movl   $0xf0104b54,0xc(%esp)
f01020f6:	f0 
f01020f7:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01020fe:	f0 
f01020ff:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102106:	00 
f0102107:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010210e:	e8 81 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102113:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102118:	89 f8                	mov    %edi,%eax
f010211a:	e8 2b e9 ff ff       	call   f0100a4a <check_va2pa>
f010211f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102122:	74 24                	je     f0102148 <mem_init+0xed7>
f0102124:	c7 44 24 0c 80 4b 10 	movl   $0xf0104b80,0xc(%esp)
f010212b:	f0 
f010212c:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102133:	f0 
f0102134:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010213b:	00 
f010213c:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102143:	e8 4c df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102148:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010214d:	74 24                	je     f0102173 <mem_init+0xf02>
f010214f:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f0102156:	f0 
f0102157:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010215e:	f0 
f010215f:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0102166:	00 
f0102167:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010216e:	e8 21 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102173:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102178:	74 24                	je     f010219e <mem_init+0xf2d>
f010217a:	c7 44 24 0c b5 45 10 	movl   $0xf01045b5,0xc(%esp)
f0102181:	f0 
f0102182:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102189:	f0 
f010218a:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102191:	00 
f0102192:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102199:	e8 f6 de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010219e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021a5:	e8 2e ed ff ff       	call   f0100ed8 <page_alloc>
f01021aa:	85 c0                	test   %eax,%eax
f01021ac:	74 04                	je     f01021b2 <mem_init+0xf41>
f01021ae:	39 c6                	cmp    %eax,%esi
f01021b0:	74 24                	je     f01021d6 <mem_init+0xf65>
f01021b2:	c7 44 24 0c b0 4b 10 	movl   $0xf0104bb0,0xc(%esp)
f01021b9:	f0 
f01021ba:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01021c9:	00 
f01021ca:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01021d1:	e8 be de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01021d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01021dd:	00 
f01021de:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021e3:	89 04 24             	mov    %eax,(%esp)
f01021e6:	e8 c5 ef ff ff       	call   f01011b0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021eb:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01021f1:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f6:	89 f8                	mov    %edi,%eax
f01021f8:	e8 4d e8 ff ff       	call   f0100a4a <check_va2pa>
f01021fd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102200:	74 24                	je     f0102226 <mem_init+0xfb5>
f0102202:	c7 44 24 0c d4 4b 10 	movl   $0xf0104bd4,0xc(%esp)
f0102209:	f0 
f010220a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102211:	f0 
f0102212:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102219:	00 
f010221a:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102221:	e8 6e de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102226:	ba 00 10 00 00       	mov    $0x1000,%edx
f010222b:	89 f8                	mov    %edi,%eax
f010222d:	e8 18 e8 ff ff       	call   f0100a4a <check_va2pa>
f0102232:	89 da                	mov    %ebx,%edx
f0102234:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010223a:	c1 fa 03             	sar    $0x3,%edx
f010223d:	c1 e2 0c             	shl    $0xc,%edx
f0102240:	39 d0                	cmp    %edx,%eax
f0102242:	74 24                	je     f0102268 <mem_init+0xff7>
f0102244:	c7 44 24 0c 80 4b 10 	movl   $0xf0104b80,0xc(%esp)
f010224b:	f0 
f010224c:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102253:	f0 
f0102254:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f010225b:	00 
f010225c:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102263:	e8 2c de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102268:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010226d:	74 24                	je     f0102293 <mem_init+0x1022>
f010226f:	c7 44 24 0c 5b 45 10 	movl   $0xf010455b,0xc(%esp)
f0102276:	f0 
f0102277:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010227e:	f0 
f010227f:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102286:	00 
f0102287:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010228e:	e8 01 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102293:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102298:	74 24                	je     f01022be <mem_init+0x104d>
f010229a:	c7 44 24 0c b5 45 10 	movl   $0xf01045b5,0xc(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01022a9:	f0 
f01022aa:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01022b1:	00 
f01022b2:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01022b9:	e8 d6 dd ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01022be:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01022c5:	00 
f01022c6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022cd:	00 
f01022ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022d2:	89 3c 24             	mov    %edi,(%esp)
f01022d5:	e8 1c ef ff ff       	call   f01011f6 <page_insert>
f01022da:	85 c0                	test   %eax,%eax
f01022dc:	74 24                	je     f0102302 <mem_init+0x1091>
f01022de:	c7 44 24 0c f8 4b 10 	movl   $0xf0104bf8,0xc(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01022ed:	f0 
f01022ee:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01022f5:	00 
f01022f6:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01022fd:	e8 92 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102302:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102307:	75 24                	jne    f010232d <mem_init+0x10bc>
f0102309:	c7 44 24 0c c6 45 10 	movl   $0xf01045c6,0xc(%esp)
f0102310:	f0 
f0102311:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102318:	f0 
f0102319:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102320:	00 
f0102321:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102328:	e8 67 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010232d:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102330:	74 24                	je     f0102356 <mem_init+0x10e5>
f0102332:	c7 44 24 0c d2 45 10 	movl   $0xf01045d2,0xc(%esp)
f0102339:	f0 
f010233a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102341:	f0 
f0102342:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102349:	00 
f010234a:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102351:	e8 3e dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102356:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010235d:	00 
f010235e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102363:	89 04 24             	mov    %eax,(%esp)
f0102366:	e8 45 ee ff ff       	call   f01011b0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010236b:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102371:	ba 00 00 00 00       	mov    $0x0,%edx
f0102376:	89 f8                	mov    %edi,%eax
f0102378:	e8 cd e6 ff ff       	call   f0100a4a <check_va2pa>
f010237d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102380:	74 24                	je     f01023a6 <mem_init+0x1135>
f0102382:	c7 44 24 0c d4 4b 10 	movl   $0xf0104bd4,0xc(%esp)
f0102389:	f0 
f010238a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102391:	f0 
f0102392:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102399:	00 
f010239a:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01023a1:	e8 ee dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01023a6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023ab:	89 f8                	mov    %edi,%eax
f01023ad:	e8 98 e6 ff ff       	call   f0100a4a <check_va2pa>
f01023b2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023b5:	74 24                	je     f01023db <mem_init+0x116a>
f01023b7:	c7 44 24 0c 30 4c 10 	movl   $0xf0104c30,0xc(%esp)
f01023be:	f0 
f01023bf:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01023c6:	f0 
f01023c7:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01023ce:	00 
f01023cf:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01023d6:	e8 b9 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01023db:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01023e0:	74 24                	je     f0102406 <mem_init+0x1195>
f01023e2:	c7 44 24 0c e7 45 10 	movl   $0xf01045e7,0xc(%esp)
f01023e9:	f0 
f01023ea:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01023f1:	f0 
f01023f2:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01023f9:	00 
f01023fa:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102401:	e8 8e dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102406:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010240b:	74 24                	je     f0102431 <mem_init+0x11c0>
f010240d:	c7 44 24 0c b5 45 10 	movl   $0xf01045b5,0xc(%esp)
f0102414:	f0 
f0102415:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010241c:	f0 
f010241d:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0102424:	00 
f0102425:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010242c:	e8 63 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102431:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102438:	e8 9b ea ff ff       	call   f0100ed8 <page_alloc>
f010243d:	85 c0                	test   %eax,%eax
f010243f:	74 04                	je     f0102445 <mem_init+0x11d4>
f0102441:	39 c3                	cmp    %eax,%ebx
f0102443:	74 24                	je     f0102469 <mem_init+0x11f8>
f0102445:	c7 44 24 0c 58 4c 10 	movl   $0xf0104c58,0xc(%esp)
f010244c:	f0 
f010244d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102454:	f0 
f0102455:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f010245c:	00 
f010245d:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102464:	e8 2b dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102469:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102470:	e8 63 ea ff ff       	call   f0100ed8 <page_alloc>
f0102475:	85 c0                	test   %eax,%eax
f0102477:	74 24                	je     f010249d <mem_init+0x122c>
f0102479:	c7 44 24 0c 09 45 10 	movl   $0xf0104509,0xc(%esp)
f0102480:	f0 
f0102481:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102488:	f0 
f0102489:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0102490:	00 
f0102491:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102498:	e8 f7 db ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010249d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01024a2:	8b 08                	mov    (%eax),%ecx
f01024a4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024aa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024ad:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01024b3:	c1 fa 03             	sar    $0x3,%edx
f01024b6:	c1 e2 0c             	shl    $0xc,%edx
f01024b9:	39 d1                	cmp    %edx,%ecx
f01024bb:	74 24                	je     f01024e1 <mem_init+0x1270>
f01024bd:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f01024c4:	f0 
f01024c5:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01024cc:	f0 
f01024cd:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01024d4:	00 
f01024d5:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01024dc:	e8 b3 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01024e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024ea:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01024ef:	74 24                	je     f0102515 <mem_init+0x12a4>
f01024f1:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f01024f8:	f0 
f01024f9:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102500:	f0 
f0102501:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102508:	00 
f0102509:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102510:	e8 7f db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102515:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102518:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010251e:	89 04 24             	mov    %eax,(%esp)
f0102521:	e8 3d ea ff ff       	call   f0100f63 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102526:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010252d:	00 
f010252e:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102535:	00 
f0102536:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010253b:	89 04 24             	mov    %eax,(%esp)
f010253e:	e8 83 ea ff ff       	call   f0100fc6 <pgdir_walk>
f0102543:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102546:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102549:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f010254f:	8b 7a 04             	mov    0x4(%edx),%edi
f0102552:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f0102558:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010255e:	89 f8                	mov    %edi,%eax
f0102560:	c1 e8 0c             	shr    $0xc,%eax
f0102563:	39 c8                	cmp    %ecx,%eax
f0102565:	72 20                	jb     f0102587 <mem_init+0x1316>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102567:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010256b:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0102572:	f0 
f0102573:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f010257a:	00 
f010257b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102582:	e8 0d db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102587:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010258d:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102590:	74 24                	je     f01025b6 <mem_init+0x1345>
f0102592:	c7 44 24 0c f8 45 10 	movl   $0xf01045f8,0xc(%esp)
f0102599:	f0 
f010259a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01025a1:	f0 
f01025a2:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f01025a9:	00 
f01025aa:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01025b1:	e8 de da ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01025b6:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01025bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025c0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01025c6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01025cc:	c1 f8 03             	sar    $0x3,%eax
f01025cf:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01025d2:	89 c2                	mov    %eax,%edx
f01025d4:	c1 ea 0c             	shr    $0xc,%edx
f01025d7:	39 d1                	cmp    %edx,%ecx
f01025d9:	77 20                	ja     f01025fb <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025df:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f01025e6:	f0 
f01025e7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025ee:	00 
f01025ef:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f01025f6:	e8 99 da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102602:	00 
f0102603:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010260a:	00 
	return (void *)(pa + KERNBASE);
f010260b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102610:	89 04 24             	mov    %eax,(%esp)
f0102613:	e8 3f 13 00 00       	call   f0103957 <memset>
	page_free(pp0);
f0102618:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010261b:	89 3c 24             	mov    %edi,(%esp)
f010261e:	e8 40 e9 ff ff       	call   f0100f63 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102623:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010262a:	00 
f010262b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102632:	00 
f0102633:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102638:	89 04 24             	mov    %eax,(%esp)
f010263b:	e8 86 e9 ff ff       	call   f0100fc6 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102640:	89 fa                	mov    %edi,%edx
f0102642:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102648:	c1 fa 03             	sar    $0x3,%edx
f010264b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010264e:	89 d0                	mov    %edx,%eax
f0102650:	c1 e8 0c             	shr    $0xc,%eax
f0102653:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102659:	72 20                	jb     f010267b <mem_init+0x140a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010265b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010265f:	c7 44 24 08 70 46 10 	movl   $0xf0104670,0x8(%esp)
f0102666:	f0 
f0102667:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010266e:	00 
f010266f:	c7 04 24 7f 43 10 f0 	movl   $0xf010437f,(%esp)
f0102676:	e8 19 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010267b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102681:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102684:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010268a:	f6 00 01             	testb  $0x1,(%eax)
f010268d:	74 24                	je     f01026b3 <mem_init+0x1442>
f010268f:	c7 44 24 0c 10 46 10 	movl   $0xf0104610,0xc(%esp)
f0102696:	f0 
f0102697:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010269e:	f0 
f010269f:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f01026a6:	00 
f01026a7:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01026ae:	e8 e1 d9 ff ff       	call   f0100094 <_panic>
f01026b3:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01026b6:	39 d0                	cmp    %edx,%eax
f01026b8:	75 d0                	jne    f010268a <mem_init+0x1419>
	kern_pgdir[0] = 0;
f01026ba:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026bf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026c8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01026ce:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01026d1:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c

	// free the pages we took
	page_free(pp0);
f01026d7:	89 04 24             	mov    %eax,(%esp)
f01026da:	e8 84 e8 ff ff       	call   f0100f63 <page_free>
	page_free(pp1);
f01026df:	89 1c 24             	mov    %ebx,(%esp)
f01026e2:	e8 7c e8 ff ff       	call   f0100f63 <page_free>
	page_free(pp2);
f01026e7:	89 34 24             	mov    %esi,(%esp)
f01026ea:	e8 74 e8 ff ff       	call   f0100f63 <page_free>

	cprintf("check_page() succeeded!\n");
f01026ef:	c7 04 24 27 46 10 f0 	movl   $0xf0104627,(%esp)
f01026f6:	e8 10 07 00 00       	call   f0102e0b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01026fb:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	if ((uint32_t)kva < KERNBASE)
f0102700:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102705:	77 20                	ja     f0102727 <mem_init+0x14b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102707:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010270b:	c7 44 24 08 00 48 10 	movl   $0xf0104800,0x8(%esp)
f0102712:	f0 
f0102713:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f010271a:	00 
f010271b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102722:	e8 6d d9 ff ff       	call   f0100094 <_panic>
f0102727:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f010272e:	00 
	return (physaddr_t)kva - KERNBASE;
f010272f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102734:	89 04 24             	mov    %eax,(%esp)
f0102737:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010273c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102741:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102746:	e8 6a e9 ff ff       	call   f01010b5 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010274b:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f0102750:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102756:	77 20                	ja     f0102778 <mem_init+0x1507>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102758:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010275c:	c7 44 24 08 00 48 10 	movl   $0xf0104800,0x8(%esp)
f0102763:	f0 
f0102764:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f010276b:	00 
f010276c:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102773:	e8 1c d9 ff ff       	call   f0100094 <_panic>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102778:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010277f:	00 
f0102780:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102787:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010278c:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102791:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102796:	e8 1a e9 ff ff       	call   f01010b5 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f010279b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027a2:	00 
f01027a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027aa:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027af:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027b4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01027b9:	e8 f7 e8 ff ff       	call   f01010b5 <boot_map_region>
	pgdir = kern_pgdir;
f01027be:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027c4:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01027c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027cc:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01027d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027db:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01027e0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01027e3:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01027e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01027eb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f01027ee:	be 00 00 00 00       	mov    $0x0,%esi
f01027f3:	eb 6d                	jmp    f0102862 <mem_init+0x15f1>
f01027f5:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027fb:	89 f8                	mov    %edi,%eax
f01027fd:	e8 48 e2 ff ff       	call   f0100a4a <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102802:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102809:	77 23                	ja     f010282e <mem_init+0x15bd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010280b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010280e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102812:	c7 44 24 08 00 48 10 	movl   $0xf0104800,0x8(%esp)
f0102819:	f0 
f010281a:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0102821:	00 
f0102822:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102829:	e8 66 d8 ff ff       	call   f0100094 <_panic>
f010282e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102831:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102834:	39 c2                	cmp    %eax,%edx
f0102836:	74 24                	je     f010285c <mem_init+0x15eb>
f0102838:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f010285c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102862:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102865:	77 8e                	ja     f01027f5 <mem_init+0x1584>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102867:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010286a:	c1 e0 0c             	shl    $0xc,%eax
f010286d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102870:	be 00 00 00 00       	mov    $0x0,%esi
f0102875:	eb 3b                	jmp    f01028b2 <mem_init+0x1641>
f0102877:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010287d:	89 f8                	mov    %edi,%eax
f010287f:	e8 c6 e1 ff ff       	call   f0100a4a <check_va2pa>
f0102884:	39 c6                	cmp    %eax,%esi
f0102886:	74 24                	je     f01028ac <mem_init+0x163b>
f0102888:	c7 44 24 0c b0 4c 10 	movl   $0xf0104cb0,0xc(%esp)
f010288f:	f0 
f0102890:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102897:	f0 
f0102898:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f010289f:	00 
f01028a0:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01028a7:	e8 e8 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028ac:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028b2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01028b5:	72 c0                	jb     f0102877 <mem_init+0x1606>
f01028b7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01028bc:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028c2:	89 f2                	mov    %esi,%edx
f01028c4:	89 f8                	mov    %edi,%eax
f01028c6:	e8 7f e1 ff ff       	call   f0100a4a <check_va2pa>
f01028cb:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f01028ce:	39 d0                	cmp    %edx,%eax
f01028d0:	74 24                	je     f01028f6 <mem_init+0x1685>
f01028d2:	c7 44 24 0c d8 4c 10 	movl   $0xf0104cd8,0xc(%esp)
f01028d9:	f0 
f01028da:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01028e1:	f0 
f01028e2:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01028e9:	00 
f01028ea:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01028f1:	e8 9e d7 ff ff       	call   f0100094 <_panic>
f01028f6:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028fc:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102902:	75 be                	jne    f01028c2 <mem_init+0x1651>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102904:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102909:	89 f8                	mov    %edi,%eax
f010290b:	e8 3a e1 ff ff       	call   f0100a4a <check_va2pa>
f0102910:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102913:	75 0a                	jne    f010291f <mem_init+0x16ae>
f0102915:	b8 00 00 00 00       	mov    $0x0,%eax
f010291a:	e9 f0 00 00 00       	jmp    f0102a0f <mem_init+0x179e>
f010291f:	c7 44 24 0c 20 4d 10 	movl   $0xf0104d20,0xc(%esp)
f0102926:	f0 
f0102927:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f010292e:	f0 
f010292f:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0102936:	00 
f0102937:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f010293e:	e8 51 d7 ff ff       	call   f0100094 <_panic>
		switch (i) {
f0102943:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102948:	72 3c                	jb     f0102986 <mem_init+0x1715>
f010294a:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010294f:	76 07                	jbe    f0102958 <mem_init+0x16e7>
f0102951:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102956:	75 2e                	jne    f0102986 <mem_init+0x1715>
			assert(pgdir[i] & PTE_P);
f0102958:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010295c:	0f 85 aa 00 00 00    	jne    f0102a0c <mem_init+0x179b>
f0102962:	c7 44 24 0c 40 46 10 	movl   $0xf0104640,0xc(%esp)
f0102969:	f0 
f010296a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102971:	f0 
f0102972:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0102979:	00 
f010297a:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102981:	e8 0e d7 ff ff       	call   f0100094 <_panic>
			if (i >= PDX(KERNBASE)) {
f0102986:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010298b:	76 55                	jbe    f01029e2 <mem_init+0x1771>
				assert(pgdir[i] & PTE_P);
f010298d:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102990:	f6 c2 01             	test   $0x1,%dl
f0102993:	75 24                	jne    f01029b9 <mem_init+0x1748>
f0102995:	c7 44 24 0c 40 46 10 	movl   $0xf0104640,0xc(%esp)
f010299c:	f0 
f010299d:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01029a4:	f0 
f01029a5:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f01029ac:	00 
f01029ad:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01029b4:	e8 db d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01029b9:	f6 c2 02             	test   $0x2,%dl
f01029bc:	75 4e                	jne    f0102a0c <mem_init+0x179b>
f01029be:	c7 44 24 0c 51 46 10 	movl   $0xf0104651,0xc(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f01029d5:	00 
f01029d6:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f01029dd:	e8 b2 d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] == 0);
f01029e2:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029e6:	74 24                	je     f0102a0c <mem_init+0x179b>
f01029e8:	c7 44 24 0c 62 46 10 	movl   $0xf0104662,0xc(%esp)
f01029ef:	f0 
f01029f0:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f01029f7:	f0 
f01029f8:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f01029ff:	00 
f0102a00:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102a07:	e8 88 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a0c:	83 c0 01             	add    $0x1,%eax
f0102a0f:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a14:	0f 85 29 ff ff ff    	jne    f0102943 <mem_init+0x16d2>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a1a:	c7 04 24 50 4d 10 f0 	movl   $0xf0104d50,(%esp)
f0102a21:	e8 e5 03 00 00       	call   f0102e0b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a26:	a1 68 79 11 f0       	mov    0xf0117968,%eax
	if ((uint32_t)kva < KERNBASE)
f0102a2b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a30:	77 20                	ja     f0102a52 <mem_init+0x17e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a32:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a36:	c7 44 24 08 00 48 10 	movl   $0xf0104800,0x8(%esp)
f0102a3d:	f0 
f0102a3e:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f0102a45:	00 
f0102a46:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102a4d:	e8 42 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a52:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a57:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102a5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5f:	e8 55 e0 ff ff       	call   f0100ab9 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a64:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a67:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a6a:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a6f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a72:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a79:	e8 5a e4 ff ff       	call   f0100ed8 <page_alloc>
f0102a7e:	89 c3                	mov    %eax,%ebx
f0102a80:	85 c0                	test   %eax,%eax
f0102a82:	75 24                	jne    f0102aa8 <mem_init+0x1837>
f0102a84:	c7 44 24 0c 5e 44 10 	movl   $0xf010445e,0xc(%esp)
f0102a8b:	f0 
f0102a8c:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102a93:	f0 
f0102a94:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102a9b:	00 
f0102a9c:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102aa3:	e8 ec d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102aa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aaf:	e8 24 e4 ff ff       	call   f0100ed8 <page_alloc>
f0102ab4:	89 c7                	mov    %eax,%edi
f0102ab6:	85 c0                	test   %eax,%eax
f0102ab8:	75 24                	jne    f0102ade <mem_init+0x186d>
f0102aba:	c7 44 24 0c 74 44 10 	movl   $0xf0104474,0xc(%esp)
f0102ac1:	f0 
f0102ac2:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102ac9:	f0 
f0102aca:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102ad1:	00 
f0102ad2:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102ad9:	e8 b6 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ade:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ae5:	e8 ee e3 ff ff       	call   f0100ed8 <page_alloc>
f0102aea:	89 c6                	mov    %eax,%esi
f0102aec:	85 c0                	test   %eax,%eax
f0102aee:	75 24                	jne    f0102b14 <mem_init+0x18a3>
f0102af0:	c7 44 24 0c 8a 44 10 	movl   $0xf010448a,0xc(%esp)
f0102af7:	f0 
f0102af8:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102aff:	f0 
f0102b00:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102b07:	00 
f0102b08:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102b0f:	e8 80 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102b14:	89 1c 24             	mov    %ebx,(%esp)
f0102b17:	e8 47 e4 ff ff       	call   f0100f63 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b1c:	89 f8                	mov    %edi,%eax
f0102b1e:	e8 e2 de ff ff       	call   f0100a05 <page2kva>
f0102b23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b2a:	00 
f0102b2b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b32:	00 
f0102b33:	89 04 24             	mov    %eax,(%esp)
f0102b36:	e8 1c 0e 00 00       	call   f0103957 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b3b:	89 f0                	mov    %esi,%eax
f0102b3d:	e8 c3 de ff ff       	call   f0100a05 <page2kva>
f0102b42:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b49:	00 
f0102b4a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b51:	00 
f0102b52:	89 04 24             	mov    %eax,(%esp)
f0102b55:	e8 fd 0d 00 00       	call   f0103957 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b5a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b61:	00 
f0102b62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b69:	00 
f0102b6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b6e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b73:	89 04 24             	mov    %eax,(%esp)
f0102b76:	e8 7b e6 ff ff       	call   f01011f6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b7b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b80:	74 24                	je     f0102ba6 <mem_init+0x1935>
f0102b82:	c7 44 24 0c 5b 45 10 	movl   $0xf010455b,0xc(%esp)
f0102b89:	f0 
f0102b8a:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102b91:	f0 
f0102b92:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102b99:	00 
f0102b9a:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102ba1:	e8 ee d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ba6:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bad:	01 01 01 
f0102bb0:	74 24                	je     f0102bd6 <mem_init+0x1965>
f0102bb2:	c7 44 24 0c 70 4d 10 	movl   $0xf0104d70,0xc(%esp)
f0102bb9:	f0 
f0102bba:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102bc1:	f0 
f0102bc2:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f0102bc9:	00 
f0102bca:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102bd1:	e8 be d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bd6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bdd:	00 
f0102bde:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102be5:	00 
f0102be6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102bea:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102bef:	89 04 24             	mov    %eax,(%esp)
f0102bf2:	e8 ff e5 ff ff       	call   f01011f6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bf7:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bfe:	02 02 02 
f0102c01:	74 24                	je     f0102c27 <mem_init+0x19b6>
f0102c03:	c7 44 24 0c 94 4d 10 	movl   $0xf0104d94,0xc(%esp)
f0102c0a:	f0 
f0102c0b:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102c12:	f0 
f0102c13:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102c1a:	00 
f0102c1b:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102c22:	e8 6d d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102c27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c2c:	74 24                	je     f0102c52 <mem_init+0x19e1>
f0102c2e:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f0102c35:	f0 
f0102c36:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102c3d:	f0 
f0102c3e:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102c45:	00 
f0102c46:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102c4d:	e8 42 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102c52:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c57:	74 24                	je     f0102c7d <mem_init+0x1a0c>
f0102c59:	c7 44 24 0c e7 45 10 	movl   $0xf01045e7,0xc(%esp)
f0102c60:	f0 
f0102c61:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102c68:	f0 
f0102c69:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102c70:	00 
f0102c71:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102c78:	e8 17 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c7d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c84:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c87:	89 f0                	mov    %esi,%eax
f0102c89:	e8 77 dd ff ff       	call   f0100a05 <page2kva>
f0102c8e:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102c94:	74 24                	je     f0102cba <mem_init+0x1a49>
f0102c96:	c7 44 24 0c b8 4d 10 	movl   $0xf0104db8,0xc(%esp)
f0102c9d:	f0 
f0102c9e:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102cad:	00 
f0102cae:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102cb5:	e8 da d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cba:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102cc1:	00 
f0102cc2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102cc7:	89 04 24             	mov    %eax,(%esp)
f0102cca:	e8 e1 e4 ff ff       	call   f01011b0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ccf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102cd4:	74 24                	je     f0102cfa <mem_init+0x1a89>
f0102cd6:	c7 44 24 0c b5 45 10 	movl   $0xf01045b5,0xc(%esp)
f0102cdd:	f0 
f0102cde:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102ce5:	f0 
f0102ce6:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102ced:	00 
f0102cee:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102cf5:	e8 9a d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cfa:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102cff:	8b 08                	mov    (%eax),%ecx
f0102d01:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102d07:	89 da                	mov    %ebx,%edx
f0102d09:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102d0f:	c1 fa 03             	sar    $0x3,%edx
f0102d12:	c1 e2 0c             	shl    $0xc,%edx
f0102d15:	39 d1                	cmp    %edx,%ecx
f0102d17:	74 24                	je     f0102d3d <mem_init+0x1acc>
f0102d19:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f0102d20:	f0 
f0102d21:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102d28:	f0 
f0102d29:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102d30:	00 
f0102d31:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102d38:	e8 57 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102d3d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d43:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d48:	74 24                	je     f0102d6e <mem_init+0x1afd>
f0102d4a:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0102d51:	f0 
f0102d52:	c7 44 24 08 99 43 10 	movl   $0xf0104399,0x8(%esp)
f0102d59:	f0 
f0102d5a:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102d61:	00 
f0102d62:	c7 04 24 73 43 10 f0 	movl   $0xf0104373,(%esp)
f0102d69:	e8 26 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d6e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d74:	89 1c 24             	mov    %ebx,(%esp)
f0102d77:	e8 e7 e1 ff ff       	call   f0100f63 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d7c:	c7 04 24 e4 4d 10 f0 	movl   $0xf0104de4,(%esp)
f0102d83:	e8 83 00 00 00       	call   f0102e0b <cprintf>
}
f0102d88:	83 c4 4c             	add    $0x4c,%esp
f0102d8b:	5b                   	pop    %ebx
f0102d8c:	5e                   	pop    %esi
f0102d8d:	5f                   	pop    %edi
f0102d8e:	5d                   	pop    %ebp
f0102d8f:	c3                   	ret    

f0102d90 <tlb_invalidate>:
{
f0102d90:	55                   	push   %ebp
f0102d91:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d93:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d96:	0f 01 38             	invlpg (%eax)
}
f0102d99:	5d                   	pop    %ebp
f0102d9a:	c3                   	ret    

f0102d9b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d9b:	55                   	push   %ebp
f0102d9c:	89 e5                	mov    %esp,%ebp
f0102d9e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102da2:	ba 70 00 00 00       	mov    $0x70,%edx
f0102da7:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102da8:	b2 71                	mov    $0x71,%dl
f0102daa:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102dab:	0f b6 c0             	movzbl %al,%eax
}
f0102dae:	5d                   	pop    %ebp
f0102daf:	c3                   	ret    

f0102db0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102db0:	55                   	push   %ebp
f0102db1:	89 e5                	mov    %esp,%ebp
f0102db3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102db7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dbc:	ee                   	out    %al,(%dx)
f0102dbd:	b2 71                	mov    $0x71,%dl
f0102dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dc2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102dc3:	5d                   	pop    %ebp
f0102dc4:	c3                   	ret    

f0102dc5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102dc5:	55                   	push   %ebp
f0102dc6:	89 e5                	mov    %esp,%ebp
f0102dc8:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102dcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dce:	89 04 24             	mov    %eax,(%esp)
f0102dd1:	e8 2b d8 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102dd6:	c9                   	leave  
f0102dd7:	c3                   	ret    

f0102dd8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102dd8:	55                   	push   %ebp
f0102dd9:	89 e5                	mov    %esp,%ebp
f0102ddb:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102dde:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102de5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102de8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dec:	8b 45 08             	mov    0x8(%ebp),%eax
f0102def:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102df3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102df6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dfa:	c7 04 24 c5 2d 10 f0 	movl   $0xf0102dc5,(%esp)
f0102e01:	e8 98 04 00 00       	call   f010329e <vprintfmt>
	return cnt;
}
f0102e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e09:	c9                   	leave  
f0102e0a:	c3                   	ret    

f0102e0b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e0b:	55                   	push   %ebp
f0102e0c:	89 e5                	mov    %esp,%ebp
f0102e0e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e11:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e18:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e1b:	89 04 24             	mov    %eax,(%esp)
f0102e1e:	e8 b5 ff ff ff       	call   f0102dd8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e23:	c9                   	leave  
f0102e24:	c3                   	ret    

f0102e25 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e25:	55                   	push   %ebp
f0102e26:	89 e5                	mov    %esp,%ebp
f0102e28:	57                   	push   %edi
f0102e29:	56                   	push   %esi
f0102e2a:	53                   	push   %ebx
f0102e2b:	83 ec 10             	sub    $0x10,%esp
f0102e2e:	89 c6                	mov    %eax,%esi
f0102e30:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102e33:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102e36:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e39:	8b 1a                	mov    (%edx),%ebx
f0102e3b:	8b 01                	mov    (%ecx),%eax
f0102e3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102e47:	eb 77                	jmp    f0102ec0 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102e49:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e4c:	01 d8                	add    %ebx,%eax
f0102e4e:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102e53:	99                   	cltd   
f0102e54:	f7 f9                	idiv   %ecx
f0102e56:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e58:	eb 01                	jmp    f0102e5b <stab_binsearch+0x36>
			m--;
f0102e5a:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0102e5b:	39 d9                	cmp    %ebx,%ecx
f0102e5d:	7c 1d                	jl     f0102e7c <stab_binsearch+0x57>
f0102e5f:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e62:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e67:	39 fa                	cmp    %edi,%edx
f0102e69:	75 ef                	jne    f0102e5a <stab_binsearch+0x35>
f0102e6b:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e6e:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e71:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102e75:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e78:	73 18                	jae    f0102e92 <stab_binsearch+0x6d>
f0102e7a:	eb 05                	jmp    f0102e81 <stab_binsearch+0x5c>
			l = true_m + 1;
f0102e7c:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102e7f:	eb 3f                	jmp    f0102ec0 <stab_binsearch+0x9b>
			*region_left = m;
f0102e81:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e84:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102e86:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0102e89:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e90:	eb 2e                	jmp    f0102ec0 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0102e92:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e95:	73 15                	jae    f0102eac <stab_binsearch+0x87>
			*region_right = m - 1;
f0102e97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e9a:	48                   	dec    %eax
f0102e9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e9e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ea1:	89 01                	mov    %eax,(%ecx)
		any_matches = 1;
f0102ea3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102eaa:	eb 14                	jmp    f0102ec0 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102eac:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102eaf:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102eb2:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102eb4:	ff 45 0c             	incl   0xc(%ebp)
f0102eb7:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0102eb9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0102ec0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102ec3:	7e 84                	jle    f0102e49 <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0102ec5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102ec9:	75 0d                	jne    f0102ed8 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102ecb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102ece:	8b 00                	mov    (%eax),%eax
f0102ed0:	48                   	dec    %eax
f0102ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ed4:	89 07                	mov    %eax,(%edi)
f0102ed6:	eb 22                	jmp    f0102efa <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ed8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102edb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102edd:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102ee0:	8b 0b                	mov    (%ebx),%ecx
		for (l = *region_right;
f0102ee2:	eb 01                	jmp    f0102ee5 <stab_binsearch+0xc0>
		     l--)
f0102ee4:	48                   	dec    %eax
		for (l = *region_right;
f0102ee5:	39 c1                	cmp    %eax,%ecx
f0102ee7:	7d 0c                	jge    f0102ef5 <stab_binsearch+0xd0>
f0102ee9:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102eec:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ef1:	39 fa                	cmp    %edi,%edx
f0102ef3:	75 ef                	jne    f0102ee4 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0102ef5:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102ef8:	89 07                	mov    %eax,(%edi)
	}
}
f0102efa:	83 c4 10             	add    $0x10,%esp
f0102efd:	5b                   	pop    %ebx
f0102efe:	5e                   	pop    %esi
f0102eff:	5f                   	pop    %edi
f0102f00:	5d                   	pop    %ebp
f0102f01:	c3                   	ret    

f0102f02 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f02:	55                   	push   %ebp
f0102f03:	89 e5                	mov    %esp,%ebp
f0102f05:	57                   	push   %edi
f0102f06:	56                   	push   %esi
f0102f07:	53                   	push   %ebx
f0102f08:	83 ec 3c             	sub    $0x3c,%esp
f0102f0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f0e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102f11:	c7 03 10 4e 10 f0    	movl   $0xf0104e10,(%ebx)
	info->eip_line = 0;
f0102f17:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102f1e:	c7 43 08 10 4e 10 f0 	movl   $0xf0104e10,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f25:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f2c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f2f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f36:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f3c:	76 12                	jbe    f0102f50 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f3e:	b8 1d cc 10 f0       	mov    $0xf010cc1d,%eax
f0102f43:	3d 4d ae 10 f0       	cmp    $0xf010ae4d,%eax
f0102f48:	0f 86 ba 01 00 00    	jbe    f0103108 <debuginfo_eip+0x206>
f0102f4e:	eb 1c                	jmp    f0102f6c <debuginfo_eip+0x6a>
  	        panic("User address");
f0102f50:	c7 44 24 08 1a 4e 10 	movl   $0xf0104e1a,0x8(%esp)
f0102f57:	f0 
f0102f58:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f5f:	00 
f0102f60:	c7 04 24 27 4e 10 f0 	movl   $0xf0104e27,(%esp)
f0102f67:	e8 28 d1 ff ff       	call   f0100094 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f6c:	80 3d 1c cc 10 f0 00 	cmpb   $0x0,0xf010cc1c
f0102f73:	0f 85 96 01 00 00    	jne    f010310f <debuginfo_eip+0x20d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f79:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f80:	b8 4c ae 10 f0       	mov    $0xf010ae4c,%eax
f0102f85:	2d 44 50 10 f0       	sub    $0xf0105044,%eax
f0102f8a:	c1 f8 02             	sar    $0x2,%eax
f0102f8d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f93:	83 e8 01             	sub    $0x1,%eax
f0102f96:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f99:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f9d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102fa4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102fa7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102faa:	b8 44 50 10 f0       	mov    $0xf0105044,%eax
f0102faf:	e8 71 fe ff ff       	call   f0102e25 <stab_binsearch>
	if (lfile == 0)
f0102fb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fb7:	85 c0                	test   %eax,%eax
f0102fb9:	0f 84 57 01 00 00    	je     f0103116 <debuginfo_eip+0x214>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102fbf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fc5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102fc8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fcc:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102fd3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102fd6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102fd9:	b8 44 50 10 f0       	mov    $0xf0105044,%eax
f0102fde:	e8 42 fe ff ff       	call   f0102e25 <stab_binsearch>

	if (lfun <= rfun) {
f0102fe3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fe6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fe9:	39 d0                	cmp    %edx,%eax
f0102feb:	7f 3d                	jg     f010302a <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fed:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102ff0:	8d b9 44 50 10 f0    	lea    -0xfefafbc(%ecx),%edi
f0102ff6:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102ff9:	8b 89 44 50 10 f0    	mov    -0xfefafbc(%ecx),%ecx
f0102fff:	bf 1d cc 10 f0       	mov    $0xf010cc1d,%edi
f0103004:	81 ef 4d ae 10 f0    	sub    $0xf010ae4d,%edi
f010300a:	39 f9                	cmp    %edi,%ecx
f010300c:	73 09                	jae    f0103017 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010300e:	81 c1 4d ae 10 f0    	add    $0xf010ae4d,%ecx
f0103014:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103017:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010301a:	8b 4f 08             	mov    0x8(%edi),%ecx
f010301d:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103020:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103022:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103025:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103028:	eb 0f                	jmp    f0103039 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010302a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010302d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103030:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103033:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103036:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103039:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103040:	00 
f0103041:	8b 43 08             	mov    0x8(%ebx),%eax
f0103044:	89 04 24             	mov    %eax,(%esp)
f0103047:	e8 ef 08 00 00       	call   f010393b <strfind>
f010304c:	2b 43 08             	sub    0x8(%ebx),%eax
f010304f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103052:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103056:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010305d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103060:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103063:	b8 44 50 10 f0       	mov    $0xf0105044,%eax
f0103068:	e8 b8 fd ff ff       	call   f0102e25 <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f010306d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103070:	6b c2 0c             	imul   $0xc,%edx,%eax
f0103073:	05 44 50 10 f0       	add    $0xf0105044,%eax
f0103078:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f010307c:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010307f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103082:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103085:	eb 06                	jmp    f010308d <debuginfo_eip+0x18b>
f0103087:	83 ea 01             	sub    $0x1,%edx
f010308a:	83 e8 0c             	sub    $0xc,%eax
f010308d:	89 d6                	mov    %edx,%esi
f010308f:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f0103092:	7f 33                	jg     f01030c7 <debuginfo_eip+0x1c5>
	       && stabs[lline].n_type != N_SOL
f0103094:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103098:	80 f9 84             	cmp    $0x84,%cl
f010309b:	74 0b                	je     f01030a8 <debuginfo_eip+0x1a6>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010309d:	80 f9 64             	cmp    $0x64,%cl
f01030a0:	75 e5                	jne    f0103087 <debuginfo_eip+0x185>
f01030a2:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01030a6:	74 df                	je     f0103087 <debuginfo_eip+0x185>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01030a8:	6b f6 0c             	imul   $0xc,%esi,%esi
f01030ab:	8b 86 44 50 10 f0    	mov    -0xfefafbc(%esi),%eax
f01030b1:	ba 1d cc 10 f0       	mov    $0xf010cc1d,%edx
f01030b6:	81 ea 4d ae 10 f0    	sub    $0xf010ae4d,%edx
f01030bc:	39 d0                	cmp    %edx,%eax
f01030be:	73 07                	jae    f01030c7 <debuginfo_eip+0x1c5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01030c0:	05 4d ae 10 f0       	add    $0xf010ae4d,%eax
f01030c5:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030ca:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030cd:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01030d2:	39 ca                	cmp    %ecx,%edx
f01030d4:	7d 4c                	jge    f0103122 <debuginfo_eip+0x220>
		for (lline = lfun + 1;
f01030d6:	8d 42 01             	lea    0x1(%edx),%eax
f01030d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030dc:	89 c2                	mov    %eax,%edx
f01030de:	6b c0 0c             	imul   $0xc,%eax,%eax
f01030e1:	05 44 50 10 f0       	add    $0xf0105044,%eax
f01030e6:	89 ce                	mov    %ecx,%esi
f01030e8:	eb 04                	jmp    f01030ee <debuginfo_eip+0x1ec>
			info->eip_fn_narg++;
f01030ea:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f01030ee:	39 d6                	cmp    %edx,%esi
f01030f0:	7e 2b                	jle    f010311d <debuginfo_eip+0x21b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030f2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01030f6:	83 c2 01             	add    $0x1,%edx
f01030f9:	83 c0 0c             	add    $0xc,%eax
f01030fc:	80 f9 a0             	cmp    $0xa0,%cl
f01030ff:	74 e9                	je     f01030ea <debuginfo_eip+0x1e8>
	return 0;
f0103101:	b8 00 00 00 00       	mov    $0x0,%eax
f0103106:	eb 1a                	jmp    f0103122 <debuginfo_eip+0x220>
		return -1;
f0103108:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010310d:	eb 13                	jmp    f0103122 <debuginfo_eip+0x220>
f010310f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103114:	eb 0c                	jmp    f0103122 <debuginfo_eip+0x220>
		return -1;
f0103116:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010311b:	eb 05                	jmp    f0103122 <debuginfo_eip+0x220>
	return 0;
f010311d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103122:	83 c4 3c             	add    $0x3c,%esp
f0103125:	5b                   	pop    %ebx
f0103126:	5e                   	pop    %esi
f0103127:	5f                   	pop    %edi
f0103128:	5d                   	pop    %ebp
f0103129:	c3                   	ret    
f010312a:	66 90                	xchg   %ax,%ax
f010312c:	66 90                	xchg   %ax,%ax
f010312e:	66 90                	xchg   %ax,%ax

f0103130 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103130:	55                   	push   %ebp
f0103131:	89 e5                	mov    %esp,%ebp
f0103133:	57                   	push   %edi
f0103134:	56                   	push   %esi
f0103135:	53                   	push   %ebx
f0103136:	83 ec 3c             	sub    $0x3c,%esp
f0103139:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010313c:	89 d7                	mov    %edx,%edi
f010313e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103141:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103144:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103147:	89 c3                	mov    %eax,%ebx
f0103149:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010314c:	8b 45 10             	mov    0x10(%ebp),%eax
f010314f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103152:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103157:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010315a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010315d:	39 d9                	cmp    %ebx,%ecx
f010315f:	72 05                	jb     f0103166 <printnum+0x36>
f0103161:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103164:	77 69                	ja     f01031cf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103166:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103169:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010316d:	83 ee 01             	sub    $0x1,%esi
f0103170:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103174:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103178:	8b 44 24 08          	mov    0x8(%esp),%eax
f010317c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103180:	89 c3                	mov    %eax,%ebx
f0103182:	89 d6                	mov    %edx,%esi
f0103184:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103187:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010318a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010318e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103192:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103195:	89 04 24             	mov    %eax,(%esp)
f0103198:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010319b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010319f:	e8 bc 09 00 00       	call   f0103b60 <__udivdi3>
f01031a4:	89 d9                	mov    %ebx,%ecx
f01031a6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01031aa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01031ae:	89 04 24             	mov    %eax,(%esp)
f01031b1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01031b5:	89 fa                	mov    %edi,%edx
f01031b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031ba:	e8 71 ff ff ff       	call   f0103130 <printnum>
f01031bf:	eb 1b                	jmp    f01031dc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01031c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031c5:	8b 45 18             	mov    0x18(%ebp),%eax
f01031c8:	89 04 24             	mov    %eax,(%esp)
f01031cb:	ff d3                	call   *%ebx
f01031cd:	eb 03                	jmp    f01031d2 <printnum+0xa2>
f01031cf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f01031d2:	83 ee 01             	sub    $0x1,%esi
f01031d5:	85 f6                	test   %esi,%esi
f01031d7:	7f e8                	jg     f01031c1 <printnum+0x91>
f01031d9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031dc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031e0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01031e4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01031e7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031ee:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01031f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031f5:	89 04 24             	mov    %eax,(%esp)
f01031f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031ff:	e8 8c 0a 00 00       	call   f0103c90 <__umoddi3>
f0103204:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103208:	0f be 80 35 4e 10 f0 	movsbl -0xfefb1cb(%eax),%eax
f010320f:	89 04 24             	mov    %eax,(%esp)
f0103212:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103215:	ff d0                	call   *%eax
}
f0103217:	83 c4 3c             	add    $0x3c,%esp
f010321a:	5b                   	pop    %ebx
f010321b:	5e                   	pop    %esi
f010321c:	5f                   	pop    %edi
f010321d:	5d                   	pop    %ebp
f010321e:	c3                   	ret    

f010321f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010321f:	55                   	push   %ebp
f0103220:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103222:	83 fa 01             	cmp    $0x1,%edx
f0103225:	7e 0e                	jle    f0103235 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103227:	8b 10                	mov    (%eax),%edx
f0103229:	8d 4a 08             	lea    0x8(%edx),%ecx
f010322c:	89 08                	mov    %ecx,(%eax)
f010322e:	8b 02                	mov    (%edx),%eax
f0103230:	8b 52 04             	mov    0x4(%edx),%edx
f0103233:	eb 22                	jmp    f0103257 <getuint+0x38>
	else if (lflag)
f0103235:	85 d2                	test   %edx,%edx
f0103237:	74 10                	je     f0103249 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103239:	8b 10                	mov    (%eax),%edx
f010323b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010323e:	89 08                	mov    %ecx,(%eax)
f0103240:	8b 02                	mov    (%edx),%eax
f0103242:	ba 00 00 00 00       	mov    $0x0,%edx
f0103247:	eb 0e                	jmp    f0103257 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103249:	8b 10                	mov    (%eax),%edx
f010324b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010324e:	89 08                	mov    %ecx,(%eax)
f0103250:	8b 02                	mov    (%edx),%eax
f0103252:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103257:	5d                   	pop    %ebp
f0103258:	c3                   	ret    

f0103259 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103259:	55                   	push   %ebp
f010325a:	89 e5                	mov    %esp,%ebp
f010325c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010325f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103263:	8b 10                	mov    (%eax),%edx
f0103265:	3b 50 04             	cmp    0x4(%eax),%edx
f0103268:	73 0a                	jae    f0103274 <sprintputch+0x1b>
		*b->buf++ = ch;
f010326a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010326d:	89 08                	mov    %ecx,(%eax)
f010326f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103272:	88 02                	mov    %al,(%edx)
}
f0103274:	5d                   	pop    %ebp
f0103275:	c3                   	ret    

f0103276 <printfmt>:
{
f0103276:	55                   	push   %ebp
f0103277:	89 e5                	mov    %esp,%ebp
f0103279:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f010327c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010327f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103283:	8b 45 10             	mov    0x10(%ebp),%eax
f0103286:	89 44 24 08          	mov    %eax,0x8(%esp)
f010328a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010328d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103291:	8b 45 08             	mov    0x8(%ebp),%eax
f0103294:	89 04 24             	mov    %eax,(%esp)
f0103297:	e8 02 00 00 00       	call   f010329e <vprintfmt>
}
f010329c:	c9                   	leave  
f010329d:	c3                   	ret    

f010329e <vprintfmt>:
{
f010329e:	55                   	push   %ebp
f010329f:	89 e5                	mov    %esp,%ebp
f01032a1:	57                   	push   %edi
f01032a2:	56                   	push   %esi
f01032a3:	53                   	push   %ebx
f01032a4:	83 ec 3c             	sub    $0x3c,%esp
f01032a7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01032aa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01032ad:	eb 14                	jmp    f01032c3 <vprintfmt+0x25>
			if (ch == '\0')
f01032af:	85 c0                	test   %eax,%eax
f01032b1:	0f 84 b3 03 00 00    	je     f010366a <vprintfmt+0x3cc>
			putch(ch, putdat);
f01032b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032bb:	89 04 24             	mov    %eax,(%esp)
f01032be:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01032c1:	89 f3                	mov    %esi,%ebx
f01032c3:	8d 73 01             	lea    0x1(%ebx),%esi
f01032c6:	0f b6 03             	movzbl (%ebx),%eax
f01032c9:	83 f8 25             	cmp    $0x25,%eax
f01032cc:	75 e1                	jne    f01032af <vprintfmt+0x11>
f01032ce:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01032d2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032d9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01032e0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01032e7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032ec:	eb 1d                	jmp    f010330b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f01032ee:	89 de                	mov    %ebx,%esi
			padc = '-';
f01032f0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01032f4:	eb 15                	jmp    f010330b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f01032f6:	89 de                	mov    %ebx,%esi
			padc = '0';
f01032f8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01032fc:	eb 0d                	jmp    f010330b <vprintfmt+0x6d>
				width = precision, precision = -1;
f01032fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103301:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103304:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010330b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010330e:	0f b6 0e             	movzbl (%esi),%ecx
f0103311:	0f b6 c1             	movzbl %cl,%eax
f0103314:	83 e9 23             	sub    $0x23,%ecx
f0103317:	80 f9 55             	cmp    $0x55,%cl
f010331a:	0f 87 2a 03 00 00    	ja     f010364a <vprintfmt+0x3ac>
f0103320:	0f b6 c9             	movzbl %cl,%ecx
f0103323:	ff 24 8d c0 4e 10 f0 	jmp    *-0xfefb140(,%ecx,4)
f010332a:	89 de                	mov    %ebx,%esi
f010332c:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f0103331:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103334:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103338:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010333b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010333e:	83 fb 09             	cmp    $0x9,%ebx
f0103341:	77 36                	ja     f0103379 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0103343:	83 c6 01             	add    $0x1,%esi
			}
f0103346:	eb e9                	jmp    f0103331 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0103348:	8b 45 14             	mov    0x14(%ebp),%eax
f010334b:	8d 48 04             	lea    0x4(%eax),%ecx
f010334e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103351:	8b 00                	mov    (%eax),%eax
f0103353:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103356:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0103358:	eb 22                	jmp    f010337c <vprintfmt+0xde>
f010335a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010335d:	85 c9                	test   %ecx,%ecx
f010335f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103364:	0f 49 c1             	cmovns %ecx,%eax
f0103367:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010336a:	89 de                	mov    %ebx,%esi
f010336c:	eb 9d                	jmp    f010330b <vprintfmt+0x6d>
f010336e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0103370:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103377:	eb 92                	jmp    f010330b <vprintfmt+0x6d>
f0103379:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f010337c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103380:	79 89                	jns    f010330b <vprintfmt+0x6d>
f0103382:	e9 77 ff ff ff       	jmp    f01032fe <vprintfmt+0x60>
			lflag++;
f0103387:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010338a:	89 de                	mov    %ebx,%esi
			goto reswitch;
f010338c:	e9 7a ff ff ff       	jmp    f010330b <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f0103391:	8b 45 14             	mov    0x14(%ebp),%eax
f0103394:	8d 50 04             	lea    0x4(%eax),%edx
f0103397:	89 55 14             	mov    %edx,0x14(%ebp)
f010339a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010339e:	8b 00                	mov    (%eax),%eax
f01033a0:	89 04 24             	mov    %eax,(%esp)
f01033a3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01033a6:	e9 18 ff ff ff       	jmp    f01032c3 <vprintfmt+0x25>
			err = va_arg(ap, int);
f01033ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01033ae:	8d 50 04             	lea    0x4(%eax),%edx
f01033b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01033b4:	8b 00                	mov    (%eax),%eax
f01033b6:	99                   	cltd   
f01033b7:	31 d0                	xor    %edx,%eax
f01033b9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033bb:	83 f8 06             	cmp    $0x6,%eax
f01033be:	7f 0b                	jg     f01033cb <vprintfmt+0x12d>
f01033c0:	8b 14 85 18 50 10 f0 	mov    -0xfefafe8(,%eax,4),%edx
f01033c7:	85 d2                	test   %edx,%edx
f01033c9:	75 20                	jne    f01033eb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01033cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033cf:	c7 44 24 08 4d 4e 10 	movl   $0xf0104e4d,0x8(%esp)
f01033d6:	f0 
f01033d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033db:	8b 45 08             	mov    0x8(%ebp),%eax
f01033de:	89 04 24             	mov    %eax,(%esp)
f01033e1:	e8 90 fe ff ff       	call   f0103276 <printfmt>
f01033e6:	e9 d8 fe ff ff       	jmp    f01032c3 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f01033eb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033ef:	c7 44 24 08 ab 43 10 	movl   $0xf01043ab,0x8(%esp)
f01033f6:	f0 
f01033f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033fe:	89 04 24             	mov    %eax,(%esp)
f0103401:	e8 70 fe ff ff       	call   f0103276 <printfmt>
f0103406:	e9 b8 fe ff ff       	jmp    f01032c3 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f010340b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010340e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103411:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0103414:	8b 45 14             	mov    0x14(%ebp),%eax
f0103417:	8d 50 04             	lea    0x4(%eax),%edx
f010341a:	89 55 14             	mov    %edx,0x14(%ebp)
f010341d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010341f:	85 f6                	test   %esi,%esi
f0103421:	b8 46 4e 10 f0       	mov    $0xf0104e46,%eax
f0103426:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103429:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010342d:	0f 84 97 00 00 00    	je     f01034ca <vprintfmt+0x22c>
f0103433:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103437:	0f 8e 9b 00 00 00    	jle    f01034d8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010343d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103441:	89 34 24             	mov    %esi,(%esp)
f0103444:	e8 9f 03 00 00       	call   f01037e8 <strnlen>
f0103449:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010344c:	29 c2                	sub    %eax,%edx
f010344e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103451:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103455:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103458:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010345b:	8b 75 08             	mov    0x8(%ebp),%esi
f010345e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103461:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0103463:	eb 0f                	jmp    f0103474 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103465:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103469:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010346c:	89 04 24             	mov    %eax,(%esp)
f010346f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103471:	83 eb 01             	sub    $0x1,%ebx
f0103474:	85 db                	test   %ebx,%ebx
f0103476:	7f ed                	jg     f0103465 <vprintfmt+0x1c7>
f0103478:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010347b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010347e:	85 d2                	test   %edx,%edx
f0103480:	b8 00 00 00 00       	mov    $0x0,%eax
f0103485:	0f 49 c2             	cmovns %edx,%eax
f0103488:	29 c2                	sub    %eax,%edx
f010348a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010348d:	89 d7                	mov    %edx,%edi
f010348f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103492:	eb 50                	jmp    f01034e4 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f0103494:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103498:	74 1e                	je     f01034b8 <vprintfmt+0x21a>
f010349a:	0f be d2             	movsbl %dl,%edx
f010349d:	83 ea 20             	sub    $0x20,%edx
f01034a0:	83 fa 5e             	cmp    $0x5e,%edx
f01034a3:	76 13                	jbe    f01034b8 <vprintfmt+0x21a>
					putch('?', putdat);
f01034a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034ac:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01034b3:	ff 55 08             	call   *0x8(%ebp)
f01034b6:	eb 0d                	jmp    f01034c5 <vprintfmt+0x227>
					putch(ch, putdat);
f01034b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034bb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034bf:	89 04 24             	mov    %eax,(%esp)
f01034c2:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034c5:	83 ef 01             	sub    $0x1,%edi
f01034c8:	eb 1a                	jmp    f01034e4 <vprintfmt+0x246>
f01034ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034cd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034d0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034d6:	eb 0c                	jmp    f01034e4 <vprintfmt+0x246>
f01034d8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034db:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034de:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034e4:	83 c6 01             	add    $0x1,%esi
f01034e7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01034eb:	0f be c2             	movsbl %dl,%eax
f01034ee:	85 c0                	test   %eax,%eax
f01034f0:	74 27                	je     f0103519 <vprintfmt+0x27b>
f01034f2:	85 db                	test   %ebx,%ebx
f01034f4:	78 9e                	js     f0103494 <vprintfmt+0x1f6>
f01034f6:	83 eb 01             	sub    $0x1,%ebx
f01034f9:	79 99                	jns    f0103494 <vprintfmt+0x1f6>
f01034fb:	89 f8                	mov    %edi,%eax
f01034fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103500:	8b 75 08             	mov    0x8(%ebp),%esi
f0103503:	89 c3                	mov    %eax,%ebx
f0103505:	eb 1a                	jmp    f0103521 <vprintfmt+0x283>
				putch(' ', putdat);
f0103507:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010350b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103512:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103514:	83 eb 01             	sub    $0x1,%ebx
f0103517:	eb 08                	jmp    f0103521 <vprintfmt+0x283>
f0103519:	89 fb                	mov    %edi,%ebx
f010351b:	8b 75 08             	mov    0x8(%ebp),%esi
f010351e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103521:	85 db                	test   %ebx,%ebx
f0103523:	7f e2                	jg     f0103507 <vprintfmt+0x269>
f0103525:	89 75 08             	mov    %esi,0x8(%ebp)
f0103528:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010352b:	e9 93 fd ff ff       	jmp    f01032c3 <vprintfmt+0x25>
	if (lflag >= 2)
f0103530:	83 fa 01             	cmp    $0x1,%edx
f0103533:	7e 16                	jle    f010354b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103535:	8b 45 14             	mov    0x14(%ebp),%eax
f0103538:	8d 50 08             	lea    0x8(%eax),%edx
f010353b:	89 55 14             	mov    %edx,0x14(%ebp)
f010353e:	8b 50 04             	mov    0x4(%eax),%edx
f0103541:	8b 00                	mov    (%eax),%eax
f0103543:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103546:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103549:	eb 32                	jmp    f010357d <vprintfmt+0x2df>
	else if (lflag)
f010354b:	85 d2                	test   %edx,%edx
f010354d:	74 18                	je     f0103567 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010354f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103552:	8d 50 04             	lea    0x4(%eax),%edx
f0103555:	89 55 14             	mov    %edx,0x14(%ebp)
f0103558:	8b 30                	mov    (%eax),%esi
f010355a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010355d:	89 f0                	mov    %esi,%eax
f010355f:	c1 f8 1f             	sar    $0x1f,%eax
f0103562:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103565:	eb 16                	jmp    f010357d <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0103567:	8b 45 14             	mov    0x14(%ebp),%eax
f010356a:	8d 50 04             	lea    0x4(%eax),%edx
f010356d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103570:	8b 30                	mov    (%eax),%esi
f0103572:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103575:	89 f0                	mov    %esi,%eax
f0103577:	c1 f8 1f             	sar    $0x1f,%eax
f010357a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f010357d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103580:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0103583:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0103588:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010358c:	0f 89 80 00 00 00    	jns    f0103612 <vprintfmt+0x374>
				putch('-', putdat);
f0103592:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103596:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010359d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01035a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035a3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035a6:	f7 d8                	neg    %eax
f01035a8:	83 d2 00             	adc    $0x0,%edx
f01035ab:	f7 da                	neg    %edx
			base = 10;
f01035ad:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01035b2:	eb 5e                	jmp    f0103612 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01035b4:	8d 45 14             	lea    0x14(%ebp),%eax
f01035b7:	e8 63 fc ff ff       	call   f010321f <getuint>
			base = 10;
f01035bc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01035c1:	eb 4f                	jmp    f0103612 <vprintfmt+0x374>
			num = getuint(&ap,lflag);
f01035c3:	8d 45 14             	lea    0x14(%ebp),%eax
f01035c6:	e8 54 fc ff ff       	call   f010321f <getuint>
			base = 8;
f01035cb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01035d0:	eb 40                	jmp    f0103612 <vprintfmt+0x374>
			putch('0', putdat);
f01035d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035d6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01035dd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01035e0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035e4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01035eb:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f01035ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01035f1:	8d 50 04             	lea    0x4(%eax),%edx
f01035f4:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01035f7:	8b 00                	mov    (%eax),%eax
f01035f9:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01035fe:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103603:	eb 0d                	jmp    f0103612 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0103605:	8d 45 14             	lea    0x14(%ebp),%eax
f0103608:	e8 12 fc ff ff       	call   f010321f <getuint>
			base = 16;
f010360d:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0103612:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103616:	89 74 24 10          	mov    %esi,0x10(%esp)
f010361a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010361d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103621:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103625:	89 04 24             	mov    %eax,(%esp)
f0103628:	89 54 24 04          	mov    %edx,0x4(%esp)
f010362c:	89 fa                	mov    %edi,%edx
f010362e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103631:	e8 fa fa ff ff       	call   f0103130 <printnum>
			break;
f0103636:	e9 88 fc ff ff       	jmp    f01032c3 <vprintfmt+0x25>
			putch(ch, putdat);
f010363b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010363f:	89 04 24             	mov    %eax,(%esp)
f0103642:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103645:	e9 79 fc ff ff       	jmp    f01032c3 <vprintfmt+0x25>
			putch('%', putdat);
f010364a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010364e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103655:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103658:	89 f3                	mov    %esi,%ebx
f010365a:	eb 03                	jmp    f010365f <vprintfmt+0x3c1>
f010365c:	83 eb 01             	sub    $0x1,%ebx
f010365f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103663:	75 f7                	jne    f010365c <vprintfmt+0x3be>
f0103665:	e9 59 fc ff ff       	jmp    f01032c3 <vprintfmt+0x25>
}
f010366a:	83 c4 3c             	add    $0x3c,%esp
f010366d:	5b                   	pop    %ebx
f010366e:	5e                   	pop    %esi
f010366f:	5f                   	pop    %edi
f0103670:	5d                   	pop    %ebp
f0103671:	c3                   	ret    

f0103672 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103672:	55                   	push   %ebp
f0103673:	89 e5                	mov    %esp,%ebp
f0103675:	83 ec 28             	sub    $0x28,%esp
f0103678:	8b 45 08             	mov    0x8(%ebp),%eax
f010367b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010367e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103681:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103685:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103688:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010368f:	85 c0                	test   %eax,%eax
f0103691:	74 30                	je     f01036c3 <vsnprintf+0x51>
f0103693:	85 d2                	test   %edx,%edx
f0103695:	7e 2c                	jle    f01036c3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103697:	8b 45 14             	mov    0x14(%ebp),%eax
f010369a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010369e:	8b 45 10             	mov    0x10(%ebp),%eax
f01036a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036a5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01036a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ac:	c7 04 24 59 32 10 f0 	movl   $0xf0103259,(%esp)
f01036b3:	e8 e6 fb ff ff       	call   f010329e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01036b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01036bb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01036be:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036c1:	eb 05                	jmp    f01036c8 <vsnprintf+0x56>
		return -E_INVAL;
f01036c3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01036c8:	c9                   	leave  
f01036c9:	c3                   	ret    

f01036ca <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01036ca:	55                   	push   %ebp
f01036cb:	89 e5                	mov    %esp,%ebp
f01036cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01036d0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01036d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01036da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e8:	89 04 24             	mov    %eax,(%esp)
f01036eb:	e8 82 ff ff ff       	call   f0103672 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036f0:	c9                   	leave  
f01036f1:	c3                   	ret    
f01036f2:	66 90                	xchg   %ax,%ax
f01036f4:	66 90                	xchg   %ax,%ax
f01036f6:	66 90                	xchg   %ax,%ax
f01036f8:	66 90                	xchg   %ax,%ax
f01036fa:	66 90                	xchg   %ax,%ax
f01036fc:	66 90                	xchg   %ax,%ax
f01036fe:	66 90                	xchg   %ax,%ax

f0103700 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103700:	55                   	push   %ebp
f0103701:	89 e5                	mov    %esp,%ebp
f0103703:	57                   	push   %edi
f0103704:	56                   	push   %esi
f0103705:	53                   	push   %ebx
f0103706:	83 ec 1c             	sub    $0x1c,%esp
f0103709:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010370c:	85 c0                	test   %eax,%eax
f010370e:	74 10                	je     f0103720 <readline+0x20>
		cprintf("%s", prompt);
f0103710:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103714:	c7 04 24 ab 43 10 f0 	movl   $0xf01043ab,(%esp)
f010371b:	e8 eb f6 ff ff       	call   f0102e0b <cprintf>

	i = 0;
	echoing = iscons(0);
f0103720:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103727:	e8 f6 ce ff ff       	call   f0100622 <iscons>
f010372c:	89 c7                	mov    %eax,%edi
	i = 0;
f010372e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0103733:	e8 d9 ce ff ff       	call   f0100611 <getchar>
f0103738:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010373a:	85 c0                	test   %eax,%eax
f010373c:	79 17                	jns    f0103755 <readline+0x55>
			cprintf("read error: %e\n", c);
f010373e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103742:	c7 04 24 34 50 10 f0 	movl   $0xf0105034,(%esp)
f0103749:	e8 bd f6 ff ff       	call   f0102e0b <cprintf>
			return NULL;
f010374e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103753:	eb 6d                	jmp    f01037c2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103755:	83 f8 7f             	cmp    $0x7f,%eax
f0103758:	74 05                	je     f010375f <readline+0x5f>
f010375a:	83 f8 08             	cmp    $0x8,%eax
f010375d:	75 19                	jne    f0103778 <readline+0x78>
f010375f:	85 f6                	test   %esi,%esi
f0103761:	7e 15                	jle    f0103778 <readline+0x78>
			if (echoing)
f0103763:	85 ff                	test   %edi,%edi
f0103765:	74 0c                	je     f0103773 <readline+0x73>
				cputchar('\b');
f0103767:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010376e:	e8 8e ce ff ff       	call   f0100601 <cputchar>
			i--;
f0103773:	83 ee 01             	sub    $0x1,%esi
f0103776:	eb bb                	jmp    f0103733 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103778:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010377e:	7f 1c                	jg     f010379c <readline+0x9c>
f0103780:	83 fb 1f             	cmp    $0x1f,%ebx
f0103783:	7e 17                	jle    f010379c <readline+0x9c>
			if (echoing)
f0103785:	85 ff                	test   %edi,%edi
f0103787:	74 08                	je     f0103791 <readline+0x91>
				cputchar(c);
f0103789:	89 1c 24             	mov    %ebx,(%esp)
f010378c:	e8 70 ce ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f0103791:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103797:	8d 76 01             	lea    0x1(%esi),%esi
f010379a:	eb 97                	jmp    f0103733 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010379c:	83 fb 0d             	cmp    $0xd,%ebx
f010379f:	74 05                	je     f01037a6 <readline+0xa6>
f01037a1:	83 fb 0a             	cmp    $0xa,%ebx
f01037a4:	75 8d                	jne    f0103733 <readline+0x33>
			if (echoing)
f01037a6:	85 ff                	test   %edi,%edi
f01037a8:	74 0c                	je     f01037b6 <readline+0xb6>
				cputchar('\n');
f01037aa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01037b1:	e8 4b ce ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f01037b6:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01037bd:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01037c2:	83 c4 1c             	add    $0x1c,%esp
f01037c5:	5b                   	pop    %ebx
f01037c6:	5e                   	pop    %esi
f01037c7:	5f                   	pop    %edi
f01037c8:	5d                   	pop    %ebp
f01037c9:	c3                   	ret    
f01037ca:	66 90                	xchg   %ax,%ax
f01037cc:	66 90                	xchg   %ax,%ax
f01037ce:	66 90                	xchg   %ax,%ax

f01037d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01037d0:	55                   	push   %ebp
f01037d1:	89 e5                	mov    %esp,%ebp
f01037d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01037d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037db:	eb 03                	jmp    f01037e0 <strlen+0x10>
		n++;
f01037dd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01037e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037e4:	75 f7                	jne    f01037dd <strlen+0xd>
	return n;
}
f01037e6:	5d                   	pop    %ebp
f01037e7:	c3                   	ret    

f01037e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037e8:	55                   	push   %ebp
f01037e9:	89 e5                	mov    %esp,%ebp
f01037eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037ee:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037f6:	eb 03                	jmp    f01037fb <strnlen+0x13>
		n++;
f01037f8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037fb:	39 d0                	cmp    %edx,%eax
f01037fd:	74 06                	je     f0103805 <strnlen+0x1d>
f01037ff:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103803:	75 f3                	jne    f01037f8 <strnlen+0x10>
	return n;
}
f0103805:	5d                   	pop    %ebp
f0103806:	c3                   	ret    

f0103807 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103807:	55                   	push   %ebp
f0103808:	89 e5                	mov    %esp,%ebp
f010380a:	53                   	push   %ebx
f010380b:	8b 45 08             	mov    0x8(%ebp),%eax
f010380e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103811:	89 c2                	mov    %eax,%edx
f0103813:	83 c2 01             	add    $0x1,%edx
f0103816:	83 c1 01             	add    $0x1,%ecx
f0103819:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010381d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103820:	84 db                	test   %bl,%bl
f0103822:	75 ef                	jne    f0103813 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103824:	5b                   	pop    %ebx
f0103825:	5d                   	pop    %ebp
f0103826:	c3                   	ret    

f0103827 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103827:	55                   	push   %ebp
f0103828:	89 e5                	mov    %esp,%ebp
f010382a:	53                   	push   %ebx
f010382b:	83 ec 08             	sub    $0x8,%esp
f010382e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103831:	89 1c 24             	mov    %ebx,(%esp)
f0103834:	e8 97 ff ff ff       	call   f01037d0 <strlen>
	strcpy(dst + len, src);
f0103839:	8b 55 0c             	mov    0xc(%ebp),%edx
f010383c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103840:	01 d8                	add    %ebx,%eax
f0103842:	89 04 24             	mov    %eax,(%esp)
f0103845:	e8 bd ff ff ff       	call   f0103807 <strcpy>
	return dst;
}
f010384a:	89 d8                	mov    %ebx,%eax
f010384c:	83 c4 08             	add    $0x8,%esp
f010384f:	5b                   	pop    %ebx
f0103850:	5d                   	pop    %ebp
f0103851:	c3                   	ret    

f0103852 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103852:	55                   	push   %ebp
f0103853:	89 e5                	mov    %esp,%ebp
f0103855:	56                   	push   %esi
f0103856:	53                   	push   %ebx
f0103857:	8b 75 08             	mov    0x8(%ebp),%esi
f010385a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010385d:	89 f3                	mov    %esi,%ebx
f010385f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103862:	89 f2                	mov    %esi,%edx
f0103864:	eb 0f                	jmp    f0103875 <strncpy+0x23>
		*dst++ = *src;
f0103866:	83 c2 01             	add    $0x1,%edx
f0103869:	0f b6 01             	movzbl (%ecx),%eax
f010386c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010386f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103872:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103875:	39 da                	cmp    %ebx,%edx
f0103877:	75 ed                	jne    f0103866 <strncpy+0x14>
	}
	return ret;
}
f0103879:	89 f0                	mov    %esi,%eax
f010387b:	5b                   	pop    %ebx
f010387c:	5e                   	pop    %esi
f010387d:	5d                   	pop    %ebp
f010387e:	c3                   	ret    

f010387f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010387f:	55                   	push   %ebp
f0103880:	89 e5                	mov    %esp,%ebp
f0103882:	56                   	push   %esi
f0103883:	53                   	push   %ebx
f0103884:	8b 75 08             	mov    0x8(%ebp),%esi
f0103887:	8b 55 0c             	mov    0xc(%ebp),%edx
f010388a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010388d:	89 f0                	mov    %esi,%eax
f010388f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103893:	85 c9                	test   %ecx,%ecx
f0103895:	75 0b                	jne    f01038a2 <strlcpy+0x23>
f0103897:	eb 1d                	jmp    f01038b6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103899:	83 c0 01             	add    $0x1,%eax
f010389c:	83 c2 01             	add    $0x1,%edx
f010389f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01038a2:	39 d8                	cmp    %ebx,%eax
f01038a4:	74 0b                	je     f01038b1 <strlcpy+0x32>
f01038a6:	0f b6 0a             	movzbl (%edx),%ecx
f01038a9:	84 c9                	test   %cl,%cl
f01038ab:	75 ec                	jne    f0103899 <strlcpy+0x1a>
f01038ad:	89 c2                	mov    %eax,%edx
f01038af:	eb 02                	jmp    f01038b3 <strlcpy+0x34>
f01038b1:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f01038b3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01038b6:	29 f0                	sub    %esi,%eax
}
f01038b8:	5b                   	pop    %ebx
f01038b9:	5e                   	pop    %esi
f01038ba:	5d                   	pop    %ebp
f01038bb:	c3                   	ret    

f01038bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01038bc:	55                   	push   %ebp
f01038bd:	89 e5                	mov    %esp,%ebp
f01038bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038c2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01038c5:	eb 06                	jmp    f01038cd <strcmp+0x11>
		p++, q++;
f01038c7:	83 c1 01             	add    $0x1,%ecx
f01038ca:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01038cd:	0f b6 01             	movzbl (%ecx),%eax
f01038d0:	84 c0                	test   %al,%al
f01038d2:	74 04                	je     f01038d8 <strcmp+0x1c>
f01038d4:	3a 02                	cmp    (%edx),%al
f01038d6:	74 ef                	je     f01038c7 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01038d8:	0f b6 c0             	movzbl %al,%eax
f01038db:	0f b6 12             	movzbl (%edx),%edx
f01038de:	29 d0                	sub    %edx,%eax
}
f01038e0:	5d                   	pop    %ebp
f01038e1:	c3                   	ret    

f01038e2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038e2:	55                   	push   %ebp
f01038e3:	89 e5                	mov    %esp,%ebp
f01038e5:	53                   	push   %ebx
f01038e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038ec:	89 c3                	mov    %eax,%ebx
f01038ee:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01038f1:	eb 06                	jmp    f01038f9 <strncmp+0x17>
		n--, p++, q++;
f01038f3:	83 c0 01             	add    $0x1,%eax
f01038f6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01038f9:	39 d8                	cmp    %ebx,%eax
f01038fb:	74 15                	je     f0103912 <strncmp+0x30>
f01038fd:	0f b6 08             	movzbl (%eax),%ecx
f0103900:	84 c9                	test   %cl,%cl
f0103902:	74 04                	je     f0103908 <strncmp+0x26>
f0103904:	3a 0a                	cmp    (%edx),%cl
f0103906:	74 eb                	je     f01038f3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103908:	0f b6 00             	movzbl (%eax),%eax
f010390b:	0f b6 12             	movzbl (%edx),%edx
f010390e:	29 d0                	sub    %edx,%eax
f0103910:	eb 05                	jmp    f0103917 <strncmp+0x35>
		return 0;
f0103912:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103917:	5b                   	pop    %ebx
f0103918:	5d                   	pop    %ebp
f0103919:	c3                   	ret    

f010391a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010391a:	55                   	push   %ebp
f010391b:	89 e5                	mov    %esp,%ebp
f010391d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103920:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103924:	eb 07                	jmp    f010392d <strchr+0x13>
		if (*s == c)
f0103926:	38 ca                	cmp    %cl,%dl
f0103928:	74 0f                	je     f0103939 <strchr+0x1f>
	for (; *s; s++)
f010392a:	83 c0 01             	add    $0x1,%eax
f010392d:	0f b6 10             	movzbl (%eax),%edx
f0103930:	84 d2                	test   %dl,%dl
f0103932:	75 f2                	jne    f0103926 <strchr+0xc>
			return (char *) s;
	return 0;
f0103934:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103939:	5d                   	pop    %ebp
f010393a:	c3                   	ret    

f010393b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010393b:	55                   	push   %ebp
f010393c:	89 e5                	mov    %esp,%ebp
f010393e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103941:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103945:	eb 07                	jmp    f010394e <strfind+0x13>
		if (*s == c)
f0103947:	38 ca                	cmp    %cl,%dl
f0103949:	74 0a                	je     f0103955 <strfind+0x1a>
	for (; *s; s++)
f010394b:	83 c0 01             	add    $0x1,%eax
f010394e:	0f b6 10             	movzbl (%eax),%edx
f0103951:	84 d2                	test   %dl,%dl
f0103953:	75 f2                	jne    f0103947 <strfind+0xc>
			break;
	return (char *) s;
}
f0103955:	5d                   	pop    %ebp
f0103956:	c3                   	ret    

f0103957 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103957:	55                   	push   %ebp
f0103958:	89 e5                	mov    %esp,%ebp
f010395a:	57                   	push   %edi
f010395b:	56                   	push   %esi
f010395c:	53                   	push   %ebx
f010395d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103960:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103963:	85 c9                	test   %ecx,%ecx
f0103965:	74 36                	je     f010399d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103967:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010396d:	75 28                	jne    f0103997 <memset+0x40>
f010396f:	f6 c1 03             	test   $0x3,%cl
f0103972:	75 23                	jne    f0103997 <memset+0x40>
		c &= 0xFF;
f0103974:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103978:	89 d3                	mov    %edx,%ebx
f010397a:	c1 e3 08             	shl    $0x8,%ebx
f010397d:	89 d6                	mov    %edx,%esi
f010397f:	c1 e6 18             	shl    $0x18,%esi
f0103982:	89 d0                	mov    %edx,%eax
f0103984:	c1 e0 10             	shl    $0x10,%eax
f0103987:	09 f0                	or     %esi,%eax
f0103989:	09 c2                	or     %eax,%edx
f010398b:	89 d0                	mov    %edx,%eax
f010398d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010398f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103992:	fc                   	cld    
f0103993:	f3 ab                	rep stos %eax,%es:(%edi)
f0103995:	eb 06                	jmp    f010399d <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103997:	8b 45 0c             	mov    0xc(%ebp),%eax
f010399a:	fc                   	cld    
f010399b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010399d:	89 f8                	mov    %edi,%eax
f010399f:	5b                   	pop    %ebx
f01039a0:	5e                   	pop    %esi
f01039a1:	5f                   	pop    %edi
f01039a2:	5d                   	pop    %ebp
f01039a3:	c3                   	ret    

f01039a4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039a4:	55                   	push   %ebp
f01039a5:	89 e5                	mov    %esp,%ebp
f01039a7:	57                   	push   %edi
f01039a8:	56                   	push   %esi
f01039a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039af:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039b2:	39 c6                	cmp    %eax,%esi
f01039b4:	73 35                	jae    f01039eb <memmove+0x47>
f01039b6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039b9:	39 d0                	cmp    %edx,%eax
f01039bb:	73 2e                	jae    f01039eb <memmove+0x47>
		s += n;
		d += n;
f01039bd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01039c0:	89 d6                	mov    %edx,%esi
f01039c2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039c4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039ca:	75 13                	jne    f01039df <memmove+0x3b>
f01039cc:	f6 c1 03             	test   $0x3,%cl
f01039cf:	75 0e                	jne    f01039df <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039d1:	83 ef 04             	sub    $0x4,%edi
f01039d4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039d7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01039da:	fd                   	std    
f01039db:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039dd:	eb 09                	jmp    f01039e8 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039df:	83 ef 01             	sub    $0x1,%edi
f01039e2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01039e5:	fd                   	std    
f01039e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039e8:	fc                   	cld    
f01039e9:	eb 1d                	jmp    f0103a08 <memmove+0x64>
f01039eb:	89 f2                	mov    %esi,%edx
f01039ed:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039ef:	f6 c2 03             	test   $0x3,%dl
f01039f2:	75 0f                	jne    f0103a03 <memmove+0x5f>
f01039f4:	f6 c1 03             	test   $0x3,%cl
f01039f7:	75 0a                	jne    f0103a03 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039f9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01039fc:	89 c7                	mov    %eax,%edi
f01039fe:	fc                   	cld    
f01039ff:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a01:	eb 05                	jmp    f0103a08 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f0103a03:	89 c7                	mov    %eax,%edi
f0103a05:	fc                   	cld    
f0103a06:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a08:	5e                   	pop    %esi
f0103a09:	5f                   	pop    %edi
f0103a0a:	5d                   	pop    %ebp
f0103a0b:	c3                   	ret    

f0103a0c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103a0c:	55                   	push   %ebp
f0103a0d:	89 e5                	mov    %esp,%ebp
f0103a0f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a12:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a19:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a23:	89 04 24             	mov    %eax,(%esp)
f0103a26:	e8 79 ff ff ff       	call   f01039a4 <memmove>
}
f0103a2b:	c9                   	leave  
f0103a2c:	c3                   	ret    

f0103a2d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a2d:	55                   	push   %ebp
f0103a2e:	89 e5                	mov    %esp,%ebp
f0103a30:	56                   	push   %esi
f0103a31:	53                   	push   %ebx
f0103a32:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a38:	89 d6                	mov    %edx,%esi
f0103a3a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a3d:	eb 1a                	jmp    f0103a59 <memcmp+0x2c>
		if (*s1 != *s2)
f0103a3f:	0f b6 02             	movzbl (%edx),%eax
f0103a42:	0f b6 19             	movzbl (%ecx),%ebx
f0103a45:	38 d8                	cmp    %bl,%al
f0103a47:	74 0a                	je     f0103a53 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103a49:	0f b6 c0             	movzbl %al,%eax
f0103a4c:	0f b6 db             	movzbl %bl,%ebx
f0103a4f:	29 d8                	sub    %ebx,%eax
f0103a51:	eb 0f                	jmp    f0103a62 <memcmp+0x35>
		s1++, s2++;
f0103a53:	83 c2 01             	add    $0x1,%edx
f0103a56:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0103a59:	39 f2                	cmp    %esi,%edx
f0103a5b:	75 e2                	jne    f0103a3f <memcmp+0x12>
	}

	return 0;
f0103a5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a62:	5b                   	pop    %ebx
f0103a63:	5e                   	pop    %esi
f0103a64:	5d                   	pop    %ebp
f0103a65:	c3                   	ret    

f0103a66 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a66:	55                   	push   %ebp
f0103a67:	89 e5                	mov    %esp,%ebp
f0103a69:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a6c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a6f:	89 c2                	mov    %eax,%edx
f0103a71:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a74:	eb 07                	jmp    f0103a7d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a76:	38 08                	cmp    %cl,(%eax)
f0103a78:	74 07                	je     f0103a81 <memfind+0x1b>
	for (; s < ends; s++)
f0103a7a:	83 c0 01             	add    $0x1,%eax
f0103a7d:	39 d0                	cmp    %edx,%eax
f0103a7f:	72 f5                	jb     f0103a76 <memfind+0x10>
			break;
	return (void *) s;
}
f0103a81:	5d                   	pop    %ebp
f0103a82:	c3                   	ret    

f0103a83 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a83:	55                   	push   %ebp
f0103a84:	89 e5                	mov    %esp,%ebp
f0103a86:	57                   	push   %edi
f0103a87:	56                   	push   %esi
f0103a88:	53                   	push   %ebx
f0103a89:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a8c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a8f:	eb 03                	jmp    f0103a94 <strtol+0x11>
		s++;
f0103a91:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103a94:	0f b6 0a             	movzbl (%edx),%ecx
f0103a97:	80 f9 09             	cmp    $0x9,%cl
f0103a9a:	74 f5                	je     f0103a91 <strtol+0xe>
f0103a9c:	80 f9 20             	cmp    $0x20,%cl
f0103a9f:	74 f0                	je     f0103a91 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103aa1:	80 f9 2b             	cmp    $0x2b,%cl
f0103aa4:	75 0a                	jne    f0103ab0 <strtol+0x2d>
		s++;
f0103aa6:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103aa9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103aae:	eb 11                	jmp    f0103ac1 <strtol+0x3e>
f0103ab0:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0103ab5:	80 f9 2d             	cmp    $0x2d,%cl
f0103ab8:	75 07                	jne    f0103ac1 <strtol+0x3e>
		s++, neg = 1;
f0103aba:	8d 52 01             	lea    0x1(%edx),%edx
f0103abd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ac1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103ac6:	75 15                	jne    f0103add <strtol+0x5a>
f0103ac8:	80 3a 30             	cmpb   $0x30,(%edx)
f0103acb:	75 10                	jne    f0103add <strtol+0x5a>
f0103acd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103ad1:	75 0a                	jne    f0103add <strtol+0x5a>
		s += 2, base = 16;
f0103ad3:	83 c2 02             	add    $0x2,%edx
f0103ad6:	b8 10 00 00 00       	mov    $0x10,%eax
f0103adb:	eb 10                	jmp    f0103aed <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103add:	85 c0                	test   %eax,%eax
f0103adf:	75 0c                	jne    f0103aed <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ae1:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f0103ae3:	80 3a 30             	cmpb   $0x30,(%edx)
f0103ae6:	75 05                	jne    f0103aed <strtol+0x6a>
		s++, base = 8;
f0103ae8:	83 c2 01             	add    $0x1,%edx
f0103aeb:	b0 08                	mov    $0x8,%al
		base = 10;
f0103aed:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103af2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103af5:	0f b6 0a             	movzbl (%edx),%ecx
f0103af8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103afb:	89 f0                	mov    %esi,%eax
f0103afd:	3c 09                	cmp    $0x9,%al
f0103aff:	77 08                	ja     f0103b09 <strtol+0x86>
			dig = *s - '0';
f0103b01:	0f be c9             	movsbl %cl,%ecx
f0103b04:	83 e9 30             	sub    $0x30,%ecx
f0103b07:	eb 20                	jmp    f0103b29 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103b09:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103b0c:	89 f0                	mov    %esi,%eax
f0103b0e:	3c 19                	cmp    $0x19,%al
f0103b10:	77 08                	ja     f0103b1a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103b12:	0f be c9             	movsbl %cl,%ecx
f0103b15:	83 e9 57             	sub    $0x57,%ecx
f0103b18:	eb 0f                	jmp    f0103b29 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103b1a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103b1d:	89 f0                	mov    %esi,%eax
f0103b1f:	3c 19                	cmp    $0x19,%al
f0103b21:	77 16                	ja     f0103b39 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103b23:	0f be c9             	movsbl %cl,%ecx
f0103b26:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b29:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103b2c:	7d 0f                	jge    f0103b3d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103b2e:	83 c2 01             	add    $0x1,%edx
f0103b31:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103b35:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103b37:	eb bc                	jmp    f0103af5 <strtol+0x72>
f0103b39:	89 d8                	mov    %ebx,%eax
f0103b3b:	eb 02                	jmp    f0103b3f <strtol+0xbc>
f0103b3d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103b3f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b43:	74 05                	je     f0103b4a <strtol+0xc7>
		*endptr = (char *) s;
f0103b45:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b48:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103b4a:	f7 d8                	neg    %eax
f0103b4c:	85 ff                	test   %edi,%edi
f0103b4e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103b51:	5b                   	pop    %ebx
f0103b52:	5e                   	pop    %esi
f0103b53:	5f                   	pop    %edi
f0103b54:	5d                   	pop    %ebp
f0103b55:	c3                   	ret    
f0103b56:	66 90                	xchg   %ax,%ax
f0103b58:	66 90                	xchg   %ax,%ax
f0103b5a:	66 90                	xchg   %ax,%ax
f0103b5c:	66 90                	xchg   %ax,%ax
f0103b5e:	66 90                	xchg   %ax,%ax

f0103b60 <__udivdi3>:
f0103b60:	55                   	push   %ebp
f0103b61:	57                   	push   %edi
f0103b62:	56                   	push   %esi
f0103b63:	83 ec 0c             	sub    $0xc,%esp
f0103b66:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b6a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103b6e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103b72:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b76:	85 c0                	test   %eax,%eax
f0103b78:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b7c:	89 ea                	mov    %ebp,%edx
f0103b7e:	89 0c 24             	mov    %ecx,(%esp)
f0103b81:	75 2d                	jne    f0103bb0 <__udivdi3+0x50>
f0103b83:	39 e9                	cmp    %ebp,%ecx
f0103b85:	77 61                	ja     f0103be8 <__udivdi3+0x88>
f0103b87:	85 c9                	test   %ecx,%ecx
f0103b89:	89 ce                	mov    %ecx,%esi
f0103b8b:	75 0b                	jne    f0103b98 <__udivdi3+0x38>
f0103b8d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b92:	31 d2                	xor    %edx,%edx
f0103b94:	f7 f1                	div    %ecx
f0103b96:	89 c6                	mov    %eax,%esi
f0103b98:	31 d2                	xor    %edx,%edx
f0103b9a:	89 e8                	mov    %ebp,%eax
f0103b9c:	f7 f6                	div    %esi
f0103b9e:	89 c5                	mov    %eax,%ebp
f0103ba0:	89 f8                	mov    %edi,%eax
f0103ba2:	f7 f6                	div    %esi
f0103ba4:	89 ea                	mov    %ebp,%edx
f0103ba6:	83 c4 0c             	add    $0xc,%esp
f0103ba9:	5e                   	pop    %esi
f0103baa:	5f                   	pop    %edi
f0103bab:	5d                   	pop    %ebp
f0103bac:	c3                   	ret    
f0103bad:	8d 76 00             	lea    0x0(%esi),%esi
f0103bb0:	39 e8                	cmp    %ebp,%eax
f0103bb2:	77 24                	ja     f0103bd8 <__udivdi3+0x78>
f0103bb4:	0f bd e8             	bsr    %eax,%ebp
f0103bb7:	83 f5 1f             	xor    $0x1f,%ebp
f0103bba:	75 3c                	jne    f0103bf8 <__udivdi3+0x98>
f0103bbc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103bc0:	39 34 24             	cmp    %esi,(%esp)
f0103bc3:	0f 86 9f 00 00 00    	jbe    f0103c68 <__udivdi3+0x108>
f0103bc9:	39 d0                	cmp    %edx,%eax
f0103bcb:	0f 82 97 00 00 00    	jb     f0103c68 <__udivdi3+0x108>
f0103bd1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103bd8:	31 d2                	xor    %edx,%edx
f0103bda:	31 c0                	xor    %eax,%eax
f0103bdc:	83 c4 0c             	add    $0xc,%esp
f0103bdf:	5e                   	pop    %esi
f0103be0:	5f                   	pop    %edi
f0103be1:	5d                   	pop    %ebp
f0103be2:	c3                   	ret    
f0103be3:	90                   	nop
f0103be4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103be8:	89 f8                	mov    %edi,%eax
f0103bea:	f7 f1                	div    %ecx
f0103bec:	31 d2                	xor    %edx,%edx
f0103bee:	83 c4 0c             	add    $0xc,%esp
f0103bf1:	5e                   	pop    %esi
f0103bf2:	5f                   	pop    %edi
f0103bf3:	5d                   	pop    %ebp
f0103bf4:	c3                   	ret    
f0103bf5:	8d 76 00             	lea    0x0(%esi),%esi
f0103bf8:	89 e9                	mov    %ebp,%ecx
f0103bfa:	8b 3c 24             	mov    (%esp),%edi
f0103bfd:	d3 e0                	shl    %cl,%eax
f0103bff:	89 c6                	mov    %eax,%esi
f0103c01:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c06:	29 e8                	sub    %ebp,%eax
f0103c08:	89 c1                	mov    %eax,%ecx
f0103c0a:	d3 ef                	shr    %cl,%edi
f0103c0c:	89 e9                	mov    %ebp,%ecx
f0103c0e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103c12:	8b 3c 24             	mov    (%esp),%edi
f0103c15:	09 74 24 08          	or     %esi,0x8(%esp)
f0103c19:	89 d6                	mov    %edx,%esi
f0103c1b:	d3 e7                	shl    %cl,%edi
f0103c1d:	89 c1                	mov    %eax,%ecx
f0103c1f:	89 3c 24             	mov    %edi,(%esp)
f0103c22:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c26:	d3 ee                	shr    %cl,%esi
f0103c28:	89 e9                	mov    %ebp,%ecx
f0103c2a:	d3 e2                	shl    %cl,%edx
f0103c2c:	89 c1                	mov    %eax,%ecx
f0103c2e:	d3 ef                	shr    %cl,%edi
f0103c30:	09 d7                	or     %edx,%edi
f0103c32:	89 f2                	mov    %esi,%edx
f0103c34:	89 f8                	mov    %edi,%eax
f0103c36:	f7 74 24 08          	divl   0x8(%esp)
f0103c3a:	89 d6                	mov    %edx,%esi
f0103c3c:	89 c7                	mov    %eax,%edi
f0103c3e:	f7 24 24             	mull   (%esp)
f0103c41:	39 d6                	cmp    %edx,%esi
f0103c43:	89 14 24             	mov    %edx,(%esp)
f0103c46:	72 30                	jb     f0103c78 <__udivdi3+0x118>
f0103c48:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c4c:	89 e9                	mov    %ebp,%ecx
f0103c4e:	d3 e2                	shl    %cl,%edx
f0103c50:	39 c2                	cmp    %eax,%edx
f0103c52:	73 05                	jae    f0103c59 <__udivdi3+0xf9>
f0103c54:	3b 34 24             	cmp    (%esp),%esi
f0103c57:	74 1f                	je     f0103c78 <__udivdi3+0x118>
f0103c59:	89 f8                	mov    %edi,%eax
f0103c5b:	31 d2                	xor    %edx,%edx
f0103c5d:	e9 7a ff ff ff       	jmp    f0103bdc <__udivdi3+0x7c>
f0103c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c68:	31 d2                	xor    %edx,%edx
f0103c6a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c6f:	e9 68 ff ff ff       	jmp    f0103bdc <__udivdi3+0x7c>
f0103c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c78:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103c7b:	31 d2                	xor    %edx,%edx
f0103c7d:	83 c4 0c             	add    $0xc,%esp
f0103c80:	5e                   	pop    %esi
f0103c81:	5f                   	pop    %edi
f0103c82:	5d                   	pop    %ebp
f0103c83:	c3                   	ret    
f0103c84:	66 90                	xchg   %ax,%ax
f0103c86:	66 90                	xchg   %ax,%ax
f0103c88:	66 90                	xchg   %ax,%ax
f0103c8a:	66 90                	xchg   %ax,%ax
f0103c8c:	66 90                	xchg   %ax,%ax
f0103c8e:	66 90                	xchg   %ax,%ax

f0103c90 <__umoddi3>:
f0103c90:	55                   	push   %ebp
f0103c91:	57                   	push   %edi
f0103c92:	56                   	push   %esi
f0103c93:	83 ec 14             	sub    $0x14,%esp
f0103c96:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c9a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c9e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103ca2:	89 c7                	mov    %eax,%edi
f0103ca4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ca8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103cac:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103cb0:	89 34 24             	mov    %esi,(%esp)
f0103cb3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cb7:	85 c0                	test   %eax,%eax
f0103cb9:	89 c2                	mov    %eax,%edx
f0103cbb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103cbf:	75 17                	jne    f0103cd8 <__umoddi3+0x48>
f0103cc1:	39 fe                	cmp    %edi,%esi
f0103cc3:	76 4b                	jbe    f0103d10 <__umoddi3+0x80>
f0103cc5:	89 c8                	mov    %ecx,%eax
f0103cc7:	89 fa                	mov    %edi,%edx
f0103cc9:	f7 f6                	div    %esi
f0103ccb:	89 d0                	mov    %edx,%eax
f0103ccd:	31 d2                	xor    %edx,%edx
f0103ccf:	83 c4 14             	add    $0x14,%esp
f0103cd2:	5e                   	pop    %esi
f0103cd3:	5f                   	pop    %edi
f0103cd4:	5d                   	pop    %ebp
f0103cd5:	c3                   	ret    
f0103cd6:	66 90                	xchg   %ax,%ax
f0103cd8:	39 f8                	cmp    %edi,%eax
f0103cda:	77 54                	ja     f0103d30 <__umoddi3+0xa0>
f0103cdc:	0f bd e8             	bsr    %eax,%ebp
f0103cdf:	83 f5 1f             	xor    $0x1f,%ebp
f0103ce2:	75 5c                	jne    f0103d40 <__umoddi3+0xb0>
f0103ce4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103ce8:	39 3c 24             	cmp    %edi,(%esp)
f0103ceb:	0f 87 e7 00 00 00    	ja     f0103dd8 <__umoddi3+0x148>
f0103cf1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103cf5:	29 f1                	sub    %esi,%ecx
f0103cf7:	19 c7                	sbb    %eax,%edi
f0103cf9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cfd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d01:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d05:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103d09:	83 c4 14             	add    $0x14,%esp
f0103d0c:	5e                   	pop    %esi
f0103d0d:	5f                   	pop    %edi
f0103d0e:	5d                   	pop    %ebp
f0103d0f:	c3                   	ret    
f0103d10:	85 f6                	test   %esi,%esi
f0103d12:	89 f5                	mov    %esi,%ebp
f0103d14:	75 0b                	jne    f0103d21 <__umoddi3+0x91>
f0103d16:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d1b:	31 d2                	xor    %edx,%edx
f0103d1d:	f7 f6                	div    %esi
f0103d1f:	89 c5                	mov    %eax,%ebp
f0103d21:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d25:	31 d2                	xor    %edx,%edx
f0103d27:	f7 f5                	div    %ebp
f0103d29:	89 c8                	mov    %ecx,%eax
f0103d2b:	f7 f5                	div    %ebp
f0103d2d:	eb 9c                	jmp    f0103ccb <__umoddi3+0x3b>
f0103d2f:	90                   	nop
f0103d30:	89 c8                	mov    %ecx,%eax
f0103d32:	89 fa                	mov    %edi,%edx
f0103d34:	83 c4 14             	add    $0x14,%esp
f0103d37:	5e                   	pop    %esi
f0103d38:	5f                   	pop    %edi
f0103d39:	5d                   	pop    %ebp
f0103d3a:	c3                   	ret    
f0103d3b:	90                   	nop
f0103d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d40:	8b 04 24             	mov    (%esp),%eax
f0103d43:	be 20 00 00 00       	mov    $0x20,%esi
f0103d48:	89 e9                	mov    %ebp,%ecx
f0103d4a:	29 ee                	sub    %ebp,%esi
f0103d4c:	d3 e2                	shl    %cl,%edx
f0103d4e:	89 f1                	mov    %esi,%ecx
f0103d50:	d3 e8                	shr    %cl,%eax
f0103d52:	89 e9                	mov    %ebp,%ecx
f0103d54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d58:	8b 04 24             	mov    (%esp),%eax
f0103d5b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103d5f:	89 fa                	mov    %edi,%edx
f0103d61:	d3 e0                	shl    %cl,%eax
f0103d63:	89 f1                	mov    %esi,%ecx
f0103d65:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d69:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103d6d:	d3 ea                	shr    %cl,%edx
f0103d6f:	89 e9                	mov    %ebp,%ecx
f0103d71:	d3 e7                	shl    %cl,%edi
f0103d73:	89 f1                	mov    %esi,%ecx
f0103d75:	d3 e8                	shr    %cl,%eax
f0103d77:	89 e9                	mov    %ebp,%ecx
f0103d79:	09 f8                	or     %edi,%eax
f0103d7b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103d7f:	f7 74 24 04          	divl   0x4(%esp)
f0103d83:	d3 e7                	shl    %cl,%edi
f0103d85:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d89:	89 d7                	mov    %edx,%edi
f0103d8b:	f7 64 24 08          	mull   0x8(%esp)
f0103d8f:	39 d7                	cmp    %edx,%edi
f0103d91:	89 c1                	mov    %eax,%ecx
f0103d93:	89 14 24             	mov    %edx,(%esp)
f0103d96:	72 2c                	jb     f0103dc4 <__umoddi3+0x134>
f0103d98:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d9c:	72 22                	jb     f0103dc0 <__umoddi3+0x130>
f0103d9e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103da2:	29 c8                	sub    %ecx,%eax
f0103da4:	19 d7                	sbb    %edx,%edi
f0103da6:	89 e9                	mov    %ebp,%ecx
f0103da8:	89 fa                	mov    %edi,%edx
f0103daa:	d3 e8                	shr    %cl,%eax
f0103dac:	89 f1                	mov    %esi,%ecx
f0103dae:	d3 e2                	shl    %cl,%edx
f0103db0:	89 e9                	mov    %ebp,%ecx
f0103db2:	d3 ef                	shr    %cl,%edi
f0103db4:	09 d0                	or     %edx,%eax
f0103db6:	89 fa                	mov    %edi,%edx
f0103db8:	83 c4 14             	add    $0x14,%esp
f0103dbb:	5e                   	pop    %esi
f0103dbc:	5f                   	pop    %edi
f0103dbd:	5d                   	pop    %ebp
f0103dbe:	c3                   	ret    
f0103dbf:	90                   	nop
f0103dc0:	39 d7                	cmp    %edx,%edi
f0103dc2:	75 da                	jne    f0103d9e <__umoddi3+0x10e>
f0103dc4:	8b 14 24             	mov    (%esp),%edx
f0103dc7:	89 c1                	mov    %eax,%ecx
f0103dc9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103dcd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103dd1:	eb cb                	jmp    f0103d9e <__umoddi3+0x10e>
f0103dd3:	90                   	nop
f0103dd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103dd8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103ddc:	0f 82 0f ff ff ff    	jb     f0103cf1 <__umoddi3+0x61>
f0103de2:	e9 1a ff ff ff       	jmp    f0103d01 <__umoddi3+0x71>
