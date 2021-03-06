DASM 	?= ndisasm
ASM		?= nasm
AS      ?= as
LD      ?= ld
CC      ?= gcc
CPP     ?= $(CC) -E
AR      ?= ar
NM      ?= nm
STRIP   ?= strip
OBJCOPY ?= objcopy
OBJDUMP ?= objdump
RANLIB  ?= ranlib
MKDIR	?= mkdir -p
MAKE	?= make


KERNEL 		:= kernel.bin
KERNEL_DUMP := dump.asm
ENTRYPOINT	:= 0x30400
ENTRYOFFSET	:= 0x400


CFLAGS 		+= -I include/ -I ./ -c -fno-builtin
ASMKFLAGS 	+= -I include/ -I ./ -f elf
LDFLAGS 	+= -Ttext $(ENTRYPOINT)
DASMFLAGS	+= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)


SRCS_KLIB := $(wildcard ./*/*.c)
SRCS_KLIB += $(wildcard ./*/*.asm)
DEPS_KLIB := $(SRCS_KLIB:%.c=%.d)
DEPS_KLIB := $(filter %.d, $(DEPS_KLIB))
OBJS_KLIB := $(SRCS_KLIB:%.c=%.o)
OBJS_KLIB += $(SRCS_KLIB:%.asm=%.obj)
OBJS_KLIB := $(filter %.obj %.o, $(OBJS_KLIB))

SRCS_BOOT := start.asm  start.c
DEPS_BOOT := $(SRCS_BOOT:%.c=%.d)
DEPS_BOOT := $(filter %.d, $(DEPS_BOOT))
OBJS_BOOT := start.obj  start.o


OBJS := $(OBJS_BOOT) $(OBJS_KLIB)
DEPS := $(DEPS_BOOT) $(DEPS_KLIB)


$(KERNEL): $(OBJS)
	@echo -e "  LD\t$(notdir $@)"
	@$(LD) $(LDFLAGS) -o $@  $(OBJS)
	@cp $(KERNEL) $(KERNEL).unstrip
	@echo -e "  STRIP\t$(notdir $@)"
	@$(STRIP) $(KERNEL)




dump:
	$(DASM) $(DASMFLAGS) $(KERNEL).unstrip > $(KERNEL_DUMP)





.PHONY: clean
clean :
	rm -f $(KERNEL) $(KERNEL).unstrip  $(OBJS) $(DEPS)  $(KERNEL_DUMP)



%.obj: %.asm
	@echo -e "  ASM\t$(notdir $@)"
	@$(ASM) $(ASMKFLAGS) -o $@ $<


%.o: %.c
	@echo -e "  CC\t$(notdir $@)"
	@$(CC) $(CFLAGS) -o $@ $<


%.d: %.c
	@echo -e "  DEP\t$(notdir $@)"
	@set -e; \
	$(CC) -E -MM $(CFLAGS) $(filter %.c, $^) >$@.tmp;\
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.tmp >$@;\
	rm -rf $@.tmp



-include 	$(DEPS_KLIB) $(DEPS_BOOT)

